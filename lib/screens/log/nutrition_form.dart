// screens/log/nutrition_form.dart
//
// How it works:
//   1. Pick meal type
//   2. Search a food → tap it → grams field appears pre-filled to 100
//      → change grams if needed → tap Add
//   3. Added item collapses to a compact row (name · grams · kcal)
//      Tap the row to expand and see macros or remove it
//   4. Tap "+ Add another food" to add more items
//   5. Tap "Save meal" → one Firestore document with all items

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/nutrition_log.dart';
import '../../../widgets/neon_widgets.dart';
import '../../../widgets/onboarding_widgets.dart'; // kNeon
import 'nutrition_constants.dart';

class NutritionForm extends StatefulWidget {
  final Future<void> Function(MealLog) onSaved;
  const NutritionForm({super.key, required this.onSaved});

  @override
  State<NutritionForm> createState() => _NutritionFormState();
}

class _NutritionFormState extends State<NutritionForm> {
  // ── Meal ────────────────────────────────────────────────────
  String               _mealType = 'lunch';
  final List<MealItem> _items    = [];
  bool                 _saving   = false;

  // ── Current search session ───────────────────────────────────
  // _showSearch controls whether the search+grams area is visible.
  // It starts true (so first food is immediately visible),
  // and goes back to true when user taps "+ Add another food".
  bool             _showSearch = true;
  FoodItem?        _picked;
  List<FoodItem>   _results = [];

  final _searchCtrl  = TextEditingController();
  final _portionCtrl = TextEditingController();

  // Which item row is expanded in the list
  int _expanded = -1;

  @override
  void initState() {
    super.initState();
    // Listen for search text changes — only registered once here
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _portionCtrl.dispose();
    super.dispose();
  }

  // ── Search logic ─────────────────────────────────────────────
  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() { _results = []; _picked = null; });
      return;
    }
    // Only show results if user is still typing (not after picking)
    if (_picked != null && _searchCtrl.text == _picked!.name) return;
    setState(() {
      _picked  = null;
      _results = kFoodCatalog
          .where((f) => f.name.toLowerCase().contains(q))
          .take(6)
          .toList();
    });
  }

  void _pickFood(FoodItem food) {
    // Picking a food fills the search field and shows the grams input.
    // No macro fields — macros are calculated silently on Add.
    setState(() {
      _picked  = food;
      _results = [];
    });
    _searchCtrl.text  = food.name;
    _portionCtrl.text = '100';
  }

  // ── Add item to the meal list ────────────────────────────────
  void _addItem() {
    if (_picked == null) {
      _snack('Select a food from the list first.');
      return;
    }
    final g = double.tryParse(_portionCtrl.text.trim());
    if (g == null || g <= 0) {
      _snack('Enter a valid gram amount.');
      return;
    }
    final r = g / 100.0;
    setState(() {
      _items.add(MealItem(
        foodName: _picked!.name,
        portionG: g,
        kcal:     _round(_picked!.kcal     * r),
        proteinG: _round(_picked!.proteinG * r),
        carbsG:   _round(_picked!.carbsG   * r),
        fatG:     _round(_picked!.fatG     * r),
      ));
      // Reset search area and hide it — user sees the item list
      _picked     = null;
      _showSearch = false;
      _results    = [];
      _searchCtrl.clear();
      _portionCtrl.clear();
    });
  }

  double _round(double v) =>
      double.parse(v.toStringAsFixed(1));

  void _removeItem(int i) => setState(() {
    _items.removeAt(i);
    _expanded = -1;
  });

  // ── Save ─────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_items.isEmpty) {
      _snack('Add at least one food.');
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      await widget.onSaved(MealLog(
        mealType:  _mealType,
        date:      _dateStr(now),
        items:     List.from(_items),
        createdAt: now,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-'
          '${d.day.toString().padLeft(2,'0')}';

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dark   = Theme.of(context).brightness == Brightness.dark;
    final bg     = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Handle
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 16),

            Text('Log meal',
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('Date set to today automatically.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 18),

            // ── Meal type ──────────────────────────────────
            _MealTypePicker(
              selected:  _mealType,
              onChanged: (v) => setState(() => _mealType = v),
            ),
            const SizedBox(height: 20),

            // ── Already-added items ────────────────────────
            if (_items.isNotEmpty) ...[
              Text('Items',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...List.generate(_items.length, (i) => _ItemTile(
                item:     _items[i],
                expanded: _expanded == i,
                onToggle: () => setState(() =>
                _expanded = _expanded == i ? -1 : i),
                onRemove: () => _removeItem(i),
              )),
              // Running total
              _TotalRow(items: _items),
              const SizedBox(height: 12),
            ],

            // ── Search + grams area ────────────────────────
            if (_showSearch) ...[
              Text(_items.isEmpty ? 'Search food' : 'Add another food',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              NeonField(
                controller: _searchCtrl,
                label: 'Food name',
                hint:  'e.g. Chicken Breast',
              ),

              // Dropdown results
              if (_results.isNotEmpty)
                _ResultsList(
                  results:    _results,
                  onSelected: _pickFood,
                  dark:       dark,
                ),

              // Once a food is picked: show grams + Add button
              if (_picked != null) ...[
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: kNeon, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_picked!.name,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  // Grams field — user can change from default 100
                  Expanded(
                    child: TextFormField(
                      controller: _portionCtrl,
                      keyboardType: const TextInputType
                          .numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .allow(RegExp(r'[\d.]')),
                      ],
                      autofocus: true,
                      style: GoogleFonts.inter(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Grams',
                        labelStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade500),
                        suffixText: 'g',
                        filled:     true,
                        fillColor:  dark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF5FFF5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade300, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: kNeon, width: 2.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNeon,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Add',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
                ]),
              ],
            ],

            // ── "+ Add another food" button ────────────────
            // Shown after an item is added and search is hidden
            if (!_showSearch && _items.isNotEmpty) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => setState(() => _showSearch = true),
                icon: const Icon(Icons.add, color: kNeon, size: 20),
                label: Text('Add another food',
                    style: GoogleFonts.inter(
                        color: kNeon,
                        fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
              ),
            ],

            const SizedBox(height: 20),

            NeonButton(
              label:     'Save meal',
              loading:   _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}


// ── Meal type picker ───────────────────────────────────────────
class _MealTypePicker extends StatelessWidget {
  final String                selected;
  final void Function(String) onChanged;
  const _MealTypePicker({
    required this.selected,
    required this.onChanged,
  });

  static const _types  = ['breakfast', 'lunch', 'dinner', 'snack'];
  static const _labels = ['Breakfast', 'Lunch',  'Dinner', 'Snack'];
  static const _emojis = ['🌅', '☀️', '🌙', '🍎'];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: List.generate(_types.length, (i) {
        final active = _types[i] == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(_types[i]),
            child: Container(
              margin: EdgeInsets.only(
                  right: i < _types.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? kNeon
                    : dark
                    ? const Color(0xFF2A2A2A)
                    : Colors.white,
                border: Border.all(
                  color: active
                      ? kNeon
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(children: [
                Text(_emojis[i],
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 2),
                Text(_labels[i],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? Colors.black
                          : Colors.grey.shade500,
                    )),
              ]),
            ),
          ),
        );
      }),
    );
  }
}


// ── Confirmed item tile ────────────────────────────────────────
// Collapsed: food name + grams + kcal + arrow
// Expanded:  + P/C/F chips + Remove button
class _ItemTile extends StatelessWidget {
  final MealItem     item;
  final bool         expanded;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _ItemTile({
    required this.item,
    required this.expanded,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final dark   = Theme.of(context).brightness == Brightness.dark;
    final bg     = dark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF8F8F8);
    final border = dark
        ? Colors.grey.shade700
        : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:        bg,
        border:       Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        // Always-visible row
        InkWell(
          onTap:        onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.foodName,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text(
                    '${item.portionG.round()} g  ·  '
                        '${item.kcal.round()} kcal',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500),
                  ),
                ],
              )),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ]),
          ),
        ),

        // Expanded detail
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(children: [
              _Chip('P ${item.proteinG.round()}g'),
              const SizedBox(width: 6),
              _Chip('C ${item.carbsG.round()}g'),
              const SizedBox(width: 6),
              _Chip('F ${item.fatG.round()}g'),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                child: Text('Remove',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.red.shade400)),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: kNeon.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600)),
  );
}


