import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:kasir_pos/View/Login.dart';
import 'package:kasir_pos/View/checkout.dart';
import 'package:kasir_pos/View/history.dart';
import 'package:kasir_pos/view-model-flutter/barang_controller.dart';
import 'package:kasir_pos/view-model-flutter/diskon_controller.dart';
import 'package:kasir_pos/View/tools/theme_mode.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

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
    if (satuanIndex < 0 || satuanIndex >= satuanData.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Index tidak valid')),
      );
      return;
    }

    bool hasAvailableStock =
        satuanData.any((satuan) => (satuan['jumlah_satuan'] ?? 0) > 0);
    bool isSelectedSatuanAvailable =
        (satuanData[satuanIndex]['jumlah_satuan'] ?? 0) > 0;

    if (!hasAvailableStock && !isSelectedSatuanAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock habis untuk barang ini!')),
      );
      return;
    }

    setState(() {
      int maxQuantity = satuanData[satuanIndex]['jumlah_satuan'] ?? 0;

      // Find if the item already exists in the cart
      int existingIndex = _cartItems.indexWhere(
        (cartItem) =>
            cartItem.item.id == item.id &&
            cartItem.selectedSatuan['id_satuan'] ==
                satuanData[satuanIndex]['id_satuan'],
      );

      if (existingIndex != -1) {
        // If item exists, update quantity
        if (_cartItems[existingIndex].quantity < maxQuantity) {
          _cartItems[existingIndex].quantity += 1;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Batas Stok Tercapai!')),
          );
        }
      } else {
        // If item doesn't exist, add new entry
        _cartItems.add(CartItem(
          item: item,
          quantity: 1,
          selectedSatuan: satuanData[satuanIndex],
          priceWithoutDiscount:
              (satuanData[satuanIndex]['harga_satuan'] ?? 0).toDouble(),
        ));
        _satuanDataList.add(satuanData);
      }

      _updateSubtotal();
    });
  }

  Future<void> fetchBarang() async {
    var barangData =
        await Future.delayed(Duration(seconds: 1), () => getBarang(id_gudang));
    setState(() {
      _items = (barangData ?? []).map((item) => Barang.fromJson(item)).toList();
      _allItems = List.from(_items);
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

          return MaterialApp(
            theme: Provider.of<ThemeManager>(context).getTheme(),
            home: Scaffold(
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistoryPage(),
                            ),
                          );
                        });
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.settings_display_rounded),
                      title: Consumer<ThemeManager>(
                        builder: (context, themeProvider, child) {
                          return Text(themeProvider.isDarkMode
                              ? 'Change Light Mode'
                              : 'Change Dark Mode');
                        },
                      ),
                      onTap: () {
                        Provider.of<ThemeManager>(context, listen: false)
                            .toggleDarkMode();
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
                    flex: 3,
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
                              height:
                                  16.0), // Space between search bar and grid
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
                                    _handleItemPressed(satuanData, item, index);
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
                  Container(
                    width: 1,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  // Right side: Cart
                  Expanded(
                    flex: 2,
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
                                Text(
                                  'Subtotal:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                    '\Rp.${NumberFormat('#,###.00', 'id_ID').format(subtotal)}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          // Tax (11%)
                          Container(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tax (11%):',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                    '\Rp.${NumberFormat('#,###.00', 'id_ID').format(subtotal * (11 / 100))}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          // Total price after tax
                          Container(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                    '\Rp.${NumberFormat('#,###.00', 'id_ID').format(total)}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
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
                                          subtotal: subtotal,
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
                                  "Checkout",
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.white),
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
        subtotal += (cartItem.priceWithDiscount!).roundToDouble();
      } else {
        subtotal += (cartItem.priceWithoutDiscount).roundToDouble();
      }
    }
    return subtotal;
  }

  double _calculateTotal() {
    // For now, total is the same as subtotal
    double totals = (_calculateSubtotal() + _calculateSubtotal() * (11 / 100))
        .roundToDouble();
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
  final String? gambar_barang; // Optional field for the image directory

  Barang({
    required this.nama_barang,
    required this.id,
    this.gambar_barang, // Optional constructor parameter
  });

  // Factory constructor to create an instance from JSON
  factory Barang.fromJson(Map<String, dynamic> json) {
    return Barang(
      nama_barang: json['nama_barang'],
      id: json['_id'],
      gambar_barang:
          json['gambar_barang'], // Load the image directory from JSON
    );
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

  ItemCard({
    required this.item,
    required this.onPressed,
    required this.satuanIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10, // Add a shadow to the card
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Theme.of(context).cardColor,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display the item image if available, otherwise show a placeholder
              if (item.gambar_barang != null && item.gambar_barang!.isNotEmpty)
                Image.memory(
                  base64Decode(item.gambar_barang!),
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if the image can't be loaded
                    return _buildPlaceholderImage();
                  },
                )
              else
                _buildPlaceholderImage(),

              // Item name
              Text(
                item.nama_barang,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Placeholder widget to show when the image is null or fails to load
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

  Widget _buildPlaceholderImage() {
    return Center(
      child: Icon(
        Icons.image_not_supported,
        size: 24,
        color: Colors.grey[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1.0),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment:
                CrossAxisAlignment.start, // Aligns the content to the top
            children: [
              // Pic placeholder
              Container(
                width: 120.0, // Fixed width for the image
                height: 120.0, // Fixed height for the image
                color: Colors.grey[300], // Placeholder background color
                child: widget.cartItem.item.gambar_barang !=
                        null // Check if image exists
                    ? Image.memory(
                        base64Decode(widget.cartItem.item
                            .gambar_barang!), // Decode Base64 string
                        height: 120,
                        width: 120,
                        fit: BoxFit
                            .cover, // Adjust the image to fit the container
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if the image can't be loaded
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(), // If no image, show placeholder
              ),
              SizedBox(width: 5.0), // Spacing between the image and text
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cartItem.item.nama_barang,
                      style: TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                        height:
                            8.0), // Spacing between the item name and quantity
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
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
                        SizedBox(width: 5.0),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Map<String, dynamic>>(
                                value: _selectedSatuan.isNotEmpty
                                    ? _selectedSatuan
                                    : null,
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    if ((newValue['jumlah_satuan'] ?? 0) > 0) {
                                      setState(() {
                                        _selectedSatuan = newValue;
                                        widget.cartItem.selectedSatuan =
                                            newValue;
                                        widget.cartItem.quantity = 1;
                                        _updatePrices();
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Stok satuan ini habis!'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                iconSize: 24.0,
                                icon: Icon(Icons.arrow_drop_down),
                                style: TextStyle(
                                    fontSize: 16.0, color: Colors.black),
                                isExpanded: true,
                                items: widget.satuanData.map<
                                        DropdownMenuItem<Map<String, dynamic>>>(
                                    (satuan) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: satuan,
                                    child: Text(
                                      '${satuan['nama_satuan']}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            width: 8.0), // Spacing between Satuan and Diskon
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                  ),
                                  ..._diskonList.where((diskon) {
                                    DateTime today = DateTime.now();
                                    DateTime startDate =
                                        DateTime.parse(diskon['start_date']);
                                    DateTime endDate =
                                        DateTime.parse(diskon['end_date']);

                                    return diskon['isActive'] == true &&
                                        today.isAfter(startDate) &&
                                        today.isBefore(endDate);
                                  }).map((diskon) {
                                    return DropdownMenuItem<
                                        Map<String, dynamic>>(
                                      value: diskon,
                                      child: Text(
                                        '${diskon['nama_diskon']}',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
    double hargaSatuan =
        ((_selectedSatuan['harga_satuan'] ?? 0.0).toDouble()).roundToDouble();
    return hargaSatuan * widget.cartItem.quantity;
  }

  double _calculateTotalDiscount() {
    if (_selectedDiskon != null) {
      double total = _calculateTotalWithoutDiscount();
      double discountPercentage =
          (_selectedDiskon!['persentase_diskon'] ?? 0) / 100;
      double discountAmount =
          (total - (total * discountPercentage)).roundToDouble();
      return discountAmount;
    }
    return 0.0;
  }
}

class QuantityWidget extends StatefulWidget {
  final int quantity; // Use this to set the initial quantity
  final int jumlahSatuan;
  final ValueChanged<int> onQuantityChanged;

  QuantityWidget({
    required this.quantity,
    required this.jumlahSatuan,
    required this.onQuantityChanged,
  });

  @override
  _QuantityWidgetState createState() => _QuantityWidgetState();
}

class _QuantityWidgetState extends State<QuantityWidget> {
  late int tempquantity; // Local state variable to hold quantity
  final TextEditingController quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tempquantity = widget.quantity; // Initialize quantity from widget
    quantityController.text = tempquantity.toString(); // Set initial text
  }

  @override
  void didUpdateWidget(covariant QuantityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity) {
      setState(() {
        tempquantity = widget.quantity;
        quantityController.text = tempquantity.toString(); // Ensure UI updates
      });
    }
  }

  @override
  void dispose() {
    quantityController
        .dispose(); // Dispose the controller to avoid memory leaks
    super.dispose();
  }

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
                  if (tempquantity > 0) {
                    setState(() {
                      tempquantity--; // Decrease quantity
                      quantityController.text =
                          tempquantity.toString(); // Update controller
                    });
                    widget.onQuantityChanged(tempquantity); // Notify parent
                  }
                },
              ),
              SizedBox(
                width: 50, // Fixed width for TextField
                child: TextField(
                  controller: quantityController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  onSubmitted: (value) {
                    int newQuantity = int.tryParse(value) ?? tempquantity;

                    if (newQuantity >= 0 &&
                        newQuantity <= widget.jumlahSatuan) {
                      setState(() {
                        tempquantity = newQuantity;
                        quantityController.text = tempquantity.toString();
                      });
                      widget.onQuantityChanged(tempquantity);
                    } else {
                      // Revert to previous valid quantity
                      quantityController.text = tempquantity.toString();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Batas Stok Tercapai!')),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  if (tempquantity < widget.jumlahSatuan) {
                    setState(() {
                      tempquantity++; // Increase quantity
                      quantityController.text =
                          tempquantity.toString(); // Update controller
                    });
                    widget.onQuantityChanged(tempquantity); // Notify parent
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Batas Stok Tercapai!')),
                    );
                  }
                },
              ),
            ],
          ),
          Text('Stock: ${widget.jumlahSatuan}'),
        ],
      ),
    );
  }
}
