import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:harpokrat/controller/session.dart';

class CreateElementState extends StatefulWidget {
  final String title;
  Session session;

  CreateElementState({Key key, @required this.session, this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new CreateElementPage();
  }
}



class CreateElementPage extends State<CreateElementState> {

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final orgaController = TextEditingController();


    showDialog(context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Create new organization"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    hintText: 'Enter name',
                  ),
                  controller: nameController,
                ),
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    hintText: 'Enter organization',
                  ),
                  controller: orgaController,
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
                  var o = widget.session.user.getOrganization(orgaController.text);
                  if (o != null)
                  widget.session.createOrganisationGroup(nameController.text,
                      o.getIdentifier());
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  void _showCreateOrganizationDialog() {
    final nameController = TextEditingController();
    showDialog(context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Create new organization"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    hintText: 'Enter name',
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
                  widget.session.createOrganization(nameController.text,
                      widget.session.user.getIdentifier());
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  void _showCreateVaultDialog() {
    final nameController = TextEditingController();
    showDialog(context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Create new vault"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    hintText: 'Enter name',
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
                  widget.session.createVault(nameController.text,
                      widget.session.user.getIdentifier());
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  void _showCreatePasswordDialog() {
    final nameController = TextEditingController();
    final loginController = TextEditingController();
    final passwordController = TextEditingController();
    showDialog(context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Create new password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    hintText: 'Enter name',
                  ),
                  controller: nameController,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    hintText: 'Enter login',
                  ),
                  controller: loginController,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    hintText: 'Enter password',
                  ),
                  obscureText: true,
                  controller: passwordController,
                )
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
                  widget.session.createPassword(nameController.text,
                      loginController.text,
                      passwordController.text, widget.session.user.getIdentifier());
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 200,
            ),
            MaterialButton(
              child: Text("Create new vault"),
              onPressed: _showCreateVaultDialog,
            ),
            MaterialButton(
              child: Text("Create new password"),
              onPressed: _showCreatePasswordDialog,
            ),
            MaterialButton(
              child: Text("Create new organisation"),
              onPressed: _showCreateOrganizationDialog,
            ),
            MaterialButton(
              child: Text("Create new group"),
              onPressed: _showCreateGroupDialog,
            )
          ],
        ),
      ),
    );
  }

}