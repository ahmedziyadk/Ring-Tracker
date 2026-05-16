import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'firebase_options.dart';
import 'models/shared_order_draft.dart';
import 'providers/auth_provider.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/customer/customer_order_view_screen.dart';
import 'screens/login_screen.dart';
import 'screens/maker/maker_dashboard.dart';
import 'screens/office/office_dashboard.dart';
import 'screens/shared/shared_order_screen.dart';
import 'services/android_share_caption_service.dart';
import 'services/shared_order_parser.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AuthProvider _authProvider;
  final AndroidShareCaptionService _captionService = AndroidShareCaptionService();
  StreamSubscription<List<SharedMediaFile>>? _sharingSubscription;
  SharedOrderDraft? _pendingSharedDraft;
  String? _lastShareSignature;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _listenForSharedOrders();
  }

  @override
  void dispose() {
    _sharingSubscription?.cancel();
    _authProvider.dispose();
    super.dispose();
  }

  bool _isCustomerOrderLink() {
    final orderId = Uri.base.queryParameters['orderId'];
    final token = Uri.base.queryParameters['token'];

    return orderId != null &&
        orderId.isNotEmpty &&
        token != null &&
        token.isNotEmpty;
  }

  void _listenForSharedOrders() {
    _sharingSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) => _handleSharedFiles(files, initial: false),
      onError: (_) {},
    );

    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _handleSharedFiles(files, initial: true);
      ReceiveSharingIntent.instance.reset();
    });
  }

  Future<void> _handleSharedFiles(
    List<SharedMediaFile> files, {
    required bool initial,
  }) async {
    if (files.isEmpty) return;

    final imagePaths = files
        .where((file) => file.type == SharedMediaType.image)
        .map((file) => file.path)
        .where((path) => path.trim().isNotEmpty)
        .toList();
    final textItems = files
        .where((file) => file.type == SharedMediaType.text)
        .map((file) => file.path)
        .where((text) => text.trim().isNotEmpty)
        .toList();
    final pluginMessages = files
        .map((file) => file.message ?? '')
        .where((message) => message.trim().isNotEmpty)
        .toList();
    final androidCaption = initial
        ? await _captionService.getInitialSharedText()
        : await _captionService.getLatestSharedText();
    final caption = [
      ...textItems,
      ...pluginMessages,
      if (androidCaption.trim().isNotEmpty) androidCaption,
    ].join('\n').trim();
    final signature = '${imagePaths.join('|')}::$caption';

    if (signature == _lastShareSignature) return;

    setState(() {
      _lastShareSignature = signature;
      _pendingSharedDraft = SharedOrderParser.parse(
        caption,
        imagePaths: imagePaths,
      );
    });

    if (initial) {
      await _captionService.resetSharedText();
    }
  }

  void _openPendingSharedDraft(AuthProvider auth) {
    final draft = _pendingSharedDraft;
    if (draft == null || auth.isLoading || auth.user == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingSharedDraft == null) return;

      final context = _navigatorKey.currentContext;
      if (context == null) return;

      if (!auth.isAdmin && !auth.isOffice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only admin or office users can create shared orders.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        setState(() => _pendingSharedDraft = null);
        return;
      }

      final draftToOpen = _pendingSharedDraft!;
      setState(() => _pendingSharedDraft = null);
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => SharedOrderScreen(draft: draftToOpen),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderId = Uri.base.queryParameters['orderId'];
    final token = Uri.base.queryParameters['token'];
    final view = Uri.base.queryParameters['view'];

    return ChangeNotifierProvider.value(
      value: _authProvider,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Ring Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
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

                  _openPendingSharedDraft(auth);

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
