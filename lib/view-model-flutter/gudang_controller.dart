import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:get_storage/get_storage.dart';
import '../api_config.dart';

Future<void> getdatagudang() async {
  try {
    final dataStorage = GetStorage();
    String idcabang = dataStorage.read('id_cabang');
    final url = '${ApiConfig().baseUrl}/gudang/$idcabang';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 304 || response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final gudang = jsonData['data'][0]['_id'];
      dataStorage.write("id_gudang", gudang.toString());
      print("id gudang dari function:$gudang");
    } else {
      final errorMessage = json.decode(response.body)['message'];
      throw Exception('Error fetching user: $errorMessage');
    }
  } catch (error) {
    throw Exception('Error fetching gudang: $error');
  }
}
