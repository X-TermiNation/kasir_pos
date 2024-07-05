import 'package:get_storage/get_storage.dart';

class SimpanData {
  final box = GetStorage();

  void saveData(String key, dynamic data) {
    box.write(key, data);
  }
}

class AmbilData {
  final box = GetStorage();

  dynamic retrieveData(String key) {
    return box.read(key);
  }
}