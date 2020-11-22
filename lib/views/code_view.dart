

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harpokrat/controller/session.dart';

class CodeView extends StatefulWidget {
  CodeView({Key key, @required this.session}) : super(key: key);

  Session session;

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
}

class CodeViewPage extends State<CodeView> {
  @override
  Widget build(BuildContext context) {
    TextEditingController formController;
    return Center(child: Column(
      children: [
        Text("Please enter the code you received below"),
        TextFormField(
          controller: formController,
        ),
        Builder(builder: (context) =>
        MaterialButton(
          onPressed: () => widget.session.verifyToken(formController.text)
              .then((value) => value ?
              Navigator.pushNamed(context, "detail_menu")
          : Scaffold.of(context).showSnackBar(SnackBar(content: Text("Code incorrect, try again")))),
          child: Text("Send code"),
        ))
      ],
    ),);
  }

}