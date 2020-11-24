
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harpokrat/controller/session.dart';
import 'package:harpokrat/views/vault_list.dart';
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
      case 1:
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
            title: Text("My Vaults"),
            subtitle: Text("See your personal vaults"),
            onTap: () => Navigator.push(context,
                new MaterialPageRoute(
                    builder: (ctxt) => new VaultList(
                        session: widget.session, owner: widget.session.user.asOwner(),)))),
          ListTile(
            title: Text("Multi factor authentication"),
            subtitle: Text("See and setup the way we can make your connection more secure"),
            onTap: () => Navigator.pushNamed(context, "mfa", arguments: widget.session),
          ),
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
              icon: Icon(Icons.settings),
              title: Text('Settings'),
            ),
          ]
      ),
    );
  }

}