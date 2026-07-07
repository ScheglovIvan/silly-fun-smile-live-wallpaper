import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'entitlement_controller.dart';
import 'subscription_package.dart';

/// Shared subscribe / restore plumbing for the paywalls.
///
/// Both the onboarding paywall (0001) and the full paywall (0009) reach the PRO
/// entitlement through the same crown / upgrade entry points, so they drive the
/// identical StoreKit / RevenueCat round-trip via these helpers instead of each
/// re-implementing the purchase call, spinner gating and result messaging.
///
/// The functions delegate to [EntitlementController] (the in-app stand-in for
/// the RevenueCat SDK), surface the outcome through a themed [SnackBar], and
/// return whether the PRO entitlement is active afterwards so the caller can
/// dismiss / advance on success.

/// Run a StoreKit purchase of the package identified by [packageId]
/// (`weekly` | `yearly`) against [controller] and report the result.
///
/// Returns `true` when PRO is active after the round-trip.
Future<bool> runPurchase(
  BuildContext context,
  EntitlementController controller,
  String packageId,
) async {
  if (controller.purchaseInFlight) return controller.isPro;
  final SubscriptionPackage? package = controller.packageById(packageId);
  final outcome = await controller.purchase(package);
  if (!context.mounted) return controller.isPro;
  _report(context, outcome);
  return controller.isPro;
}

/// Restore a previously-purchased entitlement against [controller] and report
/// the result. Returns `true` when PRO is active afterwards.
Future<bool> runRestore(
  BuildContext context,
  EntitlementController controller,
) async {
  if (controller.purchaseInFlight) return controller.isPro;
  final outcome = await controller.restorePurchases();
  if (!context.mounted) return controller.isPro;
  _report(context, outcome);
  return controller.isPro;
}

/// Human-readable message + success flag for a purchase / restore [outcome].
void _report(BuildContext context, PurchaseOutcome outcome) {
  late final String message;
  late final bool success;
  switch (outcome) {
    case PurchaseOutcome.purchased:
      message = "You're PRO — enjoy ad-free Ultra HD & 4K wallpapers.";
      success = true;
      break;
    case PurchaseOutcome.restored:
      message = 'Purchases restored — PRO is active.';
      success = true;
      break;
    case PurchaseOutcome.nothingToRestore:
      message = 'No previous purchases to restore.';
      success = false;
      break;
    case PurchaseOutcome.cancelled:
      message = 'Purchase cancelled.';
      success = false;
      break;
    case PurchaseOutcome.error:
      message = 'Something went wrong. Please try again.';
      success = false;
      break;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.info_outline,
              size: 20,
              color: success ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Confirmation shown in place of the full paywall (0009) once the PRO
/// entitlement is active — re-entering the paywall from the crown / upgrade
/// entry points after unlocking lands here instead of the purchase form.
class ProUnlockedView extends StatelessWidget {
  const ProUnlockedView({super.key, required this.onContinue});

  /// Dismisses the paywall (pops back to where the crown / upgrade tap
  /// originated, or falls through to the shell in standalone / preview mode).
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: Padding(
        padding: EdgeInsets.fromLTRB(24, media.padding.top + 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Center(
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryDim,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SILLY SMILES',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 26,
                    height: 1.0,
                    color: AppColors.text,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentPro,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 14,
                      color: AppColors.text,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              "You're all set. Ads are off and every Ultra HD & 4K wallpaper is "
              'unlocked.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
            SizedBox(height: media.padding.bottom),
          ],
        ),
      ),
    );
  }
}

/// A green pill purchase / continue CTA that swaps its label for a spinner while
/// [busy] (a purchase / restore round-trip is in flight) and disables taps.
class PurchaseCtaButton extends StatelessWidget {
  const PurchaseCtaButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
    this.fontSize = 20,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.black,
          disabledBackgroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
      ),
    );
  }
}
