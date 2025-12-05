import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../core/api_client.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  List bookings = [];
  bool loading = true;

  ApiClient get api => Provider.of<AuthStore>(context, listen: false).api;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => loading = true);
    final res = await api.get('/api/bookings/my');
    setState(() {
      bookings = res['data'] ?? [];
      loading = false;
    });
  }

  Future<void> _cancelBooking(String id) async {
    final res = await api.patch('/api/bookings/$id/cancel', {});
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled')),
      );
      _loadBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancel failed: ${res['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
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
            : bookings.isEmpty
                ? const Center(child: Text('No bookings found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, i) {
                      final b = bookings[i];
                      return Card(
                        color: const Color(0xFF020617),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b['service']['name'] ?? '',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                b['clinic']['name'] ?? '',
                                style: const TextStyle(fontSize: 14, color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${b['date']} · ${b['startTime']}',
                                style: const TextStyle(fontSize: 13, color: Colors.white54),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${b['status']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: b['status'] == 'cancelled'
                                      ? Colors.red
                                      : b['status'] == 'completed'
                                          ? Colors.green
                                          : Colors.white,
                                ),
                              ),
                              if (b['status'] != 'completed' && b['status'] != 'cancelled')
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () => _cancelBooking(b['_id']),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
