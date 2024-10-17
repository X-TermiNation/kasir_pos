import 'package:flutter/material.dart';
import 'package:kasir_pos/View/Cashier.dart';
import 'package:kasir_pos/View/Login.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:kasir_pos/View/tools/custom_toast.dart';
import 'package:kasir_pos/View/tools/theme_mode.dart';
import 'package:kasir_pos/view-model-flutter/transaksi_controller.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  int currentPage = 1;
  int transactionsPerPage = 5;
  String filterBy = '';
  bool isAscending = true;
  String searchQuery = '';
  Map<String, dynamic>? selectedTransaction;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
    resetFilters();
  }

  Future<void> fetchTransactions() async {
    try {
      final data = await getTrans();
      setState(() {
        transactions = data;
        filteredTransactions = transactions;
      });
    } catch (e) {
      print("Error fetching transactions: $e");
      CustomToast(message: "Error fetching transactions");
    }
  }

  void resetFilters() {
    setState(() {
      filterBy = '';
      isAscending = true;
      filteredTransactions = List.from(transactions);
    });
  }

  void sortTransactions() {
    setState(() {
      filteredTransactions.sort((a, b) {
        if (filterBy == 'trans_date') {
          DateTime dateA = DateTime.parse(a['trans_date']);
          DateTime dateB = DateTime.parse(b['trans_date']);
          return isAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        } else if (filterBy == 'payment_method') {
          String methodA = a['payment_method'];
          String methodB = b['payment_method'];
          return isAscending
              ? methodA.compareTo(methodB)
              : methodB.compareTo(methodA);
        } else if (filterBy == 'delivery') {
          bool deliveryA = a['delivery'] == true;
          bool deliveryB = b['delivery'] == true;
          int valueA = deliveryA ? 1 : 0;
          int valueB = deliveryB ? 1 : 0;
          return isAscending
              ? valueA.compareTo(valueB)
              : valueB.compareTo(valueA);
        } else if (filterBy == 'grand_total') {
          double totalA = a['grand_total'] != null
              ? double.parse(a['grand_total'].toString())
              : 0.0;
          double totalB = b['grand_total'] != null
              ? double.parse(b['grand_total'].toString())
              : 0.0;
          return isAscending
              ? totalA.compareTo(totalB)
              : totalB.compareTo(totalA);
        } else if (filterBy == 'status') {
          String statusA = a['status'] ?? '';
          String statusB = b['status'] ?? '';
          return isAscending
              ? statusA.compareTo(statusB)
              : statusB.compareTo(statusA);
        } else if (filterBy == 'item_amount') {
          int totalItemsA = a['Items'] != null ? a['Items'].length : 0;
          int totalItemsB = b['Items'] != null ? b['Items'].length : 0;
          return isAscending
              ? totalItemsA.compareTo(totalItemsB)
              : totalItemsB.compareTo(totalItemsA);
        }
        return 0;
      });
    });
  }

  void _filterTransactions(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredTransactions = transactions;
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

    if (transactions.isEmpty) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
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
                    height: 100,
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: DataTable(
                          sortColumnIndex: filterBy == 'trans_date'
                              ? 1
                              : filterBy == 'payment_method'
                                  ? 2
                                  : filterBy == 'delivery'
                                      ? 3
                                      : filterBy == 'grand_total'
                                          ? 4
                                          : filterBy == 'status'
                                              ? 5
                                              : filterBy == 'item_amount'
                                                  ? 6
                                                  : 0,
                          sortAscending: isAscending,
                          columns: [
                            DataColumn(
                              label: Text('Transaction ID'),
                              onSort: (index, ascending) {
                                setState(() {
                                  filterBy = '';
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
                              label: Text('Item Count'),
                              onSort: (index, ascending) {
                                setState(() {
                                  filterBy = 'item_amount';
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
                            //change the time display in history here
                            tz.initializeTimeZones();

                            String formatTransactionDate(String utcDateString) {
                              DateTime utcDate = DateTime.parse(utcDateString);

                              // change the location here
                              final zone = tz.getLocation('Asia/Jakarta');

                              tz.TZDateTime timezoneDate =
                                  tz.TZDateTime.from(utcDate, zone);

                              // Format the date using intl package
                              return DateFormat('EEEE, dd-MM-yyyy HH:mm')
                                  .format(timezoneDate);
                            }

                            return DataRow(cells: [
                              DataCell(Text(transaction['_id'])),
                              DataCell(
                                Text(formatTransactionDate(
                                    transaction['trans_date'])),
                              ),
                              DataCell(Text(transaction['payment_method'])),
                              DataCell(
                                  Text(transaction['delivery'] ? 'Yes' : 'No')),
                              DataCell(Text(
                                  '\Rp.${NumberFormat('#,###.00', 'id_ID').format(transaction['grand_total'] ?? 0.0)}')),
                              DataCell(Text(transaction['status'])),
                              DataCell(
                                  Text('${transaction['Items'].length} Items')),
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
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Transaction ID: ${selectedTransaction!['_id']}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                Text(
                                  'Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(selectedTransaction!['trans_date']))}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                Text(
                                  'Grand Total: \Rp.${NumberFormat('#,###.00', 'id_ID').format(selectedTransaction!['grand_total'] ?? 0.0)}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                Text(
                                  'Payment Method: ${selectedTransaction!['payment_method']}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                Text(
                                  'Delivery: ${selectedTransaction!['delivery'] ? "Yes" : "No"}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                Text(
                                  'Description: ${selectedTransaction!['desc'] ?? "N/A"}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                Text(
                                  'Status: ${selectedTransaction!['status']}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Items:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                ...selectedTransaction!['Items']
                                    .map<Widget>((item) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Name: ${item['nama_barang']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      Text(
                                        'Satuan: ${item['id_satuan']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      Text(
                                        'Satuan Price: ${item['satuan_price']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      Text(
                                        'Quantity: ${item['trans_qty']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      Text(
                                        'Discount: ${item['persentase_diskon'] ?? 0}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      Text(
                                        'Total Price: ${item['total_price']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      Divider(
                                        color: Theme.of(context).dividerColor,
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
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
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
