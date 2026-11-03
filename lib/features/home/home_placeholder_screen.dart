import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';

/// Stand-in for the real orders list, which lands in Phase 5. Its job
/// right now is just to prove the login flow works end-to-end: it
/// shows which store we're connected to and lets the user log out.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(auth.siteName ?? 'فروشگاه'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'خروج',
            onPressed: () => context.read<AuthController>().logout(),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'اتصال با موفقیت انجام شد.\nصفحه لیست سفارشات در فاز بعد اضافه می‌شود.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
