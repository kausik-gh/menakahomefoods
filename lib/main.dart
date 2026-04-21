import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';
import 'core/app_localizations.dart';
import 'providers/customer_profile_notifier.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uhdbfavvscwfejmacxuv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoZGJmYXZ2c2N3ZmVqbWFjeHV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0ODE0NzEsImV4cCI6MjA5MjA1NzQ3MX0.CFQvmlQU2a7l_lQyF8s2NJjHIu-of4vx-n22p0G1NMA',
  );

  debugPrint('URL check: Supabase initialized');
  debugPrint('Current user: ${Supabase.instance.client.auth.currentUser}');

  String initialRoute = '/splash';
  final session = Supabase.instance.client.auth.currentSession;

  if (session != null) {
    final email = session.user.email ?? '';
    try {
      final admin = await Supabase.instance.client
          .from('admins')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      if (admin != null) {
        initialRoute = '/admin';
      } else {
        final rider = await Supabase.instance.client
            .from('riders')
            .select('id')
            .eq('email', email)
            .maybeSingle();
        if (rider != null) {
          initialRoute = '/rider';
        } else {
          initialRoute = '/home';
        }
      }
    } catch (e) {
      initialRoute = '/splash';
    }
  }

  bool hasShownError = false;

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;
      Future.delayed(const Duration(seconds: 5), () {
        hasShownError = false;
      });
      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  await Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => CustomerProfileNotifier()..loadFromSupabase(),
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatefulWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    LanguageProvider.instance.addListener(_onLocaleChanged);
    _router = createAppRouter(initialLocation: widget.initialRoute);
  }

  @override
  void dispose() {
    LanguageProvider.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp.router(
          title: 'menakahomefoods',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          locale: LanguageProvider.instance.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
        );
      },
    );
  }
}
