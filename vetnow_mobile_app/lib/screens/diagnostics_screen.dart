import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_info.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/crash_log.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/section_title.dart';
import '../widgets/state_views.dart';

/// What build this is, and what has gone wrong on it.
///
/// This exists because of the gap between "it crashed" and a fix. Nothing
/// is uploaded anywhere — there is no crash service behind this app — so
/// the only way a stack trace from someone's phone reaches anyone who can
/// act on it is if the person can see it and send it. One screen, one
/// copy button.
///
/// It also answers the first question of any bug report, which version
/// and which backend, without anyone having to ask.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  late Future<List<CrashEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = CrashLog.read();
  }

  void _reload() => setState(() => _entries = CrashLog.read());

  Future<void> _copy() async {
    final l10n = AppLocalizations.of(context)!;
    final report = await CrashLog.export();
    await Clipboard.setData(ClipboardData(text: report));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.diagnosticsCopied)),
    );
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context)!;
    await CrashLog.clear();

    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.diagnosticsCleared)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: GradientAppBar(title: l10n.diagnosticsTitle),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          // A release pointed at a development server fails on every
          // screen with a connection error, which sends people to their
          // router. Saying it once, here, is the difference between an
          // afternoon of debugging and a rebuild.
          if (!AppInfo.pointsAtRealBackend) ...[
            _ConfigWarning(
              title: l10n.configWarningTitle,
              body: l10n.configWarningBody,
            ),
            const SizedBox(height: AppSpacing.s6),
          ],

          SectionTitle(l10n.diagnosticsAbout, color: AppColors.text),
          const SizedBox(height: AppSpacing.s3),
          _FactCard(
            rows: [
              (l10n.diagnosticsVersion, AppInfo.fullVersion),
              (l10n.diagnosticsBackend, AppInfo.apiHost),
            ],
          ),

          const SizedBox(height: AppSpacing.s8),
          SectionTitle(l10n.diagnosticsReports, color: AppColors.text),
          const SizedBox(height: 6),
          Text(
            l10n.diagnosticsExplainer,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.s4),

          FutureBuilder<List<CrashEntry>>(
            future: _entries,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s6),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              final entries = snapshot.data ?? const <CrashEntry>[];
              if (entries.isEmpty) {
                return EmptyStateView(
                  icon: Icons.check_circle_outline,
                  text: l10n.diagnosticsEmpty,
                  scrollable: false,
                );
              }

              return Column(
                children: [
                  for (final entry in entries) ...[
                    _EntryCard(entry: entry),
                    const SizedBox(height: AppSpacing.s3),
                  ],
                  const SizedBox(height: AppSpacing.s3),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copy,
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: Text(l10n.diagnosticsCopy),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _clear,
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: Text(l10n.diagnosticsClear),
                          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConfigWarning extends StatelessWidget {
  final String title;
  final String body;

  const _ConfigWarning({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  final List<(String, String)> rows;

  const _FactCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s4,
                vertical: AppSpacing.s3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Flexible(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i != rows.length - 1)
              Divider(height: 1, thickness: 1, color: AppColors.borderLight),
          ],
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final CrashEntry entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tint = entry.fatal ? AppColors.danger : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  entry.fatal ? l10n.diagnosticsFatal : l10n.diagnosticsHandled,
                  style: TextStyle(
                    color: tint,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  _stamp(entry.at),
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            entry.error,
            style: TextStyle(color: AppColors.text, fontSize: 13, height: 1.4),
          ),
          if (entry.context.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.context,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }

  /// Local time, to the minute. Seconds would be noise and the ISO string
  /// belongs in the copied report, not on screen.
  static String _stamp(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(at.day)}.${two(at.month)}.${at.year}. ${two(at.hour)}:${two(at.minute)}';
  }
}
