import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/cat_ai_l10n.dart';

enum _VoiceCallStatus { listening, thinking, speaking, paused }

/// เปิดหน้าคุยกับหมอด้วยเสียงแบบเต็มจอ (ทับแถบเมนูล่าง)
Future<void> showCatVoiceCallPage(
  BuildContext context, {
  required String catName,
  required String catPhoto,
  required bool isEn,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) =>
          CatVoiceCallPage(catName: catName, catPhoto: catPhoto, isEn: isEn),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// หน้าคุยกับหมอด้วยเสียงแบบเต็มจอ (UI ตัวอย่าง — ยังไม่ต่อไมค์และเสียงพูดจริง)
class CatVoiceCallPage extends StatefulWidget {
  const CatVoiceCallPage({
    super.key,
    required this.catName,
    required this.catPhoto,
    required this.isEn,
  });

  final String catName;
  final String catPhoto;
  final bool isEn;

  @override
  State<CatVoiceCallPage> createState() => _CatVoiceCallPageState();
}

class _CatVoiceCallPageState extends State<CatVoiceCallPage>
    with TickerProviderStateMixin {
  _VoiceCallStatus _status = _VoiceCallStatus.speaking;
  int _elapsedSeconds = 0;
  String? _lastUserText;
  String? _lastAiReply;

  Timer? _clockTimer;
  Timer? _phaseTimer;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _lastAiReply = CatAiL10n.voiceCallGreeting(widget.catName, widget.isEn);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
    _scheduleListening(const Duration(milliseconds: 2200));
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _phaseTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _scheduleListening(Duration delay) {
    _phaseTimer?.cancel();
    _phaseTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() => _status = _VoiceCallStatus.listening);
    });
  }

  void _toggleMute() {
    if (_status == _VoiceCallStatus.thinking ||
        _status == _VoiceCallStatus.speaking) {
      return;
    }
    setState(() {
      _status = _status == _VoiceCallStatus.paused
          ? _VoiceCallStatus.listening
          : _VoiceCallStatus.paused;
    });
  }

  void _sendSample() {
    if (_status != _VoiceCallStatus.listening) return;
    _phaseTimer?.cancel();
    setState(() => _status = _VoiceCallStatus.thinking);
    _phaseTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _lastUserText = CatAiL10n.voiceCallSamplePrompt(
          widget.catName,
          widget.isEn,
        );
        _lastAiReply = CatAiL10n.voiceCallSampleReply(
          widget.catName,
          widget.isEn,
        );
        _status = _VoiceCallStatus.speaking;
      });
      _scheduleListening(const Duration(milliseconds: 2400));
    });
  }

  String get _formattedTime {
    final min = _elapsedSeconds ~/ 60;
    final sec = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  String get _statusText => switch (_status) {
    _VoiceCallStatus.listening => CatAiL10n.voiceCallListening(widget.isEn),
    _VoiceCallStatus.thinking => CatAiL10n.voiceCallThinking(widget.isEn),
    _VoiceCallStatus.speaking => CatAiL10n.voiceCallSpeaking(widget.isEn),
    _VoiceCallStatus.paused => CatAiL10n.voiceCallPaused(widget.isEn),
  };

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final isMuted = _status == _VoiceCallStatus.paused;
    final muteDisabled =
        _status == _VoiceCallStatus.thinking ||
        _status == _VoiceCallStatus.speaking;
    final canSend = _status == _VoiceCallStatus.listening;

    return Semantics(
      label: CatAiL10n.voiceCallDialogLabel(widget.catName, isEn),
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.55, 1],
              colors: [
                AppColors.catAiVoiceBgStart,
                AppColors.catAiGradientMid,
                AppColors.catAiGradientEnd,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.stethoscope,
                              size: 16,
                              color: AppColors.catAiSparkEnd,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              CatAiL10n.voiceCallBadge(isEn),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.catAiSparkEnd,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formattedTime,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (!reduce &&
                                  _status == _VoiceCallStatus.speaking) ...[
                                _PingCircle(
                                  animation: _pulseCtrl,
                                  size: 196,
                                  delay: 0,
                                ),
                                _PingCircle(
                                  animation: _pulseCtrl,
                                  size: 164,
                                  delay: 0.35,
                                ),
                              ],
                              if (!reduce &&
                                  _status == _VoiceCallStatus.listening)
                                AnimatedBuilder(
                                  animation: _pulseCtrl,
                                  builder: (_, _) {
                                    final scale =
                                        1 +
                                        0.08 *
                                            (0.5 -
                                                (_pulseCtrl.value - 0.5)
                                                    .abs()) *
                                            2;
                                    return Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        width: 176,
                                        height: 176,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              AppColors.catAiMicLight
                                                  .withValues(alpha: 0.45),
                                              AppColors.catAiMicLight
                                                  .withValues(alpha: 0),
                                            ],
                                            stops: const [0.55, 0.9],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              AnimatedOpacity(
                                opacity: _status == _VoiceCallStatus.thinking
                                    ? 0.72
                                    : 1,
                                duration: const Duration(milliseconds: 240),
                                child: Container(
                                  width: 132,
                                  height: 132,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.catAiSparkEnd
                                            .withValues(alpha: 0.35),
                                        blurRadius: 32,
                                        offset: const Offset(0, 14),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      widget.catPhoto,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _statusText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.catAiSparkEnd,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 96,
                            maxWidth: 320,
                          ),
                          child: Column(
                            children: [
                              if (_lastUserText != null) ...[
                                Text(
                                  '${CatAiL10n.voiceCallYouPrefix(isEn)}$_lastUserText',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                              if (_lastAiReply != null)
                                Text(
                                  _lastAiReply!,
                                  textAlign: TextAlign.center,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: AppColors.text,
                                  ),
                                ),
                              if (_status == _VoiceCallStatus.listening) ...[
                                const SizedBox(height: 8),
                                Text(
                                  CatAiL10n.voiceCallAutoSendHint(isEn),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _VoiceActionButton(
                        icon: isMuted ? LucideIcons.micOff : LucideIcons.mic,
                        label: isMuted
                            ? CatAiL10n.voiceCallUnmute(isEn)
                            : CatAiL10n.voiceCallMute(isEn),
                        background: isMuted ? AppColors.text : Colors.white,
                        foreground: isMuted ? Colors.white : AppColors.text,
                        disabled: muteDisabled,
                        onTap: _toggleMute,
                      ),
                      const SizedBox(width: 28),
                      _VoiceActionButton(
                        icon: LucideIcons.arrowUp,
                        label: CatAiL10n.voiceCallSend(isEn),
                        background: AppColors.catAiSparkEnd,
                        foreground: Colors.white,
                        disabled: !canSend,
                        onTap: _sendSample,
                      ),
                      const SizedBox(width: 28),
                      _VoiceActionButton(
                        icon: LucideIcons.phoneOff,
                        label: CatAiL10n.voiceCallEnd(isEn),
                        background: AppColors.catAiVoiceEndCall,
                        foreground: Colors.white,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    CatAiL10n.voiceCallDisclaimer(isEn),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PingCircle extends StatelessWidget {
  const _PingCircle({
    required this.animation,
    required this.size,
    required this.delay,
  });

  final Animation<double> animation;
  final double size;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final t = (animation.value + delay) % 1.0;
        return Transform.scale(
          scale: 0.72 + t * 0.38,
          child: Opacity(
            opacity: (1 - t) * 0.45,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: AppColors.catAiMicLight,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VoiceActionButton extends StatelessWidget {
  const _VoiceActionButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: label,
          child: Opacity(
            opacity: disabled ? 0.38 : 1,
            child: Material(
              color: background,
              shape: const CircleBorder(),
              elevation: 4,
              shadowColor: AppColors.text.withValues(alpha: 0.18),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: disabled ? null : onTap,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Icon(icon, size: 28, color: foreground),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: AppColors.text2),
        ),
      ],
    );
  }
}
