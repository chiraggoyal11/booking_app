import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/auth_store.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool loading = true;
  Map stats = {};
  List bookings = [];

  ApiClient get api => Provider.of<AuthStore>(context, listen: false).api;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => loading = true);
    final res = await api.get('/api/admin/stats');
    final resBookings = await api.get('/api/admin/bookings');
    setState(() {
      stats = res['data'] ?? {};
      bookings = resBookings['data'] ?? [];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050816), Color(0xFF020617)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: const Color(0xFF020617),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statTile('Users', stats['users']?.toString() ?? '0'),
                            _statTile('Clinics', stats['clinics']?.toString() ?? '0'),
                            _statTile('Services', stats['services']?.toString() ?? '0'),
                            _statTile('Bookings', stats['bookings']?.toString() ?? '0'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Recent Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...bookings.take(10).map((b) => Card(
                          color: const Color(0xFF020617),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b['service']['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(b['clinic']['name'] ?? '', style: const TextStyle(color: Colors.white70)),
                                Text('${b['date']} · ${b['startTime']}', style: const TextStyle(color: Colors.white54)),
                                Text('User: ${b['user']['name'] ?? ''}', style: const TextStyle(color: Colors.white54)),
                                Text('Status: ${b['status']}', style: TextStyle(
                                  color: b['status'] == 'cancelled'
                                      ? Colors.red
                                      : b['status'] == 'completed'
                                          ? Colors.green
                                          : Colors.white,
                                )),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }
}
