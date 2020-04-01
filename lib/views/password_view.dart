import 'package:flutter/material.dart';
import 'package:harpokrat/entities/Password.dart';
import 'package:hclw_flutter/secret.dart' as hclw_secret;

import 'passwd_list.dart';
import '../preferences.dart';
import '../session.dart';


class PasswordView extends StatefulWidget {
  PasswordView({Key key, @required this.session, @required this.password}) : super(key: key);

  Session session;
  Password  password;
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return PasswordViewPage();
  }
}


class PasswordViewPage extends State<PasswordView> {
  void _onItemTapped(int index) {
    var page;
    switch (index) {
      case 0:
        page = new MaterialPageRoute(builder: (ctxt) => new PasswordListState(session: widget.session));
        break;
      case 2:
        page = new MaterialPageRoute(builder: (ctxt) => new PreferenceState(session: widget.session));
        break;
      default:
        break;
    }
    if (page != null)
      Navigator.push(context, page);
  }

  @override
  Widget build(BuildContext context) {
    var nameTextController = new TextEditingController(text: widget.password.secret.name);
    var domainTextController = new TextEditingController(text: widget.password.secret.domain);
    var loginTextController = new TextEditingController(text: widget.password.secret.login);
    var passwordTextController = new TextEditingController(text: widget.password.secret.password);

    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.password.secret.name),
      ),
      body: Center(
          child: Column(
            children: <Widget> [
              ListTile(
                leading: Icon(Icons.label),
                title: Text("Name"),
                subtitle: TextField(controller: nameTextController),
              ),
              ListTile(
                leading: Icon(Icons.domain),
                title: Text("Domain"),
                subtitle: TextField(controller: domainTextController),
              ),
              ListTile(
                  leading: Icon(Icons.account_circle),
                  title: Text("Login"),
                subtitle: TextField(controller: loginTextController,),
              ),
              ListTile(
                  leading: Icon(Icons.lock),
                  title: Text("Password"),
                subtitle: TextField(controller: passwordTextController),
                trailing: Icon(Icons.more_vert),
              ),
              RaisedButton(color: Colors.red,
                textColor: Colors.white,
                child: Text("Delete password"),
              onPressed: () => widget.session.deletePassword(widget.password),)
            ],
          )
      ),
      bottomNavigationBar: BottomNavigationBar(
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              title: Text('Home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_box),
              title: Text('Personal info'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              title: Text('Settings'),
            ),
          ]
      ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            widget.password.secret.name = nameTextController.text;
            widget.password.secret.domain = domainTextController.text;
            widget.password.secret.login = loginTextController.text;
            widget.password.secret.password = passwordTextController.text;
            widget.session.updatePassword(widget.password);},
          child: Icon(Icons.save),
          backgroundColor: Colors.blueAccent,
        )

    );
  }
}