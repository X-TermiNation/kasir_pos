import 'package:flutter/material.dart';
import 'package:kasir_pos/View/Cashier.dart';
import 'package:kasir_pos/View/Login.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:kasir_pos/View/tools/custom_toast.dart';
import 'package:kasir_pos/View/tools/theme_mode.dart';
import 'package:kasir_pos/view-model-flutter/transaksi_controller.dart';
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
    try {
      final data = await getTrans();
      setState(() {
        transactions = data;
        filteredTransactions = transactions;
        sortTransactions(); // Sort the transactions after fetching
      });
    } catch (e) {
      print("Error fetching transactions: $e");
      CustomToast(message: "Error fetching transactions");
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
      if (query.isEmpty) {
        filteredTransactions =
            transactions; // Reset the filtered list when the query is empty
      } else {
        filteredTransactions = transactions.where((transaction) {
          final idMatch = transaction['_id']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());
          final dateMatch = DateFormat('dd-MM-yyyy')
              .format(DateTime.parse(transaction['trans_date']))
              .toLowerCase()
              .contains(query.toLowerCase());
          final paymentMethodMatch = transaction['payment_method']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());
          final deliveryMatch = (transaction['delivery'] ? 'yes' : 'no')
              .toLowerCase()
              .contains(query.toLowerCase());
          final grandTotalMatch = transaction['grand_total']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());
          final statusMatch = transaction['status']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());

          return idMatch ||
              dateMatch ||
              paymentMethodMatch ||
              deliveryMatch ||
              grandTotalMatch ||
              statusMatch;
        }).toList();
      }
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
                      ),
                      DataColumn(
                        label: Text('Delivery'),
                      ),
                      DataColumn(
                        label: Text('Grand Total'),
                      ),
                      DataColumn(
                        label: Text('Status'),
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
                            color: Theme.of(context)
                                .colorScheme
                                .surface, // Background color from theme
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight
                                            .bold), // TextStyle from theme
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Transaction ID: ${selectedTransaction!['_id']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge, // TextStyle from theme
                              ),
                              Text(
                                'Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(selectedTransaction!['trans_date']))}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge, // TextStyle from theme
                              ),
                              Text(
                                'Grand Total: \Rp.${NumberFormat('#,###.00', 'id_ID').format(selectedTransaction!['grand_total'] ?? 0.0)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge, // TextStyle from theme
                              ),
                              Text(
                                'Payment Method: ${selectedTransaction!['payment_method']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge, // TextStyle from theme
                              ),
                              Text(
                                'Delivery: ${selectedTransaction!['delivery'] ? "Yes" : "No"}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge, // TextStyle from theme
                              ),
                              Text(
                                'Description: ${selectedTransaction!['desc'] ?? "N/A"}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge, // TextStyle from theme
                              ),
                              Text(
                                'Status: ${selectedTransaction!['status']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge, // TextStyle from theme
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Items:',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ), // Bold text from theme
                              ),
                              ...selectedTransaction!['Items']
                                  .map<Widget>((item) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Name: ${item['nama_barang']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge, // TextStyle from theme
                                    ),
                                    Text(
                                      'Satuan: ${item['id_satuan']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge, // TextStyle from theme
                                    ),
                                    Text(
                                      'Satuan Price: ${item['satuan_price']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge, // TextStyle from theme
                                    ),
                                    Text(
                                      'Quantity: ${item['trans_qty']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge, // TextStyle from theme
                                    ),
                                    Text(
                                      'Discount: ${item['persentase_diskon'] ?? 0}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge, // TextStyle from theme
                                    ),
                                    Text(
                                      'Total Price: ${item['total_price']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge, // TextStyle from theme
                                    ),
                                    Divider(
                                      color: Theme.of(context)
                                          .dividerColor, // Divider color from theme
                                    ),
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary, // Button color from theme
                                ),
                                child: Text(
                                  'Clear',
                                  style: TextStyle(color: Colors.white),
                                ),
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
