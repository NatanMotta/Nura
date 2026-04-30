import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/utils/color_utils.dart';
import '../../../../../core/widgets/glass.dart';
import '../../../../../core/widgets/mono.dart';
import '../../../../shared/data/mock_nura_data.dart';

class HomeProfile extends StatelessWidget {
  final NuraVibe vibe;
  final Color accent;
  final double safeTop, safeBottom;
  const HomeProfile(
      {super.key,
      required this.vibe,
      required this.accent,
      required this.safeTop,
      required this.safeBottom});
  @override
  Widget build(BuildContext context) {
    const battles = [
      (true, 'Polara · Soft Machine', 'Mira S. · Velvet Static', '64% · 36%'),
      (false, 'Iva K. · Tempera', 'Theo H. · Iron Lung', '41% · 59%'),
      (true, 'Rōnin · Sub Fathom', 'Nube P. · Madrugada', '58% · 42%'),
    ];
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(0, safeTop, 0, 100 + safeBottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Profilo',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: NuraBrand.mint,
                    letterSpacing: -0.5)),
            Icon(Icons.settings_outlined,
                size: 20, color: NuraBrand.mintAlpha(0.6)),
          ]),
        ),
        // Identity card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Glass(
            vibe: vibe,
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent, NuraBrand.deep])),
                  alignment: Alignment.center,
                  child: const Text('EM',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Elena Marchetti',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: NuraBrand.mint)),
                      const SizedBox(height: 2),
                      Text('@elenam · iscritta dal 2026',
                          style: TextStyle(
                              fontSize: 12, color: NuraBrand.mintAlpha(0.6))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: NuraBrand.mintAlpha(0.10),
                            border: Border.all(color: vibe.cardBorder)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.bolt, size: 12, color: accent),
                          const SizedBox(width: 6),
                          const Mono('SCOUT · LIV. 04',
                              color: NuraBrand.mint, size: 9.5),
                        ]),
                      ),
                    ])),
              ]),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Mono('xp verso liv. 05', color: NuraBrand.mintAlpha(0.55)),
                const Mono('740 / 1000', color: NuraBrand.mint),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                      height: 6,
                      color: NuraBrand.mintAlpha(0.12),
                      child: FractionallySizedBox(
                          widthFactor: 0.74,
                          alignment: Alignment.centerLeft,
                          child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [accent, NuraBrand.mint])))))),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 14),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: vibe.cardBorder))),
                child: Row(children: [
                  for (final s in const [
                    ('BRANI · LIKE', '128'),
                    ('BATTLE', '37'),
                    ('SCOUTING', '12')
                  ])
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(s.$2,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: NuraBrand.mint,
                                  letterSpacing: -0.5)),
                          Mono(s.$1, color: NuraBrand.mintAlpha(0.5)),
                        ])),
                ]),
              ),
            ]),
          ),
        ),
        // Saved tracks
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Mono('♥ brani salvati', color: NuraBrand.mint),
                      Mono('vedi tutti →', color: NuraBrand.mintAlpha(0.45)),
                    ])),
            Glass(
              vibe: vibe,
              padding: const EdgeInsets.all(4),
              child: Column(children: [
                for (int i = 0; i < 4; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        border: Border(
                            top: i == 0
                                ? BorderSide.none
                                : BorderSide(color: vibe.cardBorder))),
                    child: Row(children: [
                      Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  hueColor(
                                      0.55, 0.10, kTracks[i].hue.toDouble()),
                                  hueColor(0.38, 0.07, 195)
                                ]),
                          )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(kTracks[i].track,
                                style: const TextStyle(
                                    color: NuraBrand.mint,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text('${kTracks[i].artist} · ${kTracks[i].genre}',
                                style: TextStyle(
                                    color: NuraBrand.mintAlpha(0.55),
                                    fontSize: 11)),
                          ])),
                      Mono(kTracks[i].dur, color: NuraBrand.mintAlpha(0.45)),
                      const SizedBox(width: 8),
                      Icon(Icons.play_arrow, size: 16, color: accent),
                    ]),
                  ),
              ]),
            ),
          ]),
        ),
        // Battle history
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Mono('⚔ storico battle', color: NuraBrand.mint)),
            Glass(
              vibe: vibe,
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                for (int i = 0; i < battles.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        border: Border(
                            top: i == 0
                                ? BorderSide.none
                                : BorderSide(color: vibe.cardBorder))),
                    child: IntrinsicHeight(
                        child: Row(children: [
                      Container(
                          width: 6,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: battles[i].$1
                                  ? accent
                                  : NuraBrand.mintAlpha(0.25))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(battles[i].$2,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: NuraBrand.mint,
                                    fontWeight: FontWeight.w500)),
                            Text('vs',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: NuraBrand.mintAlpha(0.5))),
                            Text(battles[i].$3,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: NuraBrand.mintAlpha(0.7))),
                          ])),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Mono(battles[i].$1 ? 'VINTA' : 'PERSA',
                                color: battles[i].$1
                                    ? accent
                                    : NuraBrand.mintAlpha(0.45),
                                size: 10),
                            const SizedBox(height: 2),
                            Text(battles[i].$4,
                                style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontFamilyFallback: const ['monospace'],
                                    fontSize: 11,
                                    color: NuraBrand.mintAlpha(0.6))),
                          ]),
                    ])),
                  ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
