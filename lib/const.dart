import 'package:deliveryapp/views/login.dart';
import 'package:flutter/material.dart';

class Constants {
  static void logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }
}
