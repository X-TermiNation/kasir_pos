import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'package:kasir_pos/View/tools/custom_toast.dart';
import 'package:kasir_pos/view-model-flutter/gudang_controller.dart';

String idcabangglobal = "";

//verify
Future<void> verify() async {
  String uriString = "http://10.0.2.2:3000/user/verify";
  Uri uri = Uri.parse(uriString);
  final response = await http.get(uri);
}

//get user
Future<List<Map<String, dynamic>>> getUsers() async {
  final dataStorage = GetStorage();
  String id_cabangs = dataStorage.read('id_cabang');
  final request = Uri.parse('http://10.0.2.2:3000/user/list/$id_cabangs');
  final response = await http.get(request);
  if (response.body.isEmpty) {
    return [];
  }
  final Map<String, dynamic> jsonData = json.decode(response.body);
  List<dynamic> data = jsonData["data"];
  return data.cast<Map<String, dynamic>>();
}

//print data user
Future<void> fetchData() async {
  try {
    final items = await getUsers();
    print("ini data :$items");
  } catch (error) {
    print('Error fetch data: $error');
  }
}

//login
Future<int> loginbtn(String email, String pass) async {
  try {
    String uriString = "http://10.0.2.2:3000/user/loginkasir";
    Uri uri = Uri.parse(uriString);
    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': pass,
      }),
    );

    if (response.statusCode == 200) {
      int signcode = jsonDecode(response.body)['signcode'];
      idcabangglobal = jsonDecode(response.body)['userCabangId'];
      final dataStorage = GetStorage();
      dataStorage.write('id_cabang', idcabangglobal);
      await getdatagudang();
      print("ini signcode:$signcode");
      return signcode;
    } else {
      CustomToast(message: 'email atau password salah');
      return 0;
    }
  } catch (e) {
    print('Error connecting to server: $e');
    return 0;
  }
}

void tambahOwner(String email, String pass, String fname, String lname) async {
  try {
    final Owneradd = {
      'email': email,
      'password': pass,
      'fname': fname,
      'lname': lname,
    };

    if (email != "" && pass != "" && fname != "" && lname != "") {
      final url = 'http://10.0.2.2:3000/user/addOwner';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(Owneradd),
      );
      if (response.statusCode == 200) {
        print('berhasil tambah data pegawai');
      } else {
        print('Gagal menambah data pegawai ke server');
      }
    } else {
      print('Field tidak boleh kosong!');
    }
  } catch (e) {
    print('Error tambah pegawai: $e');
  }
}

//
void tambahpegawai(
    String email, String pass, String fname, String lname, String role) async {
  try {
    final useradd = {
      'email': email,
      'password': pass,
      'fname': fname,
      'lname': lname,
      'role': role,
    };

    final dataStorage = GetStorage();
    String id_cabang = dataStorage.read('id_cabang');
    if (email != "" && pass != "" && fname != "" && lname != "") {
      final url = 'http://10.0.2.2:3000/user/addUser/$id_cabang';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(useradd),
      );
      if (response.statusCode == 200) {
        print('berhasil tambah data pegawai');
      } else {
        print('Gagal menambah data pegawai ke server');
      }
    } else {
      print('Field tidak boleh kosong!');
    }
  } catch (e) {
    print('Error tambah pegawai: $e');
  }
}

//delete user
void deleteuser(String id, BuildContext context) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final url = 'http://10.0.2.2:3000/user/deleteuser/$id/$id_cabang';
  final response = await http.delete(Uri.parse(url));
  if (response.statusCode == 200) {
    // Data deleted successfully
    showToast(context, "Data Berhasil Dihapus!");
    print('Data deleted successfully');
  } else {
    // Error occurred during data deletion
    CustomToast(message: "Terjadi Kesalahan!");
    print('Error deleting data. Status code: ${response.statusCode}');
  }
}

//update user
void UpdateUser(String fname, String lname, String role, String id,
    BuildContext context) async {
  final updatedUserData = {
    'fname': fname.toString(),
    'lname': lname.toString(),
    'role': role.toString()
  };
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final url = 'http://10.0.2.2:3000/user/updateuser/$id/$id_cabang';
  try {
    final response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updatedUserData),
    );

    if (response.statusCode == 200) {
      // Data updated successfully
      showToast(context, 'Data updated successfully');
    } else {
      // Error occurred during data update
      print('Error updating data. Status code: ${response.statusCode}');
    }
  } catch (error) {
    print('Error update user: $error');
  }
}
