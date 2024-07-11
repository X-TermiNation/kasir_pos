import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'package:kasir_pos/View/tools/custom_toast.dart';
import 'package:kasir_pos/view-model-flutter/gudang_controller.dart';

//add barang
void addbarang(DateTime insertedDate, bool noExp, String nama_barang,
    String katakategori, BuildContext context) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  try {
    String? expDateString;
    String? creationDateString;
    getdatagudang();
    String id_gudangs = dataStorage.read('id_gudang');
    final requestjenis = Uri.parse(
        'http://10.0.2.2:3001/barang/getjenisfromkategori/$katakategori');
    final datajenis = await http.get(requestjenis);
    final jenis = json.decode(datajenis.body);
    if (!noExp) {
      insertedDate = insertedDate.add(Duration(days: 1));
      expDateString = insertedDate.toIso8601String();
    } else {
      expDateString = '';
    }
    DateTime creationDate = DateTime.now();
    creationDateString = creationDate.toIso8601String();
    final Barangdata = {
      'nama_barang': nama_barang,
      'jenis_barang': jenis["data"]["nama_jenis"].toString(),
      'kategori_barang': katakategori,
      'insert_date': creationDateString,
      'exp_date': expDateString,
    };
    final url = 'http://10.0.2.2:3001/barang/addbarang/$id_gudangs/$id_cabang';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(Barangdata),
    );
    if (response.statusCode == 200) {
      showToast(context, 'Berhasil menambah data');
    } else {
      showToast(context, "Gagal menambahkan data");
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }
}

//get barang
Future<List<Map<String, dynamic>>> getBarang(String idgudang) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final request =
      Uri.parse('http://10.0.2.2:3001/barang/baranglist/$idgudang/$id_cabang');
  final response = await http.get(request);
  if (response.statusCode == 200 || response.statusCode == 304) {
    final Map<String, dynamic> jsonData = json.decode(response.body);
    List<dynamic> data = jsonData["data"];
    print("ini data barang dari cabang: $data");
    return data.cast<Map<String, dynamic>>();
  } else {
    CustomToast(message: "Failed to load data: ${response.statusCode}");
    return [];
  }
}

//delete barang
void deletebarang(String id) async {
  final dataStorage = GetStorage();
  final id_cabang = dataStorage.read("id_cabang");
  final id_gudang = dataStorage.read("id_gudang");
  final url =
      'http://10.0.2.2:3001/barang/deletebarang/$id_gudang/$id_cabang/$id';
  final response = await http.delete(Uri.parse(url));
  if (response.statusCode == 200) {
    print('Data deleted successfully');
  } else {
    print('Error deleting data. Status code: ${response.statusCode}');
  }
}

//update barang
void UpdateBarang(String id, String nama_barang, String katakategori,
    String harga_barang, String jumlah_barang) async {
  final updatedBarangData = {
    'nama_barang': nama_barang,
    'kategori_barang': katakategori,
    'harga_barang': harga_barang,
    'Qty': jumlah_barang,
  };
  final dataStorage = GetStorage();
  final id_cabang = dataStorage.read("id_cabang");
  final id_gudang = dataStorage.read("id_gudang");
  final url =
      'http://10.0.2.2:3001/barang/updatebarang/$id_gudang/$id_cabang/$id';
  try {
    final response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updatedBarangData),
    );

    if (response.statusCode == 200) {
      // Data updated successfully
      CustomToast(message: 'Data updated successfully');
    } else {
      // Error occurred during data update
      print('Error updating data. Status code: ${response.statusCode}');
    }
  } catch (error) {
    print('Error: $error');
  }
}

//kategori
//add kategori
//function add
void addkategori(String nama_kategori, String selectedvalueJenis,
    BuildContext context) async {
  try {
    final Kategoridata = {
      'nama_kategori': nama_kategori,
      'id_jenis': selectedvalueJenis,
    };
    final url = 'http://10.0.2.2:3001/barang/tambahkategori';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(Kategoridata),
    );
    if (response.statusCode == 200) {
      showToast(context, 'berhasil tambah data');
      getKategori();
    } else if (selectedvalueJenis.isEmpty) {
      showToast(context, "jenis tidak ada");
      print(response.statusCode);
    } else {
      showToast(context, "gagal menambahkan data");
      print(response.statusCode);
    }
  } catch (e) {
    print(e);
  }
}

//get kategori
Future<List<Map<String, dynamic>>> getKategori() async {
  final url = 'http://10.0.2.2:3001/barang/getkategori';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200 || response.statusCode == 304) {
    print('berhasil akses data');
    final Map<String, dynamic> jsonData = json.decode(response.body);
    List<dynamic> data = jsonData["data"];
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Gagal mengambil data dari server');
  }
}

