import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/maker/maker_dashboard.dart';
import 'screens/office/office_dashboard.dart';
import 'screens/customer/customer_order_view_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  bool _isCustomerOrderLink() {
    final orderId = Uri.base.queryParameters['orderId'];
    final token = Uri.base.queryParameters['token'];

    return orderId != null &&
        orderId.isNotEmpty &&
        token != null &&
        token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final orderId = Uri.base.queryParameters['orderId'];
    final token = Uri.base.queryParameters['token'];
    final view = Uri.base.queryParameters['view'];

    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Ring Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFFFAFAF8),
          primaryColor: const Color(0xFFB8960C),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFB8960C),
            secondary: Color(0xFF8B7109),
            surface: Color(0xFFFAFAF8),
          ),
        ),
        home: _isCustomerOrderLink()
            ? CustomerOrderViewScreen(
          orderId: orderId!,
          token: token!,
          isMakerView: view == 'maker',
        )
            : Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                backgroundColor: Color(0xFFFAFAF8),
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFB8960C),
                  ),
                ),
              );
            }

            if (auth.user == null) {
              return const LoginScreen();
            }

            if (auth.isAdmin) {
              return const AdminDashboard();
            }

            if (auth.isOffice) {
              return const OfficeDashboard();
            }

            return const MakerDashboard();
          },
        ),
      ),
    );
  }
}






