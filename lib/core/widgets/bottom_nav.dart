import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final String active;
  final ValueChanged<String> onChange;
  final NuraVibe vibe;
  final Color accent;
  final double safeBottom;
  const BottomNav(
      {super.key,
      required this.active,
      required this.onChange,
      required this.vibe,
      required this.accent,
      required this.safeBottom});
  @override
  Widget build(BuildContext context) {
    const items = [
      (RouteNames.home, 'Home', Icons.home_outlined),
      (RouteNames.search, 'Cerca', Icons.search),
      (RouteNames.profile, 'Profilo', Icons.person_outline),
    ];
    final bg = vibe == NuraVibe.techy
        ? const Color(0xEB005D6D)
        : const Color(0xC7005D6D);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: EdgeInsets.fromLTRB(0, 6, 0, safeBottom),
          decoration: BoxDecoration(
            color: bg,
            border: Border(top: BorderSide(color: vibe.cardBorder)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((it) {
              final isActive = active == it.$1;
              final color =
                  isActive ? NuraBrand.mint : NuraBrand.mintAlpha(0.55);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChange(it.$1),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(it.$3, size: 22, color: color),
                    const SizedBox(height: 4),
                    Text(it.$2,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          letterSpacing: 0.4,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                        )),
                    const SizedBox(height: 2),
                    Container(
                      width: 22,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isActive ? accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. SCREENS — port of app/screens.jsx
// ─────────────────────────────────────────────────────────────────────────────
