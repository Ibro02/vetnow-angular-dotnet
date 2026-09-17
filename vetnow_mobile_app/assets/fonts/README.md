# Fontovi — nedostaju

`lib/config/theme.dart` traži dvije porodice:

```dart
static const body    = 'Inter';     // sav tekst
static const display = 'Italiana';  // veliki naslovi (Explore header)
```

Nijedan `.ttf` nije u repozitoriju, pa Flutter tiho pada na sistemski font
(Roboto na Androidu). Aplikacija zbog toga **ne izgleda loše**, ali ne
izgleda kako je dizajnirana — naročito naslov na Explore ekranu, koji je
zamišljen u serifnoj Italiani, a prikazuje se u Robotu.

Nisam ih mogao sam dodati: to su binarni fajlovi koje treba preuzeti.

## Šta treba uraditi (5 minuta)

1. Preuzmi s Google Fonts:
   - <https://fonts.google.com/specimen/Inter> — Regular, Medium, SemiBold, Bold
   - <https://fonts.google.com/specimen/Italiana> — Regular

   Oba su pod SIL Open Font License, pa smiju ići u aplikaciju i u
   repozitorij.

2. Raspakuj `.ttf` fajlove ovdje, tačno s ovim imenima:

   ```
   assets/fonts/Inter-Regular.ttf
   assets/fonts/Inter-Medium.ttf
   assets/fonts/Inter-SemiBold.ttf
   assets/fonts/Inter-Bold.ttf
   assets/fonts/Italiana-Regular.ttf
   ```

3. U `pubspec.yaml` odkomentariši blok `fonts:` — već je napisan i čeka.

4. `flutter pub get`, pa pokreni aplikaciju.

## Provjera da je uspjelo

Naslov na Explore ekranu ("Pouzdana njega, rezervisana za sekunde.")
treba postati serifni, s tankim potezima. Ako je i dalje bezserifni,
imena fajlova se ne slažu s onima u `pubspec.yaml`.

## Ako se odluči da fontovi ne trebaju

Onda `AppFonts.body` i `AppFonts.display` treba postaviti na `null`
umjesto na imena koja ne postoje — trenutno kod traži nešto čega nema,
i to je tiha laž koju je lakše ukloniti nego objasniti sljedećem čitaocu.
