import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:harpokrat/model/Organization.dart';
import 'package:harpokrat/model/Password.dart';
import 'package:harpokrat/widget/buttons.dart';

import '../controller/session.dart';
import 'group_view.dart';


class OrganizationView extends StatefulWidget {
  OrganizationView({Key key, @required this.session, @required this.organization}) : super(key: key) {
  }

  Session session;
  Organization  organization;
  @override
  State<StatefulWidget> createState() {
    return OrganizationViewPage();
  }
}


class OrganizationViewPage extends State<OrganizationView> {
  bool isObscured = true;
  String tabName = "group";

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
                        widget.organization.getIdentifier()).then((value) => _showSnackBar(context, value ? "User ${nameController.text} added": "Unable to add User"));
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }
  void _showAddGroupDialog() {
    final nameController = TextEditingController();

    showDialog(context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Create a new group"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    hintText: 'Enter organisation name',
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
                  widget.session.createOrganisationGroup(nameController.text,
                      widget.organization)
                      .then((value) => _showSnackBar(context, value ? "Group ${nameController.text} created": "Unable to create Group"));
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
          leading: Icon(Icons.group),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => null,
          ),
          onTap: () => Navigator.push(context,
              new MaterialPageRoute(
                  builder: (ctxt) => new GroupView(
                      session: widget.session, group: widget.organization.groups[index],
                      organization: widget.organization)))
      );
      },);
  }

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    setState(() {});
  }


  ListView buildMemberList() {
    final members = widget.organization.members;
    return ListView.builder(
      itemCount:members.length,
      itemBuilder: (context, index) {
        return Slidable(
            actionPane: SlidableDrawerActionPane(),
            child: ListTile(
              leading: Icon(Icons.account_circle),
              title: Text(members[index].email),
            ),
          actions: <Widget>[
            IconSlideAction(
              caption: 'Ban',
              color: Colors.red,
              icon: Icons.delete,
              onTap: () => widget.session.banOrganizationMember(members[index].email,  members[index].getIdentifier())
                  .then((value) => _showSnackBar(context, value ? 'User ${members[index].email} banned': 'Network error')),
            ),
          ],
        );
      },);
  }
  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
        length: 2,
        child: MaterialApp(
            theme: Theme.of(context),
            home: Scaffold(
              appBar: AppBar(
                bottom: TabBar(
                  isScrollable: false,
                  onTap: (index) {
                    setState(() {
                      tabName = index == 0 ? "group": "member";
                    });
                  },
                  tabs: [
                    Tab(icon: Icon(Icons.group), text: "Groups",),
                    Tab(icon: Icon(Icons.account_circle), text: "Members",),
                  ],
                ),
                title: Text(widget.organization.name),
              ),
              body: TabBarView(
                children: [
                  Center(
                    child: buildGroupList(),
                  ),
                  Center(
                    child: buildMemberList(),
                  ),
                ],
              ),
              floatingActionButton: Builder(builder: (context) => FloatingActionButton.extended(
                icon: Icon(Icons.add),
                label: Text(tabName),
                onPressed: () => (tabName == "group" ? _showAddGroupDialog() : _showAddUserDialog()),
              ),
              ),
            )
        )
    );
  }
}
