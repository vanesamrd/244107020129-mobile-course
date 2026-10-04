import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../messaging/push_service_class.dart';
import '../providers/push_service_provider.dart';

class PushServiceDemoPage extends ConsumerStatefulWidget {
  const PushServiceDemoPage({super.key});

  @override
  ConsumerState<PushServiceDemoPage> createState() =>
      _PushServiceDemoPageState();
}

class _PushServiceDemoPageState extends ConsumerState<PushServiceDemoPage> {
  final List<String> _logs = [];
  bool _subscribed = true;
  late PushService _pushService;

  void _addLog(String msg) {
    setState(() {
      final time = DateTime.now();
      final timeStr =
          '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}:'
          '${time.second.toString().padLeft(2, '0')}';
      _logs.insert(0, '$timeStr — $msg');
    });
  }

  @override
  void initState() {
    super.initState();
    _pushService = ref.read(
      pushServiceProvider(
        PushServiceArgs(
          onNavigate: (route) {
            _addLog('📲 Navigasi ke: $route');
            context.go(route);
          },
        ),
      ),
    );
    // Delay _addLog ke after build selesai (post frame callback)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addLog(
        '✅ PushService siap. Coba kirim notifikasi dari Firebase Console!',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo PushService (Prompt)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          // Panel kontrol
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kontrol Topic',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('pengumuman-kampus'),
                    subtitle: Text(
                      _subscribed
                          ? 'Sedang berlangganan topik'
                          : 'Tidak berlangganan topik',
                    ),
                    value: _subscribed,
                    onChanged: (val) async {
                      setState(() => _subscribed = val);
                      if (val) {
                        await _pushService.subscribeCampusTopic();
                        _addLog('✅ Subscribe: pengumuman-kampus');
                      } else {
                        await _pushService.unsubscribeCampusTopic();
                        _addLog('❌ Unsubscribe: pengumuman-kampus');
                      }
                    },
                  ),
                  const Divider(),
                  const Text(
                    'Panduan Uji Coba',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1. Foreground: Biarkan halaman ini terbuka, kirim dari Firebase Console.\n'
                    '2. Background: Tekan Home, lalu kirim dan klik banner.\n'
                    '3. Terminated: Tutup total aplikasi, kirim, klik banner.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          // Log event
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.terminal, size: 16),
                SizedBox(width: 6),
                Text(
                  'Event Log',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada event.\nKirim notifikasi dari Firebase Console!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _logs.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _logs[i],
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
