import 'package:flutter/material.dart';
import '../models/tablemodel.dart';
import '../models/ordermodel.dart';
import '../services/apiservice.dart';
import 'additemsscreen.dart';

class OrderScreen extends StatefulWidget {
  final TableModel table;
  const OrderScreen({super.key, required this.table});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  OrderModel? _order;
  bool _loading = true;
  bool _updating = false;
  String? _error;
  String _selectedTable = '';

  static const _blue = Color(0xFF2563EB);
  static const _dark = Color(0xFF111827);
  static const _grey = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _selectedTable = 'T${widget.table.name}';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.getOrder(widget.table.id);
    if (!mounted) return;
    setState(() {
      _order = res.data;
      _error = res.ok ? null : res.error;
      _loading = false;
    });
  }

  Future<void> _updateStatus() async {
    if (_order == null) return;

    setState(() => _updating = true);

    try {
      // Loop through items to update those that are 'PLACED'
      for (var item in _order!.items) {
        if (item.status == 'PLACED') {
          await ApiService.updateItemStatus(
            _order!.id,
            item.id,
            'PREPARING',
            batchId: item.batchId,
          );
        }
      }

      // Refresh the data after updates
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Order status updated!'),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Column(children: [
        _buildHeader(),
        if (!_loading && _order != null) _buildTableSwitcher(),
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _blue))
                : _error != null
                    ? _buildErrorState()
                    : _order == null
                        ? _buildEmptyState()
                        : _buildBody()),
        if (!_loading && _order != null) _buildBottomBar(),
      ])),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
        child: Row(children: [
          GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: _dark))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Table ${widget.table.name}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _dark)),
                if (_order != null)
                  Row(children: [
                    Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                    Text('Preparing  •  ${_order!.items.length} Items',
                        style: const TextStyle(fontSize: 12, color: _grey)),
                  ])
                else if (!_loading)
                  Text(widget.table.isReserved ? 'Reserved' : 'Available',
                      style: const TextStyle(fontSize: 12, color: _grey)),
              ])),
          if (_order != null)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('IN PROGRESS',
                    style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5))),
        ]),
      );

  Widget _buildTableSwitcher() => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('SWITCH TABLE',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 1.0)),
            Icon(Icons.search_rounded, size: 18, color: Colors.grey.shade400),
          ]),
          const SizedBox(height: 10),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: List.generate(8, (i) {
                final id = 'T${i + 1}';
                final on = _selectedTable == id;
                return GestureDetector(
                    onTap: () => setState(() => _selectedTable = id),
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: on ? _blue : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: on ? _blue : const Color(0xFFE5E7EB),
                                width: 1.5),
                            boxShadow: on
                                ? [
                                    BoxShadow(
                                        color: _blue.withOpacity(0.3),
                                        blurRadius: 10)
                                  ]
                                : []),
                        child: Center(
                            child: Text(id,
                                style: TextStyle(
                                    color: on ? Colors.white : _dark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11)))));
              }))),
        ]),
      );

  Widget _buildBody() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _col(
                    'ORDER REFERENCE',
                    _order!.reference,
                    const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _dark)),
                _col(
                    'TOTAL',
                    '\$${_order!.total.toStringAsFixed(2)}',
                    const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _blue),
                    right: true),
              ]),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 5),
                Expanded(
                    child: Text(_order!.createdAt,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500))),
                Icon(Icons.people_outline_rounded,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 5),
                Text('${_order!.seats} Seats',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Order Items',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddItemsScreen(
                        tableName: widget.table.name,
                        bookingId: _order!.id))).then((_) => _load()),
            child: Container(
                height: 72,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _blue.withOpacity(0.25))),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                          color: _blue, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 18)),
                  const SizedBox(width: 10),
                  const Text('ADD ITEMS',
                      style: TextStyle(
                          color: _blue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ])),
          ),
          ..._order!.items.map(_buildItemRow),
        ]),
      );

  Widget _col(String label, String value, TextStyle style,
          {bool right = false}) =>
      Column(
          crossAxisAlignment:
              right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value, style: style),
          ]);

  Widget _buildItemRow(OrderItem item) {
    Color fg, bg;
    if (item.status == 'READY') {
      fg = const Color(0xFF16A34A);
      bg = const Color(0xFFF0FDF4);
    } else if (item.status == 'PREPARING') {
      fg = const Color(0xFFD97706);
      bg = const Color(0xFFFEF3C7);
    } else if (item.status == 'SERVED') {
      fg = const Color(0xFF6B7280);
      bg = const Color(0xFFF3F4F6);
    } else if (item.status == 'UNAVAILABLE') {
      fg = const Color(0xFFDC2626);
      bg = const Color(0xFFFEF2F2);
    } else {
      fg = const Color(0xFF2563EB);
      bg = const Color(0xFFEFF6FF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)
          ]),
      child: Row(children: [
        Text('${item.quantity}×',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _dark)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: _dark)),
          if (item.notes.isNotEmpty)
            Text(item.notes,
                style: const TextStyle(fontSize: 12, color: _grey)),
        ])),
        const SizedBox(width: 8),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(6)),
            child: Text(item.status,
                style: TextStyle(
                    color: fg, fontSize: 10, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _buildEmptyState() => Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long_outlined,
                  size: 34, color: Colors.grey.shade400)),
          const SizedBox(height: 16),
          Text(widget.table.isReserved ? 'Table Reserved' : 'No Active Order',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: _dark)),
          const SizedBox(height: 8),
          Text(
              widget.table.isReserved
                  ? 'Waiting for guests'
                  : 'Table is currently free',
              style: const TextStyle(fontSize: 13, color: _grey)),
          const SizedBox(height: 24),
          GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text('Back to Tables',
                      style: TextStyle(
                          color: _blue, fontWeight: FontWeight.w600)))),
        ],
      ));

  Widget _buildErrorState() => Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 48, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Color(0xFF6B7280), fontSize: 14))),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, foregroundColor: Colors.white),
              child: const Text('Retry')),
        ],
      ));

  Widget _buildBottomBar() => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
        child: Row(children: [
          Expanded(
              child: GestureDetector(
                  onTap: _updating ? null : _updateStatus,
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: _updating
                                  ? [
                                      const Color(0xFFD1D5DB),
                                      const Color(0xFFD1D5DB)
                                    ]
                                  : [
                                      const Color(0xFF2563EB),
                                      const Color(0xFF1D4ED8)
                                    ]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _updating
                              ? []
                              : [
                                  BoxShadow(
                                      color: _blue.withOpacity(0.3),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5))
                                ]),
                      child: Center(
                          child: _updating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      Icon(Icons.sync_rounded,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text('Update Status',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15))
                                    ]))))),
          const SizedBox(width: 10),
          Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.more_horiz_rounded, color: _dark)),
        ]),
      );
}
