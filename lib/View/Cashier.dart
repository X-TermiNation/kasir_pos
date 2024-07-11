import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart'; // Import the intl package for NumberFormat
import 'package:kasir_pos/view-model-flutter/barang_controller.dart';

final dataStorage = GetStorage();
String id_gudangs = dataStorage.read('id_gudang');

var barangdata =
    Future.delayed(Duration(seconds: 1), () => getBarang(id_gudangs));

class Cashier extends StatefulWidget {
  const Cashier({Key? key}) : super(key: key);

  @override
  State<Cashier> createState() => _CashierState();
}

class _CashierState extends State<Cashier> {
  static const int itemsPerPage = 9;
  int currentPage = 0;
  List<Barang> _items = [];
  List<CartItem> _cartItems = [];
  List<List<Map<String, dynamic>>> _satuanDataList = [];

  @override
  void initState() {
    super.initState();
  }

  void _handleItemPressed(List<Map<String, dynamic>> satuanData, Barang item) {
    setState(() {
      CartItem? existingCartItem = _cartItems.firstWhere(
        (cartItem) => cartItem.item.nama_barang == item.nama_barang,
        orElse: () => CartItem(item: item, quantity: 0, selectedSatuan: {}),
      );
      if (existingCartItem.quantity == 0) {
        _cartItems.add(CartItem(item: item, quantity: 1, selectedSatuan: {}));
        _satuanDataList.add(satuanData);
      } else {
        existingCartItem.quantity += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: barangdata,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          _items = (snapshot.data ?? [])
              .map((item) => Barang.fromJson(item))
              .toList();
          int totalPages = (_items.length / itemsPerPage).ceil();
          List<Barang> displayedItems = _items
              .skip(currentPage * itemsPerPage)
              .take(itemsPerPage)
              .toList();

          return Scaffold(
            appBar: AppBar(
              title: Text('Point of Sale App'),
            ),
            body: Row(
              children: [
                // Left side: List of items
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // List of items
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 3,
                            childAspectRatio: 1,
                            children: displayedItems.map((item) {
                              return ItemCard(
                                item: item,
                                onPressed: () async {
                                  List<Map<String, dynamic>> satuanData =
                                      await getsatuan(item.id, context);
                                  _handleItemPressed(satuanData, item);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        // Page navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back),
                              onPressed: currentPage > 0
                                  ? () {
                                      setState(() {
                                        currentPage--;
                                      });
                                    }
                                  : null,
                            ),
                            Text('Page ${currentPage + 1} of $totalPages'),
                            IconButton(
                              icon: Icon(Icons.arrow_forward),
                              onPressed: currentPage < totalPages - 1
                                  ? () {
                                      setState(() {
                                        currentPage++;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Right side: Cart
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Cart table
                        Expanded(
                          child: ListView.builder(
                            itemCount: _cartItems.length,
                            itemBuilder: (context, index) {
                              return CartItemRow(
                                key: ValueKey(_cartItems[index].item.id),
                                cartItem: _cartItems[index],
                                satuanData: _satuanDataList[index],
                                onQuantityChanged: (newQuantity) {
                                  setState(() {
                                    if (newQuantity <= 0) {
                                      _cartItems.removeAt(index);
                                      _satuanDataList.removeAt(index);
                                    } else {
                                      _cartItems[index].quantity = newQuantity;
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        // Total price
                        Container(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal:'),
                              Text(
                                '\Rp.${NumberFormat('#,###.00', 'id_ID').format(_calculateSubtotal())}',
                              ),
                            ],
                          ),
                        ),
                        // Tax (11%)
                        Container(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tax (11%):'),
                              Text(
                                '\Rp.${NumberFormat('#,###.00', 'id_ID').format(_calculateSubtotal() * (11 / 100))}',
                              ),
                            ],
                          ),
                        ),
                        // Total price after tax
                        Container(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total:'),
                              Text(
                                '\Rp.${NumberFormat('#,###.00', 'id_ID').format(_calculateTotal() + _calculateSubtotal() * (11 / 100))}',
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                                onPressed: () {},
                                child: Text(
                                  "Pay",
                                  style: TextStyle(fontSize: 20),
                                )),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  double _calculateSubtotal() {
    double subtotal = 0.0;
    for (int i = 0; i < _cartItems.length; i++) {
      CartItem cartItem = _cartItems[i];
      Map<String, dynamic> selectedSatuan = _satuanDataList[i].firstWhere(
        (satuan) =>
            satuan['nama_satuan'] == cartItem.selectedSatuan['nama_satuan'],
        orElse: () => {},
      );
      double hargaSatuan = (selectedSatuan['harga_satuan'] ?? 0).toDouble();
      subtotal += hargaSatuan * cartItem.quantity;
    }
    return subtotal;
  }

  double _calculateTotal() {
    // For now, total is the same as subtotal
    return _calculateSubtotal();
  }
}

class Barang {
  final String nama_barang;
  final String id;

  Barang({required this.nama_barang, required this.id});
  factory Barang.fromJson(Map<String, dynamic> json) {
    return Barang(nama_barang: json['nama_barang'], id: json['_id']);
  }
}

class CartItem {
  final Barang item;
  int quantity;
  Map<String, dynamic> selectedSatuan;

  CartItem({
    required this.item,
    this.quantity = 1,
    required this.selectedSatuan,
  });
}

class ItemCard extends StatelessWidget {
  final Barang item;
  final VoidCallback onPressed;

  ItemCard({required this.item, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.nama_barang),
              // Text('\$${item.harga.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ),
    );
  }
}

class CartItemRow extends StatefulWidget {
  final CartItem cartItem;
  final List<Map<String, dynamic>> satuanData;
  final ValueChanged<int> onQuantityChanged;

  CartItemRow({
    required Key? key,
    required this.cartItem,
    required this.satuanData,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  _CartItemRowState createState() => _CartItemRowState();
}

class _CartItemRowState extends State<CartItemRow> {
  late Map<String, dynamic> _selectedSatuan;

  @override
  void initState() {
    super.initState();
    _selectedSatuan = widget.satuanData.isNotEmpty ? widget.satuanData[0] : {};
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  widget.cartItem.item.nama_barang,
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
              Expanded(
                child: QuantityWidget(
                  quantity: widget.cartItem.quantity,
                  onQuantityChanged: widget.onQuantityChanged,
                ),
              ),
              Expanded(
                flex: 2,
                child: DropdownButton<Map<String, dynamic>>(
                  value: _selectedSatuan,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedSatuan = newValue!;
                      widget.cartItem.selectedSatuan = newValue;
                      widget.onQuantityChanged(widget.cartItem.quantity);
                    });
                  },
                  iconSize: 20.0,
                  icon: Icon(Icons.arrow_drop_down),
                  style: TextStyle(fontSize: 16.0),
                  items: widget.satuanData.map((satuan) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: satuan,
                      child: Text(
                        '${satuan['nama_satuan']}',
                        style: TextStyle(color: Colors.black),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          if (_selectedSatuan.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price per unit: \Rp.${NumberFormat('#,###.00', 'id_ID').format(_selectedSatuan['harga_satuan'] ?? 0.0)}',
                  ),
                  Text(
                    'Total: \Rp.${NumberFormat('#,###.00', 'id_ID').format((_selectedSatuan['harga_satuan'] ?? 0.0) * widget.cartItem.quantity)}',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class QuantityWidget extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  QuantityWidget({required this.quantity, required this.onQuantityChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: () {
            if (quantity > 1) {
              onQuantityChanged(quantity - 1);
            } else {
              onQuantityChanged(0);
            }
          },
        ),
        Text(quantity.toString()),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            onQuantityChanged(quantity + 1);
          },
        ),
      ],
    );
  }
}
