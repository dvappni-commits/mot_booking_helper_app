import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    await AdminService.signOut();

    if (!mounted) return;

    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );

    if (ok != true) return;
    if (!mounted) return;

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

    await AdminService.signOut();

    if (!mounted) return;

    if (changed == true) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('News refreshed')),
      );
    }
  }

  Future<void> _openLink(String rawUrl) async {
    String url = rawUrl.trim();

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid link')),
      );
      return;
    }

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  List<InlineSpan> _buildLinkTextSpans(
      String text,
      TextStyle? normalStyle,
      TextStyle? linkStyle,
      ) {
    final regex = RegExp(
      r'((https?:\/\/)?(www\.)?[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}([\/\w\-\.\?\=\&\#\%\+\~:]*)?)',
      caseSensitive: false,
    );

    final spans = <InlineSpan>[];
    int start = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
            style: normalStyle,
          ),
        );
      }

      final matchedText = match.group(0)!;

      spans.add(
        TextSpan(
          text: matchedText,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              _openLink(matchedText);
            },
        ),
      );

      start = match.end;
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: normalStyle,
        ),
      );
    }

    return spans;
  }

  Widget _buildLinkableText(
      BuildContext context,
      String text, {
        TextStyle? style,
      }) {
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyLarge;
    final linkStyle = (defaultStyle ?? const TextStyle()).copyWith(
      color: Colors.blue,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w500,
    );

    return RichText(
      text: TextSpan(
        children: _buildLinkTextSpans(text, defaultStyle, linkStyle),
      ),
    );
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

          final hasAnything = [title, body, line1, line2]
              .any((x) => x != null && x.isNotEmpty);

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

          final titleStyle = Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold);
          final lineStyle = Theme.of(context).textTheme.titleMedium;
          final bodyStyle = Theme.of(context).textTheme.bodyLarge;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                (title == null || title.isEmpty) ? 'News' : title,
                style: titleStyle,
              ),
              const SizedBox(height: 12),

              if (line1 != null && line1.isNotEmpty) ...[
                _buildLinkableText(context, line1, style: lineStyle),
                const SizedBox(height: 8),
              ],

              if (line2 != null && line2.isNotEmpty) ...[
                _buildLinkableText(context, line2, style: lineStyle),
                const SizedBox(height: 12),
              ],

              if (body != null && body.isNotEmpty)
                _buildLinkableText(context, body, style: bodyStyle),
            ],
          );
        },
      ),
    );
  }
}