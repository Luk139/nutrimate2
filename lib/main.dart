// main.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'nutrient_tracker_app.dart';

  void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseHelper = DatabaseHelper();
  runApp(MyApp(databaseHelper: databaseHelper));
}
  