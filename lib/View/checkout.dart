import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:kasir_pos/View/Cashier.dart';
import 'package:kasir_pos/view-model-flutter/cabang_controller.dart';
import 'package:kasir_pos/view-model-flutter/transaksi_controller.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:qr/qr.dart';
import 'package:kasir_pos/View/tools/theme_mode.dart';
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
  String _selectedPaymentMethod = 'QRIS';
  bool _isDelivery = false;
  TextEditingController _noteController = TextEditingController();
  TextEditingController _emailinvoiceController = TextEditingController();
  TextEditingController _custTelpNumberController = TextEditingController();
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Provider.of<ThemeManager>(context).getTheme(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Confirm Payment'),
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
                                color: Colors
                                    .grey[300], // Placeholder background color
                                child: item.item.gambar_barang != null
                                    ? Image.memory(
                                        base64Decode(item.item
                                            .gambar_barang!), // Decode Base64 string
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          // Fallback if the image can't be loaded
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
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _fetchQRCodeUrl();
                                  _selectedPaymentMethod = 'QRIS';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _selectedPaymentMethod == 'QRIS'
                                        ? Colors.blue
                                        : Colors.grey,
                              ),
                              child: Text('QRIS',
                                  style: TextStyle(color: Colors.white)),
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
                                backgroundColor:
                                    _selectedPaymentMethod == 'Cash'
                                        ? Colors.blue
                                        : Colors.grey,
                              ),
                              child: Text(
                                'Cash',
                                style: TextStyle(color: Colors.white),
                              ),
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
                                    Text('Press the button to view QR Code'),
                                    ElevatedButton(
                                      onPressed: () async {
                                        // Show a dialog with the QR code when the button is pressed
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                'QR Code',
                                                textAlign: TextAlign.center,
                                              ),
                                              content: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "a/n xxx xxx xxx",
                                                    style: TextStyle(
                                                        fontSize: 30,
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  FutureBuilder<Uint8List>(
                                                    future: generateQrImage(
                                                        qrCodeUrl!),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return CircularProgressIndicator();
                                                      } else if (snapshot
                                                          .hasError) {
                                                        return Text(
                                                            'Error generating QR code'); // Handle error
                                                      } else {
                                                        return SizedBox(
                                                          width: 500,
                                                          height: 500,
                                                          child: Image.memory(
                                                              snapshot
                                                                  .data!), // Display the QR code
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: Text('Close'),
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(); // Close the dialog
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                      child: Text(
                                        'Show QR Code',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
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
                            print("status DELIVERY: $status");
                          });
                        },
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

  void _confirmPayment(String payment, bool delivery) async {
    try {
      //check delivery
      if (delivery) {
        if (_custAddressController.text.isNotEmpty &&
            _custTelpNumberController.text.isNotEmpty) {
          //transaksi
          var response = await addTrans(payment, delivery, _noteController.text,
              data_item, status, widget.total, context);
          var transData = response?['data'];
          final dataStorage = GetStorage();
          String id_cabang = dataStorage.read('id_cabang');
          //delivery
          var responseDeliver = await addDelivery(
              _custAddressController.text.toString(),
              _custTelpNumberController.text.toString(),
              transData.toString(),
              context);
          print(responseDeliver);
          List<Map<String, dynamic>> cabang =
              await getdatacabangByID(id_cabang);
          String nama_cabang = cabang[0]['nama_cabang'];
          String alamat = cabang[0]['alamat'];
          String no_telp = cabang[0]['no_telp'];
          // Initialize timezone data
          tz.initializeTimeZones();
          // Set the location to (WIB)
          final jakarta = tz.getLocation('Asia/Jakarta');
          DateTime invoicedate = tz.TZDateTime.now(jakarta);
          String isdeliver;
          if (delivery) {
            isdeliver = "yes";
          } else {
            isdeliver = "no";
          }
          //invoice
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Alamat tidak boleh kosong!')),
          );
        }
      } else {
        //transaksi
        var response = await addTrans(payment, delivery, _noteController.text,
            data_item, status, widget.total, context);
        var transData = response?['data'];
        final dataStorage = GetStorage();
        String id_cabang = dataStorage.read('id_cabang');
        List<Map<String, dynamic>> cabang = await getdatacabangByID(id_cabang);
        String nama_cabang = cabang[0]['nama_cabang'];
        String alamat = cabang[0]['alamat'];
        String no_telp = cabang[0]['no_telp'];
        // Initialize timezone data
        tz.initializeTimeZones();
        // Set the location to (WIB)
        final jakarta = tz.getLocation('Asia/Jakarta');
        DateTime invoicedate = tz.TZDateTime.now(jakarta);
        String isdeliver;
        if (delivery) {
          isdeliver = "yes";
        } else {
          isdeliver = "no";
        }
        //invoice
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
      }
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
