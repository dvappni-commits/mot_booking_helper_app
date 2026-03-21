import 'package:flutter/material.dart';

import '../services/news_service.dart';
import '../services/admin_service.dart';

import 'admin_login_screen.dart';
import 'admin_news_editor_screen.dart';

class TradeNewsScreen extends StatefulWidget {
  const TradeNewsScreen({super.key});

  @override
  State<TradeNewsScreen> createState() => _TradeNewsScreenState();
}

class _TradeNewsScreenState extends State<TradeNewsScreen> {
  Future<void> _openAdminEditor() async {
    // Always force a fresh login (even you)
    await AdminService.signOut();

    if (!mounted) return;

    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );

    if (ok != true) return;
    if (!mounted) return;

    // Extra guard
    if (!AdminService.isLoggedIn || !AdminService.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin access denied')),
      );
      await AdminService.signOut();
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminNewsEditorScreen()),
    );

    // Force sign-out after editing so it asks every time
    await AdminService.signOut();

    if (!mounted) return;

    if (changed == true) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('News refreshed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade News'),
        actions: [
          IconButton(
            tooltip: 'Admin edit',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: _openAdminEditor,
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: NewsService.streamNews(),
        builder: (context, snap) {
          final data = snap.data;

          if (snap.connectionState == ConnectionState.waiting &&
              (data == null || data.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }

          final title = (data?['title'] as String?)?.trim();
          final body = (data?['body'] as String?)?.trim();
          final line1 = (data?['line1'] as String?)?.trim();
          final line2 = (data?['line2'] as String?)?.trim();

          final hasAnything = [
            title,
            body,
            line1,
            line2,
          ].any((x) => x != null && x.isNotEmpty);

          if (!hasAnything) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No news posted yet.\n\nAdmins: tap the shield icon to post an update.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                (title == null || title.isEmpty) ? 'News' : title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (line1 != null && line1.isNotEmpty) ...[
                Text(
                  line1,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
              ],
              if (line2 != null && line2.isNotEmpty) ...[
                Text(
                  line2,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
              ],

              if (body != null && body.isNotEmpty)
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
            ],
          );
        },
      ),
    );
  }
}
