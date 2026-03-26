import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  List<SessionModel> _sessions = [];
  SessionModel? _selected;
  OrderModel? _detail;
  bool _loadingSessions = true;
  bool _loadingDetail = false;
  String? _error;

  static const _blue = Color(0xFF2563EB);
  static const _dark = Color(0xFF111827);
  static const _grey = Color(0xFF6B7280);
  static const _green = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loadingSessions = true;
      _error = null;
    });
    final res = await ApiService.getSessions(widget.table.id);
    if (!mounted) return;
    setState(() {
      _sessions = res.data ?? [];
      _error = res.error;
      _loadingSessions = false;
    });
    // Auto-select first OPEN session
    if (_sessions.isNotEmpty) {
      final open = _sessions.where((s) => s.isOpen).toList();
      _selectSession(open.isNotEmpty ? open.first : _sessions.first);
    }
  }

  Future<void> _selectSession(SessionModel s) async {
    setState(() {
      _selected = s;
      _loadingDetail = true;
      _detail = null;
    });
    final res = await ApiService.getSessionDetail(s.id);
    if (!mounted) return;
    setState(() {
      _detail = res.data;
      _loadingDetail = false;
    });
  }

  Future<void> _createSession() async {
    // Show dialog to get guest count
    final count = await showDialog<int>(
      context: context,
      builder: (_) => _NewSessionDialog(tableName: widget.table.name),
    );
    if (count == null) return;

    setState(() => _loadingSessions = true);
    final res = await ApiService.createSession(
        tableId: widget.table.id, guestCount: count);
    if (!mounted) return;
    if (res.ok && res.data != null) {
      await _loadSessions();
      // Select the new session
      final newS = _sessions.where((s) => s.id == res.data!.id).toList();
      if (newS.isNotEmpty) _selectSession(newS.first);
    } else {
      setState(() {
        _loadingSessions = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.error ?? 'Failed to create session'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
          child: Column(children: [
        _buildHeader(),
        _buildSessionsSection(),
        if (_selected != null) _buildSummaryCard(),
        Expanded(
            child: _loadingDetail
                ? const Center(child: CircularProgressIndicator(color: _blue))
                : _detail == null
                    ? _buildNoItems()
                    : _buildItemsList()),
        if (_selected != null && (_selected!.isOpen)) _buildBottomBar(),
      ])),
    );
  }

  Widget _buildHeader() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                if (_selected != null)
                  Row(children: [
                    Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                            color: _selected!.isOpen
                                ? const Color(0xFFF59E0B)
                                : _green,
                            shape: BoxShape.circle)),
                    Text(_selected!.isOpen ? 'In Progress' : 'Billed',
                        style: const TextStyle(fontSize: 12, color: _grey)),
                  ]),
              ])),
          if (_selected != null)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: _selected!.isOpen
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_selected!.isOpen ? 'IN PROGRESS' : 'BILLED',
                    style: TextStyle(
                        color: _selected!.isOpen
                            ? const Color(0xFFD97706)
                            : _green,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5))),
        ]),
      );

  Widget _buildSessionsSection() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Sessions',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
            GestureDetector(
              onTap: _createSession,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: _blue, borderRadius: BorderRadius.circular(20)),
                child: const Row(children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('New Session',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (_loadingSessions)
            const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator(color: _blue)))
          else if (_sessions.isEmpty)
            Container(
                height: 80,
                alignment: Alignment.center,
                child: const Text('No sessions yet. Create one!',
                    style: TextStyle(color: _grey, fontSize: 14)))
          else
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _sessions.length,
                itemBuilder: (_, i) => _buildSessionCard(_sessions[i]),
              ),
            ),
        ]),
      );

  Widget _buildSessionCard(SessionModel s) {
    final isSelected = _selected?.id == s.id;
    Color statusColor = s.isOpen ? const Color(0xFFF59E0B) : _green;
    Color cardBorder = isSelected ? _blue : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: () => _selectSession(s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 150,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder, width: isSelected ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: isSelected
                        ? _blue.withOpacity(0.15)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.receipt_rounded,
                    size: 16, color: isSelected ? _blue : _grey)),
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle)),
          ]),
          const SizedBox(height: 8),
          Text(s.sessionNumber,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? _blue : _dark)),
          const SizedBox(height: 2),
          Text(_formatTime(s.createdAt),
              style: const TextStyle(fontSize: 10, color: _grey)),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${s.batchCount} batch${s.batchCount != 1 ? 'es' : ''}',
                style: const TextStyle(fontSize: 10, color: _grey)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: s.isOpen
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(s.status,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: s.isOpen ? const Color(0xFFD97706) : _green)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final s = _selected!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ORDER REFERENCE',
              style: TextStyle(
                  fontSize: 10,
                  color: _grey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(s.sessionNumber,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('TOTAL',
              style: TextStyle(
                  fontSize: 10,
                  color: _grey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text('\$${s.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _blue)),
        ]),
      ]),
    );
  }

  Widget _buildItemsList() {
    final items = _detail!.items;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        const Text('Order Items',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
        const SizedBox(height: 10),
        if (_selected!.isOpen) _buildAddItemsButton(),
        if (items.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB))),
            child: const Center(
                child: Text('No items yet. Add some!',
                    style: TextStyle(color: _grey))),
          )
        else
          ...items.map(_buildItemRow),
      ],
    );
  }

  Future<void> _updateItemStatus(OrderItem item, String newStatus) async {
    final res = await ApiService.updateItemStatus(
        _detail!.id, item.batchId, item.id, newStatus);
    if (!mounted) return;
    if (res) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${item.name} → $newStatus'),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
      _selectSession(_selected!); // refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to update status'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showStatusPicker(OrderItem item) {
    // Only allow forward status progression
    final allStatuses = ['PENDING', 'PREPARING', 'READY', 'SERVED'];
    final currentIdx = allStatuses.indexOf(item.status);
    final available =
        allStatuses.where((s) => allStatuses.indexOf(s) > currentIdx).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Item already served'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827))),
                  Text('Current: ${item.status}',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280))),
                ])),
          ]),
          const SizedBox(height: 16),
          const Text('Update status to:',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          ...available.map((status) {
            final colors = _statusColor(status);
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _updateItemStatus(item, status);
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colors[1],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors[0].withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(_statusIcon(status), color: colors[0], size: 20),
                  const SizedBox(width: 12),
                  Text(status,
                      style: TextStyle(
                          color: colors[0],
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: colors[0], size: 14),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }

  List<Color> _statusColor(String s) {
    if (s == 'PREPARING')
      return [const Color(0xFFD97706), const Color(0xFFFEF3C7)];
    if (s == 'READY') return [const Color(0xFF16A34A), const Color(0xFFF0FDF4)];
    if (s == 'SERVED')
      return [const Color(0xFF2563EB), const Color(0xFFEFF6FF)];
    if (s == 'CANCELLED')
      return [const Color(0xFFDC2626), const Color(0xFFFEF2F2)];
    return [const Color(0xFF7C3AED), const Color(0xFFF5F3FF)];
  }

  IconData _statusIcon(String s) {
    if (s == 'PREPARING') return Icons.local_fire_department_rounded;
    if (s == 'READY') return Icons.check_circle_rounded;
    if (s == 'SERVED') return Icons.restaurant_rounded;
    if (s == 'CANCELLED') return Icons.cancel_rounded;
    return Icons.pending_rounded;
  }

  Widget _buildItemRow(OrderItem item) {
    Color fg, bg;
    if (item.status == 'READY') {
      fg = _green;
      bg = const Color(0xFFF0FDF4);
    } else if (item.status == 'PREPARING') {
      fg = const Color(0xFFD97706);
      bg = const Color(0xFFFEF3C7);
    } else if (item.status == 'SERVED') {
      fg = _grey;
      bg = const Color(0xFFF3F4F6);
    } else if (item.status == 'CANCELLED') {
      fg = const Color(0xFFDC2626);
      bg = const Color(0xFFFEF2F2);
    } else {
      fg = const Color(0xFF7C3AED);
      bg = const Color(0xFFF5F3FF);
    }

    final canUpdate = _selected!.isOpen &&
        item.status != 'SERVED' &&
        item.status != 'CANCELLED';

    return GestureDetector(
      onTap: canUpdate ? () => _showStatusPicker(item) : null,
      child: Container(
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
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dark)),
                if (item.notes.isNotEmpty)
                  Text(item.notes,
                      style: const TextStyle(fontSize: 11, color: _grey)),
                if (item.unitPrice > 0)
                  Text('\$${item.unitPrice.toStringAsFixed(2)} each',
                      style: const TextStyle(fontSize: 11, color: _grey)),
              ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(6)),
            child: Text(item.status,
                style: TextStyle(
                    color: fg, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          if (canUpdate) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 18),
          ],
        ]),
      ),
    );
  }

  Widget _buildNoItems() => Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long_outlined,
                  size: 32, color: Colors.grey.shade400)),
          const SizedBox(height: 12),
          const Text('Select or create a session',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
          const SizedBox(height: 8),
          const Text('Tap a session card above to view items',
              style: TextStyle(fontSize: 13, color: _grey)),
        ],
      ));

  Widget _buildBottomBar() => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        color: Colors.white,
        child: GestureDetector(
          onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddItemsScreen(
                          tableName: widget.table.name,
                          bookingId: _selected!.id)))
              .then((_) => _selectSession(_selected!)),
          child: Container(
            height: 52,
            width: double.infinity,
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
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Add Items to Session',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ]),
          ),
        ),
      );

  Widget _buildAddItemsButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddItemsScreen(
            tableName: widget.table.name,
            bookingId: _selected!.id,
          ),
        ),
      ).then((_) => _selectSession(_selected!)),
      child: Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _blue.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'ADD ITEMS',
              style: TextStyle(
                color: _blue,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m · ${dt.day}/${dt.month}';
    } catch (_) {
      return iso.length > 10 ? iso.substring(11, 16) : iso;
    }
  }
}

// ── New Session Dialog ─────────────────────────────────────────────────────────
class _NewSessionDialog extends StatefulWidget {
  final String tableName;
  const _NewSessionDialog({required this.tableName});
  @override
  State<_NewSessionDialog> createState() => _NewSessionDialogState();
}

class _NewSessionDialogState extends State<_NewSessionDialog> {
  int _guests = 2;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('New Session — Table ${widget.tableName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('How many guests?',
            style: TextStyle(color: Color(0xFF6B7280))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            onPressed: () {
              if (_guests > 1) setState(() => _guests--);
            },
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 8),
          Text('$_guests',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827))),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _guests++),
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: const Color(0xFF2563EB),
          ),
        ]),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _guests),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          child: const Text('Open Session'),
        ),
      ],
    );
  }
}
