import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/notifications/device_token_repository.dart';
import 'features/notifications/push_notifications_service.dart';
import 'features/orders/orders_controller.dart';
import 'features/orders/orders_list_screen.dart';
import 'features/orders/orders_repository.dart';

/// Lets PushNotificationsService push a new route (opening an order
/// from a tapped notification) without needing a BuildContext from
/// inside the widget that receives the tap — that callback runs
/// outside any particular screen's build method, sometimes with the
/// app freshly launched and no screen built yet at all.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class WcOrderManagerApp extends StatelessWidget {
  const WcOrderManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        // These three depend only on AuthController (read lazily per
        // call) or on nothing at all, so they can live here — above
        // the Navigator — before login even happens. That matters
        // because a screen reached via Navigator.push later (e.g.
        // order detail, opened either by tapping a row or tapping a
        // notification) is a sibling route, not a descendant of
        // anything declared inside the authenticated branch below;
        // only providers declared up here are visible to it. See
        // OrdersRepository's doc comment.
        Provider<OrdersRepository>(
          create: (context) => OrdersRepository(context.read<AuthController>()),
        ),
        Provider<DeviceTokenRepository>(
          create: (context) => DeviceTokenRepository(context.read<AuthController>()),
        ),
        Provider<PushNotificationsService>(
          create: (_) {
            final service = PushNotificationsService(navigatorKey: navigatorKey);
            // Fire-and-forget: requesting permission and wiring up
            // listeners doesn't need to block first frame.
            service.initialize();
            return service;
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
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
        // Start sending this device's FCM token to the now-connected
        // store. Safe to call on every rebuild of this branch:
        // attachStore() just re-points the repository and resets the
        // refresh-token listener.
        context.read<PushNotificationsService>().attachStore(
              context.read<DeviceTokenRepository>(),
            );

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
        context.read<PushNotificationsService>().detachStore();
        return const LoginScreen();
    }
  }
}
