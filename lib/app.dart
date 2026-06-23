import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

class SimkApp extends StatefulWidget {
  const SimkApp({super.key});

  @override
  State<SimkApp> createState() => _SimkAppState();
}

class _SimkAppState extends State<SimkApp> {
  final AuthProvider _authProvider = AuthProvider();
  late final GoRouter _router = AppRouter.create(_authProvider);

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authProvider,
      child: MaterialApp.router(
        title: 'SIMK - Manajemen Katering',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
