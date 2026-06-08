import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

class BottomNavItem {
  final String value;
  final String label;
  final IconData icon;

  const BottomNavItem(this.value, this.label, this.icon);
}

class BottomNav extends StatelessWidget {
  final String active;
  final ValueChanged<String> onChange;
  final NuraVibe vibe;
  final Color accent;
  final double safeBottom;
  final List<BottomNavItem>? items;

  const BottomNav({
    super.key,
    required this.active,
    required this.onChange,
    required this.vibe,
    required this.accent,
    required this.safeBottom,
    this.items,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = items ??
        const [
          BottomNavItem(RouteNames.home, 'Home', Icons.home_rounded),
          BottomNavItem(RouteNames.search, 'Cerca', Icons.search_rounded),
          BottomNavItem('artist_pitch', 'Pitch', Icons.music_note_rounded),
          BottomNavItem('events', 'Eventi', Icons.event_rounded),
        ];

    // Background gradient fluido ed elegante (più trasparente come richiesto)
    final isTechy = vibe == NuraVibe.techy;
    final glassGradient = isTechy
        ? LinearGradient(
            colors: [
              const Color(0xFF00E5FF).withValues(alpha: 0.08), // Cyan leggerissimo
              const Color(0xFF001F29).withValues(alpha: 0.45), // Base techy scura
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              NuraBrand.pink.withValues(alpha: 0.08), // Pink leggerissimo
              const Color(0xFF100812).withValues(alpha: 0.45), // Base classic scura
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Padding(
      // Floating dock: abbassato aderendo maggiormente alla safeArea
      padding: EdgeInsets.only(left: 20, right: 20, bottom: safeBottom > 0 ? safeBottom : 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            // Ombra sobria per staccarlo dallo sfondo, senza bagliori colorati "pacchiani"
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              height: 64, // Altezza ridotta senza i testi
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: glassGradient, // Usa il gradient ispirato alle sezioni Pitch
                borderRadius: BorderRadius.circular(36),
                // Niente bordi per un design più pulito e "glass"
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: navItems.map((item) {
                  final isActive = active == item.value;
                  
                  final activeColor = Colors.white; // Torniamo al bianco elegante per l'icona
                  final inactiveColor = Colors.white.withValues(alpha: 0.40);
                  final color = isActive ? activeColor : inactiveColor;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onChange(item.value);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              item.icon,
                              key: ValueKey<bool>(isActive),
                              size: 26,
                              color: color,
                              // Niente ombre/glow sull'icona
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isActive ? 1.0 : 0.0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isActive ? 18 : 0,
                              height: 3,
                              decoration: BoxDecoration(
                                color: accent, // La barretta usa la palette (Pink/Cyan)
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
