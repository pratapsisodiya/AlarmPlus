import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PremiumFeature {
  dailyWakePlanner,
  weeklyWakePlanner,
  sleepCoachPro,
  adaptiveAlarmTuning,
  rotatingAlarmSounds,
  weekendDriftGuard,
  recoveryDayPlanner,
  smartDismissModes,
}

class PremiumService {
  static const lifetimePriceInr = 299;
  static const _premiumUnlockedKey = 'premium.lifetime.unlocked';
  static const _productId = 'alarm_plus_lifetime_premium';

  // ─── Local unlock state ──────────────────────────────────────────────────────

  static Future<bool> isLifetimePremiumUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumUnlockedKey) ?? false;
  }

  static Future<void> unlockLifetimePremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumUnlockedKey, true);
  }

  static Future<void> lockLifetimePremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumUnlockedKey, false);
  }

  static Future<bool> canUse(PremiumFeature feature) async {
    return isLifetimePremiumUnlocked();
  }

  // ─── IAP purchase flow ───────────────────────────────────────────────────────

  /// Initiates a real Google Play / App Store purchase.
  /// Returns true when the purchase completes successfully.
  static Future<bool> purchaseLifetimePremium(BuildContext context) async {
    final iap = InAppPurchase.instance;

    final available = await iap.isAvailable();
    if (!available) {
      if (context.mounted) {
        _showSnack(context, 'Store not available. Check your connection.');
      }
      return false;
    }

    final response = await iap.queryProductDetails({_productId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      if (context.mounted) {
        _showSnack(context, 'Product not found. Please try again later.');
      }
      debugPrint('IAP product not found: ${response.notFoundIDs}');
      return false;
    }

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);

    final completer = Completer<bool>();
    late StreamSubscription<List<PurchaseDetails>> sub;

    sub = iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.productID != _productId) continue;

        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await iap.completePurchase(purchase);
          await unlockLifetimePremium();
          if (!completer.isCompleted) completer.complete(true);
          await sub.cancel();
          return;
        }

        if (purchase.status == PurchaseStatus.error) {
          if (!completer.isCompleted) completer.complete(false);
          await sub.cancel();
          return;
        }

        if (purchase.status == PurchaseStatus.canceled) {
          if (!completer.isCompleted) completer.complete(false);
          await sub.cancel();
          return;
        }
      }
    }, onError: (_) async {
      if (!completer.isCompleted) completer.complete(false);
      await sub.cancel();
    });

    final started = await iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      await sub.cancel();
      return false;
    }

    // Wait for up to 5 minutes for user to complete payment in the store UI.
    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () async {
        await sub.cancel();
        return false;
      },
    );
  }

  /// Restores existing purchases (users who reinstalled the app).
  static Future<bool> restorePurchases(BuildContext context) async {
    final iap = InAppPurchase.instance;

    final available = await iap.isAvailable();
    if (!available) {
      if (context.mounted) {
        _showSnack(context, 'Store not available. Check your connection.');
      }
      return false;
    }

    final completer = Completer<bool>();
    late StreamSubscription<List<PurchaseDetails>> sub;

    sub = iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.productID != _productId) continue;
        if (purchase.status == PurchaseStatus.restored) {
          await iap.completePurchase(purchase);
          await unlockLifetimePremium();
          if (!completer.isCompleted) completer.complete(true);
          await sub.cancel();
          return;
        }
      }
    }, onDone: () async {
      if (!completer.isCompleted) completer.complete(false);
      await sub.cancel();
    }, onError: (_) async {
      if (!completer.isCompleted) completer.complete(false);
      await sub.cancel();
    });

    await iap.restorePurchases();

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () async {
        await sub.cancel();
        return false;
      },
    );
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ─── Feature metadata ────────────────────────────────────────────────────────

  static String featureTitle(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.dailyWakePlanner:
        return 'Daily Wake Planner';
      case PremiumFeature.weeklyWakePlanner:
        return 'Weekly Wake Planner';
      case PremiumFeature.sleepCoachPro:
        return 'Sleep Coach Pro';
      case PremiumFeature.adaptiveAlarmTuning:
        return 'Adaptive Alarm Tuning';
      case PremiumFeature.rotatingAlarmSounds:
        return 'Rotating Alarm Sounds';
      case PremiumFeature.weekendDriftGuard:
        return 'Weekend Drift Guard';
      case PremiumFeature.recoveryDayPlanner:
        return 'Recovery Day Planner';
      case PremiumFeature.smartDismissModes:
        return 'Smart Dismiss Modes';
    }
  }

  static String featureDescription(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.dailyWakePlanner:
        return 'Smart daily wake suggestions based on your day type and routine.';
      case PremiumFeature.weeklyWakePlanner:
        return 'A full weekly alarm planner with commute and sleep patterns.';
      case PremiumFeature.sleepCoachPro:
        return 'Teen sleep debt, consistency score, and smarter bedtime coaching.';
      case PremiumFeature.adaptiveAlarmTuning:
        return 'Mood and sleep check-ins that auto-tune your next wake-up time.';
      case PremiumFeature.rotatingAlarmSounds:
        return 'Dynamic sound rotation to reduce alarm fatigue.';
      case PremiumFeature.weekendDriftGuard:
        return 'Protects teens from sleeping too late on weekends and breaking their weekday rhythm.';
      case PremiumFeature.recoveryDayPlanner:
        return 'Builds a next-day recovery plan when sleep debt or poor sleep quality shows up.';
      case PremiumFeature.smartDismissModes:
        return 'Advanced stop challenges that reduce snoozing and help users actually get up.';
    }
  }

  static List<PremiumFeature> bundleFeatures() {
    return const [
      PremiumFeature.sleepCoachPro,
      PremiumFeature.recoveryDayPlanner,
      PremiumFeature.weekendDriftGuard,
      PremiumFeature.adaptiveAlarmTuning,
      PremiumFeature.dailyWakePlanner,
      PremiumFeature.weeklyWakePlanner,
      PremiumFeature.rotatingAlarmSounds,
      PremiumFeature.smartDismissModes,
    ];
  }

  static List<String> bundleLabels() {
    return bundleFeatures().map(featureTitle).toList(growable: false);
  }

  static String paywallMessage(PremiumFeature feature) {
    return '${featureTitle(feature)} is part of Lifetime Premium for ₹$lifetimePriceInr.\n\n${featureDescription(feature)}';
  }

  // ─── Paywall dialog ──────────────────────────────────────────────────────────

  /// Shows a paywall and initiates a real IAP purchase.
  /// Returns true if premium was unlocked.
  static Future<bool> showLifetimePaywall(
    BuildContext context,
    PremiumFeature feature,
  ) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unlock ${featureTitle(feature)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(paywallMessage(feature)),
            const SizedBox(height: 16),
            const Text(
              'Payment is processed securely through Google Play.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx, false);
              if (ctx.mounted) {
                final restored = await restorePurchases(ctx);
                if (ctx.mounted && restored) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Premium restored!')),
                  );
                }
              }
            },
            child: const Text('Restore'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlock ₹299'),
          ),
        ],
      ),
    );

    if (proceed != true) return false;

    if (!context.mounted) return false;

    // Show loading while purchase is in flight
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Opening payment…'),
        duration: Duration(seconds: 60),
      ),
    );

    final success = await purchaseLifetimePremium(context);
    messenger.hideCurrentSnackBar();

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lifetime Premium unlocked!')),
      );
    }

    return success;
  }
}
