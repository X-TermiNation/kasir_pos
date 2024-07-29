import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasir_pos/View/tools/custom_toast.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'dart:async';

Future<String?> createqris(int amount, BuildContext context) async {
  try {
    final qrData = {
      'amount': amount,
      'callback_url': "https://yourcallbackurl.com",
    };
    final url = 'http://10.0.2.2:3001/xendit/create-qris';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(qrData),
    );
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return responseData['qrCodeUrl'];
    } else {
      showToast(context, "Gagal menampilkan QR");
      print('HTTP Error: ${response.statusCode}');
      return "";
    }
  } catch (error) {
    showToast(context, "Error: $error");
    print('Exception during HTTP request: $error');
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
    final url = 'http://10.0.2.2:3001/xendit/create-qris';
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
  BuildContext context,
) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  DateTime trans_date = DateTime.now();
  try {
    final transData = {
      'id_cabang': id_cabang,
      'trans_date':
          trans_date.toIso8601String(), // Ensure date is properly formatted
      'payment_method': payment_method,
      'delivery': delivery,
      'desc': desc,
      'status': status,
      'Items': items
    };
    final url = 'http://10.0.2.2:3001/transaksi/addtrans/$id_cabang';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transData),
    );
    if (response.statusCode == 200) {
      showToast(context, 'Berhasil menambah data');
      return transData;
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
void generateInvoice(
    String nama_cabang,
    String alamat,
    String no_telp,
    DateTime date_trans,
    String payment_method,
    String delivery, //true = yes , false = no
    List<Map<String, dynamic>> items,
    BuildContext context) async {
  try {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    String dateinvoice = formatter.format(date_trans);
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3001/invoice/generate-invoice'),
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
        SnackBar(content: Text('Invoice Successfuly Generated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Invoice Failed Generated')),
      );
      throw Exception('Failed to generate invoice');
    }
  } catch (e) {
    throw Exception("error occured while generate invoice: $e");
  }
}
