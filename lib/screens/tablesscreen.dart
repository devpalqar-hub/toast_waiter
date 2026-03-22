import 'package:flutter/material.dart';
import '../models/tablemodel.dart';
import '../services/apiservice.dart';
import '../widgets/tablecard.dart';
import 'loginscreen.dart';
import 'orderscreen.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  List<TableModel> _tables = [];
  String _filter = 'all';
  bool _loading = true;
  String? _error;

  static const _blue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await ApiService.getTables();

    if (!mounted) return;

    if (res.error == 'Session expired. Please log in again.') {
      await ApiService.clearToken();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    setState(() {
      _tables = res.data ?? [];
      _error = res.error;
      _loading = false;
    });
  }

  List<TableModel> get _filtered {
    switch (_filter) {
      case 'available':
        return _tables.where((t) => t.isAvailable).toList();
      case 'occupied':
        return _tables.where((t) => t.isOccupied).toList();
      default:
        return _tables;
    }
  }

  int get _availableCount => _tables.where((t) => t.isAvailable).length;
  int get _occupiedCount => _tables.where((t) => t.isOccupied).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
          child: Column(children: [
        _buildHeader(),
        _buildFilterTabs(),
        Expanded(child: _buildBody()),
      ])),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        backgroundColor: _blue,
        elevation: 3,
        child: const Icon(Icons.refresh_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The Bistro',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3)),
              Text(
                _loading
                    ? 'Loading tables…'
                    : _error != null
                        ? _error!
                        : '${_tables.length} tables  ·  $_availableCount available',
                style: TextStyle(
                    fontSize: 13,
                    color: _error != null
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF6B7280)),
              ),
            ],
          )),
          GestureDetector(
            onTap: _confirmLogout,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: _blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ]),
      );

  Widget _buildFilterTabs() {
    final tabs = [
      ['all', 'All (${_tables.length})'],
      ['available', 'Available ($_availableCount)'],
      ['occupied', 'Occupied ($_occupiedCount)'],
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
          children: tabs.map((tab) {
        final on = _filter == tab[0];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _filter = tab[0]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: on ? _blue : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: on
                        ? _blue.withOpacity(0.25)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: on ? 12 : 6,
                  )
                ],
              ),
              child: Text(tab[1],
                  style: TextStyle(
                      color: on ? Colors.white : const Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
            ),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    if (_error != null) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 52, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _blue, foregroundColor: Colors.white),
          ),
        ],
      ));
    }
    if (_filtered.isEmpty) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_restaurant_rounded,
              size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(_tables.isEmpty ? 'No tables found' : 'No $_filter tables',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        ],
      ));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _blue,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => TableCard(
          table: _filtered[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderScreen(table: _filtered[i])),
          ).then((_) => _load()),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Shift',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Log out and end your shift?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.clearToken();
              if (mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
