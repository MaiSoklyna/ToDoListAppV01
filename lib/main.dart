import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/task_viewmodel.dart';
import 'viewmodels/category_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/project_viewmodel.dart';
import 'viewmodels/label_viewmodel.dart';
import 'services/notification_service.dart';
import 'services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all services in parallel for fast startup
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Hive.initFlutter(),
  ]);

  // Init settings and notifications
  final settingsVM = SettingsViewModel();
  await settingsVM.init();
  await NotificationService().init();

  final connectivityService = ConnectivityService();
  final taskVM = TaskViewModel();

  // Wire sync-on-reconnect: when connectivity restored, sync pending ops
  connectivityService.onReconnected = () {
    taskVM.onReconnected();
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider.value(value: taskVM),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider.value(value: settingsVM),
        ChangeNotifierProvider(create: (_) => ProjectViewModel()),
        ChangeNotifierProvider(create: (_) => LabelViewModel()),
        ChangeNotifierProvider.value(value: connectivityService),
      ],
      child: const TaskMasterApp(),
    ),
  );
}