Future<String> getFirstKategoriId() async {
  final url = 'http://10.0.2.2:3001/barang/getfirstkategori';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200 || response.statusCode == 304) {
    print('berhasil akses data kategori pertama');
    final Map<String, dynamic> jsonData = json.decode(response.body);
    print('API Response: $jsonData');
    if (jsonData.containsKey("data") && jsonData["data"] != null) {
      final Map<String, dynamic> data = jsonData["data"];
      if (data.isNotEmpty && data.containsKey("_id")) {
        String temp = data["_id"].toString();
        return data["_id"].toString();
      } else {
        throw Exception('No data available');
      }
    } else {
      // Handle the case where data is null or not present
      print("The 'data' field is null or not present.");
      return '';
    }
  } else {
    print(
        'API Error: ${response.statusCode} - ${response.body}'); // Log the error response
    throw Exception('Gagal mengambil data dari server');
  }
}

Future<void> fetchDataKategori() async {
  try {
    final items = await getKategori();
    print("ini data Kategori :$items");
  } catch (error) {
    print('Error: $error');
  }
}

Future<Map<String, String>> getNamaKategoriMap(
    List<Map<String, dynamic>> array) async {
  final map = Map<String, String>();
  final objects = await array;
  for (final object in objects) {
    map[object['_id']] = object['nama_kategori'];
  }
  return map;
}

Future<Map<String, String>> getmapkategori() async {
  final Kategori = await getKategori();
  final namaKategoriMap = await getNamaKategoriMap(Kategori);
  print(namaKategoriMap);
  return namaKategoriMap;
}

//jenis

//add jenis
void addjenis(String nama_jenis, BuildContext context) async {
  final Jenisdata = {
    'nama_jenis': nama_jenis,
  };
  final url = 'http://10.0.2.2:3001/barang/tambahjenis';
  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(Jenisdata),
  );
  if (response.statusCode == 200) {
    showToast(context, 'berhasil tambah data');
  } else {
    showToast(context, "gagal menambahkan data");
  }
}

Future<List<Map<String, dynamic>>> getJenis() async {
  final url = 'http://10.0.2.2:3001/barang/getjenis';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200 || response.statusCode == 304) {
    print('berhasil akses data jenis');
    final Map<String, dynamic> jsonData = json.decode(response.body);
    List<dynamic> data = jsonData["data"];
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Gagal mengambil data dari server');
  }
}

Future<String> getFirstJenisId() async {
  final url = 'http://10.0.2.2:3001/barang/getfirstjenis';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200 || response.statusCode == 304) {
    print('berhasil akses data jenis pertama');
    final Map<String, dynamic> jsonData = json.decode(response.body);
    print('API Response: $jsonData');
    final Map<String, dynamic> data = jsonData["data"];
    if (data != null && data.containsKey("_id")) {
      String temp = data["_id"].toString();
      return data["_id"].toString();
    } else {
      throw Exception('No data available');
    }
  } else {
    print(
        'API Error: ${response.statusCode} - ${response.body}'); // Log the error response
    throw Exception('Gagal mengambil data dari server');
  }
}

Future<void> fetchDatajenis() async {
  try {
    final items = await getJenis();
    print("ini data Kategori :$items");
  } catch (error) {
    print('Error: $error');
  }
}

Future<Map<String, String>> getNamaJenisMap(
    List<Map<String, dynamic>> array) async {
  final map = Map<String, String>();
  final objects = await array;
  for (final object in objects) {
    map[object['_id']] = object['nama_jenis'];
  }
  return map;
}

Future<Map<String, Map<String, dynamic>>> getMapFromjenis(
    List<Map<String, dynamic>> list) async {
  final map = <String, Map<String, dynamic>>{};

  for (final item in list) {
    final id = item['_id'];
    if (id is String) {
      map[id] = item;
    }
  }

  return map;
}

Future<Map<String, String>> getmapjenis() async {
  final Jenis = await getJenis();
  final namaJenismap = await getNamaJenisMap(Jenis);
  print(namaJenismap);
  return namaJenismap;
}

//satuan
void addsatuan(String id_barang, String nama_satuan, String jumlah_satuan,
    String harga_satuan, String isi_satuan, BuildContext context) async {
  try {
    final satuandata = {
      'nama_satuan': nama_satuan,
      'jumlah_satuan': jumlah_satuan,
      'harga_satuan': harga_satuan,
      'isi_satuan': isi_satuan
    };
    final dataStorage = GetStorage();
    final id_cabang = dataStorage.read("id_cabang");
    String id_gudangs = dataStorage.read('id_gudang');
    final url =
        'http://10.0.2.2:3001/barang/addsatuan/$id_barang/$id_cabang/$id_gudangs';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(satuandata),
    );

    if (response.statusCode == 200) {
      showToast(context, 'Berhasil menambah data');
    } else {
      showToast(context, "Gagal menambahkan data");
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }
}

Future<List<Map<String, dynamic>>> getsatuan(
    String id_barang, BuildContext context) async {
  try {
    final dataStorage = GetStorage();
    final id_cabang = dataStorage.read("id_cabang");
    String id_gudangs = dataStorage.read('id_gudang');
    final url =
        'http://10.0.2.2:3001/barang/getsatuan/$id_barang/$id_cabang/$id_gudangs';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200 || response.statusCode == 304) {
      print('berhasil akses data jenis');
      final Map<String, dynamic> jsonData = json.decode(response.body);
      List<dynamic> data = jsonData["data"];
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Gagal mengambil data dari server');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    return [];
  }
}
