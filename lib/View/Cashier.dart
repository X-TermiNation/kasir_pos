import 'package:flutter/material.dart';

class Cashier extends StatefulWidget {
  const Cashier({super.key});

  @override
  State<Cashier> createState() => _CashierState();
}

class _CashierState extends State<Cashier> {
  static const int itemsPerPage = 9;
  int currentPage = 0;

  List<Item> _items = [
    Item(name: 'Item 1', price: 10.0),
    Item(name: 'Item 2', price: 20.0),
    Item(name: 'Item 3', price: 30.0),
    Item(name: 'Item 4', price: 40.0),
    Item(name: 'Item 5', price: 50.0),
    Item(name: 'Item 6', price: 60.0),
    Item(name: 'Item 7', price: 70.0),
    Item(name: 'Item 8', price: 80.0),
    Item(name: 'Item 9', price: 90.0),
    Item(name: 'Item 10', price: 100.0),
    Item(name: 'Item 11', price: 110.0),
    Item(name: 'Item 12', price: 120.0),
    Item(name: 'Item 13', price: 130.0),
    Item(name: 'Item 14', price: 140.0),
    Item(name: 'Item 15', price: 150.0),
    Item(name: 'Item 16', price: 160.0),
    Item(name: 'Item 17', price: 170.0),
    Item(name: 'Item 18', price: 180.0),
    Item(name: 'Item 10', price: 100.0),
    Item(name: 'Item 11', price: 110.0),
    Item(name: 'Item 12', price: 120.0),
    Item(name: 'Item 13', price: 130.0),
    Item(name: 'Item 14', price: 140.0),
    Item(name: 'Item 15', price: 150.0),
    Item(name: 'Item 16', price: 160.0),
    Item(name: 'Item 17', price: 170.0),
    Item(name: 'Item 18', price: 180.0),
    Item(name: 'Item 15', price: 150.0),
    Item(name: 'Item 16', price: 160.0),
    Item(name: 'Item 17', price: 170.0),
  ];

  List<CartItem> _cartItems = [];

  @override
  Widget build(BuildContext context) {
    int totalPages = (_items.length / itemsPerPage).ceil();
    List<Item> displayedItems =
        _items.skip(currentPage * itemsPerPage).take(itemsPerPage).toList();

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
                          onPressed: () {
                            setState(() {
                              CartItem? existingCartItem =
                                  _cartItems.firstWhere(
                                (cartItem) => cartItem.item.name == item.name,
                                orElse: () => CartItem(item: item, quantity: 0),
                              );
                              if (existingCartItem.quantity == 0) {
                                _cartItems
                                    .add(CartItem(item: item, quantity: 1));
                              } else {
                                existingCartItem.quantity += 1;
                              }
                            });
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
                          cartItem: _cartItems[index],
                          onQuantityChanged: (newQuantity) {
                            setState(() {
                              if (newQuantity <= 0) {
                                _cartItems.removeAt(index);
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
                            '\$${_cartItems.fold(0.0, (sum, item) => sum + item.item.price * item.quantity).toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                  // Total price
                  Container(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:'),
                        Text(
                            '\$${_cartItems.fold(0.0, (sum, item) => sum + item.item.price * item.quantity).toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Item {
  final String name;
  final double price;

  Item({required this.name, required this.price});
}

class CartItem {
  final Item item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});
}

class ItemCard extends StatelessWidget {
  final Item item;
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
              Text(item.name),
              Text('\$${item.price}'),
            ],
          ),
        ),
      ),
    );
  }
}

class CartItemRow extends StatelessWidget {
  final CartItem cartItem;
  final ValueChanged<int> onQuantityChanged;

  CartItemRow({required this.cartItem, required this.onQuantityChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(cartItem.item.name),
        QuantityWidget(
          quantity: cartItem.quantity,
          onQuantityChanged: onQuantityChanged,
        ),
        Text(
            '\$${(cartItem.item.price * cartItem.quantity).toStringAsFixed(2)}'),
      ],
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
        Text('$quantity'),
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
