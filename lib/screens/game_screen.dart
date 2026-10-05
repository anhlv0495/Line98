import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/economy_provider.dart';
import '../widgets/board_widget.dart';
import '../theme/game_themes.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final theme = GameThemes.getConfig(settings.currentTheme);
        return Scaffold(
          backgroundColor: theme.winBg,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _TitleBar(onBack: () => Navigator.pop(context)),
                    _MenuBar(),
            _ScoreBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                child: BoardWidget(),
              ),
            ),
            _BottomBar(),
                  ],
                ),
                const _ConfettiLayer(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Title bar ─────────────────────────────────────────────────────────────────
class _TitleBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TitleBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, _) {
      final theme = GameThemes.getConfig(settings.currentTheme);
      return Container(
        height: 28,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.titleStart, theme.titleEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            // Icon placeholder
            Container(
              width: 16, height: 16,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Text('L', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: theme.titleStart,
                )),
              ),
            ),
            Text(
              "LINES'98",
              style: GoogleFonts.getFont(
                theme.titleFontFamily,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          const Spacer(),
          // Minimize button (acts as back)
          _Win98SystemButton(
            label: '—',
            onTap: onBack,
          ),
          const SizedBox(width: 2),
          // Close button
          _Win98SystemButton(
            label: '✕',
            onTap: onBack,
            isClose: true,
          ),
        ],
      ),
    );
    });
  }
}

class _Win98SystemButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isClose;
  const _Win98SystemButton({required this.label, required this.onTap, this.isClose = false});

  @override
  State<_Win98SystemButton> createState() => _Win98SystemButtonState();
}

class _Win98SystemButtonState extends State<_Win98SystemButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, _) {
      final theme = GameThemes.getConfig(settings.currentTheme);
      return GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
        onTapCancel: () => setState(() => _down = false),
        child: Container(
          width: 18, height: 16,
          decoration: BoxDecoration(
            color: theme.winBg,
            border: Border(
              top: BorderSide(color: _down ? theme.borderDarker : theme.borderLight, width: 1.5),
              left: BorderSide(color: _down ? theme.borderDarker : theme.borderLight, width: 1.5),
              right: BorderSide(color: _down ? theme.borderLight : theme.borderDarker, width: 1.5),
              bottom: BorderSide(color: _down ? theme.borderLight : theme.borderDarker, width: 1.5),
            ),
          ),
          child: Center(
            child: Text(widget.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: widget.isClose ? Colors.black : Colors.black87,
                )),
          ),
        ),
      );
    });
  }
}

// ── Menu bar ──────────────────────────────────────────────────────────────────
class _MenuBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer3<GameProvider, EconomyProvider, SettingsProvider>(
      builder: (context, game, economy, settings, _) {
        final theme = GameThemes.getConfig(settings.currentTheme);
        final undoCount = economy.getItemCount(ItemType.undo);
        final canUndo = game.canUndo && undoCount > 0;

        return Container(
          color: theme.winBg,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Row(
            children: [
              _MenuText('NEW', onTap: () => game.restartGame()),
              const SizedBox(width: 12),
              _MenuText(
                'UNDO ($undoCount)',
                onTap: canUndo ? () {
                  if (economy.useItem(ItemType.undo)) game.undo();
                } : null,
                enabled: canUndo,
              ),
              const Spacer(),
              const _MenuText('HIGHSCORE', enabled: false),
            ],
          ),
        );
      },
    );
  }
}

class _MenuText extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  const _MenuText(this.text, {this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, _) {
      final theme = GameThemes.getConfig(settings.currentTheme);
      return GestureDetector(
        onTap: onTap,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: enabled ? theme.textMain : theme.borderDark,
            decoration: onTap != null ? TextDecoration.underline : null,
            decorationColor: theme.textMain,
          ),
        ),
      );
    });
  }
}

