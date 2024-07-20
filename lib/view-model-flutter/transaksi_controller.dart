import 'package:flutter/material.dart';
import 'package:kasir_pos/View/tools/custom_toast.dart';
import 'package:http/http.dart' as http;
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
      showToast(context, 'Berhasil menampilkan QR');
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
