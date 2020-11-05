
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harpokrat/controller/session.dart';
import 'package:harpokrat/widget/buttons.dart';

class UserView extends StatefulWidget {
  UserView({Key key, @required this.session});

  Session session;


  @override
  State<StatefulWidget> createState() {
    return UserViewPage();
  }
}

class UserViewPage extends State<UserView> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User details"),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text("My personal information"),
            subtitle: Text("See and modify your name, surname"),
            onTap: () => Navigator.pushNamed(context, "user_informations", arguments: widget.session),
          ),
          ListTile(
            title: Text("My organisations"),
            subtitle: Text("See your organisations"),
            onTap: () => Navigator.pushNamed(context, "organisation_list", arguments: widget.session),
          ),
          ListTile(
            title: Text("Multi factor authentication"),
            subtitle: Text("See and setup the way we can make your connection more secure"),
            onTap: () => Navigator.pushNamed(context, "mfa", arguments: widget.session),
          ),
          showSheetButton(context, "Example", Column(children: [
            Text("PLaceholder text"),
            Icon(Icons.group),
            ActionChip(
              label: Text("Action chip"),
              onPressed: () => null,
            )
          ],))
        ],
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