// ── Running total ──────────────────────────────────────────────
class _TotalRow extends StatelessWidget {
  final List<MealItem> items;
  const _TotalRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final kcal    = items.fold(0.0, (s, i) => s + i.kcal);
    final protein = items.fold(0.0, (s, i) => s + i.proteinG);
    final carbs   = items.fold(0.0, (s, i) => s + i.carbsG);
    final fat     = items.fold(0.0, (s, i) => s + i.fatG);

    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(
          vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF1A2E1A)
            : const Color(0xFFF0FFF0),
        border: Border.all(color: kNeon, width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Total('${kcal.round()}',    'kcal'),
          _Total('${protein.round()}g','Protein'),
          _Total('${carbs.round()}g',  'Carbs'),
          _Total('${fat.round()}g',    'Fat'),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String v, l;
  const _Total(this.v, this.l);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(v, style: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w800)),
    Text(l, style: GoogleFonts.inter(
        fontSize: 10, color: Colors.grey.shade500)),
  ]);
}


// ── Search results dropdown ────────────────────────────────────
class _ResultsList extends StatelessWidget {
  final List<FoodItem>          results;
  final void Function(FoodItem) onSelected;
  final bool                    dark;
  const _ResultsList({
    required this.results,
    required this.onSelected,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final bg     = dark ? const Color(0xFF2A2A2A) : Colors.white;
    final border = dark ? Colors.grey.shade700 : Colors.grey.shade200;
    return Container(
      decoration: BoxDecoration(
        color:        bg,
        border:       Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: results.map((f) => InkWell(
          onTap:        () => onSelected(f),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.name,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text(
                    '${f.kcal.round()} kcal · '
                        'P ${f.proteinG}g · '
                        'C ${f.carbsG}g · '
                        'F ${f.fatG}g  per 100g',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500),
                  ),
                ],
              )),
              Text(f.category,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey.shade400)),
            ]),
          ),
        )).toList(),
      ),
    );
  }
}
