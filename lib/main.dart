import 'package:bingo/appwidget.dart';
import 'package:bingo/global/services/inject.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Inject.instance.init();

  runApp(const Appwidget());
}
