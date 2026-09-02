import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/app_store.dart';
import '../services/audio_service.dart';
import '../widgets/glass_panel.dart';
import '../widgets/neon_ball.dart';
import '../widgets/neon_button.dart';
import '../widgets/scene_background.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _name;
  final Map<String, TextEditingController> _labels = {};

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    _name = TextEditingController(text: store.workingSetName);
  }

  @override
  void dispose() {
    _name.dispose();
    for (final c in _labels.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String id, String label) {
    return _labels.putIfAbsent(id, () => TextEditingController(text: label));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      backgroundColor: VxColors.voidBlack,
      body: SceneBackground(
        asset: AppAssets.neonOrbit,
        scrim: 0.58,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Edit Options',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                GlassPanel(
                  child: TextField(
                    controller: _name,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'Set name',
                      labelStyle: TextStyle(color: VxColors.textMuted),
                      border: InputBorder.none,
                    ),
                    onChanged: store.setWorkingName,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: store.workingOptions.length > 3,
                    child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: store.workingOptions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final option = store.workingOptions[i];
                      final controller =
                          _controllerFor(option.id, option.label);
                      return GlassPanel(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                NeonBall(colorIndex: option.colorIndex),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Option name',
                                      hintStyle: TextStyle(color: Colors.white38),
                                    ),
                                    onChanged: (v) =>
                                        store.updateOption(option.id, label: v),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    AudioService.instance
                                        .play(AppAssets.soundBallRemove);
                                    store.removeOption(option.id);
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: kBallSize + 18,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: VxColors.ballTints.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, color) {
                                  final selected = option.colorIndex == color;
                                  return GestureDetector(
                                    onTap: () => store.updateOption(
                                      option.id,
                                      colorIndex: color,
                                    ),
                                    child: NeonBall(
                                      colorIndex: color,
                                      highlighted: selected,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ),
                ),
                const SizedBox(height: 10),
                NeonButton(
                  label: 'Add option',
                  icon: Icons.add_rounded,
                  enabled: store.workingOptions.length < store.optionCap,
                  onPressed: () {
                    AudioService.instance.play(AppAssets.soundBallAdd);
                    store.addOption('Option ${store.workingOptions.length + 1}');
                  },
                ),
                const SizedBox(height: 8),
                NeonButton(
                  label: 'Save set',
                  icon: Icons.bookmark_add_rounded,
                  secondary: true,
                  onPressed: () async {
                    await store.saveWorkingSet();
                    AudioService.instance.play(AppAssets.soundSave);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Set saved on this device')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
