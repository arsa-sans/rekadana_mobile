import 'package:flutter/material.dart';
import 'core/constants/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/widgets/state_views.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/models/user_model.dart';
import 'features/organization/org_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RekaDanaMobileApp());
}

class RekaDanaMobileApp extends StatelessWidget {
  const RekaDanaMobileApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Tangani sesi kedaluwarsa secara reaktif di seluruh aplikasi
    ApiClient.onSessionExpired = () {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(
            sessionExpiredMessage: 'Sesi Anda telah kedaluwarsa. Silakan masuk kembali.',
          ),
        ),
        (route) => false,
      );
    };

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'RekaDana Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGateScreen(),
    );
  }
}

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final AuthService _authService = AuthService();
  late Future<UserModel?> _initAuthFuture;

  @override
  void initState() {
    super.initState();
    // Validasi sesi aktif ke server jika ada token tersimpan
    _initAuthFuture = _authService.verifySession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _initAuthFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingView(message: 'Memeriksa sesi login...'),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return const OrgSelectionScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
