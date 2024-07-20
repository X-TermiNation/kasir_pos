import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kasir_pos/View/Cashier.dart';
import 'package:kasir_pos/view-model-flutter/transaksi_controller.dart';
import 'package:qr/qr.dart';
import 'dart:typed_data';

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:qr/qr.dart';

Future<Uint8List> generateQrImage(String data) async {
  // Create a QR Code instance
  final qr = QrCode(4, QrErrorCorrectLevel.L);
  qr.addData(data);
  qr.make();

  final qrCodeSize = 200.0; // Adjust size as needed
  final size = qrCodeSize.toInt();

  // Create a picture recorder and canvas to draw the QR code
  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder,
      Rect.fromPoints(Offset(0, 0), Offset(size.toDouble(), size.toDouble())));

  final paint = Paint()..color = Colors.black;

  // Draw the QR code on the canvas
  for (var x = 0; x < qr.moduleCount; x++) {
    for (var y = 0; y < qr.moduleCount; y++) {
      if (qr.isDark(y, x)) {
        canvas.drawRect(
          Rect.fromLTWH(
              x * qrCodeSize / qr.moduleCount,
              y * qrCodeSize / qr.moduleCount,
              qrCodeSize / qr.moduleCount,
              qrCodeSize / qr.moduleCount),
          paint,
        );
      }
    }
  }

  // Convert the canvas to a PNG image
  final img = await pictureRecorder.endRecording().toImage(size, size);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

class PaymentDialog extends StatefulWidget {
  final double total;
  final VoidCallback onClearCart;
  final List<CartItem> cartItems;

  PaymentDialog({
    required this.total,
    required this.onClearCart,
    required this.cartItems,
  });

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _selectedPaymentMethod = 'QRIS';
  bool _isDelivery = false;
  TextEditingController _noteController = TextEditingController();
  String? qrCodeUrl;
  bool _isLoading = true;
  @override
  void dispose() {
    _noteController.dispose(); // Dispose controller when done
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (_selectedPaymentMethod == 'QRIS') {
      _fetchQRCodeUrl();
    }
  }

  Future<void> _fetchQRCodeUrl() async {
    try {
      final url = await createqris(widget.total.toInt(), context);
      setState(() {
        qrCodeUrl = url;
        _isLoading = false; // Stop showing loading indicator
      });
    } catch (e) {
      setState(() {
        _isLoading =
            false; // Stop showing loading indicator even if there's an error
      });
      // Handle error (e.g., show an error message)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Total: \Rp.${NumberFormat('#,###.00', 'id_ID').format(widget.total)}'),
            SizedBox(height: 20),
            Text('Select Payment Method:'),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true; // Start showing loading indicator
                        _fetchQRCodeUrl();
                        _selectedPaymentMethod = 'QRIS';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedPaymentMethod == 'QRIS'
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    child: Text('QRIS'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = false;
                        qrCodeUrl = null;
                        _selectedPaymentMethod = 'Cash';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedPaymentMethod == 'Cash'
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    child: Text('Cash'),
                  ),
                ),
              ],
            ),
            if (_selectedPaymentMethod == "QRIS") ...[
              Center(
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Column(
                        children: [
                          Text('Scan this QR Code'),
                          FutureBuilder<Uint8List>(
                            future: generateQrImage(qrCodeUrl!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error generating QR code');
                              } else {
                                return Image.memory(snapshot.data!);
                              }
                            },
                          )
                        ],
                      ), // Show a loading indicator while the QR code is being fetched
              ),
            ] else ...[
              SizedBox(height: 20),
              Center(
                child: Text('Please pay with cash at the cashier.'),
              ),
            ],
            SizedBox(height: 20),
            CheckboxListTile(
              title: Text('Delivery'),
              value: _isDelivery,
              onChanged: (bool? value) {
                setState(() {
                  _isDelivery = value ?? false;
                });
              },
            ),
            Expanded(
              child: TextField(
                controller: _noteController,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _confirmPayment();
                widget.onClearCart();
              },
              child: Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPayment() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Confirmed!')),
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
