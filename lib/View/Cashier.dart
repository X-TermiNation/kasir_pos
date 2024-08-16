import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:kasir_pos/View/Login.dart';
import 'package:kasir_pos/View/checkout.dart';
import 'package:kasir_pos/View/history.dart';
import 'package:kasir_pos/view-model-flutter/barang_controller.dart';
import 'package:kasir_pos/view-model-flutter/diskon_controller.dart';

final dataStorage = GetStorage();
String id_gudang = dataStorage.read('id_gudang');
double subtotal = 0;
double total = 0;
var barangdata =
    Future.delayed(Duration(seconds: 1), () => getBarang(id_gudang));

class Cashier extends StatefulWidget {
  const Cashier({Key? key}) : super(key: key);

  @override
  State<Cashier> createState() => _CashierState();
}

class _CashierState extends State<Cashier> {
  static const int itemsPerPage = 9;
  int currentPage = 0;
  List<Barang> _items = [];
  List<Barang> _displayedItems = [];
  List<CartItem> _cartItems = [];
  List<Barang> _allItems = [];
  List<List<Map<String, dynamic>>> _satuanDataList = [];

  @override
  void initState() {
    super.initState();
    fetchBarang();
  }

  void _handleItemPressed(
      List<Map<String, dynamic>> satuanData, Barang item, int satuanIndex) {
    // Check if the selected index is within bounds
    if (satuanIndex < 0 || satuanIndex >= satuanData.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Index tidak valid')),
      );
      return;
    }

    // Check if the selected satuan has available stock
    bool hasAvailableStock =
        satuanData.any((satuan) => (satuan['jumlah_satuan'] ?? 0) > 0);

    // Check if the stock for the selected satuan is greater than 0
    bool isSelectedSatuanAvailable =
        (satuanData[satuanIndex]['jumlah_satuan'] ?? 0) > 0;

    // If no satuan has available stock or the selected satuan has zero stock, show a message and return
    if (!hasAvailableStock && !isSelectedSatuanAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock habis untuk barang ini!')),
      );
      return;
    }

    setState(() {
      CartItem? existingCartItem = _cartItems.firstWhere(
        (cartItem) => cartItem.item.nama_barang == item.nama_barang,
        orElse: () => CartItem(
          item: item,
          quantity: 0,
          selectedSatuan: satuanData[0],
          priceWithoutDiscount: (satuanData[0]['harga_satuan'] ?? 0).toDouble(),
        ),
      );

      if (existingCartItem.quantity == 0) {
        existingCartItem.quantity = 1;
        _cartItems.add(existingCartItem);
        _satuanDataList.add(satuanData);
      } else {
        int currentQuantity = existingCartItem.quantity;
        int maxQuantity = satuanData[satuanIndex]['jumlah_satuan'] ?? 0;

        if (currentQuantity < maxQuantity) {
          existingCartItem.quantity += 1;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Batas Stok Tercapai!')),
          );
        }
      }

      // Update price based on selected satuan
      existingCartItem.selectedSatuan = satuanData[satuanIndex];
      existingCartItem.priceWithoutDiscount =
          (satuanData[satuanIndex]['harga_satuan'] ?? 0).toDouble();

      _updateSubtotal();
    });
  }

  Future<void> fetchBarang() async {
    var barangData =
        await Future.delayed(Duration(seconds: 1), () => getBarang(id_gudang));
    setState(() {
      _items = (barangData ?? []).map((item) => Barang.fromJson(item)).toList();
      _allItems = List.from(_items); // Initialize _allItems with all items
      _updateDisplayedItems();
    });
  }

  void _updateDisplayedItems([String query = '']) {
    setState(() {
      _displayedItems = _allItems.where((item) {
        return item.nama_barang.toLowerCase().contains(query.toLowerCase());
      }).toList();
      int totalPages = (_displayedItems.length / itemsPerPage).ceil();
      _displayedItems = _displayedItems
          .skip(currentPage * itemsPerPage)
          .take(itemsPerPage)
          .toList();
    });
  }

