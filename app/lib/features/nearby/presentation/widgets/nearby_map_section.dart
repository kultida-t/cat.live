import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/nearby_data.dart';
import 'nearby_category_chips.dart';
import 'nearby_l10n.dart';

/// แผนที่หน้าใกล้ฉัน — ใช้ได้ทั้งการ์ดย่อ (16:8) และโหมดเต็มจอพร้อมหมุดแยกสีและการ์ดพรีวิวด้านล่าง
class NearbyMapSection extends StatefulWidget {
  const NearbyMapSection({
    super.key,
    required this.centerLat,
    required this.centerLng,
    required this.places,
    required this.announcements,
    required this.showAnnouncementsOnMap,
    required this.isFullscreen,
    required this.selectedPinId,
    required this.selectedCategory,
    required this.isEn,
    required this.onToggleFullscreen,
    required this.onSelectPin,
    required this.onClearSelectedPin,
    required this.onToggleCategory,
    required this.onUseMyLocation,
    this.tileProvider,
  });

  final double centerLat;
  final double centerLng;
  final List<NearbyPlace> places;
  final List<NearbyAnnouncement> announcements;
  final bool showAnnouncementsOnMap;
  final bool isFullscreen;
  final String? selectedPinId;
  final NearbyCategory? selectedCategory;
  final bool isEn;
  final ValueChanged<bool> onToggleFullscreen;
  final ValueChanged<String> onSelectPin;
  final VoidCallback onClearSelectedPin;
  final ValueChanged<NearbyCategory> onToggleCategory;
  final VoidCallback onUseMyLocation;
  final TileProvider? tileProvider;

  @override
  State<NearbyMapSection> createState() => _NearbyMapSectionState();
}

