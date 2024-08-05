// history_page.dart

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> transactions = [];
  int currentPage = 1;
  int transactionsPerPage = 6;
  String filterBy = 'trans_date';
  bool isAscending = true;

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
        sortTransactions();
      });
    } else {
      print("Failed to load data: ${response.statusCode}");
    }
  }

  void sortTransactions() {
    transactions.sort((a, b) {
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
  }

  void _showTransactionDetailDialog(
      BuildContext context, Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final List items = transaction['Items'];
        return AlertDialog(
          title: Text('Transaction Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction ID: ${transaction['_id']}'),
                Text('Date: ${transaction['trans_date']}'),
                Text('Payment Method: ${transaction['payment_method']}'),
                Text('Delivery: ${transaction['delivery'] ? "Yes" : "No"}'),
                Text('Description: ${transaction['desc'] ?? "N/A"}'),
                Text('Status: ${transaction['status']}'),
                SizedBox(height: 20),
                Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...items.map((item) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${item['nama_barang']}'),
                      Text('Satuan: ${item['id_satuan']}'),
                      Text('Satuan Price: ${item['satuan_price']}'),
                      Text('Quantity: ${item['trans_qty']}'),
                      Text('Discount: ${item['persentase_diskon'] ?? 0}%'),
                      Text('Total Price: ${item['total_price']}'),
                      Divider(),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (transactions.length / transactionsPerPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: filterBy,
                  items: [
                    DropdownMenuItem(
                      value: 'trans_date',
                      child: Text('Transaction Date'),
                    ),
                    DropdownMenuItem(
                      value: 'items_count',
                      child: Text('Items Count'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      filterBy = value!;
                      sortTransactions();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  onPressed: () {
                    setState(() {
                      isAscending = !isAscending;
                      sortTransactions();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount:
                  (currentPage * transactionsPerPage) > transactions.length
                      ? transactions.length -
                          ((currentPage - 1) * transactionsPerPage)
                      : transactionsPerPage,
              itemBuilder: (context, index) {
                final transactionIndex =
                    (currentPage - 1) * transactionsPerPage + index;
                final transaction = transactions[transactionIndex];
                final itemsCount = transaction['Items'].length;
                final DateTime transDate =
                    DateTime.parse(transaction['trans_date']);
                final String formattedDate =
                    DateFormat('dd/MM/yyyy').format(transDate);
                final String formattedTime =
                    DateFormat('HH:mm').format(transDate);
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text('Transaction ID: ${transaction['_id']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Items Count: $itemsCount'),
                        Text('Date: $formattedDate $formattedTime'),
                        Text('Status: ${transaction['status']}'),
                      ],
                    ),
                    onTap: () {
                      _showTransactionDetailDialog(context, transaction);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
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
        ],
      ),
    );
  }
}
