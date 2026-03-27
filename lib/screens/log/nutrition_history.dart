import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/nutrition_log.dart';
import '../../../widgets/onboarding_widgets.dart';

class NutritionHistoryList extends StatefulWidget {
  final List<MealLog>         logs;
  final void Function(String) onDelete;

  const NutritionHistoryList({
    super.key,
    required this.logs,
    required this.onDelete,
  });

  @override
  State<NutritionHistoryList> createState() => _NutritionHistoryListState();
}

class _NutritionHistoryListState extends State<NutritionHistoryList> {
  int _expanded = -1;

  // Totals
  ({int kcal, int protein, int carbs, int fat}) _todayTotals() {
    final today = DateTime.now();
    final todayLogs = widget.logs.where((l) =>
    l.createdAt.year  == today.year  &&
        l.createdAt.month == today.month &&
        l.createdAt.day   == today.day).toList();
    return (
    kcal:    todayLogs.fold(0, (s, l) => s + l.totalKcal.round()),
    protein: todayLogs.fold(0, (s, l) => s + l.totalProtein.round()),
    carbs:   todayLogs.fold(0, (s, l) => s + l.totalCarbs.round()),
    fat:     todayLogs.fold(0, (s, l) => s + l.totalFat.round()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = _todayTotals();
    return CustomScrollView(
      slivers: [
        // Totals bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _TodayTotalsCard(totals: totals),
          ),
        ),
        // Meal cards
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MealCard(
                  log:      widget.logs[i],
                  expanded: _expanded == i,
                  onToggle: () => setState(() =>
                  _expanded = _expanded == i ? -1 : i),
                  onDelete: () => widget.onDelete(widget.logs[i].id!),
                ),
              ),
              childCount: widget.logs.length,
            ),
          ),
        ),
      ],
    );
  }
}

// Today totals
class _TodayTotalsCard extends StatelessWidget {
  final ({int kcal, int protein, int carbs, int fat}) totals;
  const _TodayTotalsCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : const Color(0xFFF5FFF5),
        border: Border.all(color: kNeon, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat('${totals.kcal}',     'kcal today'),
          _Stat('${totals.protein}g', 'Protein'),
          _Stat('${totals.carbs}g',   'Carbs'),
          _Stat('${totals.fat}g',     'Fat'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w800)),
    Text(label, style: GoogleFonts.inter(
        fontSize: 10, color: Colors.grey.shade500)),
  ]);
}

// Meal card
class _MealCard extends StatelessWidget {
  final MealLog      log;
  final bool         expanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _MealCard({
    required this.log,
    required this.expanded,
    required this.onToggle,
    required this.onDelete,
  });

  static const _emoji = {
    'breakfast': '🌅',
    'lunch':     '☀️',
    'dinner':    '🌙',
    'snack':     '🍎',
  };
  static const _label = {
    'breakfast': 'Breakfast',
    'lunch':     'Lunch',
    'dinner':    'Dinner',
    'snack':     'Snack',
  };

  @override
  Widget build(BuildContext context) {
    final dark   = Theme.of(context).brightness == Brightness.dark;
    final bg     = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = dark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color:        bg,
        border:       Border.all(color: border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [

        // Header row
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(children: [
              // Meal emoji
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: kNeon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(
                  _emoji[log.mealType] ?? '🍽️',
                  style: const TextStyle(fontSize: 20),
                )),
              ),
              const SizedBox(width: 12),

              // Meal type + item count + date
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label[log.mealType] ?? log.mealType,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${log.items.length} item${log.items.length == 1 ? '' : 's'}'
                        '  ·  ${log.date}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              )),

              // Total kcal
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${log.totalKcal.round()} kcal',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kNeon)),
                  // Expand/collapse arrow
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ]),
          ),
        ),

        // Expanded detail
        if (expanded) ...[
          Divider(height: 1,
              color: dark ? Colors.grey.shade800 : Colors.grey.shade200),

          // Each item
          ...log.items.map((item) => Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.foodName,
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    '${item.portionG.round()} g  ·  '
                        '${item.kcal.round()} kcal  ·  '
                        'P ${item.proteinG.round()}g  '
                        'C ${item.carbsG.round()}g  '
                        'F ${item.fatG.round()}g',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              )),
            ]),
          )),

          // Macro totals + delete
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(children: [
              _MacroChip('P', '${log.totalProtein.round()}g'),
              const SizedBox(width: 6),
              _MacroChip('C', '${log.totalCarbs.round()}g'),
              const SizedBox(width: 6),
              _MacroChip('F', '${log.totalFat.round()}g'),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline,
                    size: 18, color: Colors.red.shade300),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label, value;
  const _MacroChip(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: kNeon.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text('$label $value',
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600)),
  );
}
