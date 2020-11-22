
import 'package:flutter/material.dart';

Widget showSheetButton(BuildContext context, String title, Widget body) {
  return MaterialButton(
      color: Theme.of(context).accentColor,
      textColor: Colors.white,
      child: Text(title),
      onPressed: () {
        showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
          return Container(
              child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: body
              )
          );
        });
      }
  );
}
