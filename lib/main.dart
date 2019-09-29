import 'package:flutter/material.dart';
import 'package:harpokrat/passwd_list.dart';
import 'package:harpokrat/session.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Harpokrat mobile client',
      theme: new ThemeData(
        accentColor: Colors.blueAccent,
      ),
      home: new MyHomePage(title: 'Harpokrat'),
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
      this.launchPasswdList();
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
        print("in catchErro");
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

  void launchPasswdList() {
    Navigator.push(context,
      new MaterialPageRoute(builder: (ctxt) => new PasswdListState(session: widget.session)),);
    print("New page launched");
      _loading = false;
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
              Image(image: AssetImage("images/HPKLogo.png"), height: 150),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  hintText: 'Please enter your email address',
                ),
                controller: emailController,
              ),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  hintText: 'Please enter your password',
                ),
                obscureText: true,
                controller: passwordController,
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
