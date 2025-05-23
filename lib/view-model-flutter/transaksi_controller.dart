import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasir_pos/View/tools/custom_toast.dart';
import 'package:kasir_pos/view-model-flutter/barang_controller.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'dart:async';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<Map<String, dynamic>?> createVA(int amount, BuildContext context) async {
  try {
    final vaData = {
      'amount': amount,
    };

    final url = 'http://10.0.2.2:3000/xendit/create-va';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(vaData),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Pastikan backend mengirimkan 'account_number' pada response
      return {
        'account_number': responseData['account_number'], // Nomor VA
        'bank_code': responseData['bank_code'],
        'name': responseData['name'],
        'amount': responseData['amount'],
        'external_id': responseData['external_id'], // penting untuk simulasinya
      };
    } else {
      showToast(context, "Gagal membuat Virtual Account");
      print('HTTP Error: ${response.statusCode}');
      return null;
    }
  } catch (error) {
    showToast(context, "Terjadi error: $error");
    print('Exception during HTTP request: $error');
    return null;
  }
}

Future<void> simulateVAPayment(String externalId, int vaAmount) async {
  try {
    print("$externalId - $vaAmount");
    final url = 'http://10.0.2.2:3000/xendit/simulate-va-payment';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'external_id': externalId,
        'amount': vaAmount,
      }),
    );

    if (response.statusCode == 200) {
      print('Simulasi pembayaran berhasil');
      // Bisa kasih feedback ke UI, misal snackbar lewat callback
    } else {
      print('Gagal simulasi pembayaran');
    }
  } catch (e) {
    print('Error simulasi pembayaran: $e');
  }
}

void createInvoice(String external_id, int amount, String payer_email,
    String description, BuildContext context) async {
  try {
    final InvoiceData = {
      'external_id': external_id,
      'amount': amount,
      'payer_email': payer_email,
      'description': description,
    };
    final url = 'http://10.0.2.2:3000/xendit/create-qris';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(InvoiceData),
    );

    if (response.statusCode == 200) {
      showToast(context, 'Berhasil menampilkan Invoice');
    } else {
      showToast(context, "Gagal menampilkan Invoice");
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }
}

Future<Map<String, dynamic>?> addTrans(
  String payment_method,
  bool delivery,
  String desc,
  List<Map<String, dynamic>> items,
  String status,
  double grand_total,
  BuildContext context,
) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  // change the timezone here for transaction
  tz.initializeTimeZones();

  final timezone = tz.getLocation('Asia/Jakarta');
  DateTime trans_date = tz.TZDateTime.now(timezone);
  print("Waktu Insert transaksi:$trans_date");

  try {
    // Prepare transaction data
    final transData = {
      'id_cabang': id_cabang,
      'trans_date': DateFormat('yyyy-MM-ddTHH:mm:ss').format(trans_date),
      'payment_method': payment_method,
      'delivery': delivery,
      'desc': desc,
      'status': status,
      'grand_total': grand_total,
      'Items': items,
    };

    // Send the transaction data to the server
    final url = 'http://10.0.2.2:3000/transaksi/addtrans/$id_cabang';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transData),
    );
    final responseData = jsonDecode(response.body);
    print("ini hasil transaksi:$responseData");
    final now = DateTime.now().toUtc().add(Duration(hours: 7));

    // Format the time to a readable string in WIB
    final wibTimestamp = DateFormat('yyyyMMdd_HHmmss').format(now);

    final kodeaktivitas = "KLR_${responseData['data']}_${wibTimestamp}";

    for (var cartItem in items) {
      String id_barang = cartItem['id_reference'];
      String id_satuan = cartItem['id_satuan'];
      int quantity = cartItem['trans_qty'];
      updatejumlahSatuan(
          id_barang, id_satuan, quantity, kodeaktivitas, 'kurang', context);
    }

    // Handle the server response
    if (response.statusCode == 200) {
      showToast(context, 'Berhasil menambah data');
      return responseData;
    } else {
      showToast(context, "Gagal menambahkan data");
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }

  return null; // Return null in case of an error
}

//show alltrans in cabang
Future<List<Map<String, dynamic>>> getTrans() async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final request =
      Uri.parse('http://10.0.2.2:3000/transaksi/translist/$id_cabang');
  final response = await http.get(request);
  if (response.statusCode == 200 || response.statusCode == 304) {
    final Map<String, dynamic> jsonData = json.decode(response.body);
    List<dynamic> data = jsonData["data"];
    print("ini data transaksi dari cabang: $data");
    return data.cast<Map<String, dynamic>>();
  } else {
    CustomToast(message: "Failed to load data: ${response.statusCode}");
    return [];
  }
}

//add delivery
Future<Map<String, dynamic>?> addDelivery(
  String alamat_tujuan,
  String no_telp_cust,
  String transaksi_id,
  BuildContext context,
) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  try {
    var DeliveryData = {
      'alamat_tujuan': alamat_tujuan,
      'no_telp_cust': no_telp_cust,
      'transaksi_id': transaksi_id,
    };
    final url = 'http://10.0.2.2:3000/transaksi/addDelivery/$id_cabang';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(DeliveryData),
    );
    if (response.statusCode == 200) {
      showToast(context, 'Berhasil menambah data');
      final responseData = jsonDecode(response.body);
      return responseData;
    } else {
      showToast(context, "Gagal menambahkan data");
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
  }
  return null; // Return null in case of an error
}

//cetak invoice
Future<Map<String, dynamic>> generateInvoice(
    String nama_cabang,
    String alamat,
    String no_telp,
    DateTime date_trans,
    String payment_method,
    String delivery, //true = yes , false = no
    List<Map<String, dynamic>> items,
    BuildContext context) async {
  try {
    final DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');
    String dateinvoice = formatter.format(date_trans);
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/invoice/generate-invoice'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'nama_cabang': nama_cabang,
        'alamat': alamat,
        'no_telp': no_telp,
        'date_trans': dateinvoice.toString(),
        'payment_method': payment_method,
        'delivery': delivery,
        'items': items,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice Successfully Generated')),
      );
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String invoicePath = responseBody['downloadUrl'];
      return {'success': true, 'invoicePath': invoicePath};
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Invoice Failed to Generate')),
      );
      return {'success': false, 'invoicePath': null};
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error occurred while generating invoice: $e")),
    );
    return {'success': false, 'invoicePath': null};
  }
}

Future<bool> sendInvoiceByEmail(
    String invoicePath, String receiverEmail, BuildContext context) async {
  final Uri uri = Uri.parse('http://10.0.2.2:3000/invoice/invoice-email');
  try {
    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'Invoicepath': invoicePath,
        'receiveremail': receiverEmail,
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice sent successfully')),
      );
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Failed to send invoice')),
      );
      return false;
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error occurred while sending invoice: $e")),
    );
    return false;
  }
}
