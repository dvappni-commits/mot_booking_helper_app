import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../services/news_service.dart';

class AdminNewsEditorScreen extends StatefulWidget {
  const AdminNewsEditorScreen({super.key});

  @override
  State<AdminNewsEditorScreen> createState() => _AdminNewsEditorScreenState();
}

class _AdminNewsEditorScreenState extends State<AdminNewsEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _line1Ctrl = TextEditingController();
  final _line2Ctrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  bool _loadingInitial = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    // ✅ Hard gate: must be logged in + admin (UI side)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (!AdminService.isLoggedIn || !AdminService.isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin login required')),
        );
        Navigator.pop(context);
        return;
      }

      await _loadExisting();
    });
  }

  Future<void> _loadExisting() async {
    try {
      final data = await NewsService.getNewsOnce();
      if (!mounted) return;

      _titleCtrl.text = (data?['title'] as String?) ?? '';
      _line1Ctrl.text = (data?['line1'] as String?) ?? '';
      _line2Ctrl.text = (data?['line2'] as String?) ?? '';
      _bodyCtrl.text = (data?['body'] as String?) ?? '';
    } catch (_) {
      // ignore – editor can still work
    } finally {
      if (!mounted) return;
      setState(() => _loadingInitial = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      // ✅ Extra safety: re-check admin right before saving
      if (!AdminService.isLoggedIn || !AdminService.isAdmin) {
        throw Exception('Not authorized');
      }

      await NewsService.saveNews(
        title: _titleCtrl.text,
        line1: _line1Ctrl.text,
        line2: _line2Ctrl.text,
        body: _bodyCtrl.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('News updated')),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Save failed. Check connection and try again.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _line1Ctrl.dispose();
    _line2Ctrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Trade News'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await AdminService.signOut();
              if (!mounted) return;
              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loadingInitial
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title (shows on tile + page)',
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Enter a title'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _line1Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Preview line 1 (shows on tile)',
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Enter line 1'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _line2Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Preview line 2 (shows on tile)',
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Enter line 2'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bodyCtrl,
                      decoration: const InputDecoration(
                        labelText:
                        'Full news text (shows on news page)',
                      ),
                      minLines: 6,
                      maxLines: 14,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Padding(
                        padding:
                        const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style:
                          const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: const Text('Save & Exit'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ✅ Saving overlay
          if (_saving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.25),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Saving…'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
