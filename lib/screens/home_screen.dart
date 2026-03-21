import 'package:flutter/material.dart';

import '../widgets/quick_action_card.dart';
import '../services/link_launcher_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/news_service.dart';
import '../services/mot_calendar_service.dart';
import '../services/mot_notification_service.dart';
import '../services/subscription_service.dart';

import 'app_info_screen.dart';
import 'trade_news_screen.dart';
import 'mot_calendar_screen.dart';
import 'paywall_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  bool _rescheduling = false;

  // -------------------------
  // VEHICLE LINKS
  // -------------------------
  static const String _bookMot = 'https://dva-bookings.nidirect.gov.uk/';
  static const String _manageBooking =
      'https://dva-bookings.nidirect.gov.uk/MyBookings/Find';
  static const String _urgentBooking =
      'https://dttselfserve.nidirect.gov.uk/DVA/RequestIt#/DVA_Urgent_MOT_Requests';
  static const String _checkMot = 'https://www.check-mot.service.gov.uk/';
  static const String _duplicateCertificate =
      'https://dva-bookings.nidirect.gov.uk/certificates/duplicaterequest';

  // GOV.UK Tax + MOT check
  static const String _taxCheck =
      'https://www.gov.uk/check-vehicle-tax';

  // -------------------------
  // DRIVER LINKS
  // -------------------------
  static const String _bookDrivingTest =
      'https://dva-bookings.nidirect.gov.uk/BookDriver/Driver/DriverSearch';
  static const String _manageDriverBooking =
      'https://dva-bookings.nidirect.gov.uk/MyBookings/FindDriver';
  static const String _bookTheoryTest =
      'https://www.book-theory-test.service.gov.uk/?target=ni&lang=ni';
  static const String _practiceTheoryTest =
      'https://www.gov.uk/take-practice-theory-test';

  // -------------------------
  // TRADE LINKS (SOFT PAYWALL)
  // -------------------------
  static const String _lightVehicleManual =
      'https://www.infrastructure-ni.gov.uk/publications/light-vehicle-inspection-manual-dva';
  static const String _heavyVehicleManual =
      'https://www.infrastructure-ni.gov.uk/publications/heavy-vehicle-inspection-manual-dva';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rescheduleTodayAlerts();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _rescheduleTodayAlerts();
    }
  }

  Future<void> _rescheduleTodayAlerts() async {
    // Behind paywall (no trade notifications unless subscribed)
    if (!SubscriptionService.isSubscribed) return;

    if (_rescheduling) return;
    _rescheduling = true;
    try {
      await MotNotificationService.rescheduleTradeTodayAlerts();
    } catch (_) {
      // ignore
    } finally {
      _rescheduling = false;
    }
  }

  void _open(String url) {
    LinkLauncherService.openLink(url, context);
  }

  Future<void> _openPaywall() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
    if (mounted) setState(() {});
  }

  /// Wrap an action so it only runs if subscribed; otherwise open paywall.
  VoidCallback _tradeTapGuard(VoidCallback action) {
    return () async {
      if (!SubscriptionService.isSubscribed) {
        await _openPaywall();
        return;
      }
      action();
    };
  }

  IconData _tradeIcon(IconData unlocked) {
    return SubscriptionService.isSubscribed ? unlocked : Icons.lock_outline;
  }

  String _tradeHint(String subtitle) {
    if (SubscriptionService.isSubscribed) return subtitle;
    return '$subtitle\nTrade feature — subscribe to unlock';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
            children: [
              TextSpan(text: 'MOT '),
              TextSpan(
                text: 'Booking ',
                style: TextStyle(color: Color(0xFFFFC107)), // gold
              ),
              TextSpan(text: 'Helper'),
            ],
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'App info',
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppInfoScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 18),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Vehicle'),
            Tab(text: 'Driver'),
            Tab(text: 'Trade'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVehicleTab(),
                _buildDriverTab(),
                _buildTradeTab(),
              ],
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  // -------------------------
  // TABS
  // -------------------------
  Widget _buildVehicleTab() {
    return _tabPadding(
      _grid([
        QuickActionCard(
          icon: Icons.calendar_today,
          title: 'Book MOT',
          subtitle: 'Official booking site',
          onTap: () => _open(_bookMot),
        ),
        QuickActionCard(
          icon: Icons.manage_search,
          title: 'Manage Booking',
          subtitle: 'Find / change / rebook',
          onTap: () => _open(_manageBooking),
        ),
        QuickActionCard(
          icon: Icons.priority_high,
          title: 'Urgent/Cancellation',
          subtitle: 'Short notice form',
          onTap: () => _open(_urgentBooking),
        ),
        QuickActionCard(
          icon: Icons.assignment,
          title: 'Check MOT History',
          subtitle: 'Expiry & history (GOV.UK)',
          onTap: () => _open(_checkMot),
        ),
        QuickActionCard(
          icon: Icons.receipt_long_outlined,
          title: 'Tax Check',
          subtitle: 'Check if taxed + MOT (GOV.UK)',
          onTap: () => _open(_taxCheck),
        ),
        QuickActionCard(
          icon: Icons.description,
          title: 'Duplicate Certificate',
          subtitle: 'Request replacement',
          onTap: () => _open(_duplicateCertificate),
        ),
      ]),
    );
  }

  Widget _buildDriverTab() {
    return _tabPadding(
      _grid([
        QuickActionCard(
          icon: Icons.directions_car_outlined,
          title: 'Book Driving Test',
          subtitle: 'DVA driver booking',
          onTap: () => _open(_bookDrivingTest),
        ),
        QuickActionCard(
          icon: Icons.manage_search,
          title: 'Manage Booking',
          subtitle: 'Find / change / cancel',
          onTap: () => _open(_manageDriverBooking),
        ),
        QuickActionCard(
          icon: Icons.menu_book_outlined,
          title: 'Book Theory Test',
          subtitle: 'NI theory booking',
          onTap: () => _open(_bookTheoryTest),
        ),
        QuickActionCard(
          icon: Icons.quiz_outlined,
          title: 'Practice Theory',
          subtitle: 'Official GOV.UK practice',
          onTap: () => _open(_practiceTheoryTest),
        ),
      ]),
    );
  }

  Widget _buildTradeTab() {
    // Soft paywall: show tiles + previews, block certain opens if not subscribed
    return _tabPadding(
      _grid([
        // Manuals (locked unless subscribed)
        QuickActionCard(
          icon: _tradeIcon(Icons.menu_book_outlined),
          title: 'Light Vehicle Manual',
          subtitle: _tradeHint('DVA inspection manual'),
          onTap: _tradeTapGuard(() => _open(_lightVehicleManual)),
        ),
        QuickActionCard(
          icon: _tradeIcon(Icons.local_shipping_outlined),
          title: 'Heavy Vehicle Manual',
          subtitle: _tradeHint('DVA inspection manual'),
          onTap: _tradeTapGuard(() => _open(_heavyVehicleManual)),
        ),

        // News tile (preview visible always; open blocked unless subscribed)
        StreamBuilder<Map<String, dynamic>?>(
          stream: NewsService.streamNews(),
          builder: (context, snap) {
            final data = snap.data ?? const <String, dynamic>{};
            final title = (data['title'] as String?)?.trim();
            final line1 = (data['line1'] as String?)?.trim();
            final line2 = (data['line2'] as String?)?.trim();

            final preview = [
              if (line1 != null && line1.isNotEmpty) line1,
              if (line2 != null && line2.isNotEmpty) line2,
            ].join('\n');

            final subtitle =
            preview.isEmpty ? 'Latest updates preview' : preview;

            return QuickActionCard(
              icon: _tradeIcon(Icons.newspaper_outlined),
              title: (title == null || title.isEmpty) ? 'Trade News' : title,
              subtitle: _tradeHint(subtitle),
              onTap: _tradeTapGuard(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TradeNewsScreen()),
                );
              }),
            );
          },
        ),

        // Calendar tile (OPEN FOR EVERYONE - read-only handled inside MotCalendarScreen)
        FutureBuilder<String?>(
          future: MotCalendarService.nextAppointmentPreview(),
          builder: (context, snap) {
            final preview = (snap.data ?? '').trim();

            return QuickActionCard(
              icon: Icons.event_outlined,
              title: preview.isEmpty ? 'Calendar' : 'Next Appointment',
              subtitle: preview.isEmpty ? 'Saved entries on device' : preview,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MotCalendarScreen()),
                );

                if (mounted) setState(() {});
                await _rescheduleTodayAlerts();
              },
            );
          },
        ),
      ]),
    );
  }

  // -------------------------
  // LAYOUT HELPERS
  // -------------------------
  Widget _tabPadding(Widget child) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: child,
    );
  }

  Widget _grid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: children,
    );
  }
}
