library;

import 'package:flutter/material.dart';
import '../l10n/l10n_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../themes/colors.dart';

class AppErrorScreen extends ConsumerWidget {
  const AppErrorScreen({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: JewelryColors.darkGradient,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: JewelryColors.error.withOpacity(0.8),
              ),
              const SizedBox(height: 20),
              Text(
                ref.tr('app_error_title'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (_) => false);
                },
                icon: const Icon(Icons.refresh),
                label: Text(ref.tr('retry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JewelryColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
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
