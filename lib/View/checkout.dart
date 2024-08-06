import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:kasir_pos/View/Cashier.dart';
import 'package:kasir_pos/view-model-flutter/cabang_controller.dart';
import 'package:kasir_pos/view-model-flutter/transaksi_controller.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:qr/qr.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

Future<Uint8List> generateQrImage(String data) async {
  final qr = QrCode(4, QrErrorCorrectLevel.L);
  qr.addData(data);
  qr.make();

  final qrCodeSize = 200.0;
  final size = qrCodeSize.toInt();

  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder,
      Rect.fromPoints(Offset(0, 0), Offset(size.toDouble(), size.toDouble())));

  final paint = Paint()..color = Colors.black;

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
  TextEditingController _emailinvoiceController = TextEditingController();
  TextEditingController _custAddressController = TextEditingController();
  String? qrCodeUrl;
  bool _isLoading = true;
  List<Map<String, dynamic>> data_item = [];
  String status = "Confirmed";
  bool _isInvoiceGenerated = false;
  bool _sendinvoice = false;

  @override
  void initState() {
    super.initState();
    if (_selectedPaymentMethod == 'QRIS') {
      _fetchQRCodeUrl();
    }
    data_item = getCartData(widget.cartItems, widget.total);
  }

  List<Map<String, dynamic>> getCartData(
      List<CartItem> cartItems, double total) {
    List<Map<String, dynamic>> dataItem = [];

    for (var cartItem in cartItems) {
      Map<String, dynamic> dataTemp = {
        'id_reference': cartItem.item.id,
        'nama_barang': cartItem.item.nama_barang,
        'id_satuan': cartItem.selectedSatuan['_id'].toString(),
        'satuan_price': cartItem.selectedSatuan['harga_satuan'],
        'trans_qty': cartItem.quantity,
        'persentase_diskon': cartItem.discountpercentage ?? 0,
        'total_price':
            cartItem.priceWithDiscount ?? cartItem.priceWithoutDiscount,
      };

      dataItem.add(dataTemp);
    }

    return dataItem;
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
            Text('Cart Items:'),
            Container(
              height: 200, // Adjust as needed
              child: ListView.builder(
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];
                  return ListTile(
                    title: Text(item.item.nama_barang),
                    subtitle: item.priceWithDiscount != null
                        ? Text(
                            'Price: \Rp.${NumberFormat('#,###.00', 'id_ID').format(item.priceWithDiscount)}      Diskon:${item.discountpercentage}%')
                        : Text(
                            'Price: \Rp.${NumberFormat('#,###.00', 'id_ID').format(item.priceWithoutDiscount)}'),
                    trailing: Text('Qty: ${item.quantity}'),
                  );
                },
              ),
            ),
            Text.rich(
              TextSpan(
                text: 'Total: ',
                children: [
                  TextSpan(
                    text:
                        '\Rp.${NumberFormat('#,###.00', 'id_ID').format(widget.total)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
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
                child: Text('Silahkan pembayaran tunai langsung pada kasir.'),
              ),
            ],
            SizedBox(height: 20),
            Column(
              children: <Widget>[
                _isDelivery
                    ? TextFormField(
                        controller: _custAddressController,
                        decoration: InputDecoration(
                          labelText: 'Input Alamat Pelanggan',
                        ),
                      )
                    : Container(),
              ],
            ),
            CheckboxListTile(
              title: Text('Delivery'),
              value: _isDelivery,
              onChanged: (bool? value) {
                setState(() {
                  _isDelivery = value ?? false;
                  if (_isDelivery) {
                    status = "Pending";
                  } else {
                    status = "Confirmed";
                  }
                });
              },
            ),
            Expanded(
              child: TextField(
                controller: _noteController,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: 'Catatan Tambahan',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _confirmPayment(_selectedPaymentMethod, _isDelivery);
                widget.onClearCart();
              },
              child: Text('Pay'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPayment(String payment, bool delivery) async {
    try {
      var response = await addTrans(
          payment, delivery, _noteController.text, data_item, status, context);
      var transData = response?['data'];
      final dataStorage = GetStorage();
      String id_cabang = dataStorage.read('id_cabang');
      if (delivery && _custAddressController.text.isNotEmpty) {
        var responseDeliver =
            await addDelivery(_custAddressController.text, transData, context);
        print(responseDeliver);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alamat tidak boleh kosong!')),
        );
      }
      List<Map<String, dynamic>> cabang = await getdatacabangByID(id_cabang);
      String nama_cabang = cabang[0]['nama_cabang'];
      String alamat = cabang[0]['alamat'];
      String no_telp = cabang[0]['no_telp'];
      DateTime invoicedate = DateTime.now();
      String isdeliver;
      if (delivery) {
        isdeliver = "yes";
      } else {
        isdeliver = "no";
      }
      var result = await generateInvoice(nama_cabang, alamat, no_telp,
          invoicedate, payment, isdeliver, data_item, context);
      print("ini hasil:${result['invoicePath']}");
      _showInvoiceDialog(result['invoicePath'], context);
      _noteController.text = "";
      if (result['success']) {
        setState(() {
          _isInvoiceGenerated = true;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pay Confirmed!')),
      );
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  void _showInvoiceDialog(String invoicePath, BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder<bool>(
              future: Future.delayed(Duration(milliseconds: 500),
                  () => _isInvoiceGenerated), // Adjust delay as needed
              builder: (context, snapshot) {
                bool isGenerated = snapshot.data ?? false;
                return AlertDialog(
                  title: Text('Payment Status'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isGenerated)
                        SpinKitFadingCircle(color: Colors.blue, size: 50.0)
                      else
                        Icon(Icons.check_circle,
                            color: Colors.green, size: 50.0),
                      SizedBox(height: 20),
                      Text('Your payment has been confirmed.'),
                      SizedBox(height: 20),
                      Column(
                        children: <Widget>[
                          _sendinvoice
                              ? TextFormField(
                                  controller: _emailinvoiceController,
                                  decoration: InputDecoration(
                                    labelText: 'Enter email',
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: isGenerated
                            ? () {
                                if (_sendinvoice) {
                                  if (_emailinvoiceController.text.isNotEmpty) {
                                    sendInvoiceByEmail(invoicePath,
                                        _emailinvoiceController.text, context);

                                    setState(() {
                                      _sendinvoice = false;
                                      _emailinvoiceController
                                          .clear(); // Clear the text field
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Email tidak boleh kosong!'),
                                      ),
                                    );
                                  }
                                } else {
                                  setState(() {
                                    _sendinvoice = true;
                                  });
                                }
                              }
                            : null,
                        child: Text(_sendinvoice
                            ? 'Confirm Email'
                            : 'Send Invoice Via Email'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isGenerated
                            ? () {
                                Navigator.of(context).pop();
                                Navigator.pop(context);
                              }
                            : null,
                        child: Text('Continue'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
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
