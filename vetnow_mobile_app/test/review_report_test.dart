// Reporting a review.
//
// This exists for a policy reason as much as a product one: Play requires
// that user-generated content can be flagged, and reviews are
// user-generated. It also has to be hard to hit by accident — a flag on
// every review is one stray thumb away from being used as a disagree
// button, so the tap opens a confirmation rather than doing anything.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/l10n/app_localizations.dart';
import 'package:vetnow_mobile/models/review.dart';
import 'package:vetnow_mobile/widgets/reviews.dart';

final _review = Review(
  id: 7,
  authorName: 'Neko Nekić',
  rating: 1,
  comment: 'Ovo je sadržaj koji netko želi prijaviti.',
  createdAt: DateTime(2026, 9, 1),
);

Future<AppLocalizations> pumpCard(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('bs'),
    supportedLocales: const [Locale('bs'), Locale('hr'), Locale('sr')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: ReviewCard(review: _review)),
  ));
  await tester.pump();
  return AppLocalizations.delegate.load(const Locale('bs'));
}

void main() {
  testWidgets('every review carries a way to report it', (tester) async {
    final l10n = await pumpCard(tester);

    expect(find.bySemanticsLabel(l10n.reportReview), findsOneWidget);
  });

  testWidgets('the flag asks before it does anything', (tester) async {
    final l10n = await pumpCard(tester);

    await tester.tap(find.bySemanticsLabel(l10n.reportReview));
    await tester.pumpAndSettle();

    expect(find.text(l10n.reportReviewTitle), findsOneWidget);
    expect(find.text(l10n.reportReviewSend), findsOneWidget);
  });

  testWidgets('cancelling leaves the review alone', (tester) async {
    final l10n = await pumpCard(tester);

    await tester.tap(find.bySemanticsLabel(l10n.reportReview));
    await tester.pumpAndSettle();

    // The first action is Cancel; the send button is the second.
    await tester.tap(find.byType(TextButton).first);
    await tester.pumpAndSettle();

    expect(find.text(l10n.reportReviewTitle), findsNothing);
    // The review itself is still on screen, unchanged.
    expect(find.text(_review.comment), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the report control does not read as part of the review text',
      (tester) async {
    // Someone using a screen reader should hear the review, then a
    // separate button — not a review whose last word is "flag".
    final handle = tester.ensureSemantics();
    final l10n = await pumpCard(tester);

    expect(
      tester.getSemantics(find.bySemanticsLabel(l10n.reportReview)),
      matchesSemantics(
        label: l10n.reportReview,
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );

    handle.dispose();
  });
}
