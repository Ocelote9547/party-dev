import 'package:flutter/material.dart';

import '../services/streak_service.dart';
import '../theme/party_theme.dart';
import '../widgets/group_section.dart';
import '../widgets/party_logo.dart';
import '../widgets/play_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onPlayPressed;
  final VoidCallback? onGroupPressed;
  final VoidCallback? onExtrasPressed;
  final List<String> players;

  const HomeScreen({
    super.key,
    required this.onPlayPressed,
    required this.players,
    this.onGroupPressed,
    this.onExtrasPressed,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _streak = 0;
  DailyChallenge? _challenge;
  int _progress = 0;
  bool _claimed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final streak = await StreakService.instance.getStreak();
    final challenge = StreakService.instance.getDailyChallenge();
    final progress = await StreakService.instance.getDailyProgress();
    final claimed = await StreakService.instance.isDailyClaimed();
    if (!mounted) return;
    setState(() {
      _streak = streak;
      _challenge = challenge;
      _progress = progress;
      _claimed = claimed;
      _loading = false;
    });
  }

  Future<void> _claim() async {
    final ok = await StreakService.instance.claimDaily();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡+15 monedas reclamadas!'),
          backgroundColor: PartyColors.surface,
        ),
      );
      await _load();
    } else {
      final alreadyClaimed = await StreakService.instance.isDailyClaimed();
      if (!mounted) return;
      if (alreadyClaimed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ya reclamaste hoy'),
            backgroundColor: PartyColors.surface,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Completa el desafío para reclamar'),
            backgroundColor: PartyColors.surface,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: PartyColors.scaffoldGradient,
          stops: const [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -180,
            right: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    PartyColors.primary.withValues(alpha: 0.13),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -220,
            left: -180,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF087C9A).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 120),
              child: Column(
                children: [
                  const PartyLogo(),
                  const SizedBox(height: 18),
                  _buildStreakBadge(),
                  const SizedBox(height: 16),
                  _buildDailyCard(),
                  const SizedBox(height: 20),
                  PlayCard(onTap: widget.onPlayPressed),
                  const SizedBox(height: 16),
                  GroupSection(players: widget.players),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge() {
    final streakText = _loading ? '🔥 x—' : '🔥 x$_streak';
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: PartyColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PartyColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              streakText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: PartyColors.text,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _streak == 0
                  ? '¡Juega hoy!'
                  : _streak == 1
                      ? 'racha'
                      : 'días',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PartyColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCard() {
    if (_loading || _challenge == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PartyColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PartyColors.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: PartyColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cargando desafío...',
              style: TextStyle(color: PartyColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final challenge = _challenge!;
    final target = challenge.target;
    final progress = _progress.clamp(0, target);
    final pct = target == 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);
    final isCompleted = progress >= target;
    final canClaim = isCompleted && !_claimed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PartyColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _claimed
              ? PartyColors.success.withValues(alpha: 0.35)
              : PartyColors.primary.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PartyColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PartyColors.primary.withValues(alpha: 0.25)),
                ),
                child: const Text(
                  'DAILY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: PartyColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (_claimed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PartyColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Reclamado ✓',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: PartyColors.success,
                    ),
                  ),
                )
              else
                Text(
                  '$progress / $target',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: PartyColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            challenge.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: PartyColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            challenge.description,
            style: TextStyle(fontSize: 12, color: PartyColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct.toDouble(),
              minHeight: 8,
              backgroundColor: PartyColors.border.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(
                _claimed ? PartyColors.success : PartyColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _claimed
                  ? null
                  : canClaim
                      ? _claim
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: PartyColors.primary,
                foregroundColor: PartyColors.onPrimary,
                disabledBackgroundColor: PartyColors.border,
                disabledForegroundColor: PartyColors.textMuted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: canClaim ? 2 : 0,
              ),
              child: Text(
                _claimed
                    ? 'Reclamado'
                    : canClaim
                        ? 'Reclamar +15 🪙'
                        : 'Progreso $progress/$target',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
