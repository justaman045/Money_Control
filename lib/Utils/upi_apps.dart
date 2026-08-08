import 'dart:ui';

/// A UPI payment app shown in the app-chooser step.
class UpiAppDescriptor {
  final String name;
  final String? package;
  final String icon;
  final Color color;

  const UpiAppDescriptor({
    required this.name,
    this.package,
    required this.icon,
    required this.color,
  });

  /// Whether this entry opens the Android system UPI chooser instead of a
  /// specific installed app.
  bool get isSystemChooser => package == null;
}

/// Filters [pinned] UPI apps down to the ones actually installed on the
/// device, then appends any additional installed UPI apps (not in [pinned])
/// using their real label from the OS.
///
/// [installedPackages] maps package name → display label as reported by the
/// platform. System-chooser entries (null package) in [pinned] are hidden
/// whenever at least one UPI app is installed; they are used only as a
/// fallback so the flow never dead-ends when nothing is installed.
List<UpiAppDescriptor> filterInstalledUpiApps({
  required List<UpiAppDescriptor> pinned,
  required Map<String, String> installedPackages,
  required Color fallbackColor,
}) {
  final result = <UpiAppDescriptor>[];

  for (final app in pinned) {
    // System-chooser entries are only a fallback (see below).
    if (app.package == null) continue;
    if (installedPackages.containsKey(app.package)) result.add(app);
  }

  for (final entry in installedPackages.entries) {
    final alreadyShown = result.any((a) => a.package == entry.key);
    if (alreadyShown) continue;
    final label = entry.value.trim().isEmpty ? entry.key : entry.value.trim();
    result.add(
      UpiAppDescriptor(
        name: label,
        package: entry.key,
        icon: label.substring(0, 1).toUpperCase(),
        color: fallbackColor,
      ),
    );
  }

  if (result.isEmpty) {
    result.addAll(pinned.where((a) => a.package == null));
  }

  return result;
}
