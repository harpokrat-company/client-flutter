

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harpokrat/controller/session.dart';
import 'package:harpokrat/model/Owner.dart';
import 'package:harpokrat/model/Vault.dart';
import 'package:harpokrat/views/vault_view.dart';

class VaultList extends StatefulWidget {
  VaultList({Key key, @required this.session, this.owner}): super(key: key);

  Session session;
  Owner owner;

  @override
  State<StatefulWidget> createState() {
    return VaultListPage();
  }
}

class VaultListPage extends State<VaultList> {
  Widget buildList(BuildContext context, List<Vault> vaultList) {
    return ListView.builder(padding: const EdgeInsets.all(8.0),
        itemCount: vaultList.length,
        itemBuilder: (BuildContext context, int idx) {
          return Container(
            child: ListTile(
              leading: Icon(Icons.security),
              title: Text(vaultList[idx].name),
              subtitle: Text("${vaultList[idx].passwords.length} passwords"),
              onTap: () => {Navigator.push(context, new MaterialPageRoute(builder: (ctxt) => new VaultView(
                  session: widget.session, vault: vaultList[idx])))},
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My vaults"),
      ),
      body: FutureBuilder(
        future: () async {
          var vl = await widget.session.getOwnerVaults(widget.owner);
          for (var v in vl)
//            await widget.session.getVaultData(v, widget.owner.publicKey.asRSAPublic(), widget.owner.privateKey.asRSAPrivate());
            await widget.session.getVaultData(v, null, null);
          return vl;}(),
          builder: (BuildContext context, AsyncSnapshot<List<Vault>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }else if (snapshot.hasError)
              return Center(
                child: Text("Error while loading vault list"),
              );
            else if (snapshot.data.isNotEmpty)
              return buildList(context, snapshot.data);
            return Center(child: Text("No vault to show"),);
          }),
      floatingActionButton: Builder(builder: (context) => FloatingActionButton.extended(
        onPressed: () {
//          widget.session.createVault("plop", widget.owner.identifier, widget.owner.publicKey.asRSAPublic(), widget.owner.privateKey.asRSAPrivate())
          widget.session.createVault("\$master", widget.owner.identifier, null, null)
                .then((value) {
                  Scaffold.of(context).showSnackBar(SnackBar(content: Text(value != null ? "Vault created": "Error when creationg vault"),));});
      },
        icon: Icon(Icons.add),
        label: Text("Create new Vault"),
        backgroundColor: Colors.blueAccent,
      )),
    );
  }
}