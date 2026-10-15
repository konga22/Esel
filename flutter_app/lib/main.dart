import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.setup();
  runApp(const EselApp());
}
