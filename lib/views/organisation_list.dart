import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harpokrat/controller/session.dart';
import 'package:harpokrat/views/organization_view.dart';
import 'package:flutter_slidable/flutter_slidable.dart';


class OrganisationList extends StatefulWidget {

  OrganisationList({Key key, @required this.session}): super(key: key);

  Session session;

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return OrganisationListPage();
  }
}

class OrganisationListPage extends State<OrganisationList> {

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    setState(() {});
  }

  ListView buildOrganisationList(BuildContext context) {
    final organizations = widget.session.user.organizations;
    return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: organizations.length,
        itemBuilder: (BuildContext context, int idx) {
          return Container(
            child: Slidable(
              actionPane: SlidableDrawerActionPane(),
            child: ListTile(
              title: Text(organizations[idx].name),
              subtitle: Text("${organizations[idx].members.length} members"),
              onTap: () =>  Navigator.push(context, new MaterialPageRoute(
                  builder: (ctxt) => new OrganizationView(
                      session: widget.session, organization: organizations[idx])))
            ),
              actions: <Widget>[
                IconSlideAction(
                  caption: 'Leave',
                  color: Colors.red,
                  icon: Icons.delete,
                  onTap: () => widget.session.banOrganizationMember(widget.session.user.email, organizations[idx].getIdentifier())
                      .then((value) => _showSnackBar(context, value ? 'Organization left': 'Network error')),
                ),
              ],
            )
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
                      widget.session.user.getIdentifier())
                      .then((value) => _showSnackBar(this.context, value ? "Organization ${nameController.text} created" : "Unbale to create organization"));
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  Widget buildFrame(BuildContext context) {
    return buildOrganisationList(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("My organizations"),
        ),
        body: FutureBuilder<bool>(
      future: widget.session.getPersonalInfo(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          else if (!snapshot.data)
            return Center(child: Text('Could not fetch user information'));
          else
            return buildFrame(context);
        }
      }
    ),
      floatingActionButton: Builder(builder: (context) => FloatingActionButton.extended(
        onPressed: _showCreateOrganizationDialog,
        icon: Icon(Icons.add),
        label: Text("Create new organization"),
        backgroundColor: Theme.of(context).accentColor,
      )),
    );
  }
}