import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_locale.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/presentation/splash_overlay.dart';

class CatLiveApp extends ConsumerStatefulWidget {
  const CatLiveApp({super.key, this.showSplash = true});

  final bool showSplash;

  @override
  ConsumerState<CatLiveApp> createState() => _CatLiveAppState();
}

class _CatLiveAppState extends ConsumerState<CatLiveApp> {
  final _router = createAppRouter();
  late bool _showSplash = widget.showSplash;

  @override
  Widget build(BuildContext context) {
    final isEn = ref.watch(appLocaleProvider) == 'en';

    return MaterialApp.router(
      title: 'แมว.live',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            if (_showSplash)
              SplashOverlay(
                isEn: isEn,
                onFinished: () {
                  if (mounted) setState(() => _showSplash = false);
                },
              ),
          ],
        );
      },
    );
  }
}
