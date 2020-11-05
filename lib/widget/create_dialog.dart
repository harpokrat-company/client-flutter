
import 'package:flutter/material.dart';

void showCreateDialog(BuildContext context, String title, String hintText, Function onSave) {
  final nameController = TextEditingController();

  showDialog(context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  hintText: hintText,
                ),
                controller: nameController,
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("Save"),
              onPressed: () {
                onSave(nameController.text);
                Navigator.of(context).pop();
              },
            )
          ],
        );
      });
}