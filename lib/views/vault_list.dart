

import 'package:flutter/cupertino.dart';
import 'package:harpokrat/controller/session.dart';
import 'package:harpokrat/model/Vault.dart';

class VaultList extends StatefulWidget {
  VaultList({Key key, @required this.session, @required List<Vault> vaultList}): super(key: key);

  Session session;
  List<Vault> vaultList;

  @override
  State<StatefulWidget> createState() {
    return VaultListPage();
  }
}

class VaultListPage extends State<VaultList> {

  ListView buildList(BuildContext context) {
    return ListView.builder(padding: const EdgeInsets.all(8.0),
        itemCount: widget.vaultList.length,
        itemBuilder: (BuildContext context, int idx) {
          return Container(

          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("PLOP"),);
  }

}