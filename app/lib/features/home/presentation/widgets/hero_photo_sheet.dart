import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/hero_photo.dart';
import '../providers/home_controller.dart';

/// ชีตเลือกรูปหน้าแรก: น้องแมวของฉัน + อัปโหลด + รูปจากแมว.live + สวิตช์สลับอัตโนมัติ
Future<void> showHeroPhotoSheet(
  BuildContext context, {
  ValueChanged<String>? onMessage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _HeroPhotoSheet(onMessage: onMessage),
  );
}

class _HeroPhotoSheet extends ConsumerWidget {
  const _HeroPhotoSheet({this.onMessage});

  final ValueChanged<String>? onMessage;

  Future<void> _pickFromDevice(BuildContext context, WidgetRef ref) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      ref.read(homeControllerProvider.notifier).setUploadedPhoto(picked.path);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      onMessage?.call('ไม่สามารถเปิดคลังรูปภาพได้');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final activeId = state.activeHeroPhoto.id;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'รูปหน้าแรก',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'ปิด',
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.soft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.x,
                              size: 20,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'น้องแมวของฉัน',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final cat in state.gallery.myCats) ...[
                    Expanded(
                      child: _PhotoTile(
                        option: cat,
                        selected: activeId == cat.id,
                        onTap: () {
                          controller.selectCustomPhoto(cat);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: _UploadTile(
                      selected: activeId == 'custom-upload',
                      onTap: () => _pickFromDevice(context, ref),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'รูปจากแมว.live',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < state.gallery.presets.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _PhotoTile(
                        option: state.gallery.presets[i],
                        selected: activeId == state.gallery.presets[i].id,
                        onTap: () {
                          controller.selectPreset(state.gallery.presets[i]);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สลับรูปอัตโนมัติ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'วนรูปจากแมว.live ทุก 4–5 วินาที',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      toggled: state.autoRotate,
                      label: 'สลับรูปอัตโนมัติ',
                      child: Switch.adaptive(
                        value: state.autoRotate,
                        activeTrackColor: AppColors.ink,
                        onChanged: controller.setAutoRotate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final HeroPhotoOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: option.label ?? option.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: selected ? const EdgeInsets.all(2) : EdgeInsets.zero,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: selected
                  ? Border.all(color: AppColors.text, width: 3)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(selected ? 13 : 16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    source: option.imageSource,
                    cacheWidth: 240,
                    semanticLabel: option.semanticLabel,
                  ),
                  if (option.label != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(6, 12, 6, 5),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0x8C000000), Colors.transparent],
                          ),
                        ),
                        child: Text(
                          option.label!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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

class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'อัปโหลดรูปหน้าแรก',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _DashedRectPainter(
              color: selected ? AppColors.text : AppColors.line2,
              strokeWidth: selected ? 2.5 : 1.5,
              radius: 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.upload, size: 20, color: AppColors.text2),
                  SizedBox(height: 4),
                  Text(
                    'อัปโหลด',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text2,
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

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius;
}
