import 'package:flutter/material.dart';
import 'package:kasir_pos/view-model-flutter/user_controller.dart';
import 'package:kasir_pos/view-model-flutter/models_flutter/user_model.dart';
import 'package:kasir_pos/View/tools/custom_toast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

Future<List<Map<String, dynamic>>> getallcabang() async {
  final url = 'http://10.0.2.2:3001/cabang/showAllcabang';
  final response = await http.get(Uri.parse(url));
  if (response.body.isEmpty) {
    return [];
  }
  final Map<String, dynamic> jsonData = json.decode(response.body);
  List<dynamic> data = jsonData["data"];
  return data.cast<Map<String, dynamic>>();
}

//delete cabang
void deletecabang(String id, BuildContext context) async {
  final url = 'http://10.0.2.2:3001/cabang/delete/$id';
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

Future<String> getdatacabang(String email) async {
  final url = 'http://10.0.2.2:3001/user/cariUserbyEmail/$email';
  final response = await http.get(Uri.parse(url));
  // Check the response status code
  if (response.statusCode == 304 || response.statusCode == 200) {
    // The request was successful
    final jsonData = json.decode(response.body);
    final user = User.fromJson(jsonData['data']);
    final id_cabang = user.id_cabang.toString();
    // Return the user's id_cabang
    print("id dari login page:$id_cabang");
    idcabangglobal = user.id_cabang;
    print("ini dari function: $idcabangglobal");
    return idcabangglobal;
  } else {
    // The request failed
    final errorMessage = json.decode(response.body)['message'];
    // Throw an error
    throw Exception('Error fetching user: $errorMessage');
  }
}
