import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../widgets/glass_panel.dart';
import '../widgets/scene_background.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return SceneBackground(
      asset: AppAssets.neonOrbit,
      scrim: 0.55,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Column(
            children: [
              const Text(
                'History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: store.history.isEmpty
                    ? GlassPanel(
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.asset(
                                AppAssets.historyArt,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const Text(
                              'No results yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Every Drop is stored locally on this device.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: VxColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: store.history.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final entry = store.history[i];
                          return GlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _title(entry),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _modeLabel(entry.mode),
                                      style: const TextStyle(
                                        color: VxColors.cyan,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _subtitle(entry),
                                  style: const TextStyle(color: VxColors.textMuted),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _format(entry.at),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(HistoryEntry entry) {
    if (entry.mode == DropMode.split) {
      return entry.setName;
    }
    return entry.results.join(', ');
  }

  String _subtitle(HistoryEntry entry) {
    if (entry.mode == DropMode.split) {
      final parts = <String>[];
      final groups = entry.groups ?? const [];
      for (var i = 0; i < groups.length; i++) {
        parts.add('G${i + 1}: ${groups[i].join(', ')}');
      }
      return parts.join('  ·  ');
    }
    return entry.setName;
  }

  String _modeLabel(DropMode mode) {
    switch (mode) {
      case DropMode.quick:
        return 'QUICK';
      case DropMode.multi:
        return 'MULTI';
      case DropMode.split:
        return 'SPLIT';
    }
  }

  String _format(DateTime at) {
    final local = at.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}  $hh:$mm';
  }
}
