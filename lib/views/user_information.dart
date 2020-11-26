import 'package:flutter/material.dart';
import 'package:harpokrat/views/organization_view.dart';

import '../controller/session.dart';


class UserInformationState extends StatefulWidget {
  UserInformationState({Key key, @required this.session}) : super(key: key);

  Session session;
  bool infoFetched = false;
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return UserInformationPage();
  }
}

void darkModeChanged(bool newState) {

}

class UserInformationPage extends State<UserInformationState> {

  Future<bool> fetchUserInfo() async {
    if (widget.infoFetched == false) {
      final isFetched = await widget.session.getPersonalInfo();
      setState(() {
        widget.infoFetched = isFetched;
      });
    }
    return widget.infoFetched;
  }

  ListView getOrganizations() {
    final ol = widget.session.user.organizations;
    return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: ol.length,
      itemBuilder: (BuildContext context, int index) {
          return ListTile(
            onTap: () => Navigator.push(context, new MaterialPageRoute(builder: (ctxt) => new OrganizationView(session: widget.session, organization: ol[index],))),
            title: Text(ol[index].name),

            subtitle: ol[index].groups.length != 0 ? Text(ol[index].groups[0].name)
            : Text("This organization contains no groups")
          );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    fetchUserInfo();

    var firstNameController = new TextEditingController();
    var passwordController = new TextEditingController();
    var lastNameController = new TextEditingController();
    if (widget.infoFetched) {
      firstNameController.text = widget.session.user.attributes["firstName"];
      lastNameController.text = widget.session.user.attributes["lastName"];
    }
    // TODO: implement build
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("My informations"),
        leading: MaterialButton(child: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.popAndPushNamed(context, "main", arguments: widget.session),
        ),
      ),
      body: Center(
        child: !widget.infoFetched ? CircularProgressIndicator() : Column(
          children: <Widget> [
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text("First name"),
              subtitle: TextField(controller: firstNameController),
              trailing: Icon(Icons.more_vert),
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text("Last name"),
                subtitle: TextField(controller: lastNameController),
                trailing: Icon(Icons.more_vert)
            ),
            ListTile(
                leading: Icon(Icons.mail),
                title: Text("E-mail"),
                subtitle: Text(widget.session.user.email),
                trailing: Icon(Icons.more_vert)
            ),
            ListTile(
                leading: Icon(Icons.security),
                title: Text("Password"),
                subtitle: Text(widget.session.user.password),
                trailing: Icon(Icons.more_vert)
            ),
          ],
        )
      ),
      floatingActionButton: Builder (builder: (context) => FloatingActionButton.extended(
        onPressed: () {
      widget.session.user.attributes["firstName"] = firstNameController.text;
      widget.session.user.attributes["lastName"] = lastNameController.text;
          widget.session.user.password = passwordController.text;
      widget.session.updateUser().then((value) =>
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? "Information updated" : "Error updating information"),))
      );},
        label: Text("Save"),
    icon: Icon(Icons.save),
    backgroundColor: Colors.blueAccent,
    )),
    );
  }
}