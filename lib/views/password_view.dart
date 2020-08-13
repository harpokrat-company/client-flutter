import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:harpokrat/model/Password.dart';

import '../controler/session.dart';


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
  bool isObscured = true;


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
            child: SizedBox(
              width: 400,
                child: Card(

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget> [
                        Text("Password"),
                        TextField(controller: nameTextController,
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.label),
                              labelText: "Name"),),
                        SizedBox(height: 10),
                        TextField(controller: domainTextController,
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.domain),
                              labelText: "Domain"
                          ),),
                        SizedBox(height: 10), // use Spacer
                        TextField(controller: loginTextController,
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.account_circle),
                              labelText: "Login",
                              suffixIcon: Icon(Icons.content_copy)
                          ),),
                        SizedBox(height: 10),
                        TextField(
                            obscureText: isObscured,
                            decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: Icon(Icons.lock),
                                suffix: MaterialButton(child:Icon(isObscured ? Icons.visibility: Icons.visibility_off),
                                    onPressed: () => {setState(() => {isObscured = !isObscured})})
                            ),
                            controller: passwordTextController),
                        RaisedButton(color: Colors.red,
                          textColor: Colors.white,
                          child: Text("Delete password"),
                          onPressed: () {
                            widget.session.deletePassword(widget.password)
                                .then((value) => Navigator.of(context).pop());
                          },)
                      ],
                    )
                )
            )
        ),
        floatingActionButton: Builder(builder: (context) => FloatingActionButton.extended(
          onPressed: () {
            widget.password.secret.name = nameTextController.text;
            widget.password.secret.domain = domainTextController.text;
            widget.password.secret.login = loginTextController.text;
            widget.password.secret.password = passwordTextController.text;
            widget.session.updatePassword(widget.password)
                .then((value) => Scaffold.of(context)
                .showSnackBar(SnackBar(content: Text(value ? "Password updated": "Error when updating password"),)));},
          icon: Icon(Icons.save),
          label: Text("Save"),
          backgroundColor: Colors.blueAccent,
        ))

    );
  }
}