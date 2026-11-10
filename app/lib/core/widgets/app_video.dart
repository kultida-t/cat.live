import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_colors.dart';

/// เล่นวิดีโอจาก URL, `asset:<path>` หรือ `file:<path>`
/// [autoplayLoop] = เล่นวนแบบปิดเสียง (ตัวอย่างตอนเลือกคลิป) ไม่งั้นแตะเพื่อเล่น/หยุด
class AppVideo extends StatefulWidget {
  const AppVideo({
    super.key,
    required this.source,
    this.autoplayLoop = false,
    this.semanticLabel,
  });

  final String source;
  final bool autoplayLoop;
  final String? semanticLabel;

  @override
  State<AppVideo> createState() => _AppVideoState();
}

class _AppVideoState extends State<AppVideo> {
  late final VideoPlayerController _controller = _create(widget.source);
  late final Future<void> _ready = _init();

  static VideoPlayerController _create(String source) {
    if (source.startsWith('file:')) {
      return VideoPlayerController.file(File(source.substring(5)));
    }
    if (source.startsWith('asset:')) {
      return VideoPlayerController.asset(source.substring(6));
    }
    return VideoPlayerController.networkUrl(Uri.parse(source));
  }

  Future<void> _init() async {
    await _controller.initialize();
    if (widget.autoplayLoop) {
      await _controller.setVolume(0);
      await _controller.setLooping(true);
      await _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.autoplayLoop) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      child: ColoredBox(
        color: Colors.black,
        child: FutureBuilder<void>(
          future: _ready,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Icon(LucideIcons.videoOff, color: AppColors.unchecked),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
              );
            }
            return GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  if (!widget.autoplayLoop)
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: _controller,
                      builder: (_, value, _) => value.isPlaying
                          ? const SizedBox.shrink()
                          : Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0x8C000000),
                              ),
                              child: const Icon(
                                LucideIcons.play,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
