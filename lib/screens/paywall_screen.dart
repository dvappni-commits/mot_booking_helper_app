import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = false;
  String? _error;

  static final Uri _termsUrl = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );

  static final Uri _privacyUrl = Uri.parse(
    'https://dvappni-commits.github.io/dvapp.github.io/privacy.html',
  );

  @override
  void initState() {
    super.initState();
    _ensureProductLoaded();
  }

  Future<void> _ensureProductLoaded() async {
    if (SubscriptionService.tradeProduct != null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final p = await SubscriptionService.fetchProduct();
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

  Future<void> _openUrl(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = SubscriptionService.tradeProduct;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade Access'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ValueListenableBuilder<bool>(
          valueListenable: SubscriptionService.subscribed,
          builder: (context, isSubbed, _) {
            if (isSubbed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.pop(context);
              });
            }

            return ListView(
              children: [
                const Text(
                  'Trade features require a subscription',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unlock premium trade tools including:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• MOT calendar\n'
                      '• Import from email\n'
                      '• Trade notifications\n'
                      '• Trade updates',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                if (isSubbed)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.4),
                      ),
                    ),
                    child: const Text(
                      'You are subscribed.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                else if (product == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      _loading
                          ? 'Loading subscription…'
                          : 'Subscription product not found.\n\n'
                          'Check:\n'
                          '1) Product ID in code matches App Store Connect / Google Play\n'
                          '2) Subscription is active and attached correctly\n'
                          '3) On iPhone, install from TestFlight\n'
                          '4) On Android, install from Play internal testing\n\n'
                          'Product ID expected: ${SubscriptionService.kTradeSubscriptionId}',
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${product.price} per month',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1-month auto-renewing subscription',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Includes MOT calendar access, trade notifications, import from email, and trade updates during each subscription period.',
                          style: TextStyle(fontSize: 15, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Includes a free trial for eligible new subscribers.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'After any introductory period, billing continues at the monthly price shown above unless cancelled.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Manage or cancel in your Apple ID account settings.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => _openUrl(_termsUrl),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text('Terms of Use'),
                ),
                TextButton(
                  onPressed: () => _openUrl(_privacyUrl),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text('Privacy Policy'),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_loading || isSubbed || product == null)
                        ? null
                        : _subscribe,
                    child: Text(
                      _loading
                          ? 'Please wait…'
                          : product == null
                          ? 'Subscribe'
                          : 'Subscribe ${product.price} per month',
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