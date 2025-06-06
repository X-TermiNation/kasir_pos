import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:kasir_pos/View/Cashier.dart';
import 'package:kasir_pos/view-model-flutter/cabang_controller.dart';
import 'package:kasir_pos/view-model-flutter/transaksi_controller.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:qr/qr.dart';
import 'package:kasir_pos/View/tools/theme_mode.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
  final double subtotal;
  final VoidCallback onClearCart;
  final List<CartItem> cartItems;

  PaymentDialog({
    required this.total,
    required this.subtotal,
    required this.onClearCart,
    required this.cartItems,
  });

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  //VA Payment & others
  String? external_id;
  String? accountNumber;
  String? bankCode;
  String? vaName;
  int? vaAmount;
  String _selectedPaymentMethod = 'Cash';
  bool _isDelivery = false;
  //controller
  TextEditingController _noteController = TextEditingController();
  TextEditingController _emailinvoiceController = TextEditingController();
  TextEditingController _custTelpNumberController = TextEditingController();
  TextEditingController _custAddressController = TextEditingController();
  String? qrCodeUrl;
  String? qrBase64;
  bool _isLoading = true;
  List<Map<String, dynamic>> data_item = [];
  String status = "Confirmed";
  bool _isInvoiceGenerated = false;
  bool _sendinvoice = false;

  @override
  void initState() {
    super.initState();
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

  Widget _buildPlaceholderImage() {
    return Container(
      height: 120,
      width: 120,
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Future<void> _fetchVAInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await createVA(widget.total.toInt(), context);

      if (result == null ||
          !result.containsKey('account_number') ||
          !result.containsKey('bank_code') ||
          !result.containsKey('name') ||
          !result.containsKey('amount')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data Virtual Account")),
        );
        return;
      }

      setState(() {
        accountNumber = result['account_number'];
        bankCode = result['bank_code'];
        vaName = result['name'];
        vaAmount = result['amount'];
        external_id = result['external_id'];
      });
    } catch (e) {
      print('Error fetching VA info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan saat mengambil data VA")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //qrcode
  Future<void> _fetchQRCodeUrl() async {
    try {
      final url = await createqris(widget.total.toInt(), context);
      setState(() {
        qrBase64 = url;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Uint8List base64ToImage(String base64String) {
    final uriHeaderRegex = RegExp(r'data:image\/\w+;base64,');
    final cleanedBase64 = base64String.replaceAll(uriHeaderRegex, '');
    return base64Decode(cleanedBase64);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Provider.of<ThemeManager>(context).getTheme(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Checkout Page'),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Expanded(
                child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Cart Items:'),
                  Container(
                    height: 400,
                    child: ListView.builder(
                      itemCount: widget.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = widget.cartItems[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1.0,
                              ),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120.0,
                                height: 120.0,
                                color: Colors.grey[300],
                                child: item.item.gambar_barang != null
                                    ? Image.memory(
                                        base64Decode(item.item.gambar_barang!),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return _buildPlaceholderImage();
                                        },
                                      )
                                    : _buildPlaceholderImage(),
                              ),
                              SizedBox(width: 16.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.item.nama_barang,
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8.0),
                                    if (item.priceWithDiscount != null)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Price:',
                                              style: TextStyle(fontSize: 16.0),
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '\Rp.${NumberFormat('#,###.00', 'id_ID').format(item.priceWithoutDiscount)}',
                                                    style: TextStyle(
                                                      fontSize: 16.0,
                                                      color: Colors.red,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '\Rp.${NumberFormat('#,###.00', 'id_ID').format(item.priceWithDiscount)}',
                                                style: TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Price:',
                                              style: TextStyle(fontSize: 16.0),
                                            ),
                                          ),
                                          Text(
                                            '\Rp.${NumberFormat('#,###.00', 'id_ID').format(item.priceWithoutDiscount)}',
                                            style: TextStyle(
                                              fontSize: 16.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    SizedBox(height: 4.0),
                                    if (item.discountpercentage != null)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Discount:',
                                              style: TextStyle(fontSize: 16.0),
                                            ),
                                          ),
                                          Text(
                                            '${item.discountpercentage}%',
                                            style: TextStyle(fontSize: 16.0),
                                          ),
                                        ],
                                      ),
                                    SizedBox(height: 4.0),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Qty:',
                                            style: TextStyle(fontSize: 16.0),
                                          ),
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: TextStyle(fontSize: 16.0),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: Text(
                          "Subtotal: ",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Text(
                          '\Rp.${NumberFormat('#,###.00', 'id_ID').format(widget.subtotal)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: Text(
                          "Tax (11%): ",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Text(
                          '\Rp.${NumberFormat('#,###.00', 'id_ID').format(widget.subtotal * 11 / 100)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: Text(
                          "Grand Total: ",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Text(
                          '\Rp.${NumberFormat('#,###.00', 'id_ID').format(widget.total)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      Text('Select Payment Method:'),
                      Row(
                        children: [
                          // Expanded(
                          //   child: ElevatedButton(
                          //     onPressed: () {
                          //       setState(() {
                          //         _isLoading = true;
                          //         _fetchQRCodeUrl();
                          //         _selectedPaymentMethod = 'VA';
                          //       });
                          //     },
                          //     style: ElevatedButton.styleFrom(
                          //       minimumSize: Size(120, 120),
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(15),
                          //       ),
                          //       padding: EdgeInsets.all(0),
                          //       backgroundColor:
                          //           _selectedPaymentMethod == 'QRIS'
                          //               ? Theme.of(context).primaryColor
                          //               : Theme.of(context).brightness ==
                          //                       Brightness.dark
                          //                   ? Colors.grey[800]
                          //                   : Colors.grey[300],
                          //       elevation: 15,
                          //       shadowColor: Colors.black.withOpacity(0.3),
                          //     ),
                          //     child: Column(
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       children: [
                          //         Icon(
                          //           Icons.qr_code_2,
                          //           size: 55,
                          //           color: _selectedPaymentMethod == 'QRIS'
                          //               ? Colors.white
                          //               : Theme.of(context).brightness ==
                          //                       Brightness.dark
                          //                   ? Colors.white
                          //                   : Colors.black,
                          //         ),
                          //         SizedBox(height: 8),
                          //         Text(
                          //           'QRIS',
                          //           style: TextStyle(
                          //             color: _selectedPaymentMethod == 'QRIS'
                          //                 ? Colors.white
                          //                 : Theme.of(context).brightness ==
                          //                         Brightness.dark
                          //                     ? Colors.white
                          //                     : Colors.black,
                          //             fontWeight: FontWeight.bold,
                          //             fontSize: 16,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedPaymentMethod = 'VA';
                                });
                                _fetchVAInfo(); // Panggil saat VA dipilih
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(120, 120),
                                backgroundColor: _selectedPaymentMethod == 'VA'
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[800]
                                        : Colors.grey[300],
                                elevation: 15,
                                shadowColor: Colors.black.withOpacity(0.3),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_balance,
                                    size: 55,
                                    color: _selectedPaymentMethod == 'VA'
                                        ? Colors.white
                                        : Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Virtual Account',
                                    style: TextStyle(
                                      color: _selectedPaymentMethod == 'VA'
                                          ? Colors.white
                                          : Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedPaymentMethod = 'Cash';
                                  _isLoading = false;
                                  accountNumber = null;
                                  bankCode = null;
                                  vaName = null;
                                  vaAmount = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(120, 120),
                                backgroundColor:
                                    _selectedPaymentMethod == 'Cash'
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[800]
                                            : Colors.grey[300],
                                elevation: 15,
                                shadowColor: Colors.black.withOpacity(0.3),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.money_rounded,
                                    size: 55,
                                    color: _selectedPaymentMethod == 'Cash'
                                        ? Colors.white
                                        : Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Cash',
                                    style: TextStyle(
                                      color: _selectedPaymentMethod == 'Cash'
                                          ? Colors.white
                                          : Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedPaymentMethod == "VA") ...[
                        SizedBox(height: 20),
                        if (_isLoading)
                          Center(child: CircularProgressIndicator())
                        else
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 60,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Klik tombol untuk melihat nomor Virtual Account',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    if (accountNumber != null) {
                                      await simulateVAPayment(
                                          external_id!, vaAmount!);
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 20,
                                            ),
                                            title: const Center(
                                              child: Text(
                                                'Nomor Virtual Account',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  "Bank BCA a.n PT POS CABANG",
                                                  textAlign: TextAlign.center,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 16),
                                                SelectableText(
                                                  accountNumber!,
                                                  textAlign: TextAlign.center,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineSmall
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            actions: <Widget>[
                                              Center(
                                                child: TextButton.icon(
                                                  icon: const Icon(Icons.close),
                                                  label: const Text('Tutup'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Nomor VA belum tersedia')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('Tampilkan Nomor VA'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                // ElevatedButton(
                                //   onPressed: () async {
                                //     if (qrBase64 != null &&
                                //         qrBase64!.isNotEmpty) {
                                //       showDialog(
                                //         context: context,
                                //         builder: (BuildContext context) {
                                //           return AlertDialog(
                                //             title: Text('QR Code'),
                                //             content: Column(
                                //               mainAxisSize: MainAxisSize.min,
                                //               children: [
                                //                 Text(
                                //                   "a/n xxx xxx xxx",
                                //                   style: TextStyle(
                                //                       fontSize: 18,
                                //                       fontWeight:
                                //                           FontWeight.bold),
                                //                 ),
                                //                 SizedBox(height: 20),
                                //                 Image.memory(
                                //                     base64ToImage(qrBase64!)),
                                //               ],
                                //             ),
                                //             actions: <Widget>[
                                //               TextButton(
                                //                 child: Text('Close'),
                                //                 onPressed: () {
                                //                   Navigator.of(context).pop();
                                //                 },
                                //               ),
                                //             ],
                                //           );
                                //         },
                                //       );
                                //     }
                                //   },
                                //   style: ElevatedButton.styleFrom(
                                //     backgroundColor: Colors.blue,
                                //   ),
                                //   child: Text(
                                //     'Show QR Code',
                                //     style: TextStyle(color: Colors.white),
                                //   ),
                                // ),
                              ],
                            ),
                          )
                      ] else ...[
                        SizedBox(height: 20),
                        Center(
                          child: Text(
                              'Silahkan pembayaran tunai langsung pada kasir.'),
                        ),
                      ],
                      SizedBox(height: 20),
                      Column(
                        children: <Widget>[
                          if (_isDelivery) ...[
                            TextFormField(
                              controller: _custAddressController,
                              decoration: InputDecoration(
                                labelText: 'Input Alamat Pelanggan',
                              ),
                            ),
                            SizedBox(
                                height:
                                    16), // Optional: Add spacing between fields
                            TextFormField(
                              controller: _custTelpNumberController,
                              decoration: InputDecoration(
                                labelText: 'Input Nomor Telepon Pelanggan',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ]
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Delivery:',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: Switch(
                              value: _isDelivery,
                              onChanged: (bool value) {
                                setState(() {
                                  _isDelivery = value;
                                  status =
                                      _isDelivery ? "Pending" : "Confirmed";
                                  print("status DELIVERY: $status");
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _noteController,
                        maxLines: null,
                        decoration: InputDecoration(
                          labelText: 'Catatan Tambahan',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _confirmPayment(_selectedPaymentMethod, _isDelivery);
                          widget.onClearCart();
                        },
                        child: Text('Pay'),
                      ),
                    ],
                  ),
                ],
              ),
            ))),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Generating Invoice..."),
          ],
        ),
      ),
    );
  }

  void _confirmPayment(String payment, bool delivery) async {
    try {
      if (delivery) {
        if (_custAddressController.text.isEmpty ||
            _custTelpNumberController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Alamat tidak boleh kosong!')),
          );
          return;
        }
      }

      var response = await addTrans(payment, delivery, _noteController.text,
          data_item, status, widget.total, context);
      var transData = response?['data'];

      if (delivery) {
        await addDelivery(
          _custAddressController.text,
          _custTelpNumberController.text,
          transData.toString(),
          context,
        );
      }

      final dataStorage = GetStorage();
      String id_cabang = dataStorage.read('id_cabang');
      List<Map<String, dynamic>> cabang = await getdatacabangByID(id_cabang);
      String nama_cabang = cabang[0]['nama_cabang'];
      String alamat = cabang[0]['alamat'];
      String no_telp = cabang[0]['no_telp'];

      _showLoadingDialog(context);

      tz.initializeTimeZones();
      final jakarta = tz.getLocation('Asia/Jakarta');
      DateTime invoicedate = tz.TZDateTime.now(jakarta);
      String isdeliver = delivery ? "yes" : "no";

      var result = await generateInvoice(nama_cabang, alamat, no_telp,
          invoicedate, payment, isdeliver, data_item, context);

      Navigator.of(context).pop();
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
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
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
