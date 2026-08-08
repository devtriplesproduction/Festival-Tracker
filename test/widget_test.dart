import 'package:provider/provider.dart';
import 'package:festival_tracker/core/services/logger_service.dart';
import 'package:festival_tracker/bootstrap/bootstrap_app.dart';
import 'package:festival_tracker/data/repositories/auth_repository.dart';
import 'package:festival_tracker/data/repositories/local_auth_repository.dart';
import 'package:festival_tracker/data/repositories/app_repository.dart';
import 'package:festival_tracker/providers/app_state.dart';
import 'package:festival_tracker/providers/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(AppState, AuthState)> boot() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalAppRepository(prefs);
    await repo.init();
    final state = AppState(repo);
    await state.init(localStore: true);
    final auth = AuthState(LocalAuthRepository(prefs));
    await auth.init();
    return (state, auth);
  }

  Widget createTestApp(AppState state, AuthState auth) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: auth),
        Provider.value(value: LoggerService()),
      ],
      child: const FestivalTrackerApp(),
    );
  }

  testWidgets('shows login when signed out', (tester) async {
    final (state, auth) = await boot();
    await tester.pumpWidget(createTestApp(state, auth));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Festival Tracker'), findsOneWidget);
  });

  testWidgets('admin login opens pipeline; assign creates job', (tester) async {
    final (state, auth) = await boot();

    final ok = await auth.login(
      AuthRepository.defaultAdminUsername,
      AuthRepository.defaultAdminPassword,
    );
    expect(ok, isTrue);

    await tester.pumpWidget(createTestApp(state, auth));
    await tester.pumpAndSettle();

    expect(find.text('Pipeline'), findsWidgets);
    expect(state.festivals, isNotEmpty);

    final client = await state.saveClient(
      name: 'Acme Jewels',
      whatsappNumber: '919876543210',
    );
    final diwali = state.festivals.firstWhere((f) => f.name == 'Diwali');
    await state.createAssignment(
      clientId: client.id,
      festivalId: diwali.id,
    );
    await tester.pumpAndSettle();

    expect(state.assignments.length, 1);
    expect(find.text('Acme Jewels'), findsOneWidget);
  });
}
