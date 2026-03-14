import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/app_localizations.dart';
import '../../viewmodels/task_viewmodel.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'projects_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late ConfettiController _confettiController;

  final List<Widget> _screens = const [
    DashboardScreen(),
    HomeScreen(),
    ProjectsScreen(),
    CalendarScreen(),
    StatisticsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    // Listen for task completion to trigger confetti
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskVM = context.read<TaskViewModel>();
      taskVM.onTaskCompleted = () {
        _confettiController.play();
      };
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final titles = [
      l.get('dashboard'),
      l.get('appName'),
      l.get('projects'),
      l.get('calendar'),
      l.get('statistics'),
      l.get('profile'),
    ];

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(titles[_currentIndex]),
            centerTitle: true,
            actions: [
              // Kanban board button
              IconButton(
                icon: const Icon(Icons.view_kanban_outlined),
                tooltip: l.get('kanbanBoard'),
                onPressed: () => context.push('/kanban'),
              ),
              // Pomodoro timer button
              IconButton(
                icon: const Icon(Icons.timer_outlined),
                tooltip: l.get('pomodoro'),
                onPressed: () => context.push('/pomodoro'),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          body: _screens[_currentIndex],
          floatingActionButton: _currentIndex != 0
              ? FloatingActionButton(
                  onPressed: () => context.push('/add-task'),
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard),
                label: l.get('dashboard'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.task_alt_outlined),
                selectedIcon: const Icon(Icons.task_alt),
                label: l.get('tasks'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.folder_outlined),
                selectedIcon: const Icon(Icons.folder),
                label: l.get('projects'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month),
                label: l.get('calendar'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(Icons.bar_chart),
                label: l.get('statistics'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: l.get('profile'),
              ),
            ],
          ),
        ),
        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.amber,
            ],
            numberOfParticles: 20,
            emissionFrequency: 0.05,
            gravity: 0.15,
          ),
        ),
      ],
    );
  }
}
