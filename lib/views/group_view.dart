import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:harpokrat/model/Group.dart';
import 'package:harpokrat/model/Organization.dart';
import 'package:harpokrat/views/vault_view.dart';
import 'package:harpokrat/widget/create_dialog.dart';


import '../controller/session.dart';


class GroupView extends StatefulWidget {
  GroupView({Key key, @required this.session, @required this.group, @required this.organization}) : super(key: key);

  Session session;
  Group  group;
  Organization organization;
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return GroupeViewPage();
  }
}


class GroupeViewPage extends State<GroupView> {
  bool isObscured = true;
  final tabNameList = ["group", "vault", "member"];
  String tabName = "group";

  void _showAddUserDialog() {
    final nameController = TextEditingController();

    showDialog(context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Add a user to a group"),
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
                    widget.session.addGroupMember(nameController.text,
                        widget.group.getIdentifier());
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  ListView buildGroupList() {
    final groups = widget.group.groups;
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return Slidable(
          actionPane: SlidableDrawerActionPane(),
          child: ListTile(
            leading: Icon(Icons.account_circle),
            title: Text(groups[index].name),
          ),
          actions: <Widget>[
            IconSlideAction(
              caption: 'Ban',
              color: Colors.red,
              icon: Icons.delete,
              onTap: () => widget.session.deleteGroup(groups[index])
                  .then((value) => _showSnackBar(context, value ? 'Group ${groups[index].name} banned': 'Network error')),
            ),
          ],
        );
      },
    );
  }

  ListView buildVaultList() {
    return ListView.builder(
      itemCount: widget.group.vaults.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(widget.group.vaults[index].name),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => null,
          ),
          onTap: () {
/*            widget.session.getVaultData(widget.group.vaults[index],
                widget.group.publicKey.asRSAPublic(), widget.group.privateKey.asRSAPrivate());*/
            Navigator.push(context,
              new MaterialPageRoute(
                  builder: (ctxt) => new VaultView(
                      session: widget.session, vault: widget.group.vaults[index])));
          },
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    setState(() {});
  }

  ListView buildMemberList() {
    final members = widget.group.members;
    return ListView.builder(
      itemCount: widget.group.members.length,
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
              onTap: () => widget.session.banGroupMember(members[index].email,  members[index].getIdentifier())
                  .then((value) => _showSnackBar(context, value ? 'User ${members[index].email} banned': 'Network error')),
            ),
          ],
        );
      },
    );
  }

  Future<bool> fetch() async {
    return await widget.group.fetchData(widget.session);
  }

  void onSaveUser(String userName) {
    widget.session.addGroupMember(userName,
        widget.group.getIdentifier());
  }

  void onSaveGroup(String groupName) {
    widget.session.createGroupGroup(groupName, widget.group, widget.organization);
  }

  Widget buildFrame(BuildContext context) {
    return new DefaultTabController(
        length: 3,
        child: MaterialApp(
            theme: Theme.of(context),
            home: Scaffold(
              appBar: AppBar(
                bottom: TabBar(
                  isScrollable: false,
                  onTap: (index) {
                    setState(() {
                      tabName = tabNameList[index];
                    });
                  },
                  tabs: [
                    Tab(icon: Icon(Icons.group), text: "Groups",),
                    Tab(icon: Icon(Icons.security), text: "Vaults",),
                    Tab(icon: Icon(Icons.account_circle), text: "Members",),
                  ],
                ),
                title: Text(widget.group.name),
              ),
              body: buildTabBarView(context),
              floatingActionButton: Builder(builder: (context) => FloatingActionButton.extended(
                icon: Icon(Icons.add),
                label: Text(tabName),
                onPressed: () {
                  if (tabName == "group")
                    showCreateDialog(context, "New Group", "Group name", onSaveGroup);
                  if (tabName == "member")
                  showCreateDialog(context, "New member", "member email", onSaveUser);
                },
              ),
              ),
            )
        )
    );
  }

  Widget  buildTabBarView(BuildContext context) {
    return FutureBuilder<bool>(
        future: this.fetch(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return TabBarView(
                children: [
                  Center(child: CircularProgressIndicator()),
                  Center(child: CircularProgressIndicator()),
                  Center(child: CircularProgressIndicator())
                ]
            );
          } else {
            if (snapshot.hasError)
              return TabBarView(
                  children: [
                    Center(child: Text('Error: ${snapshot.error}')),
                    Center(child: Text('Error: ${snapshot.error}')),
                    Center(child: Text('Error: ${snapshot.error}'))
                  ]);
            else
              return new TabBarView(
              children: [
                Center(
                  child: buildGroupList(),
                ),
                Center(
                  child: buildVaultList(),
                ),
                Center(
                  child: buildMemberList(),
                ),
              ],
            );
          }
        }
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return buildFrame(context);
  }
}