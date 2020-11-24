

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:harpokrat/controller/session.dart';

class CodeView extends StatefulWidget {
  CodeView({Key key, @required this.session}) : super(key: key);

  Session session;

  @override
  State<StatefulWidget> createState() {
    return CodeViewPage();
  }
}

class CodeViewPage extends State<CodeView> {
  @override
  Widget build(BuildContext context) {
    TextEditingController formController = TextEditingController();
    return Scaffold(
        body: Center(child: Card(
      child: Column(children: [
        ListTile(
        title: Text("Please enter the code you received below", style: TextStyle(
          fontSize: 20,
        ),),
        subtitle: TextFormField(
          controller: formController,
        ),
      ),
        Builder(builder: (context) =>
            MaterialButton(
              onPressed: () => widget.session.verifyToken(formController.text)
                  .then((value) => value ?
              Navigator.pushNamed(context, "detail_menu", arguments: widget.session)
                  : Scaffold.of(context).showSnackBar(SnackBar(content: Text("Code incorrect, try again")))),
              child: Text("Verify code"),
              textColor: Colors.white,
              color: Theme.of(context).accentColor,
            )),

      ]
      )
        )
        )
    );
  }

}