class _NearbyMapSectionState extends State<NearbyMapSection> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  LatLng get _areaCenter => LatLng(widget.centerLat, widget.centerLng);

  @override
  void didUpdateWidget(covariant NearbyMapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isMapReady) return;

    if (oldWidget.centerLat != widget.centerLat ||
        oldWidget.centerLng != widget.centerLng) {
      _mapController.move(_areaCenter, widget.isFullscreen ? 15.6 : 15.0);
      return;
    }

    if (widget.selectedPinId != null &&
        widget.selectedPinId != oldWidget.selectedPinId) {
      final selectedLatLng = _latLngForPin(widget.selectedPinId!);
      if (selectedLatLng != null) {
        _mapController.move(selectedLatLng, 15.8);
      }
    }
  }

  LatLng? _latLngForPin(String pinId) {
    for (final p in widget.places) {
      if (p.id == pinId) return LatLng(p.latitude, p.longitude);
    }
    for (final a in widget.announcements) {
      if (a.id == pinId) return LatLng(a.latitude, a.longitude);
    }
    return null;
  }

  void _recenter() {
    if (_isMapReady) {
      _mapController.move(_areaCenter, widget.isFullscreen ? 15.4 : 15.0);
    }
  }

  Color _placePinColor(NearbyPlaceType type) {
    return switch (type) {
      NearbyPlaceType.clinic => AppColors.nearbyPinClinic,
      NearbyPlaceType.shop => AppColors.nearbyPinShop,
      NearbyPlaceType.grooming => AppColors.nearbyPinGrooming,
      NearbyPlaceType.boarding => AppColors.nearbyPinBoarding,
      NearbyPlaceType.cafe => AppColors.nearbyPinCafe,
    };
  }

  IconData _placePinIcon(NearbyPlaceType type) {
    return switch (type) {
      NearbyPlaceType.clinic => LucideIcons.hospital,
      NearbyPlaceType.shop => LucideIcons.shoppingBag,
      NearbyPlaceType.grooming => LucideIcons.scissors,
      NearbyPlaceType.boarding => LucideIcons.bedDouble,
      NearbyPlaceType.cafe => LucideIcons.coffee,
    };
  }

  Color _announcementPinColor(NearbyAnnouncementType type) {
    return switch (type) {
      NearbyAnnouncementType.lostCat => AppColors.nearbyPinLostCat,
      NearbyAnnouncementType.foundCat => AppColors.nearbyPinFoundCat,
      NearbyAnnouncementType.communityCat => AppColors.nearbyPinCommunityCat,
    };
  }

  IconData _announcementPinIcon(NearbyAnnouncementType type) {
    return switch (type) {
      NearbyAnnouncementType.lostCat => LucideIcons.megaphone,
      NearbyAnnouncementType.foundCat => LucideIcons.cat,
      NearbyAnnouncementType.communityCat => LucideIcons.heart,
    };
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildMapCore() {
    final markers = <Marker>[
      // จุดสีน้ำเงินตำแหน่งผู้ใช้ตรงกลางพื้นที่
      Marker(
        point: _areaCenter,
        width: 28,
        height: 28,
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.nearbyUserDot,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x384F86C6),
                  blurRadius: 0,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
      ...widget.places.map((p) {
        final isSelected = widget.selectedPinId == p.id;
        return Marker(
          point: LatLng(p.latitude, p.longitude),
          width: isSelected ? 40 : 34,
          height: isSelected ? 40 : 34,
          child: _TeardropPin(
            key: Key('nearby-pin-${p.id}'),
            color: _placePinColor(p.type),
            icon: _placePinIcon(p.type),
            isSelected: isSelected,
            onTap: () => widget.onSelectPin(p.id),
          ),
        );
      }),
      if (widget.showAnnouncementsOnMap)
        ...widget.announcements.map((a) {
          final isSelected = widget.selectedPinId == a.id;
          return Marker(
            point: LatLng(a.latitude, a.longitude),
            width: isSelected ? 40 : 34,
            height: isSelected ? 40 : 34,
            child: _TeardropPin(
              key: Key('nearby-pin-${a.id}'),
              color: _announcementPinColor(a.type),
              icon: _announcementPinIcon(a.type),
              isSelected: isSelected,
              onTap: () => widget.onSelectPin(a.id),
            ),
          );
        }),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        const _NearbyFallbackMapBackground(),
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _areaCenter,
            initialZoom: widget.isFullscreen ? 15.4 : 15.0,
            minZoom: 13,
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
              } else if (widget.selectedPinId != null) {
                widget.onClearSelectedPin();
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'live.cat.app',
              tileProvider: widget.tileProvider,
              errorTileCallback: (_, _, _) {},
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFullscreen) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AspectRatio(
          aspectRatio: 16 / 8,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildMapCore(),
                Positioned(
                  left: 10,
                  top: 10,
                  child: _MapActionPill(
                    key: const Key('nearby-inline-recenter-btn'),
                    icon: LucideIcons.locateFixed,
                    iconColor: AppColors.trackerSafeTeal,
                    label: NearbyL10n.recenterBtn(widget.isEn),
                    labelColor: AppColors.trackerSafeTeal,
                    onTap: () {
                      _recenter();
                      widget.onUseMyLocation();
                    },
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: _MapActionPill(
                    key: const Key('nearby-fullscreen-btn'),
                    icon: LucideIcons.map,
                    label: NearbyL10n.fullscreenBtn(widget.isEn),
                    onTap: () => widget.onToggleFullscreen(true),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // โหมดแผนที่เต็มจอ
    NearbyPlace? selectedPlace;
    NearbyAnnouncement? selectedAnnouncement;
    if (widget.selectedPinId != null) {
      for (final p in widget.places) {
        if (p.id == widget.selectedPinId) {
          selectedPlace = p;
          break;
        }
      }
      if (selectedPlace == null) {
        for (final a in widget.announcements) {
          if (a.id == widget.selectedPinId) {
            selectedAnnouncement = a;
            break;
          }
        }
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildMapCore(),
        // แถบหมวดหมู่ + ปุ่มใช้ตำแหน่งของฉันลอยด้านบน (ภาพ 2)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NearbyCategoryChips(
                    selectedCategory: widget.selectedCategory,
                    isEn: widget.isEn,
                    onToggleCategory: widget.onToggleCategory,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MapActionPill(
                          key: const Key('nearby-recenter-btn'),
                          icon: LucideIcons.locateFixed,
                          iconColor: AppColors.trackerSafeTeal,
                          label: NearbyL10n.recenterBtn(widget.isEn),
                          labelColor: AppColors.trackerSafeTeal,
                          onTap: () {
                            _recenter();
                            widget.onUseMyLocation();
                          },
                        ),
                        Material(
                          color: Colors.white.withValues(alpha: 0.96),
                          elevation: 3,
                          shadowColor: const Color(0x244A3428),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _recenter,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: const Icon(
                                LucideIcons.locateFixed,
                                size: 18,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ปุ่มดูรายการมุมขวาล่าง
        Positioned(
          right: 14,
          bottom: (selectedPlace != null || selectedAnnouncement != null)
              ? 112
              : 16,
          child: _MapActionPill(
            key: const Key('nearby-list-view-btn'),
            icon: LucideIcons.list,
            label: NearbyL10n.listBtn(widget.isEn),
            onTap: () => widget.onToggleFullscreen(false),
          ),
        ),
        // การ์ดพรีวิวแถวเดียวกะทัดรัดด้านล่าง (ภาพ 4)
        if (selectedPlace != null)
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: _MapPreviewCard(
              imageSource: selectedPlace.imageSource,
              categoryLabel: NearbyL10n.placeTypeLabel(
                selectedPlace.type,
                widget.isEn,
              ),
              distanceText: NearbyL10n.placeDistance(
                selectedPlace.distanceKm,
                isEn: widget.isEn,
              ),
              title: selectedPlace.name(widget.isEn),
              subtitle: selectedPlace.statusText(widget.isEn),
              onNavigate: () => _openGoogleMaps(
                selectedPlace!.latitude,
                selectedPlace.longitude,
              ),
              onClose: widget.onClearSelectedPin,
            ),
          )
        else if (selectedAnnouncement != null)
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: _MapPreviewCard(
              imageSource: selectedAnnouncement.imageSource,
              categoryLabel: NearbyL10n.announcementTypeLabel(
                selectedAnnouncement.type,
                widget.isEn,
              ),
              distanceText: formatNearbyDistance(
                selectedAnnouncement.distanceKm,
                isEn: widget.isEn,
              ),
              title: selectedAnnouncement.title(widget.isEn),
              subtitle: selectedAnnouncement.timeText(widget.isEn),
              onNavigate: () => _openGoogleMaps(
                selectedAnnouncement!.latitude,
                selectedAnnouncement.longitude,
              ),
              onClose: widget.onClearSelectedPin,
            ),
          ),
      ],
    );
  }
}

class _TeardropPin extends StatelessWidget {
  const _TeardropPin({
    super.key,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 34.0 : 28.0;
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(999),
                topRight: Radius.circular(999),
                bottomLeft: Radius.circular(999),
                bottomRight: Radius.zero,
              ),
              border: Border.all(
                color: isSelected ? AppColors.ink : Colors.white,
                width: isSelected ? 2.5 : 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E4A3428),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: Icon(
                  icon,
                  size: isSelected ? 16 : 13,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapActionPill extends StatelessWidget {
  const _MapActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.text,
    this.labelColor = AppColors.text,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 3,
      shadowColor: const Color(0x244A3428),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({
    required this.imageSource,
    required this.categoryLabel,
    required this.distanceText,
    required this.title,
    required this.subtitle,
    required this.onNavigate,
    required this.onClose,
  });

  final String imageSource;
  final String categoryLabel;
  final String distanceText;
  final String title;
  final String subtitle;
  final VoidCallback onNavigate;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('nearby-map-preview-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x244A3428),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: AppImage(source: imageSource),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$categoryLabel · $distanceText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            key: const Key('nearby-preview-navigate-btn'),
            onTap: onNavigate,
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.btn,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.btnBorder),
              ),
              child: const Icon(
                LucideIcons.navigation,
                size: 17,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            key: const Key('nearby-preview-close-btn'),
            onTap: onClose,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 34,
              height: 34,
              child: Icon(
                LucideIcons.x,
                size: 18,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyFallbackMapBackground extends StatelessWidget {
  const _NearbyFallbackMapBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FallbackGridPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _FallbackGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.trackerMapFallback,
    );

    final gridPaint = Paint()
      ..color = AppColors.trackerMapGrid
      ..strokeWidth = 1;
    for (double x = 24; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 24; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final roadPaint = Paint()
      ..color = AppColors.trackerMapRoad
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.45),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.42, 0),
      Offset(size.width * 0.52, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
