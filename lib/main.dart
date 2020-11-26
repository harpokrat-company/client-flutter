import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harpokrat/controller/f_grecaptcha.dart';
import 'package:harpokrat/views/code_view.dart';

import 'package:harpokrat/views/mfa_view.dart';
import 'package:harpokrat/views/organisation_list.dart';
import 'package:harpokrat/views/preferences.dart';
import 'package:harpokrat/views/passwd_list.dart';
import 'package:harpokrat/controller/session.dart';
import 'package:harpokrat/views/user_information.dart';
import 'package:harpokrat/views/user_menu_view.dart';
import 'package:hclw_flutter/symmetrickey.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_login/flutter_login.dart';

import 'model/User.dart';



void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> routes = {
      "main": (x) => new MyHomePage(),
      "password_list": (x) => new PasswordListState(session: x),
      "user_informations": (x) => new UserInformationState(session: x),
      "preferences": (x) => new PreferenceState(session: x),
      "mfa": (x) => new MfaView(session: x),
      "detail_menu": (x) => new UserView(session: x),
      "code_view": (x) => new CodeView(session: x),
      "organisation_list": (x) => new OrganisationList(session: x)
    };
    final hpkBlue = Color.fromARGB(255, 56, 103, 143);
    return new MaterialApp(
      title: 'Harpokrat mobile client',
      theme: ThemeData(
      primarySwatch: Colors.blueGrey,
        buttonColor: hpkBlue,
        primaryColor: hpkBlue,
        accentColor: hpkBlue,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,

          fillColor: hpkBlue.withOpacity(.1),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: hpkBlue, width: 1),
              gapPadding: 20,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(5.0),
                top: Radius.circular(5.0),
              )
          ),
          contentPadding: EdgeInsets.zero,
          errorStyle: TextStyle(
            backgroundColor: Colors.redAccent,
            color: Colors.black,
          ),
          border: OutlineInputBorder(
              borderSide: BorderSide(color: hpkBlue, width: 1),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(5.0),
                top: Radius.circular(5.0),
              )
          ),

        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: hpkBlue,
          splashColor: hpkBlue,
          hoverColor: Colors.yellow,
          focusColor: hpkBlue
        ),
        cursorColor: Colors.grey,
        textTheme: TextTheme(
          display2: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 45.0,
            color: Colors.orange,
          ),
          button: TextStyle(
            fontFamily: 'OpenSans',
          ),
          subhead: TextStyle(fontFamily: 'NotoSans'),
          body1: TextStyle(fontFamily: 'NotoSans'),
        ),
      ),
      initialRoute: "/",
      onGenerateRoute: (setting) {
        return CupertinoPageRoute(
          builder: (context) =>  routes[setting.name](setting.arguments)
        );
      },
      home: new MyHomePage(title: 'Harpokrat password manager'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  Session session = Session('https://api.harpokrat.com', "443");

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loading = false;
  String action;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _errorScaffoldKey = GlobalKey<ScaffoldState>();

  String errorMessage;



  Future<void> initPlatformState() async {
  }

  void handleConnection(bool success) {
    if (success)
      this.launchPasswordList();
    else {
      setState(() {
        _loading = false;
        errorMessage = "Can't connect user: ${emailController.text}";
      });
      _errorScaffoldKey.currentState.showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  ///
  /// This method tries to connect to the server and display a
  /// snackbar with the error on it when it fails
  ///
  void connectUser() {
    setState(() {
      _loading = true;
    });
    final email = emailController.text;
    try {
      Future<bool> connected =
      widget.session.connectUser(email, passwordController.text);
      connected.then(this.handleConnection).
      catchError((onError) {
        print("in catchError");
        setState(() {
          _loading = false;
        });
        _errorScaffoldKey.currentState.showSnackBar(SnackBar(content: Text(onError.toString())));
      });
    } on Exception catch (e) {
      setState(() {
        _loading = false;
      });
      _errorScaffoldKey.currentState.showSnackBar(SnackBar(content: Text(errorMessage)));
    }
    print("Exiting connectUser function");
  }

  @override
  void dispose() {
    // dispose data to avoid critical memory leaks
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void launchPasswordList() {
    setState(() {
      _loading = false;
    });
    Navigator.pushNamed(context, "password_list", arguments: widget.session);
  }

  _launchURL() async {
    const url = 'https://www.harpokrat.com/login/forgot-password';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }


  Future<String> _authUser(LoginData data) {
    var future = widget.session.connectInitUser(data.name, data.password);
    action = "login";
    return future.then((value) => value ? null: "cannot connect user");
  }

  Future<String> _registerUser(LoginData data) async {
    print('Name: ${data.name}, Password: ${data.password}');
    final SITE_KEY = "6LfZE9EZAAAAAK7e-A9oK426Ei3m_l_2QKn8mmBQ";
    var futureCaptcha = FGrecaptcha.verifyWithRecaptcha(SITE_KEY).then((jwt) {
      var symKey = new SymmetricKey(widget.session.lib);
      symKey.key = data.password;
      var future = widget.session.createUser(new User(data.name, data.password, symKey), jwt);

      action = "register";
      return future.then((value) => value ? _authUser(data) : "cannot create user");
    }, onError: (e, s){
      print("Could not verify:\n $e at\n $s");
    });
    return futureCaptcha.then((value) => value);
  }

  @override
  Widget build(BuildContext context) {
    final hpkBlue = Color.fromARGB(255, 56, 103, 143);

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return FlutterLogin(
      title: 'Harpokrat',
      logo: 'images/HPKLogo.png',
      onLogin: _authUser,
      onSignup: _registerUser,
      onSubmitAnimationCompleted: () {
        if (action == "login") {
          if (widget.session.user.mfa)
            Navigator.pushReplacementNamed(context, "code_view",
                arguments: widget.session);
          else
            Navigator.pushReplacementNamed(context, "detail_menu",
                arguments: widget.session);
        }
      },
      messages: LoginMessages(
          recoverPasswordDescription: "We will send you a link to reset your password"
      ),
      onRecoverPassword: (okio) async => okio,
      theme: LoginTheme(
        primaryColor: hpkBlue,
        accentColor: hpkBlue.withOpacity(0),
        errorColor: Colors.redAccent,
        titleStyle: TextStyle(
          color: Colors.grey.shade900,
          fontFamily: 'Quicksand',
          letterSpacing: 4,
        ),
        bodyStyle: TextStyle(
          color: Colors.black,
        ),
        pageColorDark: hpkBlue,
        pageColorLight: hpkBlue,
        cardTheme: CardTheme(
        color: Colors.white,
        elevation: 5,
          margin: EdgeInsets.all(25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
          inputTheme: InputDecorationTheme(
              filled: true,
              fillColor: hpkBlue.withOpacity(.1),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: hpkBlue, width: 1),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(5.0),
                    top: Radius.circular(5.0),
                  )
              ),
              contentPadding: EdgeInsets.zero,
              errorStyle: TextStyle(
                backgroundColor: Colors.redAccent,
                color: Colors.black,
              ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: hpkBlue, width: 1),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(5.0),
                  top: Radius.circular(5.0),
                )
            ),
          ),
        buttonTheme: LoginButtonTheme(
          splashColor: Colors.white,
          backgroundColor: hpkBlue,
          highlightColor: Colors.blueAccent,
          elevation: 1,
          highlightElevation: 6.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))
        ),
      ),
    );
  }
}
