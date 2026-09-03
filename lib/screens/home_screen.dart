import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../data/shot_keep.dart';
import '../widgets/face_chip.dart';
import '../widgets/glass_panel.dart';
import '../widgets/neon_ball.dart';
import '../widgets/neon_button.dart';
import '../widgets/scene_background.dart';
import 'drop_scene_screen.dart';
import 'editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _presets = <(String, List<String>)>[
    ('Eat', ['Pizza', 'Sushi', 'Burger', 'Salad', 'Ramen', 'Tacos']),
    ('Watch', ['Movie', 'Series', 'YouTube', 'Anime', 'Doc']),
    ('Start', ['Inbox', 'Workout', 'Deep work', 'Break', 'Walk']),
    ('Coin', ['Heads', 'Tails']),
    ('Yes/No', ['Yes', 'No']),
    ('Team', ['A', 'B', 'C', 'D']),
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final n = store.workingOptions.length;
    final chance = n >= 2 ? '${(100 / n).toStringAsFixed(n > 6 ? 0 : 1)}%' : '';
    return SceneBackground(
      asset: AppAssets.dropChamber,
      scrim: 0.48,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FaceChip(
                    path: store.facePath,
                    stamp: store.faceStamp,
                    size: 46,
                    showCamMark: store.facePath == null,
                    onTap: () => _openFaceSheet(context, store),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Image.asset(
                      AppAssets.gameName,
                      height: 56,
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.contain,
                    ),
                  ),
                  _StreakPill(
                    streak: store.settings.streakCount,
                    total: store.settings.totalDrops,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                store.workingSetName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                n >= 2
                    ? 'Equal local pick · each ball $chance'
                    : 'Offline decision tool',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: VxColors.cyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              _ModeRow(store: store),
              if (store.mode == DropMode.multi) ...[
                const SizedBox(height: 10),
                _StepperCard(
                  title: 'Ranked results',
                  value: store.pickCount,
                  min: 2,
                  max: store.workingOptions.length.clamp(2, 10),
                  onChanged: store.setPickCount,
                ),
              ],
              if (store.mode == DropMode.split) ...[
                const SizedBox(height: 10),
                _StepperCard(
                  title: 'Number of groups',
                  value: store.groupCount,
                  min: 2,
                  max: store.workingOptions.length.clamp(2, 10),
                  onChanged: store.setGroupCount,
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: store.workingOptions.isEmpty
                    ? _EmptyHome(
                        onAdd: () => _addOption(context, store),
                        onPreset: (name, labels) {
                          AudioService.instance.play(AppAssets.soundBallAdd);
                          store.applyPreset(name, labels);
                        },
                      )
                    : Scrollbar(
                        thumbVisibility: n > 4,
                        child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: store.workingOptions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final option = store.workingOptions[i];
                          return GlassPanel(
                            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                            child: Row(
                              children: [
                                NeonBall(colorIndex: option.colorIndex),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (n >= 2 || option.wins > 0)
                                        Text(
                                          [
                                            if (n >= 2) chance,
                                            if (option.wins > 0)
                                              'Won ${option.wins}x',
                                          ].join(' · '),
                                          style: const TextStyle(
                                            color: VxColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove',
                                  onPressed: () {
                                    AudioService.instance
                                        .play(AppAssets.soundBallRemove);
                                    store.removeOption(option.id);
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      )
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: NeonButton(
                      label: 'Add',
                      icon: Icons.add_rounded,
                      secondary: true,
                      enabled: store.workingOptions.length < store.optionCap,
                      onPressed: () => _addOption(context, store),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeonButton(
                      label: 'Edit',
                      icon: Icons.tune_rounded,
                      secondary: true,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EditorScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _DropButton(
                mode: store.mode,
                onCharged: (charge) => _startDrop(context, store, charge),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFaceSheet(BuildContext context, AppStore store) async {
    AudioService.instance.play(AppAssets.soundTap);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheet) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profile photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.photo_camera_rounded,
                    color: VxColors.cyan,
                  ),
                  title: const Text(
                    'Take a photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    await store.takeFace(FaceSource.camera);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.photo_library_rounded,
                    color: VxColors.cyan,
                  ),
                  title: const Text(
                    'Choose from library',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    await store.takeFace(FaceSource.gallery);
                  },
                ),
                if (store.facePath != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: VxColors.cyan,
                    ),
                    title: const Text(
                      'Remove photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () async {
                      Navigator.of(sheet).pop();
                      await store.wipeFace();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addOption(BuildContext context, AppStore store) async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.graphite,
        title: const Text('Add option', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Coffee, Movie, Walk…',
            hintStyle: TextStyle(color: Colors.white38),
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (label == null) return;
    AudioService.instance.play(AppAssets.soundBallAdd);
    store.addOption(label);
  }

  void _startDrop(BuildContext context, AppStore store, double charge) {
    final error = store.validateDrop();
    if (error != null) {
      AudioService.instance.play(AppAssets.soundError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFF3A1020),
        ),
      );
      return;
    }
    final session = store.createSession();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DropSceneScreen(session: session, charge: charge),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak, required this.total});
  final int streak;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xF0121228),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VxColors.cyan.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: VxColors.magenta, size: 16),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.south_rounded, color: VxColors.cyan, size: 14),
          const SizedBox(width: 3),
          Text(
            '$total',
            style: const TextStyle(
              color: VxColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: NeonButton.height,
      child: Row(
        children: [
          _chip(DropMode.quick, Icons.bolt_rounded, 'Quick'),
          const SizedBox(width: 8),
          _chip(DropMode.multi, Icons.format_list_numbered, 'Multi'),
          const SizedBox(width: 8),
          _chip(DropMode.split, Icons.groups_rounded, 'Split'),
        ],
      ),
    );
  }

  Widget _chip(DropMode mode, IconData icon, String label) {
    final selected = store.mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => store.setMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected ? VxColors.buttonGradient : null,
            color: selected ? null : const Color(0xFF1A1A30),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropButton extends StatefulWidget {
  const _DropButton({required this.mode, required this.onCharged});
  final DropMode mode;
  final void Function(double charge) onCharged;

  @override
  State<_DropButton> createState() => _DropButtonState();
}

class _DropButtonState extends State<_DropButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _charge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _charge.dispose();
    super.dispose();
  }

  void _release() {
    final value = _charge.value;
    _charge.reverse();
    widget.onCharged(value);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.mode == DropMode.split ? 'Split' : 'Drop';
    final v = _charge.value;
    return GestureDetector(
      onTapDown: (_) => _charge.forward(),
      onTapUp: (_) => _release(),
      onTapCancel: () => _charge.reverse(),
      child: Container(
        height: NeonButton.height + 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: VxColors.buttonGradient,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: VxColors.magenta.withValues(alpha: 0.28 + 0.4 * v),
              blurRadius: 16 + 12 * v,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: v,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    v > 0.5 ? Icons.rocket_launch_rounded : Icons.south_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    v > 0.05 ? '$label · hold to charge' : label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperCard extends StatelessWidget {
  const _StepperCard({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: VxColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onAdd, required this.onPreset});

  final VoidCallback onAdd;
  final void Function(String name, List<String> labels) onPreset;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        children: [
          Expanded(
            child: Image.asset(AppAssets.emptyState, fit: BoxFit.contain),
          ),
          const Text(
            'No options yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a preset or add your own choices.',
            textAlign: TextAlign.center,
            style: TextStyle(color: VxColors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final preset in HomeScreen._presets)
                ActionChip(
                  label: Text(preset.$1),
                  backgroundColor: const Color(0xFF1C1C32),
                  labelStyle: const TextStyle(color: Colors.white),
                  onPressed: () => onPreset(preset.$1, preset.$2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          NeonButton(label: 'Add first option', onPressed: onAdd),
        ],
      ),
    );
  }
}