//main display
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
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

          return Scaffold(
            appBar: AppBar(
              title: Text('Point of Sale App'),
            ),
            drawer: Drawer(
              child: Column(
                children: [
                  SizedBox(
                    height: 100, // Set a custom height for the header
                    child: DrawerHeader(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Cashier App',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.point_of_sale),
                    title: Text('Cashier'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.history),
                    title: Text('Transaction History'),
                    onTap: () {
                      setState(() {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryPage(),
                          ),
                        );
                      });
                    },
                  ),
                  Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey, width: 1.0),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Log Out'),
                      onTap: () {
                        showLogoutConfirmationDialog(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
            body: Row(
              children: [
                // Left side: List of items with search bar
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search items...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (query) {
                            _updateDisplayedItems(query);
                          },
                        ),
                        SizedBox(
                            height: 16.0), // Space between search bar and grid
                        // List of items
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 3,
                            childAspectRatio: 1,
                            children:
                                _displayedItems.asMap().entries.map((entry) {
                              int index = 0;
                              Barang item = entry.value;
                              return ItemCard(
                                item: item,
                                satuanIndex:
                                    index, // Pass the index to ItemCard
                                onPressed: () async {
                                  List<Map<String, dynamic>> satuanData =
                                      await getsatuan(item.id, context);
                                  _handleItemPressed(satuanData, item,
                                      index); // Pass index to _handleItemPressed
                                  _updateSubtotal();
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Cart Items: ${_cartItems.length}"),
                        ),

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
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    setState(() {
                                      if (newQuantity <= 0) {
                                        _cartItems.removeAt(index);
                                        _satuanDataList.removeAt(index);
                                      } else {
                                        _cartItems[index].quantity =
                                            newQuantity;
                                      }
                                      _updateSubtotal();
                                    });
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
                                '\Rp.${NumberFormat('#,###.00', 'id_ID').format(subtotal)}',
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
                                '\Rp.${NumberFormat('#,###.00', 'id_ID').format(subtotal * (11 / 100))}',
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
                                '\Rp.${NumberFormat('#,###.00', 'id_ID').format(total)}',
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: () {
                                if (_cartItems.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentDialog(
                                        total: total,
                                        onClearCart: _clearCart,
                                        cartItems: _cartItems,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Warning: Cart tidak boleh kosong!')),
                                  );
                                }
                              },
                              child: Text(
                                "CheckOut",
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
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

  void showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log Out'),
          content: Text('Anda Ingin Log Out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                GetStorage().erase();
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Login()));
                // Close the dialog
              },
              child: Text('Ya'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Tidak'),
            ),
          ],
        );
      },
    );
  }

  double _calculateSubtotal() {
    double subtotal = 0.0;
    for (CartItem cartItem in _cartItems) {
      if (cartItem.priceWithDiscount != null) {
        subtotal += cartItem.priceWithDiscount!;
      } else {
        subtotal += cartItem.priceWithoutDiscount;
      }
    }
    return subtotal;
  }

  double _calculateTotal() {
    // For now, total is the same as subtotal
    double totals = _calculateSubtotal() + _calculateSubtotal() * (11 / 100);
    return totals;
  }

  void _updateSubtotal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        subtotal = _calculateSubtotal();
        total = _calculateTotal();
      });
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _satuanDataList.clear();
      _updateSubtotal();
    });
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
  double priceWithoutDiscount;
  double? priceWithDiscount;
  int? discountpercentage;

  CartItem(
      {required this.item,
      this.quantity = 1,
      required this.selectedSatuan,
      required this.priceWithoutDiscount,
      this.priceWithDiscount,
      this.discountpercentage});
}

class ItemCard extends StatelessWidget {
  final Barang item;
  final VoidCallback onPressed;
  final int satuanIndex;

  ItemCard(
      {required this.item, required this.onPressed, required this.satuanIndex});

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
  List<Map<String, dynamic>> _diskonList = [];
  Map<String, dynamic>? _selectedDiskon;

  @override
  void initState() {
    super.initState();
    _initializeSelectedSatuan();
    fetchDiskonList();
  }

  void _initializeSelectedSatuan() {
    List<Map<String, dynamic>> availableSatuan = widget.satuanData
        .where((satuan) => (satuan['jumlah_satuan'] ?? 0) > 0)
        .toList();

    if (availableSatuan.isNotEmpty) {
      setState(() {
        _selectedSatuan = availableSatuan[0];
      });
    } else {
      setState(() {
        _selectedSatuan = {};
      });
    }

    _updatePrices();
  }

  void fetchDiskonList() async {
    try {
      List<Map<String, dynamic>> diskonData =
          await getDiskonbyBarang(widget.cartItem.item.id);
      setState(() {
        _diskonList = diskonData;
        _selectedDiskon = null;
        _updatePrices();
      });
    } catch (e) {
      print('Error fetching discounts: $e');
    }
  }

