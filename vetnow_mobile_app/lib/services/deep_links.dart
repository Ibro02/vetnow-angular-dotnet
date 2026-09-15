import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';

import 'crash_log.dart';

/// Where a link wants to go.
///
/// Immutable, and marked as such: the shell compares an incoming link
/// against the last one it acted on, so equality has to be by value, and
/// value equality on something that can change is a bug waiting for a
/// mutation.
@immutable
sealed class DeepLink {
  const DeepLink();
}

/// One clinic's page.
class ClinicLink extends DeepLink {
  final int id;
  const ClinicLink(this.id);

  @override
  bool operator ==(Object other) => other is ClinicLink && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ClinicLink($id)';
}

/// One of the three tabs.
enum Destination { explore, appointments, profile }

class TabLink extends DeepLink {
  final Destination destination;
  const TabLink(this.destination);

  @override
  bool operator ==(Object other) =>
      other is TabLink && other.destination == destination;

  @override
  int get hashCode => destination.hashCode;

  @override
  String toString() => 'TabLink($destination)';
}

/// Turns an incoming URI into something the app can act on.
///
/// Two spellings have to work and mean the same thing:
///
///   vetnow://clinic/3
///   https://vetnow.ba/clinic/3
///
/// The first works today with nothing but the manifest. The second only
/// opens without a chooser once the domain serves an assetlinks.json
/// naming this app's signing certificate — until then Android asks which
/// app to use, which is a worse experience but not a broken one.
///
/// Deliberately a pure function over a Uri: this is the part that can be
/// tested, and link parsing is exactly where a typo produces a link that
/// silently opens the wrong page.
DeepLink? parseDeepLink(Uri uri) {
  // A custom-scheme URI puts the first segment in the host
  // (vetnow://clinic/3 → host "clinic", path "/3"); an https one puts it
  // in the path (https://vetnow.ba/clinic/3 → host "vetnow.ba").
  final segments = <String>[
    if (uri.scheme == 'vetnow' && uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments.where((s) => s.isNotEmpty),
  ];

  if (segments.isEmpty) return const TabLink(Destination.explore);

  switch (segments.first.toLowerCase()) {
    case 'clinic':
    case 'klinika':
      if (segments.length < 2) return const TabLink(Destination.explore);
      final id = int.tryParse(segments[1]);
      // A non-numeric id is a malformed link, not a request for clinic
      // zero. Falling back to Explore is better than opening the wrong
      // clinic.
      return id == null ? const TabLink(Destination.explore) : ClinicLink(id);

    case 'appointments':
    case 'termini':
      return const TabLink(Destination.appointments);

    case 'profile':
    case 'profil':
      return const TabLink(Destination.profile);

    case 'explore':
    case 'istrazi':
      return const TabLink(Destination.explore);
  }

  // Anything unrecognised opens the app rather than failing. A link that
  // does nothing looks like a broken app; a link that opens the front
  // door looks like an old link.
  return const TabLink(Destination.explore);
}

/// Listens for links and hands them to the app.
///
/// Two channels, and both are needed: the link that launched a cold start
/// arrives once via [AppLinks.getInitialLink], and every link that arrives
/// while the app is already open comes through the stream. Handling only
/// the stream means a link from a closed app opens the front door;
/// handling only the initial one means tapping a second link does
/// nothing.
class DeepLinkListener {
  final void Function(DeepLink link) onLink;

  DeepLinkListener({required this.onLink});

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _subscription;

  Future<void> start() async {
    try {
      final links = _appLinks ??= AppLinks();

      final initial = await links.getInitialLink();
      if (initial != null) _dispatch(initial);

      _subscription = links.uriLinkStream.listen(
        _dispatch,
        onError: (Object error, StackTrace stack) =>
            CrashLog.record(error, stack, context: 'deeplink.stream'),
      );
    } catch (error, stack) {
      // A platform channel that is not there (a unit test, an unsupported
      // platform) must not stop the app from starting.
      await CrashLog.record(error, stack, context: 'deeplink.start');
    }
  }

  void _dispatch(Uri uri) {
    final link = parseDeepLink(uri);
    if (link != null) onLink(link);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

/// Carries the pending link down the tree so the shell can act on it.
class DeepLinkScope extends InheritedNotifier<ValueNotifier<DeepLink?>> {
  const DeepLinkScope({
    super.key,
    required ValueNotifier<DeepLink?> super.notifier,
    required super.child,
  });

  static ValueNotifier<DeepLink?>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DeepLinkScope>()?.notifier;
}
