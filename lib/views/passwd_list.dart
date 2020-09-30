import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'package:harpokrat/model/Password.dart';
import 'package:harpokrat/controller/session.dart';
import 'package:harpokrat/views/create_element.dart';
import 'package:harpokrat/views/password_search.dart';
import 'package:harpokrat/views/password_view.dart';





class PasswordListState extends StatefulWidget {
  PasswordListState({Key key, @required this.session, this.title}) : super(key: key);

  final String title;
  final Session session;

  @override
  PasswordList createState() {
    return PasswordList();
  }

  Future<List<Password>> loadPassword() async {
    await session.getPersonalInfo();
    return this.session.getPassword();
  }

}


class PasswordList extends State<PasswordListState> {
  ListView listView;
  List<Password> passwordList;
  bool loaded = false;
  bool loading = false;

  Future<Null> loadPassword() async {

    this.loading = true;
    return widget.loadPassword().then((onValue) {
      setState(() {
        this.passwordList = onValue;
        this.loadWidget(onValue);
        this.loading = false;
      });
    });
  }

  void _onItemTapped(int index) {
    var page;
    switch (index) {
      case 1:
        page = "user_informations";
        break;
      case 2:
        page = "preferences";
        break;
      default:
        return;
    }
    Navigator.pushReplacementNamed(context, page, arguments: widget.session);
  }



  Future<Null> _refresh() {
    return this.loadPassword();
  }

  /// This method generates the password list
  ///
  void loadWidget(List<Password> passwordList) {
    this.listView = ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: passwordList.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            height: 144,
            child: Card(
              child: InkWell(
              onTap: () => Navigator.push(context,
                  new MaterialPageRoute(
                      builder: (ctxt) => new PasswordView(
                          session: widget.session, password: passwordList[index]))),
          child:Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.security),
                    title: Text('${passwordList[index].secret.name}'),
                    subtitle: Text('${passwordList[index].secret.login}'),
                  ),
                  ButtonBarTheme( // make buttons use the appropriate styles for cards
                    child: ButtonBar(
                      children: <Widget>[
                        FlatButton(
                          child: const Text('COPY'),
                          onPressed: () {
                            Clipboard.setData(new ClipboardData(text: passwordList[index].secret.password));
                            Scaffold.of(context).showSnackBar(new SnackBar(content: Text("password copied to clipboard")));
                            },
                        ),
                        FlatButton(
                          child: const Text('SHOW'),
                          onPressed: () { Scaffold.of(context)
                              .showSnackBar(new SnackBar(content: Text("Your password is ${passwordList[index].secret.password}"))); },
                        ),
                      ],
                    ),
                    data: ButtonBarThemeData(),
                  ),
                ],
              ),
            ),));
        }
    );
    this.loaded = true;
  }

  ListView loadGroups() {
    return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: passwordList.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
              height: 144,
              child: ExpansionTile(
                title: Text("PLOP"),

              ));
        }
    );
  }

  // This widget is the root of my page
  @override
  Widget build(BuildContext context) {
    if (this.loaded == false && this.loading == false)
      this.loadPassword();
    return new Scaffold(
      resizeToAvoidBottomInset: false,
        drawer: Drawer(
          child: Text("PLOP")
        ),
        appBar: new AppBar(
          title: new Text("My passwords"),
          leading: new MaterialButton(
            child: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.popAndPushNamed(context, "main", arguments: widget.session),
          ),
          actions: [IconButton(
            icon: Icon(Icons.search),
            onPressed: () => showSearch(context: context, delegate: PasswordSearchDelegate(this.passwordList, widget.session)),
          )],
        ),
        body: RefreshIndicator(
            onRefresh: _refresh,
            child:(this.loading) ? CircularProgressIndicator(): this.listView),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, new MaterialPageRoute(builder: (ctxt) => new CreateElementState(session: widget.session))),
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}