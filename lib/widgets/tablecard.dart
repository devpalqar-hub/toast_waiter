import 'package:flutter/material.dart';
import '../models/tablemodel.dart';

class TableCard extends StatelessWidget {
  final TableModel  table;
  final VoidCallback onTap;

  const TableCard({super.key, required this.table, required this.onTap});

  Color  get _color => switch (table.status) {
    'occupied' => const Color(0xFFEF4444),
    'reserved' => const Color(0xFFF59E0B),
    _          => const Color(0xFF22C55E),
  };

  Color  get _bg => switch (table.status) {
    'occupied' => const Color(0xFFFEF2F2),
    'reserved' => const Color(0xFFFEF3C7),
    _          => const Color(0xFFF0FDF4),
  };

  String get _label => switch (table.status) {
    'occupied' => 'Occupied',
    'reserved' => 'Reserved',
    _          => 'Available',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: table.isOccupied ? _color.withOpacity(0.3) : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Table number + seats
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('T${table.name}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
            Row(children: [
              Icon(Icons.people_outline_rounded, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 3),
              Text('${table.seats}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
            ]),
          ]),

          // Item preview for occupied tables
          if (table.isOccupied && table.items.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(table.items.take(3).join('\n'),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.5),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
            )
          else
            const Spacer(),

          const SizedBox(height: 10),

          // Status chip
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
              child: Text(_label,
                  style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            if (table.isOccupied)
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF2563EB)),
              ),
          ]),
        ]),
      ),
    );
  }
}