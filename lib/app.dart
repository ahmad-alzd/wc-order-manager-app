import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_placeholder_screen.dart';

class WcOrderManagerApp extends StatelessWidget {
  const WcOrderManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: MaterialApp(
        title: 'WC Order Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        // The UI text is Persian; rather than pull in
        // flutter_localizations just to set locale/MaterialLocalizations
        // for "fa", we force RTL directly. Fields that must stay LTR
        // (URL, API key/secret) override this per-widget.
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Decides which screen to show based on [AuthController.status]:
/// a loading screen while a saved session is being restored, the
/// login form, or (once Phase 5 lands) the orders list.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    context.read<AuthController>().tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthController>().status;

    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const HomePlaceholderScreen();
      case AuthStatus.authenticating:
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
