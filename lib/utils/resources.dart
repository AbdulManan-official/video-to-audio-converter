import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void toastFlutter({required String toastmessage, required Color? color}) {
  Fluttertoast.showToast(
      msg: toastmessage,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.SNACKBAR,
      timeInSecForIosWeb: 3,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0);
}
