import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:harpokrat/model/Organization.dart';
import 'package:harpokrat/model/Password.dart';

import '../controller/session.dart';


class OrganizationView extends StatefulWidget {
  OrganizationView({Key key, @required this.session, @required this.organization}) : super(key: key);

  Session session;
  Organization  organization;
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return OrganizationViewPage();
  }
}


class OrganizationViewPage extends State<OrganizationView> {
  bool isObscured = true;

  void _showAddUserDialog() {
    final nameController = TextEditingController();

    showDialog(context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Add a user to an organization"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    hintText: 'Enter user email',
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
                    widget.session.addOrganizationMember(nameController.text,
                        widget.organization.getIdentifier());
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  ListView buildGroupList() {
    return ListView.builder(
      itemCount: widget.organization.groups.length,
      itemBuilder: (context, index) {
      return ListTile(
        title: Text(widget.organization.groups[index].name),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => null,
             ),
      );
    },);
  }

  ListView buildMemberList() {
    return ListView.builder(
      itemCount: widget.organization.members.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(widget.organization.members[index].email),
        );
      },);
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.organization.name),
        ),
        body: Center(
          child: Column(
            children: [
              Text("Groups: "),
              Expanded(
                child: buildGroupList(),
              ),
              Text("Members: "),
              Expanded(
                child: buildMemberList(),
              )
            ],
          ),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: Text("Add user"),
      ),
    );
  }
}