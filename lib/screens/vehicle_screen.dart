import 'package:flutter/material.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/ad_banner.dart';
import '../services/link_launcher_service.dart';
import '../utils/links.dart';

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final launcher = const LinkLauncherService();

    Future<void> open(String url) async {
      try {
        await launcher.open(url);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              QuickActionCard(
                title: 'Book MOT',
                subtitle: 'Official booking site',
                icon: Icons.event_available_outlined,
                onTap: () => open(AppLinks.bookTest),
              ),
              QuickActionCard(
                title: 'Manage Booking',
                subtitle: 'Find / change / rebook',
                icon: Icons.manage_search_outlined,
                onTap: () => open(AppLinks.manageBooking),
              ),
              QuickActionCard(
                title: 'Urgent/Cancellation',
                subtitle: 'urgent booking',
                icon: Icons.priority_high_outlined,
                onTap: () => open(AppLinks.urgentMot),
              ),
              QuickActionCard(
                title: 'Check MOT',
                subtitle: 'Expiry & history (GOV.UK)',
                icon: Icons.fact_check_outlined,
                onTap: () => open(AppLinks.checkMot),
              ),
              QuickActionCard(
                title: 'Duplicate Certificate',
                subtitle: 'Request replacement',
                icon: Icons.description_outlined,
                onTap: () => open(AppLinks.duplicateCert),
              ),
            ],
          ),

          // Replaces the Affiliate section
          const AdBanner(),

          const SizedBox(height: 14),

          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Remove ads coming soon')),
                );
              },
              child: const Text('❤️ Support – Remove ads'),
            ),
          ),
        ],
      ),
    );
  }
}
