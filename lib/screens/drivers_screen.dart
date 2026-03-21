import 'package:flutter/material.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/ad_banner.dart';
import '../services/link_launcher_service.dart';

class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key});

  // Official driver-related links
  static const String _bookDrivingTest =
      'https://dva-bookings.nidirect.gov.uk/BookDriver/Driver/DriverSearch';

  static const String _bookTheoryTest =
      'https://www.nidirect.gov.uk/services/book-your-theory-test-online';

  static const String _renewLicence =
      'https://www.nidirect.gov.uk/articles/renew-your-driving-licence';

  static const String _replaceLostLicence =
      'https://www.nidirect.gov.uk/services/replace-your-driving-licence';

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
            'Driver',
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
                title: 'Replace Lost Licence',
                subtitle: 'Lost or stolen licence',
                icon: Icons.report_gmailerrorred_outlined,
                onTap: () => open(_replaceLostLicence),
              ),
              QuickActionCard(
                title: 'Renew Licence',
                subtitle: 'Check eligibility & renew',
                icon: Icons.badge_outlined,
                onTap: () => open(_renewLicence),
              ),
              QuickActionCard(
                title: 'Book Driving Test',
                subtitle: 'DVA booking portal',
                icon: Icons.directions_car_outlined,
                onTap: () => open(_bookDrivingTest),
              ),
              QuickActionCard(
                title: 'Book Theory Test',
                subtitle: 'NI Direct booking',
                icon: Icons.menu_book_outlined,
                onTap: () => open(_bookTheoryTest),
              ),
            ],
          ),

          // Ad placeholder (replaces affiliate section)
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
