import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeader extends StatelessWidget {
  final String firstName;
  const HomeHeader({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hello, $firstName 👋',
            style: GoogleFonts.inter(
                fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(_dateLabel(),
            style: GoogleFonts.inter(
                fontSize: 13, color: Colors.grey.shade500)),
      ],
    );
  }

  String _dateLabel() {
    final now  = DateTime.now();
    const wday = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const mon  = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${wday[now.weekday - 1]}, '
        '${now.day} ${mon[now.month - 1]} ${now.year}';
  }
}
