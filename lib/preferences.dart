import 'package:flutter/material.dart';
import 'package:harpokrat/user_information.dart';

import 'passwd_list.dart';
import 'session.dart';


class PreferenceState extends StatefulWidget {
  PreferenceState({Key key, @required this.session}) : super(key: key);

  final Session session;

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return PreferencePage();
  }
}

void darkModeChanged(bool newState) {

}

class PreferencePage extends State<PreferenceState> {

  void _onItemTapped(int index) {
    var page;
    switch (index) {
      case 0:
        page = new MaterialPageRoute(builder: (ctxt) => new PasswordListState(session: widget.session));
        break;
      case 1:
        page = new MaterialPageRoute(builder: (ctxt) => new UserInformationState(session: widget.session));
        break;
    }
    Navigator.push(context, page);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("My preferences"),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.local_hotel),
                title: Text("dark mode"),
                subtitle: Text("Let your eyes rest"),
                trailing: Switch(value: false, onChanged: darkModeChanged)
            ),
            ListTile(
                leading: Icon(Icons.https),
                title: Text("Keep me logged"),
                subtitle: Text("So you don't have to enter your password everytime"),
                trailing: Switch(value: false, onChanged: darkModeChanged)
            )
          ],
        ),
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