  void _updatePrices() {
    setState(() {
      widget.cartItem.priceWithoutDiscount = _calculateTotalWithoutDiscount();
      if (_selectedDiskon != null) {
        widget.cartItem.priceWithDiscount = _calculateTotalDiscount();
        widget.cartItem.discountpercentage =
            _selectedDiskon!['persentase_diskon'];
      } else {
        widget.cartItem.priceWithDiscount = null;
      }
      widget.onQuantityChanged(widget.cartItem.quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  widget.cartItem.item.nama_barang,
                  style: TextStyle(fontSize: 18.0),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                flex: 2,
                child: QuantityWidget(
                  quantity: widget.cartItem.quantity,
                  jumlahSatuan: _selectedSatuan['jumlah_satuan'] ?? 0,
                  onQuantityChanged: (newQuantity) {
                    setState(() {
                      if (newQuantity <= 0) {
                        widget.onQuantityChanged(0);
                      } else {
                        widget.cartItem.quantity = newQuantity;
                        _updatePrices();
                      }
                    });
                  },
                ),
              ),
              Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey, // Background color
                      borderRadius: BorderRadius.circular(12), // Rounded edges
                      border: Border.all(color: Colors.grey), // Border color
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 12), // Padding inside the dropdown
                    child: DropdownButtonHideUnderline(
                      // Hides the default underline
                      child: DropdownButton<Map<String, dynamic>>(
                        value:
                            _selectedSatuan.isNotEmpty ? _selectedSatuan : null,
                        onChanged: (newValue) {
                          if (newValue != null) {
                            print(newValue);
                            // Check stock
                            if ((newValue['jumlah_satuan'] ?? 0) > 0) {
                              setState(() {
                                _selectedSatuan = newValue;
                                widget.cartItem.selectedSatuan = newValue;
                                widget.cartItem.quantity = 1;
                                _updatePrices();
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Stok satuan ini habis!'),
                                ),
                              );
                            }
                          }
                        },
                        iconSize: 24.0,
                        icon: Icon(Icons.arrow_drop_down),
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                        isExpanded: true,
                        items: widget.satuanData
                            .map<DropdownMenuItem<Map<String, dynamic>>>(
                                (satuan) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: satuan,
                            child: Text(
                              '${satuan['nama_satuan']}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(color: Colors.black),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )),
              SizedBox(
                width: 5,
              ),
              Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueGrey, // Background color
                      borderRadius: BorderRadius.circular(12), // Rounded edges
                      border: Border.all(color: Colors.grey), // Border color
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 12), // Padding inside the dropdown
                    child: DropdownButtonHideUnderline(
                      // Hides the default underline
                      child: DropdownButton<Map<String, dynamic>>(
                        value: _selectedDiskon,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedDiskon = newValue;
                            _updatePrices();
                          });
                        },
                        iconSize: 20.0,
                        icon: Icon(Icons.arrow_drop_down),
                        style: TextStyle(fontSize: 16.0),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              'No Discount',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          ..._diskonList.map((diskon) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: diskon,
                              child: Text(
                                '${diskon['nama_diskon']}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
          if (_selectedSatuan.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price per unit: \Rp.${NumberFormat('#,###.00', 'id_ID').format(_selectedSatuan['harga_satuan'] ?? 0.0)}',
                      ),
                      _selectedDiskon == null
                          ? Text(
                              'Total: \Rp.${NumberFormat('#,###.00', 'id_ID').format(_calculateTotalWithoutDiscount())}',
                            )
                          : Text(
                              '\Rp.${NumberFormat('#,###.00', 'id_ID').format(_calculateTotalWithoutDiscount())}',
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                              ),
                            )
                    ],
                  ),
                  if (_selectedDiskon != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discount (${_selectedDiskon!['nama_diskon']}): ${_selectedDiskon!['persentase_diskon']}%',
                        ),
                        Text(
                          'Total: \Rp.${NumberFormat('#,###.00', 'id_ID').format(_calculateTotalDiscount())}',
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  double _calculateTotalWithoutDiscount() {
    double hargaSatuan = (_selectedSatuan['harga_satuan'] ?? 0.0).toDouble();
    return hargaSatuan * widget.cartItem.quantity;
  }

  double _calculateTotalDiscount() {
    if (_selectedDiskon != null) {
      double total = _calculateTotalWithoutDiscount();
      double discountPercentage =
          (_selectedDiskon!['persentase_diskon'] ?? 0) / 100;
      double discountAmount = total - (total * discountPercentage);
      return discountAmount;
    }
    return 0.0;
  }
}

class QuantityWidget extends StatelessWidget {
  final int quantity;
  final int jumlahSatuan;
  final ValueChanged<int> onQuantityChanged;

  QuantityWidget({
    required this.quantity,
    required this.jumlahSatuan,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  if (quantity >= 1) {
                    onQuantityChanged(quantity - 1);
                  } else {}
                },
              ),
              Text(quantity.toString()),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  if (quantity < jumlahSatuan) {
                    onQuantityChanged(quantity + 1);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Batas Stok Tercapai!')),
                    );
                  }
                },
              ),
            ],
          ),
          Text('Stock: $jumlahSatuan'),
        ],
      ),
    );
  }
}
