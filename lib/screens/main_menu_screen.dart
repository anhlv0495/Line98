import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_mode.dart';
import '../models/theme_type.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/economy_provider.dart';
import '../widgets/daily_login_dialog.dart';
import 'game_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/game_themes.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyLogin();
    });
  }

  void _checkDailyLogin() {
    final economy = Provider.of<EconomyProvider>(context, listen: false);
    if (!economy.hasClaimedToday) {
      // For now, keep the old dialog or style it. Let's just use the default one
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const DailyLoginDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final theme = GameThemes.getConfig(settings.currentTheme);
        return Scaffold(
          backgroundColor: theme.desktopBg,
          body: SafeArea(
            child: Stack(
          children: [
            // Center Window
            Center(
              child: _Win98Window(
                title: 'Lines 98',
                width: 300,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        "LINES'98",
                        style: GoogleFonts.vt323(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: theme.textMain,
                          letterSpacing: 4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "REMASTERED",
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.borderDark,
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      Consumer<GameProvider>(
                        builder: (context, gameProvider, child) {
                          if (gameProvider.hasSavedGame) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Win98LargeButton(
                                  label: 'CONTINUE',
                                  onTap: () {
                                    gameProvider.resumeGame();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const GameScreen()),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      _Win98LargeButton(
                        label: 'PLAY NOW',
                        onTap: () => _showGameModeSelector(context),
                      ),
                      const SizedBox(height: 8),
                      _Win98LargeButton(
                        label: 'LEADERBOARD',
                        onTap: () => _showLeaderboard(context),
                      ),
                      const SizedBox(height: 8),
                      _Win98LargeButton(
                        label: 'SHOP',
                        onTap: () => _showShop(context),
                      ),
                      const SizedBox(height: 8),
                      _Win98LargeButton(
                        label: 'ACHIEVEMENTS',
                        onTap: () => _showAchievements(context),
                      ),
                      const SizedBox(height: 8),
                      _Win98LargeButton(
                        label: 'SETTINGS & HELP',
                        onTap: () => _showSettings(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Gold display (top left)
            Positioned(
              top: 16, left: 16,
              child: Consumer<EconomyProvider>(
                builder: (context, economy, child) {
                  return _Win98Panel(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Gold: ${economy.gold}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textMain),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
          ),
        );
      },
    );
  }

  void _showGameModeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        final theme = GameThemes.getConfig(settings.currentTheme);
        return Center(
          child: _Win98Window(
            title: 'Select Game Mode',
            width: 280,
            onClose: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Win98LargeButton(
                    label: 'CLASSIC MODE',
                    onTap: () {
                      Navigator.pop(context);
                      Future.microtask(() => Provider.of<GameProvider>(context, listen: false).restartGameMode(GameMode.classic));
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Traditional Line 98 rules.', style: TextStyle(fontSize: 11, color: theme.textMain)),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey, height: 1),
                  const SizedBox(height: 16),
                  _Win98LargeButton(
                    label: 'ARCADE MODE',
                    onTap: () {
                      Navigator.pop(context);
                      Future.microtask(() => Provider.of<GameProvider>(context, listen: false).restartGameMode(GameMode.arcade));
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Includes Power-ups (Bomb, Rainbow).', style: TextStyle(fontSize: 11, color: theme.textMain)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showShop(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: _Win98Window(
            title: 'Item & Theme Shop',
            width: 340,
            onClose: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Consumer2<EconomyProvider, SettingsProvider>(
                builder: (context, economy, settings, _) {
                  final theme = GameThemes.getConfig(settings.currentTheme);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Available Gold: ${economy.gold}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textMain), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text('Items', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textMain)),
                      const SizedBox(height: 4),
                      _buildShopItem(economy, settings, ItemType.hammer, 'Hammer', 'Destroy 1 ball', Icons.hardware),
                      _buildShopItem(economy, settings, ItemType.brush, 'Brush', 'Change color', Icons.brush),
                      _buildShopItem(economy, settings, ItemType.undo, 'Undo', 'Rewind 1 step', Icons.undo),
                      const SizedBox(height: 12),
                      Text('Themes', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textMain)),
                      const SizedBox(height: 4),
                      _buildThemeItem(economy, settings, GameTheme.classic, 'Classic Win98', 0),
                      _buildThemeItem(economy, settings, GameTheme.windowsXp, 'Windows XP', 500),
                      _buildThemeItem(economy, settings, GameTheme.msDos, 'MS-DOS', 1000),
                      const SizedBox(height: 12),
                      _Win98LargeButton(label: 'OK', onTap: () => Navigator.pop(context)),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopItem(EconomyProvider economy, SettingsProvider settings, ItemType type, String name, String desc, IconData icon) {
    final theme = GameThemes.getConfig(settings.currentTheme);
    final count = economy.getItemCount(type);
    final price = economy.getItemPrice(type);
    final canAfford = economy.gold >= price;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.borderDark),
        color: theme.cellFace,
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.textMain.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textMain)),
                Text(desc, style: TextStyle(fontSize: 11, color: theme.textMain.withOpacity(0.7))),
              ],
            ),
          ),
          Text('x$count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textMain)),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: _Win98LargeButton(
              label: 'BUY ($price)',
              onTap: canAfford ? () => economy.buyItem(type) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeItem(EconomyProvider economy, SettingsProvider settings, GameTheme theme, String name, int price) {
    final isUnlocked = settings.unlockedThemes.contains(theme);
    final isEquipped = settings.currentTheme == theme;
    final canAfford = economy.gold >= price;
    
    final themeConfig = GameThemes.getConfig(settings.currentTheme);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: themeConfig.borderDark),
        color: themeConfig.cellFace,
      ),
      child: Row(
        children: [
          Icon(Icons.palette, size: 24, color: themeConfig.textMain.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: themeConfig.textMain)),
          ),
          if (isEquipped)
            const SizedBox(width: 100, child: Center(child: Text('EQUIPPED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))))
          else if (isUnlocked)
            SizedBox(width: 100, child: _Win98LargeButton(label: 'EQUIP', onTap: () => settings.setTheme(theme)))
          else
            SizedBox(
              width: 100,
              child: _Win98LargeButton(
                label: 'BUY ($price G)',
                onTap: canAfford ? () {
                  if (economy.spendGold(price)) {
                    settings.unlockTheme(theme);
                  }
                } : null,
              ),
            ),
        ],
      ),
    );
  }

  void _showLeaderboard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: _Win98Window(
            title: 'High Scores',
            width: 250,
            onClose: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<GameProvider>(
                builder: (context, game, _) {
                  final settings = Provider.of<SettingsProvider>(context, listen: false);
                  final theme = GameThemes.getConfig(settings.currentTheme);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (game.highScores.isEmpty)
                        Text('No records yet.', style: TextStyle(fontSize: 13, color: theme.textMain))
                      else
                        ...List.generate(game.highScores.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${i + 1}.', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textMain)),
                                Text(
                                  '${game.highScores[i]}',
                                  style: TextStyle(fontFamily: 'monospace', fontSize: 16, color: theme.textMain),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                      _Win98LargeButton(label: 'OK', onTap: () => Navigator.pop(context)),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAchievements(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: _Win98Window(
            title: 'Achievements',
            width: 320,
            onClose: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Consumer<AchievementProvider>(
                builder: (context, achProvider, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 300, // constrained height for list
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: achProvider.allAchievements.length,
                          itemBuilder: (context, index) {
                            final ach = achProvider.allAchievements[index];
                            final isUnlocked = achProvider.unlockedIds.contains(ach.id);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.all(8),
                              color: isUnlocked ? Colors.white : Colors.grey[300],
                              child: Row(
                                children: [
                                  Icon(ach.icon, color: isUnlocked ? Colors.amber : Colors.grey, size: 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(ach.title, style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isUnlocked ? Colors.black : Colors.black54,
                                        )),
                                        Text(ach.description, style: TextStyle(
                                          fontSize: 11,
                                          color: isUnlocked ? Colors.black87 : Colors.black45,
                                        )),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Win98LargeButton(label: 'OK', onTap: () => Navigator.pop(context)),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: _Win98Window(
            title: 'Settings & Help',
            width: 320,
            onClose: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  final theme = GameThemes.getConfig(settings.currentTheme);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Show Next Balls (Preview)', style: TextStyle(color: theme.textMain)),
                          Checkbox(
                            value: settings.showNextBalls,
                            onChanged: (v) => settings.toggleShowNextBalls(),
                            checkColor: Colors.white,
                            activeColor: theme.titleStart,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Vibration (Haptics)', style: TextStyle(color: theme.textMain)),
                          Checkbox(
                            value: settings.hapticsEnabled,
                            onChanged: (v) => settings.toggleHaptics(),
                            checkColor: Colors.white,
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('HOW TO PLAY', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textMain)),
                      const SizedBox(height: 8),
                      Text(
                        '1. Tap a ball to select it, then tap an empty cell to move it.\n'
                        '2. The ball can only move if there is a clear path.\n'
                        '3. Form lines of 5+ balls to score points.\n'
                        '4. Game ends when board is full.',
                        style: TextStyle(fontSize: 12, color: theme.textMain),
                      ),
                      const SizedBox(height: 16),
                      _Win98LargeButton(label: 'OK', onTap: () => Navigator.pop(context)),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
// ── UI Components ─────────────────────────────────────────────────────────────

class _Win98Window extends StatelessWidget {
  final String title;
  final Widget child;
  final double width;
  final VoidCallback? onClose;

  const _Win98Window({
    required this.title,
    required this.child,
    required this.width,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, _) {
      final theme = GameThemes.getConfig(settings.currentTheme);
      return Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: theme.winBg,
            border: Border(
              top: BorderSide(color: theme.borderLight, width: 2),
              left: BorderSide(color: theme.borderLight, width: 2),
              right: BorderSide(color: theme.borderDarker, width: 2),
              bottom: BorderSide(color: theme.borderDarker, width: 2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title bar
              Container(
                height: 24,
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.titleStart, theme.titleEnd],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (onClose != null)
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 16, height: 14,
                          decoration: BoxDecoration(
                            color: theme.winBg,
                            border: Border(
                              top: BorderSide(color: theme.borderLight, width: 1),
                              left: BorderSide(color: theme.borderLight, width: 1),
                              right: BorderSide(color: theme.borderDarker, width: 1),
                              bottom: BorderSide(color: theme.borderDarker, width: 1),
                            ),
                          ),
                          child: Center(
                            child: Text('X', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textMain)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Body
              child,
            ],
          ),
        ),
      );
    });
  }
}

class _Win98Panel extends StatelessWidget {
  final Widget child;
  const _Win98Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, _) {
      final theme = GameThemes.getConfig(settings.currentTheme);
      return Container(
        decoration: BoxDecoration(
          color: theme.winBg,
          border: Border(
            top: BorderSide(color: theme.borderLight, width: 1.5),
            left: BorderSide(color: theme.borderLight, width: 1.5),
            right: BorderSide(color: theme.borderDark, width: 1.5),
            bottom: BorderSide(color: theme.borderDark, width: 1.5),
          ),
        ),
        child: child,
      );
    });
  }
}

class _Win98LargeButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const _Win98LargeButton({required this.label, this.onTap});

  @override
  State<_Win98LargeButton> createState() => _Win98LargeButtonState();
}

class _Win98LargeButtonState extends State<_Win98LargeButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Consumer<SettingsProvider>(builder: (context, settings, _) {
      final theme = GameThemes.getConfig(settings.currentTheme);
      return GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) {
          setState(() => _down = false);
          widget.onTap!();
        } : null,
        onTapCancel: () => setState(() => _down = false),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.winBg,
            border: Border(
              top: BorderSide(color: _down ? theme.borderDarker : theme.borderLight, width: 2),
              left: BorderSide(color: _down ? theme.borderDarker : theme.borderLight, width: 2),
              right: BorderSide(color: _down ? theme.borderLight : theme.borderDarker, width: 2),
              bottom: BorderSide(color: _down ? theme.borderLight : theme.borderDarker, width: 2),
            ),
          ),
          child: Center(
            widthFactor: 1.0,
            child: Padding(
              padding: _down ? const EdgeInsets.only(top: 1, left: 1) : EdgeInsets.zero,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: enabled ? theme.textMain : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
