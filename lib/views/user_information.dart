import 'package:flutter/material.dart';

import '../controler/session.dart';


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

  void _onItemTapped(int index) {
    var page;
    switch (index) {
      case 0:
        page = "password_list";
        break;
      case 2:
        page = "preferences";
        break;
      default:
        return;
    }
    Navigator.pushReplacementNamed(context, page, arguments: widget.session);
  }

  Future<bool> fetchUserInfo() async {
    if (widget.infoFetched == false) {
      final isFetched = await widget.session.getPersonalInfo();
      setState(() {
        widget.infoFetched = isFetched;
      });
    }
    return widget.infoFetched;
  }

  @override
  Widget build(BuildContext context) {
    fetchUserInfo();

    var firstNameController = new TextEditingController();
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
            )
          ],
        )
      ),
      floatingActionButton: Builder (builder: (context) => FloatingActionButton.extended(
        onPressed: () {
      widget.session.user.attributes["firstName"] = firstNameController.text;
      widget.session.user.attributes["lastName"] = lastNameController.text;
      widget.session.updateUser().then((value) =>
      Scaffold.of(context).showSnackBar(
          SnackBar(content: Text(value ? "Information updated" : "Error updating information"),))
      );},
        label: Text("Save"),
    icon: Icon(Icons.save),
    backgroundColor: Colors.blueAccent,
    )),
      bottomNavigationBar: BottomNavigationBar(
          onTap: _onItemTapped,
          currentIndex: 1,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              title: Text('Home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_box),
              title: Text('Personal info'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              title: Text('Settings'),
            ),
          ]
      ),
    );
  }
}