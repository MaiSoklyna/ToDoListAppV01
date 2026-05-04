import 'package:flutter/material.dart';

/// Renders a monochrome PNG icon from `assets/images/icon/` and tints it with
/// the surrounding [IconTheme] so it adapts to light/dark mode and to
/// selected/unselected states (e.g. inside `NavigationBar`, `ListTile`,
/// `IconButton`) without needing per-call color overrides.
///
/// Pass [color] only when you need to override the inherited tint
/// (e.g. an error red for destructive actions).
class AppAssetIcon extends StatelessWidget {
  final String assetPath;
  final double? size;
  final Color? color;

  const AppAssetIcon(this.assetPath, {super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final effectiveSize = size ?? iconTheme.size ?? 24;
    final effectiveColor = color ??
        iconTheme.color ??
        Theme.of(context).colorScheme.onSurface;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      child: Image.asset(
        assetPath,
        width: effectiveSize,
        height: effectiveSize,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Centralised asset paths for the Khmer-modern custom icon set.
/// Keeps file paths out of widget code so a future rename only edits one
/// place.
class AppIcons {
  static const String task = 'assets/images/icon/task.png';
  static const String project = 'assets/images/icon/project.png';
  static const String calendar = 'assets/images/icon/calendar.png';
  static const String statistic = 'assets/images/icon/statistic.png';
  static const String checklist = 'assets/images/icon/checklist.png';
  static const String focus = 'assets/images/icon/focusorPomodoro.png';
  static const String notification = 'assets/images/icon/notification.png';
  static const String setting = 'assets/images/icon/setting.png';
}
