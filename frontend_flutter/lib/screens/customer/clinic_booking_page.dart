import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../core/api_client.dart';

class ClinicBookingPage extends StatefulWidget {
  final String clinicId;
  const ClinicBookingPage({super.key, required this.clinicId});

  @override
  State<ClinicBookingPage> createState() => _ClinicBookingPageState();
}

class _ClinicBookingPageState extends State<ClinicBookingPage> {
  Map<String, dynamic>? clinic;
  List services = [];
  List<String> slots = [];
  String? selectedServiceId;
  String? selectedSlot;
  DateTime? selectedDate;
  bool loading = true;

  ApiClient get api => Provider.of<AuthStore>(context, listen: false).api;

  @override
  void initState() {
    super.initState();
    _loadClinic();
  }

  Future<void> _loadClinic() async {
    setState(() => loading = true);
    final cRes = await api.get('/api/clinic/${widget.clinicId}');
    final sRes = await api.get('/api/clinic/${widget.clinicId}/services');
    setState(() {
      clinic = cRes['data'];
      services = sRes['data'];
      loading = false;
    });
  }

  Future<void> _fetchSlots() async {
    if (selectedDate == null) return;
    final date = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
    final res = await api.get('/api/bookings/slots', params: {
      'clinicId': widget.clinicId,
      'date': date,
    });
    setState(() {
      slots = List<String>.from(res['data']['slots']);
      selectedSlot = null;
    });
  }

  Future<void> _book() async {
    if (selectedServiceId == null || selectedSlot == null || selectedDate == null) return;
    final date = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
    final res = await api.post('/api/bookings', {
      'clinicId': widget.clinicId,
      'serviceId': selectedServiceId,
      'date': date,
      'startTime': selectedSlot,
      'endTime': selectedSlot,
    });
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment booked successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: ${res['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || clinic == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050816), Color(0xFF020617)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    return isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildClinicInfoCard()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildBookingCard()),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildClinicInfoCard(),
                                const SizedBox(height: 16),
                                _buildBookingCard(),
                              ],
                            ),
                          );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClinicInfoCard() {
    return Card(
      color: const Color(0xFF020617).withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              clinic!['name'] ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              clinic!['description'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "${clinic!['address']} · ${clinic!['city']}",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Services',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: services.map((s) {
                return Chip(
                  label: Text(
                    "${s['name']} · ₹${s['price']}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFF020617),
                  side: const BorderSide(color: Color(0xFF1E293B)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard() {
    return Card(
      color: const Color(0xFF020617).withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book an appointment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text('Service', style: TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: selectedServiceId,
              dropdownColor: const Color(0xFF020617),
              style: const TextStyle(color: Colors.white),
              items: services.map<DropdownMenuItem<String>>((s) {
                return DropdownMenuItem(
                  value: s['_id'],
                  child: Text("${s['name']} · ₹${s['price']}"),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedServiceId = v),
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 12),
            const Text('Date', style: TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 4),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? now,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 30)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Colors.deepPurple,
                          onPrimary: Colors.white,
                          surface: Color(0xFF020617),
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                  _fetchSlots();
                }
              },
              child: InputDecorator(
                decoration: _inputDecoration(),
                child: Text(
                  selectedDate == null
                      ? 'Select a date'
                      : "${selectedDate!.day.toString().padLeft(2, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.year}",
                  style: TextStyle(color: selectedDate == null ? Colors.white54 : Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Available slots', style: TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: slots.isEmpty
                  ? const Center(
                      child: Text('No slots loaded yet', style: TextStyle(fontSize: 12, color: Colors.white54)),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        final isSelected = selectedSlot == slot;
                        return GestureDetector(
                          onTap: () => setState(() => selectedSlot = slot),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.deepPurpleAccent : const Color(0xFF1E293B),
                              ),
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                                    )
                                  : null,
                              color: isSelected ? null : const Color(0xFF020617),
                            ),
                            child: Text(
                              slot,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _book,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.deepPurpleAccent,
                ),
                child: const Text('Confirm Booking', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF020617),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.deepPurpleAccent),
      ),
    );
  }
}
