import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../widgets/glass_panel.dart';
import '../widgets/neon_ball.dart';
import '../widgets/neon_button.dart';
import '../widgets/scene_background.dart';
import 'drop_scene_screen.dart';
import 'editor_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.session});

  final DropSession session;

  @override
  Widget build(BuildContext context) {
    final title = session.mode == DropMode.split
        ? 'Groups'
        : session.winners.length == 1
            ? 'Chosen'
            : 'Ranking';
    return Scaffold(
      backgroundColor: VxColors.voidBlack,
      body: SceneBackground(
        asset: AppAssets.dropChamber,
        scrim: 0.5,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.mode == DropMode.split
                      ? session.setName
                      : '${session.setName} · 1 in ${session.options.length}',
                  style: const TextStyle(color: VxColors.textMuted),
                ),
                const SizedBox(height: 16),
                Expanded(child: _body()),
                Row(
                  children: [
                    Expanded(
                      child: NeonButton(
                        label: 'Copy',
                        icon: Icons.copy_rounded,
                        secondary: true,
                        onPressed: () => _copy(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: NeonButton(
                        label: 'Drop again',
                        icon: Icons.replay_rounded,
                        onPressed: () {
                          final store = context.read<AppStore>();
                          final next = store.createSession();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => DropSceneScreen(session: next),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: NeonButton(
                        label: 'Edit',
                        icon: Icons.edit_rounded,
                        secondary: true,
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => const EditorScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: NeonButton(
                        label: 'Home',
                        icon: Icons.home_rounded,
                        secondary: true,
                        onPressed: () {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (session.mode == DropMode.split) {
      return ListView.separated(
        itemCount: session.groups.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final group = session.groups[i];
          return GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group ${i + 1}',
                  style: const TextStyle(
                    color: VxColors.cyan,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                for (final option in group)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ResultRow(option: option),
                  ),
              ],
            ),
          );
        },
      );
    }

    if (session.winners.length == 1) {
      final winner = session.winners.single;
      return Center(
        child: GlassPanel(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeonBall(
                colorIndex: winner.colorIndex,
                size: kBallSize * 2.4,
                highlighted: true,
              ),
              const SizedBox(height: 18),
              const Text(
                'CHOSEN',
                style: TextStyle(
                  color: VxColors.cyan,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                winner.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              if (winner.wins > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Won ${winner.wins}x total',
                  style: const TextStyle(color: VxColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: session.winners.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final option = session.winners[i];
        return GlassPanel(
          child: _ResultRow(option: option, badge: '#${i + 1}'),
        );
      },
    );
  }

  void _copy(BuildContext context) {
    final text = _shareText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result copied to clipboard')),
    );
  }

  String _shareText() {
    if (session.mode == DropMode.split) {
      final buf = StringBuffer('Vortixa Drop · ${session.setName}\n');
      for (var i = 0; i < session.groups.length; i++) {
        buf.writeln('Group ${i + 1}: ${session.groups[i].map((o) => o.label).join(", ")}');
      }
      return buf.toString().trim();
    }
    if (session.winners.length == 1) {
      return 'Vortixa Drop picked: ${session.winners.first.label}';
    }
    final list = session.winners.asMap().entries.map((e) => '${e.key + 1}. ${e.value.label}');
    return 'Vortixa Drop · ${session.setName}\n${list.join("\n")}';
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.option, this.badge});

  final ChoiceOption option;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NeonBall(
          colorIndex: option.colorIndex,
          highlighted: true,
          badge: badge != null && badge!.startsWith('#') ? badge : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badge != null)
                Text(
                  badge!,
                  style: const TextStyle(
                    color: VxColors.cyan,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.6,
                  ),
                ),
              Text(
                option.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
