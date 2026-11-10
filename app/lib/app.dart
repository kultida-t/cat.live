import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class CatLiveApp extends StatefulWidget {
  const CatLiveApp({super.key});

  @override
  State<CatLiveApp> createState() => _CatLiveAppState();
}

class _CatLiveAppState extends State<CatLiveApp> {
  final _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'แมว.live',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
