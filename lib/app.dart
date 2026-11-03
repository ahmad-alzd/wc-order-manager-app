import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/orders/orders_controller.dart';
import 'features/orders/orders_list_screen.dart';
import 'features/orders/orders_repository.dart';

class WcOrderManagerApp extends StatelessWidget {
  const WcOrderManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        // Depends only on AuthController (read lazily per call), so it
        // can live here — above the Navigator — before login even
        // happens. That matters because a screen reached via
        // Navigator.push later (e.g. order detail) is a sibling route,
        // not a descendant of anything declared inside the
        // authenticated branch below; only providers declared up here
        // are visible to it. See OrdersRepository's doc comment.
        Provider<OrdersRepository>(
          create: (context) => OrdersRepository(context.read<AuthController>()),
        ),
      ],
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
        // (URL, API key/secret, prices) override this per-widget.
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Decides which screen to show based on [AuthController.status]: a
/// loading screen while a saved session is being restored, the login
/// form, or the orders list once authenticated.
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
        return ChangeNotifierProvider<OrdersController>(
          // Scoped to this route only: nothing pushed via
          // Navigator.push from the orders list needs the *list*
          // state, only the repository above, so this doesn't hit the
          // same visibility problem.
          create: (context) {
            final controller = OrdersController(context.read<OrdersRepository>());
            controller.loadStatusOptions();
            controller.refresh();
            return controller;
          },
          child: const OrdersListScreen(),
        );
      case AuthStatus.authenticating:
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
