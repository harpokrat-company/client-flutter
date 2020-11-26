import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harpokrat/controller/session.dart';
import 'package:harpokrat/model/Password.dart';
import 'package:harpokrat/model/Vault.dart';

class VaultView extends StatefulWidget {
  VaultView({Key key, @required this.session, @required this.vault})
      : super(key: key);
  Session session;
  Vault vault;

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return VaultViewPage();
  }
}

class VaultViewPage extends State<VaultView> {
  bool isObscured = true;

  void showPasswordBottomSheet(BuildContext context, Password password) {
    var nameTextController = new TextEditingController(text: password.name);
    var domainTextController = new TextEditingController(text: password.domain);
    var loginTextController = new TextEditingController(text: password.login);
    var passwordTextController = new TextEditingController(text: password.password);

    showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
      return Container(
          child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget> [
                  Text("Password"),
                  TextField(controller: nameTextController,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.label),
                        labelText: "Name"),),
                  SizedBox(height: 10),
                  TextField(controller: domainTextController,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.domain),
                        labelText: "Domain"
                    ),),
                  SizedBox(height: 10), // use Spacer
                  TextField(controller: loginTextController,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.account_circle),
                        labelText: "Login",
                        suffixIcon: Icon(Icons.content_copy)
                    ),),
                  SizedBox(height: 10),
                  TextField(
                      obscureText: isObscured,
                      decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                          suffix: MaterialButton(child: Icon(isObscured ? Icons.visibility: Icons.visibility_off),
                              onPressed: () => {setState(() => {isObscured = !isObscured})})
                      ),
                      controller: passwordTextController),
                  RaisedButton(color: Theme.of(context).accentColor,
                      textColor: Colors.white,
                      child: Text("Save changes"),
                      onPressed: () {
                        password.name = nameTextController.text;
                        password.domain = domainTextController.text;
                        password.login = loginTextController.text;
                        password.password = passwordTextController.text;
                        widget.session.updatePassword(password, widget.vault.getIdentifier(), null /*widget.vault.symmetricKey.asSymmetric()*/)
                            .then((value) => ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(value ? "Password updated" : "Network error"),)));
                      }
                  ),
                  RaisedButton(color: Colors.red,
                    textColor: Colors.white,
                    child: Text("Delete password"),
                    onPressed: () {
                      widget.session.deletePassword(password)
                          .then((value) => Navigator.of(context).pop());
                    },)
                ],
              )
          )
      );
    });
  }

  void _showCreatePasswordDialog() {
    final nameController = TextEditingController();
    final loginController = TextEditingController();
    final passwordController = TextEditingController();
    showDialog(context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Create new password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    hintText: 'Enter name',
                  ),
                  controller: nameController,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    hintText: 'Enter login',
                  ),
                  controller: loginController,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    hintText: 'Enter password',
                  ),
                  obscureText: true,
                  controller: passwordController,
                )
              ],
            ),
            actions: <Widget>[
              FlatButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text("Save"),
                onPressed: () {
                  widget.session.createPassword(nameController.text,
                      loginController.text,
                      passwordController.text,
                      widget.vault.getIdentifier(),
                      null);
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }


  Widget createPasswordList(List<Password> passwordList) {
    return ListView.builder(
      itemCount: passwordList.length,
        itemBuilder: (BuildContext context, int idx) {
      return Container(
        child: Card(
          child: InkWell(
            onTap: () => showPasswordBottomSheet(context, passwordList[idx]),
            child:  Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.security),
                  title: Text('${passwordList[idx].name}'),
                  subtitle: Text('${passwordList[idx].login}'),
                ),
                ButtonBarTheme(
                  data: ButtonBarThemeData(),
                  child: ButtonBar(
                    children: [
                      FlatButton(
                        child: Text("SHOW"),
                        onPressed: () {
                          Clipboard.setData(new ClipboardData(text: passwordList[idx].password));
                          ScaffoldMessenger.of(context).showSnackBar(new SnackBar(content: Text("password copied to clipboard")));
                        },
                      ),
                      FlatButton(
                        child: Text("COPY"),
                        onPressed: () { ScaffoldMessenger.of(context)
                            .showSnackBar(new SnackBar(content: Text("Your password is ${passwordList[idx].password}")));
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vault.name),
      ),
      body: FutureBuilder<bool>(
          future: widget.session.getPasswordVault(widget.vault),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else {
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));
              else if (!snapshot.data)
                return Center(child: Text('Could not fetch Passwords in vault'));
              else if (widget.vault.passwords.isNotEmpty)
                return Center(child: createPasswordList(widget.vault.passwords));
              else
                return Center(child: Text("No password found"),);
            }
          }
      ),
        floatingActionButton: Builder(builder: (context) => FloatingActionButton.extended(
          onPressed: _showCreatePasswordDialog,
          icon: Icon(Icons.add),
          label: Text("Create new passwords"),
          backgroundColor: Theme.of(context).accentColor,
        )),
    );
  }
}