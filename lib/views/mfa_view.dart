
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harpokrat/controller/session.dart';

class MfaView extends StatefulWidget {
  MfaView({Key key, @required this.session}): super(key: key);
  Session session;

  @override
  State<StatefulWidget> createState() {
    return MfaViewPage();
  }
}

class MfaViewPage extends State<MfaView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Multi-factor authentication"),
      ),
      body: Column(
        children: [
          ExpansionTile(
              title: Text("Phone"),
              children: [
                TextFormField(
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.textsms),
                      labelText: "Phone number"),
                ),
              ]),
          ExpansionTile(
            title: Text("Mail"),
            children: [
              CheckboxListTile(
                title: Text("Activate"),
                subtitle: Text("Activate MFA for email"),
                onChanged: (value) => widget.session.activateMFA(value).then((value) => setState( ()=> null)),
                value: widget.session.user.mfa,
              ),
              TextFormField(
                decoration: InputDecoration(
                    prefixIcon: Icon(Icons.mail),
                    labelText: "Email address"),
              )
            ],
          ),
          ExpansionTile(
            title: Text("Authenticator"),
            children: [
              TextFormField(
                decoration: InputDecoration(
                    prefixIcon: Icon(Icons.vpn_key),
                    labelText: "Authenticator seed"),
              )
            ],
          )
        ],
      ),
      floatingActionButton: Builder(builder: (context) => FloatingActionButton.extended(
      label: Text("Save"),
        icon: Icon(Icons.save),
        onPressed: () => Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text("Setting saved"),)),
      ),)
    );
  }
}