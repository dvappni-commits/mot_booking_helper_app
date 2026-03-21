import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  static const String _videoUrl =
      'https://youtube.com/shorts/o0C8KrmH-Tg?si=aZhswOLsars-vaxi';

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.parse(_videoUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the video link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Info'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        children: [
          // -------------------------
          // APP INFO
          // -------------------------
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: cs.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MOT Booking Helper',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Motoring links, trade updates, and calendar to easily store appointment details straight from your DVA appointment email. '
                              'MOT Booking Helper App is an independent app and is not affiliated with the DVA, DVLA, UK or Northern Ireland governments. '
                              'All links direct to publicly available websites.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // -------------------------
          // VIDEO HELP (NEW)
          // -------------------------
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.play_circle_outline, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Watch a quick tutorial video',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Watch a quick video on app features & how to import appointments from emails to save to your in app calendar.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.80),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: () => _openVideo(context),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open YouTube video'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // -------------------------
          // NOTIFICATIONS (fixed layout)
          // -------------------------
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '!! Never miss a MOT appointment again !!\n\n'
                              'Trade alerts are scheduled automatically:\n'
                              '• 7:30am summary of today’s appointments\n'
                              '• 1 hour before each appointment\n'
                              '• 8:00pm summary of tomorrow’s appointments\n\n'
                              'These refresh when you add/edit/delete entries '
                              'and when the app starts.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // -------------------------
          // QUICK TUTORIAL
          // -------------------------
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school_outlined, color: cs.primary),
                      const SizedBox(width: 10),
                      const Text(
                        'Quick Tutorial',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const _StepTile(
                    number: 1,
                    title: 'Open your appointment email',
                    body:
                    'Open the email that contains your MOT appointment details '
                        '(date, time, centre, lane, booking reference).',
                  ),
                  const SizedBox(height: 10),
                  const _StepTile(
                    number: 2,
                    title: 'Copy the appointment details',
                    body:
                    'Press and hold on the text in the email, select all or drag '
                        'the handles to select everything. Tap Copy.',
                  ),
                  const SizedBox(height: 10),
                  const _StepTile(
                    number: 3,
                    title: 'Go to Calendar',
                    body: 'Home → Trade tab → Calendar.',
                  ),
                  const SizedBox(height: 10),
                  const _StepTile(
                    number: 4,
                    title: 'Tap “Import from Email”',
                    body:
                    'Paste the copied text into the import box and tap Import. '
                        'The app will auto-fill fields.',
                  ),
                  const SizedBox(height: 10),
                  const _StepTile(
                    number: 5,
                    title: 'Confirm and Save',
                    body:
                    'If anything is missing (lane/time etc.), add manually and '
                        'press Save.',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.primary.withOpacity(0.25),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tip: If import doesn’t detect everything, you can still '
                                'add manually using the “Add” button on the Entries row.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int number;
  final String title;
  final String body;

  const _StepTile({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              color: cs.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(body),
            ],
          ),
        ),
      ],
    );
  }
}