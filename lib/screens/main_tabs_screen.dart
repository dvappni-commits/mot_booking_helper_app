import 'package:flutter/material.dart';
import 'vehicle_screen.dart';
import 'drivers_screen.dart';

class MainTabsScreen extends StatelessWidget {
  const MainTabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);

          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                  children: const [
                                    TextSpan(text: 'MOT '),
                                    TextSpan(
                                      text: 'Booking ',
                                      style: TextStyle(color: Color(0xFFFFC107)), // gold
                                    ),
                                    TextSpan(text: 'Helper'),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 4),
                              Text(
                                'MOT Booking helper App for motorists in Northern Ireland',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'About',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('About'),
                                content: const Text(
                                  'MOT Booking helper App provides quick access to official motoring services.\n\n'
                                      'Not affiliated with the DVA / NI Direct.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline),
                        ),
                      ],
                    ),
                  ),

                  // Chrome-style tab strip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _ChromeTabStrip(
                      activeIndex: controller.index,
                      onTabSelected: (i) => controller.animateTo(i),
                    ),
                  ),

                  // A thin divider under the tabs (like Chrome)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Expanded(
                    child: TabBarView(
                      children: [
                        VehicleScreen(),
                        DriversScreen(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChromeTabStrip extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  const _ChromeTabStrip({
    required this.activeIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget tab({
      required int index,
      required String label,
    }) {
      final isActive = index == activeIndex;

      return Expanded(
        child: GestureDetector(
          onTap: () => onTabSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : theme.colorScheme.primary.withValues(alpha: 0.06),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              boxShadow: isActive
                  ? [
                BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  color: Colors.black.withValues(alpha: 0.05),
                )
              ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(index: 0, label: 'Vehicle'),
        const SizedBox(width: 8),
        tab(index: 1, label: 'Driver'),
      ],
    );
  }
}
