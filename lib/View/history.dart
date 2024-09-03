import 'package:flutter/material.dart';
import 'package:kasir_pos/View/Cashier.dart';
import 'package:kasir_pos/View/Login.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kasir_pos/View/tools/theme_mode.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  int currentPage = 1;
  int transactionsPerPage = 5;
  String filterBy = 'trans_date';
  bool isAscending = true;
  String searchQuery = '';
  Map<String, dynamic>? selectedTransaction;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    final dataStorage = GetStorage();
    String id_cabang = dataStorage.read('id_cabang');
    final request =
        Uri.parse('http://10.0.2.2:3001/transaksi/translist/$id_cabang');
    final response = await http.get(request);
    if (response.statusCode == 200 || response.statusCode == 304) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      List<dynamic> data = jsonData["data"];
      setState(() {
        transactions = data.cast<Map<String, dynamic>>();
        filteredTransactions = transactions;
        sortTransactions();
      });
    } else {
      print("Failed to load data: ${response.statusCode}");
    }
  }

  void sortTransactions() {
    setState(() {
      filteredTransactions.sort((a, b) {
        if (filterBy == 'trans_date') {
          DateTime dateA = DateTime.parse(a['trans_date']);
          DateTime dateB = DateTime.parse(b['trans_date']);
          return isAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        } else if (filterBy == 'items_count') {
          int itemsA = a['Items'].length;
          int itemsB = b['Items'].length;
          return isAscending
              ? itemsA.compareTo(itemsB)
              : itemsB.compareTo(itemsA);
        }
        return 0;
      });
    });
  }

  void _filterTransactions(String query) {
    setState(() {
      filteredTransactions = transactions.where((transaction) {
        return transaction.values
            .any((value) => value.toString().toLowerCase().contains(query));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPages =
        (filteredTransactions.length / transactionsPerPage).ceil();
    final currentTransactions = filteredTransactions
        .skip((currentPage - 1) * transactionsPerPage)
        .take(transactionsPerPage)
        .toList();

    return MaterialApp(
      theme: Provider.of<ThemeManager>(context).getTheme(),
      home: Scaffold(
          appBar: AppBar(
            title: Text('Transaction History'),
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
                  onTap: () {
                    setState(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Cashier(),
                        ),
                      );
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Transaction History'),
                  onTap: () {},
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
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Log Out'),
                  onTap: () {
                    showLogoutConfirmationDialog(context);
                  },
                ),
              ],
            ),
          ),
          body: Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      _filterTransactions(value);
                    },
                  ),
                ),
                Expanded(
                  child: DataTable(
                    sortColumnIndex: filterBy == 'trans_date' ? 1 : 2,
                    sortAscending: isAscending,
                    columns: [
                      DataColumn(
                        label: Text('Transaction ID'),
                        onSort: (index, ascending) {
                          setState(() {
                            filterBy = '_id';
                            isAscending = ascending;
                            sortTransactions();
                          });
                        },
                      ),
                      DataColumn(
                        label: Text('Transaction Date'),
                        onSort: (index, ascending) {
                          setState(() {
                            filterBy = 'trans_date';
                            isAscending = ascending;
                            sortTransactions();
                          });
                        },
                      ),
                      DataColumn(
                        label: Text('Payment Method'),
                        onSort: (index, ascending) {
                          setState(() {
                            filterBy = 'payment_method';
                            isAscending = ascending;
                            sortTransactions();
                          });
                        },
                      ),
                      DataColumn(
                        label: Text('Delivery'),
                        onSort: (index, ascending) {
                          setState(() {
                            filterBy = 'delivery';
                            isAscending = ascending;
                            sortTransactions();
                          });
                        },
                      ),
                      DataColumn(
                        label: Text('Grand Total'),
                        onSort: (index, ascending) {
                          setState(() {
                            filterBy = 'grand_total';
                            isAscending = ascending;
                            sortTransactions();
                          });
                        },
                      ),
                      DataColumn(
                        label: Text('Status'),
                        onSort: (index, ascending) {
                          setState(() {
                            filterBy = 'status';
                            isAscending = ascending;
                            sortTransactions();
                          });
                        },
                      ),
                      DataColumn(
                        label: Text('Action'),
                      ),
                    ],
                    rows: currentTransactions.map((transaction) {
                      return DataRow(cells: [
                        DataCell(Text(transaction['_id'])),
                        DataCell(
                          Text(DateFormat('dd-MM-yyyy').format(
                              DateTime.parse(transaction['trans_date']))),
                        ),
                        DataCell(Text(transaction['payment_method'])),
                        DataCell(Text(transaction['delivery'] ? 'Yes' : 'No')),
                        DataCell(Text(
                            '\Rp.${NumberFormat('#,###.00', 'id_ID').format(transaction['grand_total'] ?? 0.0)}')),
                        DataCell(Text(transaction['status'])),
                        DataCell(ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[400]),
                          onPressed: () {
                            setState(() {
                              selectedTransaction = transaction;
                            });
                          },
                          child: Text('Detail',
                              style: TextStyle(color: Colors.white)),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: currentPage > 1
                            ? () {
                                setState(() {
                                  currentPage--;
                                });
                              }
                            : null,
                        child: Text('Previous'),
                      ),
                      Text('Page $currentPage of $totalPages'),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: currentPage < totalPages
                            ? () {
                                setState(() {
                                  currentPage++;
                                });
                              }
                            : null,
                        child: Text('Next'),
                      ),
                    ],
                  ),
                ),
                if (selectedTransaction != null)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transaction Details',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              Text(
                                  'Transaction ID: ${selectedTransaction!['_id']}'),
                              Text(
                                  'Date: ${selectedTransaction!['trans_date']}'),
                              Text(
                                  'Payment Method: ${selectedTransaction!['payment_method']}'),
                              Text(
                                  'Delivery: ${selectedTransaction!['delivery'] ? "Yes" : "No"}'),
                              Text(
                                  'Description: ${selectedTransaction!['desc'] ?? "N/A"}'),
                              Text('Status: ${selectedTransaction!['status']}'),
                              SizedBox(height: 20),
                              Text('Items:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              ...selectedTransaction!['Items']
                                  .map<Widget>((item) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Name: ${item['nama_barang']}'),
                                    Text('Satuan: ${item['id_satuan']}'),
                                    Text(
                                        'Satuan Price: ${item['satuan_price']}'),
                                    Text('Quantity: ${item['trans_qty']}'),
                                    Text(
                                        'Discount: ${item['persentase_diskon'] ?? 0}%'),
                                    Text('Total Price: ${item['total_price']}'),
                                    Divider(),
                                  ],
                                );
                              }).toList(),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedTransaction = null;
                                  });
                                },
                                child: Text('Clear'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )),
    );
  }
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
