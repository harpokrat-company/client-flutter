import 'package:flutter/material.dart';

import 'passwd_list.dart';
import 'preferences.dart';
import 'session.dart';


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
        page = new MaterialPageRoute(builder: (ctxt) => new PasswordListState(session: widget.session));
        break;
      case 2:
        page = new MaterialPageRoute(builder: (ctxt) => new PreferenceState(session: widget.session));
        break;
      default:
        break;
    }
    if (page != null)
      Navigator.push(context, page);
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
    // TODO: implement build
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("My informations"),
      ),
      body: Center(
        child: !widget.infoFetched ? CircularProgressIndicator() : Column(
          children: <Widget> [
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text("First name"),
              subtitle: Text(widget.session.user.attributes["firstName"]),
              trailing: Icon(Icons.more_vert),
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text("Last name"),
              subtitle: Text(widget.session.user.attributes["lastName"]),
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
      bottomNavigationBar: BottomNavigationBar(
          onTap: _onItemTapped,
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