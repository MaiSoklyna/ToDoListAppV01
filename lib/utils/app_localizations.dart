import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;
  }

  /// Look up [key] and substitute `{name}` placeholders with [params].
  String format(String key, Map<String, Object?> params) {
    var s = get(key);
    params.forEach((k, v) {
      s = s.replaceAll('{$k}', '${v ?? ''}');
    });
    return s;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App
      'appName': 'Focus365',
      'loading': 'Loading...',

      // Nav
      'home': 'Home',
      'calendar': 'Calendar',
      'statistics': 'Statistics',
      'profile': 'Profile',
      'settings': 'Settings',
      'projects': 'Projects',

      // Auth
      'welcomeBack': 'Welcome back!',
      'createAccount': 'Create your account',
      'signIn': 'Sign In',
      'register': 'Register',
      'signOut': 'Sign Out',
      'fullName': 'Full Name',
      'email': 'Email',
      'password': 'Password',
      'forgotPassword': 'Forgot Password?',
      'resetPassword': 'Reset Password',
      'alreadyHaveAccount': 'Already have an account? Sign In',
      'dontHaveAccount': "Don't have an account? Register",
      'nameRequired': 'Name is required',
      'emailRequired': 'Email is required',
      'validEmail': 'Enter a valid email',
      'passwordRequired': 'Password is required',
      'passwordLength': 'At least 6 characters',
      'send': 'Send',
      'cancel': 'Cancel',
      'passwordResetSent': 'Password reset email sent!',
      'signOutConfirm': 'Are you sure you want to sign out?',

      // Tasks
      'addTask': 'Add Task',
      'editTask': 'Edit Task',
      'deleteTask': 'Delete Task',
      'deleteConfirm': 'Delete',
      'taskTitle': 'Task Title',
      'taskTitleHint': 'What do you need to do?',
      'titleRequired': 'Title is required',
      'description': 'Description (optional)',
      'descriptionHint': 'Add details...',
      'dueDate': 'Due Date',
      'pickDate': 'Pick date',
      'setTime': 'Set time',
      'priority': 'Priority',
      'low': 'Low',
      'medium': 'Medium',
      'high': 'High',
      'category': 'Category',
      'subtasks': 'Subtasks',
      'addSubtask': 'Add a subtask...',
      'save': 'Save',
      'taskColor': 'Task Color',
      'noColor': 'No color',

      // Projects
      'project': 'Project',
      'addProject': 'Add Project',
      'editProject': 'Edit Project',
      'deleteProject': 'Delete Project',
      'deleteProjectConfirm': 'Delete this project and unlink its tasks?',
      'projectName': 'Project Name',
      'inbox': 'Inbox',
      'noProjectsYet': 'No projects yet.\nCreate one to organize your tasks!',
      'projectNotFound': 'Project not found',

      // Labels
      'labels': 'Labels',
      'addLabel': 'Add Label',
      'editLabel': 'Edit Label',
      'deleteLabel': 'Delete Label',
      'labelName': 'Label Name',

      // Recurrence
      'recurrence': 'Repeat',
      'noRecurrence': 'No repeat',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'every': 'Every',
      'days': 'day(s)',
      'weeks': 'week(s)',
      'months': 'month(s)',
      'mon': 'M',
      'tue': 'T',
      'wed': 'W',
      'thu': 'T',
      'fri': 'F',
      'sat': 'S',
      'sun': 'S',

      // Attachments
      'attachments': 'Attachments',
      'addAttachment': 'Add note or link...',

      // Home
      'all': 'All',
      'active': 'Active',
      'done': 'Done',
      'completed': 'Completed',
      'searchTasks': 'Search tasks...',
      'noTasksYet': 'No tasks yet!\nTap + to add one',
      'noCompletedTasks': 'No completed tasks yet',
      'today': 'Today',
      'tomorrow': 'Tomorrow',
      'yesterday': 'Yesterday',

      // Calendar
      'noTasksForDay': 'No tasks for this day',
      'task': 'task',
      'tasks': 'tasks',

      // Statistics
      'total': 'Total',
      'completionRate': 'Completion Rate',
      'thisWeek': 'This Week',
      'byCategory': 'By Category',
      'byPriority': 'By Priority',
      'noTasksStats': 'No tasks yet!\nAdd tasks to see statistics',

      // Profile
      'guestUser': 'Guest User',
      'notSignedIn': 'Not signed in',
      'signInToSync': 'Sign in to sync your tasks across devices',

      // Settings
      'theme': 'Theme',
      'darkMode': 'Dark Mode',
      'lightMode': 'Light Mode',
      'systemDefault': 'System Default',
      'language': 'Language',
      'english': 'English',
      'khmer': 'ខ្មែរ',
      'notifications': 'Notifications',
      'manageReminders': 'Manage reminders',
      'notificationsSoon': 'Notification settings coming soon!',
      'about': 'About',
      'helpSupport': 'Help & Support',
      'help': 'Help',

      // Onboarding
      'skip': 'Skip',
      'next': 'Next',
      'getStarted': 'Get Started',
      'onboardTitle1': 'Manage Your Tasks',
      'onboardDesc1': 'Create, organize, and track all your tasks in one place. Set priorities, categories, and due dates.',
      'onboardTitle2': 'Calendar View',
      'onboardDesc2': 'See your tasks on a calendar. Plan your week and never miss a deadline.',
      'onboardTitle3': 'Track Progress',
      'onboardDesc3': 'View statistics and charts to understand your productivity patterns.',
      'onboardTitle4': 'Safe & Secure',
      'onboardDesc4': 'Your data is protected with Firebase security. Sign in to sync across all your devices.',

      // Help & FAQ
      'quickTips': 'Quick Tips',
      'quickTipsDesc': 'Swipe left on a task to delete. Tap a task to see details. Use the + button to add new tasks.',
      'faq': 'Frequently Asked Questions',
      'faq1Q': 'How do I create a task?',
      'faq1A': 'Tap the + button at the bottom of the home screen. Fill in the title, description, priority, category, and due date, then tap Save.',
      'faq2Q': 'How do I edit a task?',
      'faq2A': 'Tap on any task to view its details. From the detail view, you can edit all task properties.',
      'faq3Q': 'How do I delete a task?',
      'faq3A': 'Swipe the task card to the left, or tap on it and use the delete option.',
      'faq4Q': 'Can I use the app offline?',
      'faq4A': 'Yes! Tasks are cached locally so you can view them offline. Changes will sync when you reconnect.',
      'faq5Q': 'How do I change the language?',
      'faq5A': 'Go to Settings and select your preferred language (English or Khmer).',
      'contactSupport': 'Contact Support',
      'emailSupport': 'Email Support',
      'sendFeedback': 'Send Feedback',
      'sendFeedbackDesc': 'Tell us how we can improve',
      'feedbackHint': 'Share your thoughts...',
      'feedbackThanks': 'Thank you for your feedback!',

      // Share
      'shareTask': 'Share Task',
      'shareTaskText': 'Task: {title}\nPriority: {priority}\nCategory: {category}',

      // Data protection
      'dataProtection': 'Data Protection',
      'dataProtectionDesc': 'Your data is encrypted and secured',
      'privacyPolicy': 'Privacy Policy',

      // Pomodoro
      'pomodoro': 'Pomodoro Timer',
      'focusTime': 'Focus Time',
      'breakTime': 'Break Time',
      'session': 'Session',
      'pomodorosCompleted': 'pomodoros completed',
      'focusOn': 'Focus on a task',
      'selectTask': 'Select a task...',
      'noTaskSelected': 'No task selected',

      // Biometric
      'biometricLock': 'Biometric Lock',
      'biometricLockDesc': 'Use fingerprint or face to unlock',

      // Export
      'exportData': 'Export Data',
      'exportDataDesc': 'Export tasks as PDF or CSV',
      'exportPdfDesc': 'Professional report with charts',
      'exportCsvDesc': 'Spreadsheet-compatible format',
      'exportSuccess': 'File exported successfully!',
      'open': 'Open',

      // Notifications settings
      'notificationsEnabled': 'Notifications are enabled',
      'notificationsDisabled': 'Notifications are disabled',

      // Profile
      'editProfile': 'Edit Profile',
      'memberSince': 'Member since',

      // Connectivity
      'offlineMode': 'You are offline. Changes will sync when reconnected.',

      // Streaks & Productivity
      'productivityScore': 'Productivity Score',
      'currentStreak': 'Current Streak',
      'bestStreak': 'Best Streak',
      'totalDone': 'Total Done',

      // Dashboard
      'dashboard': 'Dashboard',
      'goodMorning': 'Good Morning!',
      'goodAfternoon': 'Good Afternoon!',
      'goodEvening': 'Good Evening!',
      'streak': 'Streak',
      'score': 'Score',
      'overdue': 'Overdue',
      'quickAdd': 'Quick Add',
      'templateShopping': 'Shopping',
      'templateWorkout': 'Workout',
      'templateStudy': 'Study',
      'templateMeeting': 'Meeting',
      'templateCall': 'Phone Call',
      'todayTasks': "Today's Tasks",
      'noTasksToday': 'All clear for today!',
      'upcoming': 'Upcoming',

      // Kanban
      'kanbanBoard': 'Kanban Board',
      'toDo': 'To Do',
      'inProgress': 'In Progress',

      // Sorting & Batch
      'sortBy': 'Sort by',
      'sortCreated': 'Date Created',
      'sortPriority': 'Priority',
      'sortDueDate': 'Due Date',
      'sortName': 'Name',
      'batchMode': 'Batch Mode',
      'selected': 'selected',
      'markComplete': 'Mark Complete',
      'batchDeleteConfirm': 'Delete selected tasks?',
      'deleted': 'deleted',
      'undo': 'Undo',

      // Drawer / Top bar
      'search': 'Search',
      'sharedLists': 'Shared lists',
      'notes': 'Notes',
      'navigate': 'Navigate',
      'tools': 'Tools',
      'categories': 'Categories',

      // Home filters & sections
      'important': 'Important',
      'assignedToMe': 'Assigned to me',
      'later': 'Later',
      'noDate': 'No date',
      'tasksTodayOne': '1 task today',
      'tasksTodayOther': '{count} tasks today',
      'overdueOne': '1 overdue',
      'overdueOther': '{count} overdue',
      'categoryFilter': 'Category · {name}',
      'projectFilter': 'Project · {name}',

      // Pomodoro
      'focusingOn': 'Focusing on',
      'sessionOne': '1 session',
      'sessionOther': '{count} sessions',

      // Settings extras
      'restoreBackup': 'Restore from backup',
      'restoreBackupDesc': 'Append items from a previous JSON backup',
      'newTaskDefaults': 'New-task defaults',
      'newTaskDefaultsDesc': 'Applied when you create a task',
      'defaultReminder': 'Default reminder',
      'defaultCategoryTitle': 'Default category',
      'priorityMed': 'Med',
      'appDescription':
          'A full-featured task management app with Firebase integration, offline support, and multi-language support.',
      'reminderOff': 'Off',
      'reminderAtDue': 'At due time',
      'reminderMinBefore': '{n} min before',
      'reminderHourBeforeOne': '1 hour before',
      'reminderHourBeforeOther': '{n} hours before',
      'reminderDayBeforeOne': '1 day before',
      'reminderDayBeforeOther': '{n} days before',
      'pickFileFromDevice': 'Pick a file from device…',
      'recentBackups': 'Recent backups',
      'cantReadFile':
          "Couldn't read the selected file. Try a different location.",
      'restoreThisBackup': 'Restore this backup?',
      'restoreWarning':
          'Existing items with the same id will be kept; only new items will be added. This action cannot be undone.',
      'restoreAction': 'Restore',
      'signInToRestore': 'Sign in to restore a backup.',
      'restoreFailed': 'Restore failed: {error}',
      'jsonBackup': 'JSON backup',
      'jsonBackupDesc': 'Full snapshot — tasks, projects, labels, notes',
      'editCategory': 'Edit category',
      'addCategory': 'Add category',
      'name': 'Name',
      'icon': 'Icon',
      'color': 'Color',
      'builtIn': 'Built-in',

      // Add task screen
      'pleaseSignInToSave': 'Please sign in to save tasks.',
      'list': 'List',
      'myTasks': 'My Tasks',
      'assignee': 'Assignee',
      'unassigned': 'Unassigned',
      'reminders': 'Reminders',
      'pickEmoji': 'Pick an emoji',
      'clear': 'Clear',
      'saveFirstForReminders': 'Save the task first to add reminders',
      'noRemindersTap': 'No reminders — tap to add',
      'reminderOne': '1 reminder',
      'reminderOther': '{count} reminders',

      // Quick add sheet
      'whatNeedsDoing': 'What needs doing?',
      'moreOptions': 'More options',
      'addTaskAction': 'Add task',

      // Notes screen
      'noNotesYet': 'No notes yet',
      'tapPlusToCapture': 'Tap + to capture a quick thought.',
      'untitled': 'Untitled',
      'deleteNoteQ': 'Delete note?',
      'thisCannotBeUndone': 'This cannot be undone.',
      'delete': 'Delete',
      'title': 'Title',
      'note': 'Note',
      'untitledNote': '(Untitled note)',

      // Search screen
      'searchTasksAndNotes': 'Search tasks and notes',
      'startTypingToSearch': 'Start typing to search',
      'noResultsFor': 'No results for "{query}"',

      // Calendar
      'allDay': 'All day',
      'thirtyDaysAgo': '30d ago',

      // Statistics
      'last30Days': 'Last 30 days',
      'byDayOfWeek': 'By day of week',
    },
    'km': {
      // App
      'appName': 'Focus365',
      'loading': 'កំពុងផ្ទុក...',

      // Nav
      'home': 'ទំព័រដើម',
      'calendar': 'ប្រតិទិន',
      'statistics': 'ស្ថិតិ',
      'profile': 'ប្រវត្តិរូប',
      'settings': 'ការកំណត់',
      'projects': 'គម្រោង',

      // Auth
      'welcomeBack': 'សូមស្វាគមន៍មកវិញ!',
      'createAccount': 'បង្កើតគណនីរបស់អ្នក',
      'signIn': 'ចូល',
      'register': 'ចុះឈ្មោះ',
      'signOut': 'ចាកចេញ',
      'fullName': 'ឈ្មោះពេញ',
      'email': 'អ៊ីមែល',
      'password': 'ពាក្យសម្ងាត់',
      'forgotPassword': 'ភ្លេចពាក្យសម្ងាត់?',
      'resetPassword': 'កំណត់ពាក្យសម្ងាត់ឡើងវិញ',
      'alreadyHaveAccount': 'មានគណនីរួចហើយ? ចូល',
      'dontHaveAccount': 'មិនមានគណនី? ចុះឈ្មោះ',
      'nameRequired': 'ត្រូវការឈ្មោះ',
      'emailRequired': 'ត្រូវការអ៊ីមែល',
      'validEmail': 'សូមបញ្ចូលអ៊ីមែលត្រឹមត្រូវ',
      'passwordRequired': 'ត្រូវការពាក្យសម្ងាត់',
      'passwordLength': 'យ៉ាងតិច ៦ តួអក្សរ',
      'send': 'ផ្ញើ',
      'cancel': 'បោះបង់',
      'passwordResetSent': 'អ៊ីមែលកំណត់ពាក្យសម្ងាត់ឡើងវិញត្រូវបានផ្ញើ!',
      'signOutConfirm': 'តើអ្នកពិតជាចង់ចាកចេញមែនទេ?',

      // Tasks
      'addTask': 'បន្ថែមភារកិច្ច',
      'editTask': 'កែសម្រួលភារកិច្ច',
      'deleteTask': 'លុបភារកិច្ច',
      'deleteConfirm': 'លុប',
      'taskTitle': 'ចំណងជើងភារកិច្ច',
      'taskTitleHint': 'តើអ្នកត្រូវធ្វើអ្វី?',
      'titleRequired': 'ត្រូវការចំណងជើង',
      'description': 'ការពិពណ៌នា (ស្រេចចិត្ត)',
      'descriptionHint': 'បន្ថែមព័ត៌មានលម្អិត...',
      'dueDate': 'កាលបរិច្ឆេទកំណត់',
      'pickDate': 'ជ្រើសរើសកាលបរិច្ឆេទ',
      'setTime': 'កំណត់ម៉ោង',
      'priority': 'អាទិភាព',
      'low': 'ទាប',
      'medium': 'មធ្យម',
      'high': 'ខ្ពស់',
      'category': 'ប្រភេទ',
      'subtasks': 'ភារកិច្ចរង',
      'addSubtask': 'បន្ថែមភារកិច្ចរង...',
      'save': 'រក្សាទុក',
      'taskColor': 'ពណ៌ភារកិច្ច',
      'noColor': 'គ្មានពណ៌',

      // Projects
      'project': 'គម្រោង',
      'addProject': 'បន្ថែមគម្រោង',
      'editProject': 'កែសម្រួលគម្រោង',
      'deleteProject': 'លុបគម្រោង',
      'deleteProjectConfirm': 'លុបគម្រោងនេះ និងផ្ដាច់ភារកិច្ចរបស់វា?',
      'projectName': 'ឈ្មោះគម្រោង',
      'inbox': 'ប្រអប់សំបុត្រ',
      'noProjectsYet': 'មិនមានគម្រោងនៅឡើយ។\nបង្កើតមួយដើម្បីរៀបចំភារកិច្ច!',
      'projectNotFound': 'រកមិនឃើញគម្រោង',

      // Labels
      'labels': 'ស្លាក',
      'addLabel': 'បន្ថែមស្លាក',
      'editLabel': 'កែសម្រួលស្លាក',
      'deleteLabel': 'លុបស្លាក',
      'labelName': 'ឈ្មោះស្លាក',

      // Recurrence
      'recurrence': 'ធ្វើម្ដងទៀត',
      'noRecurrence': 'មិនធ្វើម្ដងទៀត',
      'daily': 'ប្រចាំថ្ងៃ',
      'weekly': 'ប្រចាំសប្ដាហ៍',
      'monthly': 'ប្រចាំខែ',
      'every': 'រៀងរាល់',
      'days': 'ថ្ងៃ',
      'weeks': 'សប្ដាហ៍',
      'months': 'ខែ',
      'mon': 'ច',
      'tue': 'អ',
      'wed': 'ព',
      'thu': 'ព្រ',
      'fri': 'សុ',
      'sat': 'ស',
      'sun': 'អា',

      // Attachments
      'attachments': 'ឯកសារភ្ជាប់',
      'addAttachment': 'បន្ថែមកំណត់ត្រា ឬតំណ...',

      // Home
      'all': 'ទាំងអស់',
      'active': 'សកម្ម',
      'done': 'រួចរាល់',
      'completed': 'បានបញ្ចប់',
      'searchTasks': 'ស្វែងរកភារកិច្ច...',
      'noTasksYet': 'មិនមានភារកិច្ចនៅឡើយ!\nចុច + ដើម្បីបន្ថែម',
      'noCompletedTasks': 'មិនមានភារកិច្ចបានបញ្ចប់នៅឡើយ',
      'today': 'ថ្ងៃនេះ',
      'tomorrow': 'ថ្ងៃស្អែក',
      'yesterday': 'ម្សិលមិញ',

      // Calendar
      'noTasksForDay': 'មិនមានភារកិច្ចសម្រាប់ថ្ងៃនេះ',
      'task': 'ភារកិច្ច',
      'tasks': 'ភារកិច្ច',

      // Statistics
      'total': 'សរុប',
      'completionRate': 'អត្រាបញ្ចប់',
      'thisWeek': 'សប្ដាហ៍នេះ',
      'byCategory': 'តាមប្រភេទ',
      'byPriority': 'តាមអាទិភាព',
      'noTasksStats': 'មិនមានភារកិច្ចនៅឡើយ!\nបន្ថែមភារកិច្ចដើម្បីមើលស្ថិតិ',

      // Profile
      'guestUser': 'អ្នកប្រើភ្ញៀវ',
      'notSignedIn': 'មិនបានចូល',
      'signInToSync': 'ចូលដើម្បីធ្វើសមកាលកម្មភារកិច្ចរបស់អ្នកឆ្លងឧបករណ៍',

      // Settings
      'theme': 'រចនាប័ទ្ម',
      'darkMode': 'របៀបងងឹត',
      'lightMode': 'របៀបភ្លឺ',
      'systemDefault': 'លំនាំដើមប្រព័ន្ធ',
      'language': 'ភាសា',
      'english': 'English',
      'khmer': 'ខ្មែរ',
      'notifications': 'ការជូនដំណឹង',
      'manageReminders': 'គ្រប់គ្រងការរំលឹក',
      'notificationsSoon': 'ការកំណត់ការជូនដំណឹងនឹងមកដល់ឆាប់ៗ!',
      'about': 'អំពី',
      'helpSupport': 'ជំនួយ និងការគាំទ្រ',
      'help': 'ជំនួយ',

      // Onboarding
      'skip': 'រំលង',
      'next': 'បន្ទាប់',
      'getStarted': 'ចាប់ផ្ដើម',
      'onboardTitle1': 'គ្រប់គ្រងភារកិច្ចរបស់អ្នក',
      'onboardDesc1': 'បង្កើត រៀបចំ និងតាមដានភារកិច្ចទាំងអស់នៅកន្លែងតែមួយ។ កំណត់អាទិភាព ប្រភេទ និងកាលបរិច្ឆេទកំណត់។',
      'onboardTitle2': 'ទិដ្ឋភាពប្រតិទិន',
      'onboardDesc2': 'មើលភារកិច្ចរបស់អ្នកនៅលើប្រតិទិន។ គ្រោងផែនការសប្ដាហ៍របស់អ្នក។',
      'onboardTitle3': 'តាមដានវឌ្ឍនភាព',
      'onboardDesc3': 'មើលស្ថិតិ និងតារាងដើម្បីយល់ពីលំនាំផលិតភាពរបស់អ្នក។',
      'onboardTitle4': 'សុវត្ថិភាព',
      'onboardDesc4': 'ទិន្នន័យរបស់អ្នកត្រូវបានការពារដោយ Firebase។ ចូលដើម្បីធ្វើសមកាលកម្មឆ្លងឧបករណ៍។',

      // Help & FAQ
      'quickTips': 'គន្លឹះរហ័ស',
      'quickTipsDesc': 'អូសទៅឆ្វេងដើម្បីលុប។ ចុចភារកិច្ចដើម្បីមើលព័ត៌មានលម្អិត។ ប្រើប៊ូតុង + ដើម្បីបន្ថែម។',
      'faq': 'សំណួរដែលសួរញឹកញាប់',
      'faq1Q': 'តើខ្ញុំបង្កើតភារកិច្ចដោយរបៀបណា?',
      'faq1A': 'ចុចប៊ូតុង + បំពេញព័ត៌មាន រួចចុចរក្សាទុក។',
      'faq2Q': 'តើខ្ញុំកែភារកិច្ចដោយរបៀបណា?',
      'faq2A': 'ចុចលើភារកិច្ចណាមួយដើម្បីមើល និងកែសម្រួល។',
      'faq3Q': 'តើខ្ញុំលុបភារកិច្ចដោយរបៀបណា?',
      'faq3A': 'អូសកាតភារកិច្ចទៅឆ្វេង។',
      'faq4Q': 'តើខ្ញុំអាចប្រើកម្មវិធីដោយគ្មានអ៊ីនធឺណិតបានទេ?',
      'faq4A': 'បាន! ភារកិច្ចត្រូវបានរក្សាទុកក្នុងឧបករណ៍។ ការផ្លាស់ប្ដូរនឹងធ្វើសមកាលកម្មពេលភ្ជាប់ឡើងវិញ។',
      'faq5Q': 'តើខ្ញុំផ្លាស់ប្ដូរភាសាដោយរបៀបណា?',
      'faq5A': 'ចូលទៅការកំណត់ រួចជ្រើសរើសភាសាដែលអ្នកចង់បាន។',
      'contactSupport': 'ទាក់ទងផ្នែកគាំទ្រ',
      'emailSupport': 'អ៊ីមែលគាំទ្រ',
      'sendFeedback': 'ផ្ញើមតិកែលម្អ',
      'sendFeedbackDesc': 'ប្រាប់ពួកយើងពីរបៀបធ្វើឱ្យប្រសើរឡើង',
      'feedbackHint': 'ចែករំលែកគំនិតរបស់អ្នក...',
      'feedbackThanks': 'សូមអរគុណសម្រាប់មតិកែលម្អរបស់អ្នក!',

      // Share
      'shareTask': 'ចែករំលែកភារកិច្ច',
      'shareTaskText': 'ភារកិច្ច: {title}\nអាទិភាព: {priority}\nប្រភេទ: {category}',

      // Data protection
      'dataProtection': 'ការការពារទិន្នន័យ',
      'dataProtectionDesc': 'ទិន្នន័យរបស់អ្នកត្រូវបានអ៊ិនគ្រីប និងការពារ',
      'privacyPolicy': 'គោលការណ៍ឯកជនភាព',

      // Pomodoro
      'pomodoro': 'កម្មវិធីកំណត់ម៉ោង Pomodoro',
      'focusTime': 'ពេលផ្ដោត',
      'breakTime': 'ពេលសម្រាក',
      'session': 'វគ្គ',
      'pomodorosCompleted': 'Pomodoro បានបញ្ចប់',
      'focusOn': 'ផ្ដោតលើភារកិច្ច',
      'selectTask': 'ជ្រើសរើសភារកិច្ច...',
      'noTaskSelected': 'មិនបានជ្រើសរើសភារកិច្ច',

      // Biometric
      'biometricLock': 'ចាក់សោជីវមាត្រ',
      'biometricLockDesc': 'ប្រើស្នាមម្រាមដៃ ឬមុខដើម្បីដោះសោ',

      // Export
      'exportData': 'នាំចេញទិន្នន័យ',
      'exportDataDesc': 'នាំចេញភារកិច្ចជា PDF ឬ CSV',
      'exportPdfDesc': 'របាយការណ៍វិជ្ជាជីវៈជាមួយតារាង',
      'exportCsvDesc': 'ទម្រង់ដែលឆបគ្នានឹង Spreadsheet',
      'exportSuccess': 'ឯកសារត្រូវបាននាំចេញដោយជោគជ័យ!',
      'open': 'បើក',

      // Notifications settings
      'notificationsEnabled': 'ការជូនដំណឹងត្រូវបានបើក',
      'notificationsDisabled': 'ការជូនដំណឹងត្រូវបានបិទ',

      // Profile
      'editProfile': 'កែសម្រួលប្រវត្តិរូប',
      'memberSince': 'សមាជិកតាំងពី',

      // Connectivity
      'offlineMode': 'អ្នកមិនបានតភ្ជាប់អ៊ីនធឺណិត។ ការផ្លាស់ប្ដូរនឹងធ្វើសមកាលកម្មពេលភ្ជាប់ឡើងវិញ។',

      // Streaks & Productivity
      'productivityScore': 'ពិន្ទុផលិតភាព',
      'currentStreak': 'គ្រាបច្ចុប្បន្ន',
      'bestStreak': 'គ្រាល្អបំផុត',
      'totalDone': 'សរុបបានធ្វើ',

      // Dashboard
      'dashboard': 'ផ្ទាំងគ្រប់គ្រង',
      'goodMorning': 'អរុណសួស្តី!',
      'goodAfternoon': 'ទិវាសួស្តី!',
      'goodEvening': 'សាយណ្ហសួស្តី!',
      'streak': 'គ្រា',
      'score': 'ពិន្ទុ',
      'overdue': 'ហួសកំណត់',
      'quickAdd': 'បន្ថែមរហ័ស',
      'templateShopping': 'ទិញទំនិញ',
      'templateWorkout': 'ហាត់ប្រាណ',
      'templateStudy': 'សិក្សា',
      'templateMeeting': 'កិច្ចប្រជុំ',
      'templateCall': 'ទូរស័ព្ទ',
      'todayTasks': 'ភារកិច្ចថ្ងៃនេះ',
      'noTasksToday': 'គ្មានភារកិច្ចសម្រាប់ថ្ងៃនេះ!',
      'upcoming': 'នាពេលខាងមុខ',

      // Kanban
      'kanbanBoard': 'ក្ដារ Kanban',
      'toDo': 'ត្រូវធ្វើ',
      'inProgress': 'កំពុងដំណើរការ',

      // Sorting & Batch
      'sortBy': 'តម្រៀបតាម',
      'sortCreated': 'កាលបរិច្ឆេទបង្កើត',
      'sortPriority': 'អាទិភាព',
      'sortDueDate': 'កាលបរិច្ឆេទកំណត់',
      'sortName': 'ឈ្មោះ',
      'batchMode': 'របៀបបាច់',
      'selected': 'បានជ្រើសរើស',
      'markComplete': 'សម្គាល់ថាបានបញ្ចប់',
      'batchDeleteConfirm': 'លុបភារកិច្ចដែលបានជ្រើសរើស?',
      'deleted': 'បានលុប',
      'undo': 'មិនធ្វើវិញ',

      // Drawer / Top bar
      'search': 'ស្វែងរក',
      'sharedLists': 'បញ្ជីរួម',
      'notes': 'កំណត់ត្រា',
      'navigate': 'រុករក',
      'tools': 'ឧបករណ៍',
      'categories': 'ប្រភេទ',

      // Home filters & sections
      'important': 'សំខាន់',
      'assignedToMe': 'បានកំណត់ឱ្យខ្ញុំ',
      'later': 'ពេលក្រោយ',
      'noDate': 'គ្មានកាលបរិច្ឆេទ',
      'tasksTodayOne': 'ភារកិច្ច ១ ថ្ងៃនេះ',
      'tasksTodayOther': 'ភារកិច្ច {count} ថ្ងៃនេះ',
      'overdueOne': 'ហួសកំណត់ ១',
      'overdueOther': 'ហួសកំណត់ {count}',
      'categoryFilter': 'ប្រភេទ · {name}',
      'projectFilter': 'គម្រោង · {name}',

      // Pomodoro
      'focusingOn': 'កំពុងផ្ដោតលើ',
      'sessionOne': 'វគ្គ ១',
      'sessionOther': 'វគ្គ {count}',

      // Settings extras
      'restoreBackup': 'ស្ដារពីការបម្រុងទុក',
      'restoreBackupDesc': 'បន្ថែមធាតុពីការបម្រុងទុក JSON មុន',
      'newTaskDefaults': 'លំនាំដើមភារកិច្ចថ្មី',
      'newTaskDefaultsDesc': 'អនុវត្តពេលអ្នកបង្កើតភារកិច្ច',
      'defaultReminder': 'ការរំលឹកលំនាំដើម',
      'defaultCategoryTitle': 'ប្រភេទលំនាំដើម',
      'priorityMed': 'មធ្យម',
      'appDescription':
          'កម្មវិធីគ្រប់គ្រងភារកិច្ចពេញលេញដែលមាន Firebase ការគាំទ្រគ្មានអ៊ីនធឺណិត និងពហុភាសា។',
      'reminderOff': 'បិទ',
      'reminderAtDue': 'នៅពេលកំណត់',
      'reminderMinBefore': '{n} នាទីមុន',
      'reminderHourBeforeOne': '១ ម៉ោងមុន',
      'reminderHourBeforeOther': '{n} ម៉ោងមុន',
      'reminderDayBeforeOne': '១ ថ្ងៃមុន',
      'reminderDayBeforeOther': '{n} ថ្ងៃមុន',
      'pickFileFromDevice': 'ជ្រើសរើសឯកសារពីឧបករណ៍…',
      'recentBackups': 'ការបម្រុងទុកថ្មីៗ',
      'cantReadFile':
          'មិនអាចអានឯកសារដែលបានជ្រើសរើស។ សូមសាកមួយផ្សេង។',
      'restoreThisBackup': 'ស្ដារការបម្រុងទុកនេះ?',
      'restoreWarning':
          'ធាតុដែលមាន id ដូចគ្នានឹងត្រូវរក្សាទុក។ មានតែធាតុថ្មីប៉ុណ្ណោះនឹងត្រូវបន្ថែម។ សកម្មភាពនេះមិនអាចមិនធ្វើវិញបានទេ។',
      'restoreAction': 'ស្ដារ',
      'signInToRestore': 'ចូលដើម្បីស្ដារការបម្រុងទុក។',
      'restoreFailed': 'ការស្ដារបរាជ័យ: {error}',
      'jsonBackup': 'ការបម្រុងទុក JSON',
      'jsonBackupDesc': 'ការថតយកពេញលេញ — ភារកិច្ច គម្រោង ស្លាក កំណត់ត្រា',
      'editCategory': 'កែសម្រួលប្រភេទ',
      'addCategory': 'បន្ថែមប្រភេទ',
      'name': 'ឈ្មោះ',
      'icon': 'រូបតំណាង',
      'color': 'ពណ៌',
      'builtIn': 'លំនាំដើម',

      // Add task screen
      'pleaseSignInToSave': 'សូមចូលដើម្បីរក្សាទុកភារកិច្ច។',
      'list': 'បញ្ជី',
      'myTasks': 'ភារកិច្ចរបស់ខ្ញុំ',
      'assignee': 'អ្នកទទួល',
      'unassigned': 'មិនបានកំណត់',
      'reminders': 'ការរំលឹក',
      'pickEmoji': 'ជ្រើសរើសអ៊ីម៉ូជី',
      'clear': 'សម្អាត',
      'saveFirstForReminders': 'រក្សាទុកមុនដើម្បីបន្ថែមការរំលឹក',
      'noRemindersTap': 'គ្មានការរំលឹក — ចុចដើម្បីបន្ថែម',
      'reminderOne': 'ការរំលឹក ១',
      'reminderOther': 'ការរំលឹក {count}',

      // Quick add sheet
      'whatNeedsDoing': 'តើត្រូវធ្វើអ្វី?',
      'moreOptions': 'ជម្រើសផ្សេងទៀត',
      'addTaskAction': 'បន្ថែមភារកិច្ច',

      // Notes screen
      'noNotesYet': 'មិនមានកំណត់ត្រានៅឡើយ',
      'tapPlusToCapture': 'ចុច + ដើម្បីសរសេរគំនិតរហ័ស។',
      'untitled': 'គ្មានចំណងជើង',
      'deleteNoteQ': 'លុបកំណត់ត្រា?',
      'thisCannotBeUndone': 'សកម្មភាពនេះមិនអាចមិនធ្វើវិញបានទេ។',
      'delete': 'លុប',
      'title': 'ចំណងជើង',
      'note': 'កំណត់ត្រា',
      'untitledNote': '(កំណត់ត្រាគ្មានចំណងជើង)',

      // Search screen
      'searchTasksAndNotes': 'ស្វែងរកភារកិច្ច និងកំណត់ត្រា',
      'startTypingToSearch': 'ចាប់ផ្ដើមវាយដើម្បីស្វែងរក',
      'noResultsFor': 'គ្មានលទ្ធផលសម្រាប់ "{query}"',

      // Calendar
      'allDay': 'ពេញមួយថ្ងៃ',
      'thirtyDaysAgo': '៣០ថ្ងៃមុន',

      // Statistics
      'last30Days': 'ថ្ងៃចុងក្រោយ ៣០',
      'byDayOfWeek': 'តាមថ្ងៃនៃសប្ដាហ៍',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'km'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
