import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';


class PasswdListState extends StatefulWidget {
  PasswdListState({Key key, this.title}) : super(key: key);

  final String title;
  ListView listView;
  final passwordList = ["Google", "Outlook", "Facebook", "Amazon", "twitter"];
  final passwordHint = ["email and services provider", "e-mail provider",
  'social media', 'e-shop', 'social media'];

  @override
  PasswdList createState() {
    this.listView = ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: this.passwordList.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            height: 144,
            child: Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.security),
                    title: Text('${this.passwordList[index]}'),
                    subtitle: Text('${this.passwordHint[index]}'),
                  ),
                  ButtonTheme.bar( // make buttons use the appropriate styles for cards
                    child: ButtonBar(
                      children: <Widget>[
                        FlatButton(
                          child: const Text('COPY'),
                          onPressed: () { /* ... */ },
                        ),
                        FlatButton(
                          child: const Text('SHOW'),
                          onPressed: () { /* ... */ },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),);
        }
    );
    return PasswdList();
  }
}


class PasswdList extends State<PasswdListState> {
  // This widget is the root of my page
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("My passwords"),
        ),
        body: widget.listView,
        bottomNavigationBar: BottomNavigationBar(
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
              )
            ]
        )
    );
  }
}