import 'package:flutter/widgets.dart';

import 'src/application/orbit_coordinator.dart';
import 'src/platform/desktop_host.dart';
import 'src/platform/settings_store.dart';
import 'src/presentation/orbit_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = await OrbitSettings.load();
  final host = NativeDesktopHost();
  final coordinator = OrbitCoordinator(host: host, settings: settings);
  await coordinator.initialize();

  runApp(OrbitApp(coordinator: coordinator));
}
