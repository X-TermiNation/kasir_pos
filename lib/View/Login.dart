import 'package:flutter/material.dart';
import 'package:kasir_pos/View/Cashier.dart';
//import 'package:kasir_pos/view-model-flutter/barang_controller.dart';
import 'package:kasir_pos/view-model-flutter/user_controller.dart';
import 'package:kasir_pos/View/tools/custom_toast.dart';

String idcabangglobal = "";
String emailstr = "";

class Login extends StatefulWidget {
  const Login({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = new TextEditingController();
  TextEditingController password = new TextEditingController();
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Kasir"),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Kasir Pos',
            ),
            TextFormField(
              controller: email,
              onChanged: (value) {
                setState(() {
                  emailstr = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Field tidak boleh kosong';
                }
                return null;
              },
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Email',
              ),
            ),
            TextFormField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Enter your Password',
              ),
              validator: (value) {
                if (value == null) {
                  showToast(context, 'Field password tidak boleh kosong!');
                }
                return null;
              },
            ),
            FilledButton(
                onPressed: () async {
                  showToast(context, "akuditekan");
                  int signcode = await loginbtn(email.text, password.text);
                  if (signcode == 1) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Cashier()));
                  } else {
                    showToast(
                        context, "Username/Password Salah! signcode:$signcode");
                  }
                },
                child: Text("Login"))
          ],
        ),
      ),
    );
  }
}
