import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../routes.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _fullToken;
  String? _tokenPreview;
  bool _isSubscribedTopic = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      if (!mounted) return;
      setState(() {
        _fullToken = token;
        _tokenPreview = _maskToken(token);
      });
    });
  }

  Future<void> _loadToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (!mounted) return;
    setState(() {
      _fullToken = token;
      _tokenPreview = token == null
          ? 'Token belum tersedia'
          : _maskToken(token);
    });
  }

  String _maskToken(String token) {
    if (token.length <= 16) return token;
    return '${token.substring(0, 16)}...';
  }

  Future<void> _toggleTopic(bool value) async {
    setState(() => _isSubscribedTopic = value);
    if (value) {
      await subscribeCampusTopic();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berlangganan topik "pengumuman-kampus"')),
      );
    } else {
      await unsubscribeCampusTopic();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhenti langganan topik "pengumuman-kampus"'),
        ),
      );
    }
  }

  void _copyTokenToClipboard() {
    if (_fullToken != null) {
      Clipboard.setData(ClipboardData(text: _fullToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FCM Token disalin ke clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Debug FCM Token',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: 'Salin Token Lengkap',
                        onPressed: _fullToken != null
                            ? _copyTokenToClipboard
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tokenPreview ?? 'Memuat token...',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: const Text(
                'Topik: pengumuman-kampus',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Broadcast pengumuman semua mahasiswa'),
              value: _isSubscribedTopic,
              onChanged: _toggleTopic,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Daftar Pengumuman',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Pengumuman 1'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.announcementDetail(id: '1')),
          ),
          ListTile(
            title: const Text('Pengumuman 2'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.announcementDetail(id: '2')),
          ),
          ListTile(
            title: const Text('Pengumuman 3'),
            subtitle: const Text('Jadwal kuliah berubah (Praktikum 3)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.announcementDetail(id: '3')),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.indigo.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.indigo.shade200),
            ),
            leading: const Icon(Icons.developer_mode, color: Colors.indigo),
            title: const Text(
              'Demo PushService (Hasil Prompt)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            subtitle: const Text(
              'Lihat event log Foreground / Background / Terminated',
            ),
            trailing: const Icon(Icons.arrow_forward, color: Colors.indigo),
            onTap: () => context.go(AppRoutes.pushServiceDemo),
          ),
        ],
      ),
    );
  }
}
