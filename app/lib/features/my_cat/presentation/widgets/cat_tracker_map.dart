import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/my_cat_data.dart';
import 'my_cat_l10n.dart';

/// แผนที่ OpenStreetMap แสดงตำแหน่งบ้าน เขตปลอดภัย และหมุดรูปแมวแต่ละตัว
class CatTrackerMap extends StatefulWidget {
  const CatTrackerMap({
    super.key,
    required this.cats,
    required this.selectedCat,
    required this.isFullscreen,
    required this.isEn,
    required this.onToggleFullscreen,
    required this.onSelectCat,
    this.tileProvider,
  });

  final List<CatProfile> cats;
  final CatProfile? selectedCat;
  final bool isFullscreen;
  final bool isEn;
  final ValueChanged<bool> onToggleFullscreen;
  final ValueChanged<CatProfile> onSelectCat;
  final TileProvider? tileProvider;

  static const homeLatLng = LatLng(13.7796, 100.5447);
  static const defaultCenter = LatLng(13.7787, 100.5453);

  @override
  State<CatTrackerMap> createState() => _CatTrackerMapState();
}

class _CatTrackerMapState extends State<CatTrackerMap> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  @override
  void didUpdateWidget(covariant CatTrackerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isMapReady) return;
    final nextCat = widget.selectedCat;
    if (nextCat != null &&
        nextCat.id != oldWidget.selectedCat?.id &&
        nextCat.trackerInfo.hasTag) {
      final target = LatLng(
        nextCat.trackerInfo.latitude,
        nextCat.trackerInfo.longitude,
      );
      _mapController.move(target, widget.isFullscreen ? 16.8 : 16.4);
    } else if (nextCat == null && oldWidget.selectedCat != null) {
      _mapController.move(CatTrackerMap.defaultCenter, 16.1);
    }
  }

  List<LatLng> _safeZoneRingPoints(double radiusMeters) {
    const distance = Distance();
    const steps = 64;
    return [
      for (var i = 0; i <= steps; i++)
        distance.offset(
          CatTrackerMap.homeLatLng,
          radiusMeters,
          (360 / steps) * i,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeCat = widget.selectedCat;
    final showSafeZone = activeCat != null && activeCat.trackerInfo.hasTag;
    final isSafe = activeCat?.trackerStatus != CatTrackerStatus.outOfZone;
    final safeRadius = (activeCat?.trackerInfo.safeZoneRadiusMeters ?? 100)
        .toDouble();
    final safeZoneBorderColor = isSafe
        ? AppColors.trackerSafeTeal
        : AppColors.heart;
    final safeZoneFillColor = isSafe
        ? AppColors.trackerSafeZoneFill
        : AppColors.trackerOutZoneFill;

    final taggedCats = widget.cats.where((c) => c.trackerInfo.hasTag).toList();
    // วางหมุดที่เลือกไว้ท้ายสุดเพื่อให้ซ้อนอยู่ด้านบนเสมอ
    taggedCats.sort((a, b) {
      if (a.id == activeCat?.id) return 1;
      if (b.id == activeCat?.id) return -1;
      return 0;
    });

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // พื้นหลังแผนที่สำรองเมื่อยังโหลดภาพไม่เสร็จหรือออฟไลน์
          const _AriFallbackMapBackground(),
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: CatTrackerMap.defaultCenter,
              initialZoom: 16.1,
              minZoom: 14,
              maxZoom: 18.5,
              interactionOptions: InteractionOptions(
                flags: widget.isFullscreen
                    ? InteractiveFlag.all & ~InteractiveFlag.rotate
                    : InteractiveFlag.none,
              ),
              onMapReady: () => _isMapReady = true,
              onTap: (_, _) {
                if (!widget.isFullscreen) {
                  widget.onToggleFullscreen(true);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'live.maew.app',
                tileProvider: widget.tileProvider,
                evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                errorTileCallback: (_, _, _) {},
              ),
              if (showSafeZone) ...[
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: CatTrackerMap.homeLatLng,
                      radius: safeRadius,
                      useRadiusInMeter: true,
                      color: safeZoneFillColor,
                      borderStrokeWidth: 0,
                    ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _safeZoneRingPoints(safeRadius),
                      color: safeZoneBorderColor,
                      strokeWidth: 2,
                      pattern: StrokePattern.dashed(segments: const [7, 5]),
                    ),
                  ],
                ),
              ],
              MarkerLayer(
                markers: [
                  Marker(
                    point: CatTrackerMap.homeLatLng,
                    width: 34,
                    height: 34,
                    child: Semantics(
                      label: widget.isEn ? 'Home' : 'บ้าน',
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.trackerHomePin,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.card, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x334A3428),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.house,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  for (final cat in taggedCats)
                    Marker(
                      point: LatLng(
                        cat.trackerInfo.latitude,
                        cat.trackerInfo.longitude,
                      ),
                      width: 58,
                      height: 62,
                      alignment: Alignment.topCenter,
                      child: _CatMapPin(
                        cat: cat,
                        selected: cat.id == activeCat?.id,
                        isEn: widget.isEn,
                        onTap: () => widget.onSelectCat(cat),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // จับการแตะทั่วพื้นที่แผนที่ในโหมดปกติเพื่อขยายเต็มจอ (ปล่อยหมุดให้กดเลือกแมวได้)
          if (!widget.isFullscreen)
            Positioned(
              right: 12,
              bottom: 30,
              child: Semantics(
                button: true,
                label: widget.isEn
                    ? 'Tap map for full screen'
                    : 'แตะเพื่อดูแผนที่เต็มจอ',
                child: Material(
                  color: const Color(0xE6FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                  elevation: 1,
                  child: InkWell(
                    onTap: () => widget.onToggleFullscreen(true),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text(
                        widget.isEn
                            ? 'Tap for full screen'
                            : 'แตะเพื่อดูเต็มจอ',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (widget.isFullscreen)
            Positioned(
              top: 12,
              right: 12,
              child: Semantics(
                button: true,
                label: widget.isEn ? 'Minimize map' : 'ย่อแผนที่',
                child: Material(
                  color: const Color(0xF2FFFFFF),
                  shape: const CircleBorder(),
                  shadowColor: const Color(0x3D4A3428),
                  elevation: 4,
                  child: InkWell(
                    onTap: () => widget.onToggleFullscreen(false),
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        LucideIcons.minimize2,
                        size: 20,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 10,
            bottom: 28,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xCCFFFFFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '© OpenStreetMap',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatMapPin extends StatelessWidget {
  const _CatMapPin({
    required this.cat,
    required this.selected,
    required this.isEn,
    required this.onTap,
  });

  final CatProfile cat;
  final bool selected;
  final bool isEn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pinColor = cat.trackerStatus == CatTrackerStatus.outOfZone
        ? AppColors.heart
        : AppColors.ink;
    final name = MyCatL10n.catName(cat.name, isEn);

    return Semantics(
      button: true,
      selected: selected,
      label: isEn ? 'Locate $name on map' : 'ดูตำแหน่ง$nameบนแผนที่',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.1 : 0.9,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: pinColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D5A4030),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: AppAvatar(
                    source: cat.avatarSource,
                    bg: cat.avatarBg,
                    size: 38,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -5),
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: pinColor,
                      border: const Border(
                        right: BorderSide(color: AppColors.card, width: 2),
                        bottom: BorderSide(color: AppColors.card, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AriFallbackMapBackground extends StatelessWidget {
  const _AriFallbackMapBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AriMapFallbackPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _AriMapFallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.trackerMapFallback,
    );

    final gridPaint = Paint()
      ..color = AppColors.trackerMapGrid
      ..strokeWidth = 1;
    for (double x = 28; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 24; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final roadPaint = Paint()
      ..color = AppColors.trackerMapRoad
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    canvas.drawLine(
      Offset(0, size.height * 0.34),
      Offset(size.width, size.height * 0.42),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.36, size.height),
      roadPaint..strokeWidth = 8,
    );
    canvas.drawLine(
      Offset(size.width * 0.68, 0),
      Offset(size.width * 0.58, size.height),
      roadPaint..strokeWidth = 6,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
