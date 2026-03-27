import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/menuitem.dart';
import '../services/apiservice.dart';

class AddItemsScreen extends StatefulWidget {
  final String tableName;
  final String bookingId; // sessionId

  const AddItemsScreen({
    super.key,
    required this.tableName,
    required this.bookingId,
  });

  @override
  State<AddItemsScreen> createState() => _AddItemsScreenState();
}

class _AddItemsScreenState extends State<AddItemsScreen> {
  List<MenuItem> _menu = [];
  final Map<String, CartItem> _cart = {};
  String _category = 'All';
  String _search = '';
  bool _loading = true;
  bool _sending = false;
  String? _error;

  static const _blue = Color(0xFF2563EB);
  static const _dark = Color(0xFF111827);
  static const _grey = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.getMenuItems();
    if (!mounted) return;
    setState(() {
      _menu = res.data ?? [];
      _error = res.error;
      _loading = false;
    });
  }

  List<String> get _categories {
    final cats = _menu.map((m) => m.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  List<MenuItem> get _filtered => _menu.where((m) {
        final matchCat = _category == 'All' || m.category == _category;
        final matchSearch = _search.isEmpty ||
            m.name.toLowerCase().contains(_search.toLowerCase()) ||
            m.description.toLowerCase().contains(_search.toLowerCase());
        return matchCat && matchSearch;
      }).toList();

  int get _cartCount => _cart.values.fold(0, (s, c) => s + c.quantity);
  double get _cartTotal => _cart.values.fold(0.0, (s, c) => s + c.subtotal);

  void _add(MenuItem item) => setState(() {
        if (_cart.containsKey(item.id))
          _cart[item.id]!.quantity++;
        else
          _cart[item.id] = CartItem(item);
      });

  void _remove(MenuItem item) => setState(() {
        if (!_cart.containsKey(item.id)) return;
        if (_cart[item.id]!.quantity > 1)
          _cart[item.id]!.quantity--;
        else
          _cart.remove(item.id);
      });

  Future<void> _sendToKitchen() async {
    if (_cart.isEmpty) return;
    setState(() => _sending = true);
    final items = _cart.entries
        .map((e) => <String, dynamic>{
              'menuItemId': e.key,
              'quantity': e.value.quantity,
            })
        .toList();
    final ok = await ApiService.addBatchToSession(widget.bookingId, items);
    setState(() => _sending = false);
    if (!mounted) return;
    Fluttertoast.showToast(
      msg: ok ? 'Sent to kitchen! 🍳' : 'Failed. Try again.',
      backgroundColor: ok ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
      toastLength: Toast.LENGTH_SHORT,
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Column(children: [
        _buildHeader(),
        _buildSearchBar(),
        _buildCategoryTabs(),
        Expanded(child: _buildBody()),
        if (_cart.isNotEmpty) _buildCartBar(),
      ])),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
        child: Row(children: [
          GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 15, color: _dark))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Table ${widget.tableName}',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _dark)),
                const Text('NEW BATCH',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _blue,
                        letterSpacing: 0.5)),
              ])),
          const Icon(Icons.more_vert_rounded,
              color: Colors.transparent), // hidden
        ]),
      );

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          onChanged: (v) => setState(() => _search = v),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Quick search...',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded,
                color: Color(0xFF9CA3AF), size: 20),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _blue, width: 1.5)),
          ),
        ),
      );

  Widget _buildCategoryTabs() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(
            children: _categories.map((cat) {
          final on = _category == cat;
          return GestureDetector(
            onTap: () => setState(() => _category = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: on ? _blue : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(cat,
                  style: TextStyle(
                      color: on ? Colors.white : _grey,
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
            ),
          );
        }).toList()),
      );

  Widget _buildBody() {
    if (_loading)
      return const Center(child: CircularProgressIndicator(color: _blue));
    if (_error != null)
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 48, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: _grey, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _loadMenu,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, foregroundColor: Colors.white),
              child: const Text('Retry')),
        ],
      ));
    if (_filtered.isEmpty)
      return const Center(
          child: Text('No items found',
              style: TextStyle(color: _grey, fontSize: 15)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _buildMenuRow(_filtered[i]),
    );
  }

  Widget _buildMenuRow(MenuItem item) {
    final inCart = _cart[item.id];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)
          ]),
      child: Row(children: [
        // Item image
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFF3F4F6)),
          child: item.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.restaurant_rounded,
                          color: Color(0xFF9CA3AF),
                          size: 24)))
              : const Icon(Icons.restaurant_rounded,
                  color: Color(0xFF9CA3AF), size: 24),
        ),
        const SizedBox(width: 12),
        // Name + description
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: _dark)),
          if (item.description.isNotEmpty)
            Text(item.description,
                style: const TextStyle(fontSize: 12, color: _grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          if (item.price > 0)
            Text('\$${item.price.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 12, color: _blue, fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(width: 8),
        // Qty controls
        if (inCart == null)
          GestureDetector(
              onTap: () => _add(item),
              child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: _blue, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 20)))
        else
          Row(children: [
            GestureDetector(
                onTap: () => _remove(item),
                child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        border: Border.all(color: _blue),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.remove_rounded,
                        color: _blue, size: 16))),
            SizedBox(
                width: 34,
                child: Center(
                    child: Text('${inCart.quantity}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _dark)))),
            GestureDetector(
                onTap: () => _add(item),
                child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: _blue, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 16))),
          ]),
      ]),
    );
  }

  Widget _buildCartBar() => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.shopping_basket_outlined, color: _blue, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Current Batch',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _dark)),
                  Text(
                      '$_cartCount item${_cartCount > 1 ? 's' : ''}  •  total \$${_cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: _grey)),
                ])),
            GestureDetector(
                onTap: _showCartSheet,
                child: const Text('View Details',
                    style: TextStyle(
                        fontSize: 13,
                        color: _blue,
                        fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
              onTap: _sending ? null : _sendToKitchen,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _blue.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Center(
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Text('Send to Kitchen',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                SizedBox(width: 8),
                                Text('🍳', style: TextStyle(fontSize: 16)),
                              ])),
              )),
        ]),
      );

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const Text('Current Batch',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _dark)),
            const SizedBox(height: 16),
            ..._cart.values.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(c.item.name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _dark)),
                          Text(
                              '\$${c.item.price.toStringAsFixed(2)} × ${c.quantity}',
                              style:
                                  const TextStyle(fontSize: 12, color: _grey)),
                        ])),
                    Text('\$${c.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _dark)),
                    const SizedBox(width: 12),
                    GestureDetector(
                        onTap: () {
                          setState(() => _cart.remove(c.item.id));
                          setS(() {});
                          if (_cart.isEmpty) Navigator.pop(ctx);
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: _grey)),
                  ]),
                )),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15, color: _dark)),
              Text('\$${_cartTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15, color: _blue)),
            ]),
          ]),
        ),
      ),
    );
  }
}
