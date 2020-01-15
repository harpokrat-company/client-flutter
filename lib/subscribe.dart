

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'entities/User.dart';
import 'session.dart';

class SubscribeState extends StatefulWidget {
  SubscribeState({Key key, @required session,this.title}) : super(key: key);

  final String title;
  Session session = Session('https://api.harpokrat.com', "443");

  @override
  SubscribePage createState() {
    return SubscribePage();
  }

}


class SubscribePage extends State<SubscribeState> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();


  void createUser() {
    if (passwordController.text != confirmPasswordController.text) {
      showDialog(context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Error"),
              content: Text("The passwords must be the same"),
              actions: <Widget>[
                FlatButton(
                  child: Text("Ok"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
      return;
    }
    final user = User(emailController.text, passwordController.text);
    user.attributes.addAll({
      "firstName": firstNameController.text,
      "lastName": lastNameController.text
    });
    final willUserCreated = widget.session.createUser(user);
    willUserCreated.then((isUserCreated) {
      if (isUserCreated) {
        print("USER created");
        showDialog(context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Success"),
                content: Text("User ${user.email} created"),
                actions: <Widget>[
                  FlatButton(
                    child: Text("Ok"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              );
            });
        // Navigator.of(context).pop();
      }
      else
        showDialog(context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Error"),
                content: Text("The server refused to create the user"),
                actions: <Widget>[
                  FlatButton(
                    child: Text("Ok"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              );
            });
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new Scaffold(
        body: new Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                  child: Image(image: AssetImage("images/HPKLogo.png"))),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  hintText: 'Please enter your first name',
                ),
                controller: firstNameController,
              ),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  hintText: 'Please enter your last name',
                ),
                controller: lastNameController,
              ),

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
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  hintText: 'Please confirm your password',
                ),
                obscureText: true,
                controller: confirmPasswordController,
              ),
              RaisedButton(
                  onPressed: createUser,
                  child: const Text(
                      'Subscribe',
                      style: TextStyle(fontSize: 20)
                  ))
            ],
          ),
        )
    );

  }

}