import 'package:flutter/material.dart';
import '../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ensureProductLoaded();
  }

  Future<void> _ensureProductLoaded() async {
    // If already cached, nothing to do
    if (SubscriptionService.tradeProduct != null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final p = await SubscriptionService.fetchProduct();
      // cache it for UI
      SubscriptionService.tradeProduct = p;
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _subscribe() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await SubscriptionService.buyTradeMonthly();
      // SubscriptionService listener updates subscribed + isSubscribed.
      // Paywall will auto-close via ValueListenableBuilder below.
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await SubscriptionService.restorePurchases();
      if (!mounted) return;

      if (SubscriptionService.isSubscribed) {
        Navigator.pop(context);
      } else {
        setState(() => _error = 'No active subscription found to restore.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = SubscriptionService.tradeProduct;

    return Scaffold(
      appBar: AppBar(title: const Text('Trade Access')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ValueListenableBuilder<bool>(
          valueListenable: SubscriptionService.subscribed,
          builder: (context, isSubbed, _) {
            // Auto-close the paywall when subscription becomes active
            if (isSubbed) {
              // Delay pop to avoid setState during build issues
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.pop(context);
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trade features require a subscription',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  '• MOT calendar\n'
                      '• Import from email\n'
                      '• Trade notifications\n'
                      '• Trade updates',
                ),
                const SizedBox(height: 16),

                if (isSubbed)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.4)),
                    ),
                    child: const Text('✅ You are subscribed.'),
                  )
                else if (product == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.4)),
                    ),
                    child: Text(
                      _loading
                          ? 'Loading subscription…'
                          : 'Subscription product not found.\n\n'
                          'Check:\n'
                          '1) Product ID in code matches Play Console\n'
                          '2) Subscription + base plan are Active\n'
                          '3) You installed from Internal testing via Play Store\n\n'
                          'Product ID expected: ${SubscriptionService.kTradeSubscriptionId}',
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [],
                  ),

                if (product != null && !isSubbed) ...[
                  Text(
                    '${product.title}\n${product.price} / month',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Cancel anytime',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_loading || isSubbed || product == null)
                        ? null
                        : _subscribe,
                    child: Text(
                      _loading ? 'Please wait…' : 'Start 30-day free trial',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _restore,
                    child: const Text('Restore purchase'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Maybe later'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
