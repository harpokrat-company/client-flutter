

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:harpokrat/recaptcha_v2.dart';

import '../model/User.dart';
import '../controller/session.dart';

class SubscribeState extends StatefulWidget {
  SubscribeState({Key key, @required this.session, this.title}) : super(key: key);

  final String title;
  Session session;

  @override
  SubscribePage createState() {
    return SubscribePage();
  }

}

class SubscribePage extends State<SubscribeState> {
  RecaptchaV2Controller recaptchaV2Controller = RecaptchaV2Controller();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new Scaffold(
        body: new Center(
          child: RecaptchaV2(
            apiKey : widget.session.captchaKey,
            controller: recaptchaV2Controller,
            session: widget.session,
          )
        )
    );

  }

}