import 'package:flutter/material.dart';

class Cashier extends StatefulWidget {
  const Cashier({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<Cashier> createState() => _CashierState();
}

class _CashierState extends State<Cashier> {
  final List<String> _items = [
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
    'Item 6',
    'Item 7',
    'Item 8',
    'Item 9',
    'Item 10',
    'Item 11',
    'Item 12',
    'Item 13',
    'Item 14',
    'Item 15',
    'Item 16',
    'Item 17',
    'Item 18',
    'Item 19',
    'Item 20',
    'Item 21',
    'Item 22',
    'Item 23',
    'Item 24',
    'Item 25',
  ];
  List<String> _cart = [];
  Map<String, int> _itemCounts = {};
  List<String> _searchResults = [];
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('POS Cashier'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                  _searchResults = _items
                      .where((item) => item.toLowerCase().contains(query.toLowerCase()))
                      .toList();
                });
              },
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GridView.count(
                    crossAxisCount: 4,
                    children: (_searchQuery.isEmpty? _items : _searchResults).map((item) {
                      return CardButton(
                        onPressed: () {
                          setState(() {
                            if (_cart.contains(item)) {
                              _itemCounts[item] = (_itemCounts[item]?? 0) + 1;
                            } else {
                              _cart.add(item);
                              _itemCounts[item] = 1;
                            }
                          });
                        },
                        child: Text(item),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_cart[index]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${_itemCounts[_cart[index]].toString()}x",style: TextStyle(fontSize: 15),),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  _itemCounts.remove(_cart[index]);
                                  _cart.remove(_cart[index]);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your submit logic here
          print('Submit button pressed');
        },
        tooltip: 'Submit',
        child: Text("Submit"),
      ),
    );
  }
}


class CardButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const CardButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: child,
        ),
      ),
    );
  }
}