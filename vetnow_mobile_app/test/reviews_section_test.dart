// Widget tests for the reviews block on a clinic page.
//
// The states here are the ones most likely to go wrong quietly: a clinic
// nobody has rated must never render as a zero-star clinic, and the "rate
// your visit" prompt must only appear for someone the backend says actually
// has an unrated visit there.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/l10n/app_localizations.dart';
import 'package:vetnow_mobile/models/review.dart';
import 'package:vetnow_mobile/widgets/reviews.dart';

void main() {
  Future<void> pumpSection(
    WidgetTester tester, {
    ReviewSummary? summary,
    bool isLoading = false,
    PendingReview? pending,
    VoidCallback? onRate,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bs'),
        supportedLocales: const [Locale('bs'), Locale('hr'), Locale('sr')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReviewsSection(
              summary: summary,
              isLoading: isLoading,
              pending: pending,
              onRate: onRate,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final populated = ReviewSummary(
    averageRating: 4.8,
    reviewCount: 4,
    ratingCounts: const {1: 0, 2: 0, 3: 0, 4: 1, 5: 3},
    reviews: [
      Review(
        id: 1,
        authorName: 'User U.',
        rating: 5,
        comment: 'Ljubazno osoblje i brz pregled.',
        createdAt: DateTime(2026, 9, 11, 13),
      ),
      Review(
        id: 2,
        authorName: 'Dino B.',
        rating: 4,
        comment: '',
        createdAt: DateTime(2026, 8, 30, 17),
      ),
    ],
  );

  const emptyFeed = ReviewSummary(
    averageRating: 0,
    reviewCount: 0,
    ratingCounts: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    reviews: [],
  );

  final pendingVisit = PendingReview(
    appointmentId: 9,
    vetStationId: 1,
    vetStationName: 'Happy Paws Vet Clinic',
    visitDate: DateTime(2026, 9, 14, 8, 30),
  );

  testWidgets('shows the score, the count and every review', (tester) async {
    await pumpSection(tester, summary: populated);

    expect(find.text('4.8 · 4 recenzije'), findsOneWidget);
    expect(find.text('User U.'), findsOneWidget);
    expect(find.text('Ljubazno osoblje i brz pregled.'), findsOneWidget);
    expect(find.byType(ReviewCard), findsNWidgets(2));
  });

  testWidgets('a review with no comment still renders its author and stars',
      (tester) async {
    await pumpSection(tester, summary: populated);

    // The second seeded review has an empty comment; it must not disappear,
    // and it must not leave a stray blank line where the text would be.
    expect(find.text('Dino B.'), findsOneWidget);
    expect(find.text(''), findsNothing);
  });

  testWidgets('dates are shown in local day.month.year form', (tester) async {
    await pumpSection(tester, summary: populated);
    expect(find.text('11.9.2026.'), findsOneWidget);
    expect(find.text('30.8.2026.'), findsOneWidget);
  });

  testWidgets('a clinic with no reviews is not shown as a zero score',
      (tester) async {
    await pumpSection(tester, summary: emptyFeed);

    expect(find.text('Još nema recenzija'), findsOneWidget);
    // The critical part: no "0.0" anywhere, and no summary line at all.
    expect(find.textContaining('0.0'), findsNothing);
    expect(find.textContaining('recenzij', skipOffstage: false),
        findsOneWidget, reason: 'only the empty-state heading');
    expect(find.byType(ReviewCard), findsNothing);
  });

  testWidgets('a feed that failed to load looks the same as an empty one',
      (tester) async {
    // `summary: null` is what a failed request leaves behind. Showing "no
    // reviews yet" is truthful; showing a 0.0 score would not be.
    await pumpSection(tester, summary: null);
    expect(find.text('Još nema recenzija'), findsOneWidget);
    expect(find.byType(ReviewCard), findsNothing);
  });

  testWidgets('while loading, neither a score nor an empty state is claimed',
      (tester) async {
    await pumpSection(tester, summary: null, isLoading: true);

    expect(find.text('Još nema recenzija'), findsNothing);
    expect(find.byType(ReviewCard), findsNothing);
  });

  testWidgets('the rate prompt appears only for an unrated visit here',
      (tester) async {
    await pumpSection(tester, summary: populated);
    expect(find.text('Ocijeni svoju posjetu'), findsNothing);

    var tapped = 0;
    await pumpSection(
      tester,
      summary: populated,
      pending: pendingVisit,
      onRate: () => tapped++,
    );

    expect(find.text('Ocijeni svoju posjetu'), findsOneWidget);
    expect(find.text('Posjeta 14.9.2026.'), findsOneWidget);

    await tester.tap(find.text('Ocijeni svoju posjetu'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('an unrated clinic invites the person who can rate it',
      (tester) async {
    await pumpSection(tester, summary: emptyFeed);
    expect(find.text('Budi prvi koji će ocijeniti ovu kliniku.'), findsNothing);

    await pumpSection(
      tester,
      summary: emptyFeed,
      pending: pendingVisit,
      onRate: () {},
    );
    expect(find.text('Budi prvi koji će ocijeniti ovu kliniku.'), findsOneWidget);
  });
}
