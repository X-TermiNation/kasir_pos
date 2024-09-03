import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kasir_pos/View/Login.dart';
import 'package:kasir_pos/View/tools/theme_mode.dart';
import 'package:provider/provider.dart';

void main() async {
  await GetStorage.init();
  runApp(
    ChangeNotifierProvider<ThemeManager>(
      create: (_) => ThemeManager(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: Provider.of<ThemeManager>(context).getTheme(),
      home: const Login(),
    );
  }
}
