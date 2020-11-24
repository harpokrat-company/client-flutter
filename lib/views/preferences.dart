import 'package:flutter/material.dart';

import '../controller/session.dart';


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
        page = "detail_menu";
        break;
      default:
        return;
    }
    Navigator.pushReplacementNamed(context, page, arguments: widget.session);
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("My preferences"),
        leading: MaterialButton(child: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.popAndPushNamed(context, "main", arguments: widget.session),
        ),
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
          currentIndex: 1,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              title: Text('Home'),
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