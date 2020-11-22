
import 'package:flutter/material.dart';
import 'package:harpokrat/model/Password.dart';
import 'package:harpokrat/controller/session.dart';
import 'package:harpokrat/views/password_view.dart';


class PasswordSearchDelegate extends SearchDelegate {
  List<Password> passwordList;
  Session session;

  PasswordSearchDelegate(this.passwordList, this.session);


  @override
  Widget buildSuggestions(BuildContext context) {
    var filteredList = passwordList.where(
            (element) =>
                element.name.contains(this.query)
                    || element.login.contains(this.query)
                    || element.domain.contains(this.query))
        .toList();
    return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: filteredList.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            child: ListTile(
              onTap: () => Navigator.push(context,
                  new MaterialPageRoute(
                      builder: (ctxt) => new PasswordView(
                          session: this.session, password: filteredList[index]))),
              leading: Icon(Icons.security),
              title: Text('${filteredList[index].name}'),
              subtitle: Text('${filteredList[index].login}'),
            ),
          );
        });
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }


  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    var filteredList = passwordList.where(
            (element) =>
        element.name.contains(this.query)
            || element.login.contains(this.query)
            || element.domain.contains(this.query))
        .toList();
    if (filteredList.length == 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Text(
              "No password found",
            ),
          )
        ],
      );
    }
    return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: filteredList.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            child: ListTile(
              onTap: () => Navigator.push(context,
                  new MaterialPageRoute(
                      builder: (ctxt) => new PasswordView(
                          session: this.session, password: filteredList[index]))),
              leading: Icon(Icons.security),
              title: Text('${filteredList[index].name}'),
              subtitle: Text('${filteredList[index].login}'),
            ),
          );
        });
  }


}