
import 'package:go_router/go_router.dart';
import 'serial/serial_monitor.dart';
import 'setting/setting.dart';
final appRouter = GoRouter(
  initialLocation: "/",
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SerialMonitor()),
    GoRoute(path: '/home', builder: (context, state) => const SerialMonitor()),
    GoRoute(
      path: '/setting',
      builder: (context, state) => const Setting(),
    ),
  ],
);
