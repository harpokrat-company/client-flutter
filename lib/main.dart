import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harpokrat/preferences.dart';
import 'package:harpokrat/views/passwd_list.dart';
import 'package:harpokrat/session.dart';
import 'package:harpokrat/views/subscribe.dart';
import 'package:harpokrat/views/user_information.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> routes = {
      "password_list": (x) => new PasswordListState(session: x),
      "user_informations": (x) => new UserInformationState(session: x),
      "preferences": (x) => new PreferenceState(session: x)
    };
    return new MaterialApp(
      title: 'Harpokrat mobile client',
      theme: new ThemeData(
        accentColor: Colors.blueAccent,
        backgroundColor: Colors.black
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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _errorScaffoldKey = GlobalKey<ScaffoldState>();

  String errorMessage;


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

  void launchSubscribePage() {
    Navigator.push(context,
      new MaterialPageRoute(builder: (ctxt) => new SubscribeState(session: widget.session)),);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return new Scaffold(
      key: this._errorScaffoldKey,
        appBar: new AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: new Text(widget.title),
        ),
        body: new Center(

          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Image(image: AssetImage("images/HPKLogo.png"))),
              Text("HPK", style: TextStyle(fontSize: 80)),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  icon: Icon(Icons.account_box),
                  hintText: 'Please enter your email address',
                ),
                controller: emailController,
              ),
              TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.vpn_key),
                  hintText: 'Please enter your password',
                ),
                obscureText: true,
                controller: passwordController,
              ),
              InkWell (
                child: Text("I don't have an account",
                  style: TextStyle(
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline),
                textScaleFactor: 1.3,),
                onTap: launchSubscribePage,
              ),
              if (_loading)
                CircularProgressIndicator()
              else
                RaisedButton(
                    onPressed: connectUser,
                    child: const Text(
                        'Log in',
                        style: TextStyle(fontSize: 20)
                    )),
            ],
          ),
        )
    );
  }
}
