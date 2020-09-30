import 'package:harpokrat/controller/session.dart';
import "package:webview_flutter/webview_flutter.dart";
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecaptchaV2 extends StatefulWidget {
  final String apiKey;
  Session session;
  final String pluginURL = "https://api.dev.harpokrat.com";
  final RecaptchaV2Controller controller;

  RecaptchaV2({
    this.apiKey,
    this.session,
    RecaptchaV2Controller controller,
  })  : controller = controller ?? RecaptchaV2Controller(),
        assert(apiKey != null, "Api key is missing");

  @override
  State<StatefulWidget> createState() => _RecaptchaV2State();
}

class _RecaptchaV2State extends State<RecaptchaV2> {
  RecaptchaV2Controller controller;
  WebViewController webViewController;

  void verifyToken(String token) async {
  }

  void onListen() {
    if (controller.visible) {
      if (webViewController != null) {
        webViewController.clearCache();
        webViewController.reload();
      }
    }
    setState(() {
      controller.visible;
    });
  }

  @override
  void initState() {
    controller = widget.controller;
    controller.addListener(onListen);
    super.initState();
  }

  @override
  void didUpdateWidget(RecaptchaV2 oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(onListen);
      controller = widget.controller;
      controller.removeListener(onListen);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.removeListener(onListen);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return controller.visible
        ? Stack(
      children: <Widget>[
        WebView(
          initialUrl: '',

          javascriptMode: JavascriptMode.unrestricted,
          javascriptChannels: <JavascriptChannel>[
            JavascriptChannel(
              name: 'RecaptchaFlutterChannel',
              onMessageReceived: (JavascriptMessage receiver) {
                // print(receiver.message);
                String _token = receiver.message;
                if (_token.contains("verify")) {
                  _token = _token.substring(7);
                }
                controller._token = _token;
                widget.session.captchaToken = _token;
                widget.session.createUser(widget.session.user)
                    .then((value) => {controller.hide(), Navigator.pop(context)});
              },
            ),
          ].toSet(),
          onWebViewCreated: (_controller) {
            webViewController = _controller;
            _controller.loadUrl(Uri.dataFromString(
                """
            <html>
              <head>
              <title>reCAPTCHA</title>
            <script src="https://www.google.com/recaptcha/api.js" async defer></script>
            </head>
            <body style='background-color: aqua;'>
            <div style='height: 60px;'></div>
            <form action="?" method="POST">
            <div class="g-recaptcha"
            data-sitekey="${widget.session.captchaKey}"
            data-callback="captchaCallback"></div>
            </form>
            <script>
            function captchaCallback(response){
                //console.log(response);
                if(typeof Captcha!=="undefined"){
              Captcha.postMessage(response);
            }
          }
            </script>
            </body>
            </html>""",
                mimeType: 'text/html',
                encoding: Encoding.getByName('utf-8')
            ).toString());
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: RaisedButton(
                    child: Text("CANCEL RECAPTCHA"),
                    onPressed: () {
                      controller.hide();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    )
        : Container();
  }
}

class RecaptchaV2Controller extends ChangeNotifier {
  bool isDisposed = false;
  String _token;
  List<VoidCallback> _listeners = [];

  bool _visible = true;
  bool get visible => _visible;

  void show() {
    _visible = true;
    if (!isDisposed) notifyListeners();
  }

  void hide() {
    _visible = false;
    if (!isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _listeners = [];
    isDisposed = true;
    super.dispose();
  }

  String getToken() {
    return _token;
  }

  @override
  void addListener(listener) {
    _listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(listener) {
    _listeners.remove(listener);
    super.removeListener(listener);
  }
}
