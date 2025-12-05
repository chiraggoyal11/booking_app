import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'core/auth_store.dart';
import 'core/api_client.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const ClinicBookingApp());
}

class ClinicBookingApp extends StatelessWidget {
  const ClinicBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(baseUrl: 'http://localhost:5000');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStore(api: apiClient)),
      ],
      child: MaterialApp(
        title: 'Clinic/Salon Booking',
        theme: appTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
