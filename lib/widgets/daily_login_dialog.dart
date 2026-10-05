import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/economy_provider.dart';
import '../utils/app_colors.dart';

class DailyLoginDialog extends StatelessWidget {
  const DailyLoginDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Consumer<EconomyProvider>(
        builder: (context, economy, child) {
          return Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.boardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassmorphismBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DAILY REWARD',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.amberAccent.withOpacity(0.5),
                        blurRadius: 10,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login 7 days to get a huge reward!',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                // 7 Days Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final isToday = day == economy.loginStreak;
                    final isPast = day < economy.loginStreak;
                    final isClaimed = isPast || (isToday && economy.hasClaimedToday);
                    
                    if (day == 7) {
                      return _buildDay7Card(isToday, isClaimed);
                    }
                    return _buildDayCard(day, isToday, isClaimed);
                  },
                ),
                const SizedBox(height: 24),
                
                if (!economy.hasClaimedToday)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    onPressed: () {
                      economy.claimDailyReward();
                    },
                    child: Text(
                      'CLAIM REWARD',
                      style: GoogleFonts.outfit(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.glassmorphismColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'CLOSE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayCard(int day, bool isToday, bool isClaimed) {
    String rewardText = '';
    IconData iconData = Icons.monetization_on;
    Color iconColor = Colors.amber;

    switch (day) {
      case 1: rewardText = '50'; break;
      case 2: rewardText = '100'; break;
      case 3: rewardText = '1'; iconData = Icons.hardware; iconColor = Colors.blueAccent; break;
      case 4: rewardText = '150'; break;
      case 5: rewardText = '1'; iconData = Icons.brush; iconColor = Colors.greenAccent; break;
      case 6: rewardText = '200'; break;
    }

    return _buildCardWrapper(
      day: day,
      isToday: isToday,
      isClaimed: isClaimed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: isClaimed ? iconColor.withOpacity(0.5) : iconColor, size: 36),
          const SizedBox(height: 8),
          Text(
            rewardText,
            style: GoogleFonts.outfit(
              color: isClaimed ? Colors.white54 : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDay7Card(bool isToday, bool isClaimed) {
    return _buildCardWrapper(
      day: 7,
      isToday: isToday,
      isClaimed: isClaimed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monetization_on, color: isClaimed ? Colors.amber.withOpacity(0.5) : Colors.amber, size: 24),
              const SizedBox(width: 4),
              Icon(Icons.undo, color: isClaimed ? Colors.purpleAccent.withOpacity(0.5) : Colors.purpleAccent, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'BIG BOX',
            style: GoogleFonts.outfit(
              color: isClaimed ? Colors.white54 : Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({required int day, required bool isToday, required bool isClaimed, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isClaimed 
            ? AppColors.cellBackground.withOpacity(0.5) 
            : (isToday ? Colors.amber.withOpacity(0.2) : AppColors.cellBackground),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday && !isClaimed ? Colors.amber : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Center(child: child),
          Positioned(
            top: 6,
            left: 8,
            child: Text(
              'D$day',
              style: GoogleFonts.inter(
                color: isClaimed ? Colors.white38 : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isClaimed)
            Positioned(
              bottom: 6,
              right: 6,
              child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
            ),
        ],
      ),
    );
  }
}