// ── Score bar (black panel, cyan digital numbers, center preview balls) ────────
class _ScoreBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, SettingsProvider>(
      builder: (context, game, settings, _) {
        final theme = GameThemes.getConfig(settings.currentTheme);
        Future.microtask(() {
          Provider.of<AchievementProvider>(context, listen: false)
              .checkScoreAchievements(game.score);
        });

        return Container(
          color: theme.scoreBg,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              // Current score
              Expanded(
                child: Text(
                  game.score.toString().padLeft(5, '0'),
                  style: GoogleFonts.getFont(
                    theme.titleFontFamily,
                    color: theme.scoreText,
                    fontSize: 32,
                    letterSpacing: 2,
                  ),
                ),
              ),

              // Next balls preview — centered
              if (!game.isGameOver && settings.showNextBalls)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: game.nextColors.map((c) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 22,
                      height: 22,
                      child: CustomPaint(
                        painter: _MiniMarblePainter(color: c.color),
                      ),
                    );
                  }).toList(),
                ),

              // High score
              Expanded(
                child: Text(
                  game.highScore.toString().padLeft(5, '0'),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.getFont(
                    theme.titleFontFamily,
                    color: theme.scoreText,
                    fontSize: 32,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        if (game.isGameOver) {
          final gold = game.score ~/ 10;
          if (!game.rewardGiven && gold > 0) {
            Future.microtask(() {
              Provider.of<EconomyProvider>(context, listen: false).addGold(gold);
              game.markRewardGiven();
            });
          }
          return _Win98Panel(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('GAME OVER',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2,
                      )),
                  if (gold > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text('+$gold Gold',
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  _Win98Button(label: 'NEW GAME', onTap: () => game.restartGame()),
                ],
              ),
            ),
          );
        }

        return Consumer2<EconomyProvider, GameProvider>(
          builder: (context, economy, g, _) {
            return _Win98Panel(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    _Win98Button(
                      label: 'HAMMER  (${economy.getItemCount(ItemType.hammer)})',
                      onTap: economy.getItemCount(ItemType.hammer) > 0
                          ? () => g.toggleActiveItem(ItemType.hammer)
                          : null,
                      active: g.activeItem == ItemType.hammer,
                    ),
                    const SizedBox(width: 8),
                    _Win98Button(
                      label: 'BRUSH  (${economy.getItemCount(ItemType.brush)})',
                      onTap: economy.getItemCount(ItemType.brush) > 0
                          ? () => g.toggleActiveItem(ItemType.brush)
                          : null,
                      active: g.activeItem == ItemType.brush,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Reusable Windows 98 components ──────────────────────────────────────────

class _Win98Panel extends StatelessWidget {
  final Widget child;
  const _Win98Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, _) {
      final theme = GameThemes.getConfig(settings.currentTheme);
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.winBg,
          border: Border(
            top: BorderSide(color: theme.borderLight, width: 1.5),
          ),
        ),
        child: child,
      );
    });
  }
}

class _Win98Button extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool active;
  const _Win98Button({required this.label, this.onTap, this.active = false});

  @override
  State<_Win98Button> createState() => _Win98ButtonState();
}

class _Win98ButtonState extends State<_Win98Button> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, _) {
      final theme = GameThemes.getConfig(settings.currentTheme);
      final isDown = _down || widget.active;
      final enabled = widget.onTap != null;
      return GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) {
          setState(() => _down = false);
          widget.onTap!();
        } : null,
        onTapCancel: () => setState(() => _down = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.active ? theme.borderDark : theme.winBg,
            border: Border(
              top: BorderSide(color: isDown ? theme.borderDarker : theme.borderLight, width: 1.5),
              left: BorderSide(color: isDown ? theme.borderDarker : theme.borderLight, width: 1.5),
              right: BorderSide(color: isDown ? theme.borderLight : theme.borderDarker, width: 1.5),
              bottom: BorderSide(color: isDown ? theme.borderLight : theme.borderDarker, width: 1.5),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: enabled ? theme.textMain : theme.borderDark,
            ),
          ),
        ),
      );
    });
  }
}

// ── Mini marble painter for the score bar preview dots ────────────────────────
class _MiniMarblePainter extends CustomPainter {
  final Color color;
  const _MiniMarblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);


    // Body with smooth classic white to black gradient
    canvas.drawCircle(
      center, r * 0.90,
      Paint()..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        radius: 0.9,
        colors: [
          Colors.white,
          _lightenColor(color, 0.3),
          color,
          _darkenColor(color, 0.5),
          Colors.black,
        ],
        stops: const [0.0, 0.2, 0.5, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_MiniMarblePainter old) => old.color != color;
}

Color _lightenColor(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

Color _darkenColor(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

// ── Confetti Layer ────────────────────────────────────────────────────────────

class _ConfettiLayer extends StatefulWidget {
  const _ConfettiLayer({Key? key}) : super(key: key);

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer> {
  late ConfettiController _controller;
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        if (game.isGameOver && game.isNewHighScore && !_hasPlayed) {
          _hasPlayed = true;
          _controller.play();
        } else if (!game.isGameOver) {
          _hasPlayed = false; // Reset when game restarts
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirection: pi / 2, // Downwards
            maxBlastForce: 20,
            minBlastForce: 5,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
          ),
        );
      },
    );
  }
}

