import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ball.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/economy_provider.dart';
import 'ball_widget.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/game_themes.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, SettingsProvider>(
      builder: (context, gameProvider, settings, _) {
        final theme = GameThemes.getConfig(settings.currentTheme);
        return LayoutBuilder(
          builder: (context, constraints) {
            final double boardSize = constraints.maxWidth;
            final double cellSize  = boardSize / GameProvider.boardSize;
            final double ballSize  = cellSize * 0.80;

            return Stack(
              children: [
                Container(
              width: boardSize,
              height: boardSize,
              // Outer raised border
              decoration: BoxDecoration(
                color: theme.cellFace,
                border: Border(
                  top:    BorderSide(color: theme.borderLight, width: 2),
                  left:   BorderSide(color: theme.borderLight, width: 2),
                  right:  BorderSide(color: theme.borderDarker, width: 2),
                  bottom: BorderSide(color: theme.borderDarker, width: 2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: GameProvider.boardSize,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                  ),
                  itemCount: GameProvider.boardSize * GameProvider.boardSize,
                  itemBuilder: (context, index) {
                    final int x = index % GameProvider.boardSize;
                    final int y = index ~/ GameProvider.boardSize;

                    final settings = Provider.of<SettingsProvider>(context);
                    Ball? ball = gameProvider.board[y][x];
                    if (ball == null && settings.showNextBalls) {
                      try {
                        ball = gameProvider.nextBalls
                            .firstWhere((b) => b.x == x && b.y == y);
                      } catch (_) {}
                    }

                    final bool isSelected =
                        gameProvider.selectedPoint?.x == x &&
                        gameProvider.selectedPoint?.y == y;

                    return GestureDetector(
                      onTap: () {
                        final economy = Provider.of<EconomyProvider>(
                            context, listen: false);
                        gameProvider.selectCell(x, y, economy, haptics: settings.hapticsEnabled);
                      },
                      child: _Win98Cell(
                        isSelected: isSelected,
                        theme: theme,
                        child: ball != null
                            ? Padding(
                                padding: const EdgeInsets.all(2),
                                child: BallWidget(
                                  ball: ball,
                                  size: ball.isNext ? ballSize * 0.40 : ballSize,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            ...gameProvider.floatingScores.map((fs) {
              return Positioned(
                left: fs.position.x * cellSize + (cellSize / 2) - 20, // center horizontally
                top: fs.position.y * cellSize + (cellSize / 2) - 10,  // center vertically
                child: _FloatingScoreWidget(
                  key: ValueKey(fs.id),
                  score: fs.amount,
                  message: fs.message,
                  theme: theme,
                ),
              );
            }).toList(),
          ],
        );
      },
    );
      },
    );
  }
}

class _Win98Cell extends StatelessWidget {
  final bool isSelected;
  final ThemeConfig theme;
  final Widget? child;

  const _Win98Cell({required this.isSelected, required this.theme, this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CellPainter(isSelected: isSelected, theme: theme),
      child: Center(child: child),
    );
  }
}

class _CellPainter extends CustomPainter {
  final bool isSelected;
  final ThemeConfig theme;
  const _CellPainter({required this.isSelected, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = isSelected ? theme.cellSelect : theme.cellBg,
    );

    if (!isSelected) {
      // Sunken border: dark top-left, light bottom-right
      final pDark = Paint()
        ..color = theme.cellShadow
        ..strokeWidth = 1;
      final pLight = Paint()
        ..color = theme.borderLight
        ..strokeWidth = 1;

      // Top edge
      canvas.drawLine(Offset(0, 0), Offset(w, 0), pDark);
      // Left edge
      canvas.drawLine(Offset(0, 0), Offset(0, h), pDark);
      // Bottom edge
      canvas.drawLine(Offset(0, h - 1), Offset(w, h - 1), pLight);
      // Right edge
      canvas.drawLine(Offset(w - 1, 0), Offset(w - 1, h), pLight);
    } else {
      // Selected: bright yellow border
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = const Color(0xFFFFC107)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_CellPainter old) => old.isSelected != isSelected;
}

class _FloatingScoreWidget extends StatefulWidget {
  final int score;
  final String? message;
  final ThemeConfig theme;
  const _FloatingScoreWidget({Key? key, required this.score, this.message, required this.theme}) : super(key: key);

  @override
  State<_FloatingScoreWidget> createState() => _FloatingScoreWidgetState();
}

class _FloatingScoreWidgetState extends State<_FloatingScoreWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    _translateY = Tween<double>(begin: 0.0, end: -60.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateY.value),
          child: Opacity(
            opacity: _opacity.value,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+${widget.score}',
            style: GoogleFonts.getFont(
              widget.theme.titleFontFamily,
              color: widget.theme.scoreText,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              shadows: [
                const Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
                const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 0)),
              ],
            ),
          ),
          if (widget.message != null)
            Text(
              widget.message!,
              style: GoogleFonts.getFont(
                widget.theme.titleFontFamily,
                color: Colors.orangeAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [
                  const Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
                  const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 0)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
