import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kasir_pos/View/tools/custom_toast.dart';
import 'package:get_storage/get_storage.dart';
import '../api_config.dart';

//getdiskon
//bermasalah
Future<List<Map<String, dynamic>>> getDiskon() async {
  await ApiConfig().refreshConnectionIfNeeded();
  final dataStorage = GetStorage();
  final id_cabangs = dataStorage.read('id_cabang');
  final request =
      Uri.parse('${ApiConfig().baseUrl}/barang/diskonlist/$id_cabangs');
  final response = await http.get(request);
  final Map<String, dynamic> jsonData = json.decode(response.body);
  if (!jsonData.containsKey("data")) {
    return [];
  } else {
    List<dynamic> data = jsonData["data"];
    return data.cast<Map<String, dynamic>>();
  }
}

//fetch data barang diskon
Future<List<Map<String, dynamic>>> fetchDataDiskonItem(
    String id_gudangs) async {
  try {
    await ApiConfig().refreshConnectionIfNeeded();
    List<Map<String, dynamic>> data = await getbarangdiskonlist(id_gudangs);
    print("data bawaan: $data");
    return data;
  } catch (error) {
    // Handle error
    print('Error: $error');
    throw Exception("error fetch diskon:$error");
  }
}

//barang diskon
Future<List<Map<String, dynamic>>> getbarangdiskonlist(String id_gudang) async {
  try {
    await ApiConfig().refreshConnectionIfNeeded();
    final dataStorage = GetStorage();
    String id_cabangs = dataStorage.read('id_cabang');
    final request = Uri.parse(
        '${ApiConfig().baseUrl}/barang/baranglist/$id_gudang/$id_cabangs');
    final response = await http.get(request);
    if (response.statusCode == 200 || response.statusCode == 304) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      List<dynamic> data = jsonData["data"];
      print("ini data barang untuk diskon: $data");
      return data.cast<Map<String, dynamic>>();
    } else {
      CustomToast(message: "Data Barang Kosong!");
      return [];
    }
  } catch (e) {
    throw Exception("error:$e");
  }
}

//diskon filtered by assigned barang
Future<List<Map<String, dynamic>>> getDiskonbyBarang(id_reference) async {
  await ApiConfig().refreshConnectionIfNeeded();
  final dataStorage = GetStorage();
  String id_cabangs = dataStorage.read('id_cabang');
  final request = Uri.parse(
      '${ApiConfig().baseUrl}/barang/diskonlistBarangFilter/$id_reference/$id_cabangs');
  final response = await http.get(request);
  final Map<String, dynamic> jsonData = json.decode(response.body);
  if (!jsonData.containsKey("data")) {
    return [];
  } else {
    List<dynamic> data = jsonData["data"];
    return data.cast<Map<String, dynamic>>();
  }
}

//insert diskon
Future<void> tambahdiskon(
    String nama_diskon,
    String persentase_diskon,
    String DateStringStart,
    String DateStringEnd,
    List<bool> isCheckedList,
    List<Map<String, dynamic>> databarang,
    BuildContext context) async {
  try {
    await ApiConfig().refreshConnectionIfNeeded();
    final dataStorage = GetStorage();
    String id_cabangs = dataStorage.read('id_cabang');
    String id_gudang = dataStorage.read('id_gudang');
    for (var i = 0; i < isCheckedList.length; i++) {
      print("ini isinya :${isCheckedList[i]}");
    }
    final diskonadd = {
      'nama_diskon': nama_diskon,
      'id_cabang_reference': id_cabangs,
      'persentase_diskon': persentase_diskon,
      'start_date': DateStringStart,
      'end_date': DateStringEnd,
    };

    if (nama_diskon != "" && persentase_diskon != "") {
      final url = '${ApiConfig().baseUrl}/barang/tambahdiskon/$id_cabangs';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(diskonadd),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 304) {
        showToast(context, "Berhasil tambah diskon");
        String nmdiskon = nama_diskon.toString();
        //mencari diskon sesuai nama yang baru di add
        final request3 = Uri.parse(
            '${ApiConfig().baseUrl}/barang/diskonlist/$id_cabangs/$nmdiskon');
        final response3 = await http.get(request3);
        if (response3.statusCode == 200 ||
            response.statusCode == 204 ||
            response3.statusCode == 304) {
          final jsonDiskon = json.decode(response3.body);
          final datadiskon = jsonDiskon["data"];
          for (var i = 0; i < isCheckedList.length; i++) {
            //print("ini ngulang ${isCheckedList[i]}");
            if (isCheckedList[i] == true) {
              final diskonadd2 = {
                'nama_barang': databarang[i]['nama_barang'],
                'id_reference': databarang[i]['_id'],
                'insert_date': databarang[i]['insert_date'],
                'exp_date': databarang[i]['exp_date'],
                'jenis_barang': databarang[i]['jenis_barang'],
                'kategori_barang': databarang[i]['kategori_barang'],
              };
              final url2 =
                  '${ApiConfig().baseUrl}/barang/tambahdiskonbarang/${datadiskon[0]['_id']}/${databarang[i]['_id']}/$id_cabangs/$id_gudang';
              final response2 = await http.post(
                Uri.parse(url2),
                headers: {
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(diskonadd2),
              );
              if (response2.statusCode == 200) {
                showToast(context, "berhasil tambah barang");
              } else {
                showToast(context, "gagal tambah barang");
              }
            }
          }
        } else {
          showToast(context, "something is wrong here");
        }
      } else {
        CustomToast(message: 'Gagal menambah data ke server');
      }
    } else {
      CustomToast(message: 'Field tidak boleh kosong!');
    }
  } catch (e) {
    print('Error tambah diskon: $e');
  }
}

//hapus diskon
void deletediskon(String id) async {
  await ApiConfig().refreshConnectionIfNeeded();
  final dataStorage = GetStorage();
  String id_cabangs = dataStorage.read('id_cabang');
  final url = '${ApiConfig().baseUrl}/barang/deletediskon/$id/$id_cabangs';
  final response = await http.delete(Uri.parse(url));

  if (response.statusCode == 200) {
    // Data deleted successfully
    print('Data deleted successfully');
  } else {
    // Error occurred during data deletion
    print('Error deleting data. Status code: ${response.statusCode}');
  }
  await getDiskon();
}
