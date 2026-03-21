import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkLauncherService {
  static Future<void> openLink(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch the link")),
      );
    }
  }
}
