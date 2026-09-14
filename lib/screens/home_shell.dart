import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../core/orientation.dart';
import '../data/app_store.dart';
import '../services/audio_service.dart';
import 'about_screen.dart';
import 'daily_screen.dart';
import 'duel_screen.dart';
import 'favorites_screen.dart';
import 'guide_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'lab_screen.dart';
import 'presets_screen.dart';
import 'saved_sets_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {

  static const _pages = [
    HomeScreen(),
    SavedSetsScreen(),
    HistoryScreen(),
    DailyScreen(),
    PresetsScreen(),
    DuelScreen(),
    StatsScreen(),
    FavoritesScreen(),
    GuideScreen(),
    LabScreen(),
    AboutScreen(),
    SettingsScreen(),
  ];

  static const _tabs = [
    (Icons.south_rounded, 'Drop'),
    (Icons.folder_special_rounded, 'Sets'),
    (Icons.history_rounded, 'History'),
    (Icons.today_rounded, 'Daily'),
    (Icons.auto_awesome_mosaic_rounded, 'Presets'),
    (Icons.sports_kabaddi_rounded, 'Duel'),
    (Icons.insights_rounded, 'Stats'),
    (Icons.star_rounded, 'Favorites'),
    (Icons.menu_book_rounded, 'Guide'),
    (Icons.science_rounded, 'Lab'),
    (Icons.info_outline_rounded, 'About'),
    (Icons.settings_rounded, 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    VxOrientation.lockPortrait();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppStore>().openTab(widget.initialTab);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final index = store.shellTab.clamp(0, _pages.length - 1);
    return Scaffold(
      backgroundColor: VxColors.voidBlack,
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xF00A0A18),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final tab = _tabs[i];
                  return _NavItem(
                    icon: tab.$1,
                    label: tab.$2,
                    selected: index == i,
                    onTap: () => _select(i),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _select(int index) {
    final store = context.read<AppStore>();
    if (index == store.shellTab) return;
    AudioService.instance.play(AppAssets.soundMenuOpen);
    store.openTab(index);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? VxColors.cyan : Colors.white54;
    return SizedBox(
      width: 76,
      child: Material(
        color: selected
            ? VxColors.cyan.withValues(alpha: 0.14)
            : const Color(0xFF141428),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
