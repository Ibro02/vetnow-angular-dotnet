# Puštanje VetNow aplikacije na Google Play

Ovo je redoslijed koraka od "radi na mom računaru" do "instalirano s Play-a".
Sve što je moglo biti urađeno u kodu jeste; ostalo traži nalog, domenu ili
ključ koje samo vlasnik projekta može napraviti.

---

## 1. Jednokratno: ključ za potpisivanje

Bez ovoga Play odbija build. Ključ se pravi **jednom** i čuva zauvijek —
ako se izgubi, aplikacija se više nikad ne može ažurirati pod istim
listingom i mora ići kao nova aplikacija, s nulom instalacija.

```bash
keytool -genkey -v -keystore vetnow-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias vetnow
```

Snimi `vetnow-upload.jks` u `android/`, pa kopiraj
`android/key.properties.example` u `android/key.properties` i popuni
lozinke.

Oba fajla su u `.gitignore` i **ne smiju** ući u repozitorij. Backup ključa
drži negdje gdje ne ovisi o ovom računaru.

Provjera da je uzeo ključ — ako ovo ispiše upozorenje o debug ključu,
`key.properties` nije pročitan:

```bash
flutter build appbundle --release
```

---

## 2. Backend na javnoj HTTPS adresi

Aplikacija u release buildu odbija `http://` i ne zna za `localhost`.
Treba joj adresa do koje telefon na mobilnom internetu može doći.

Build za produkciju je onda:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.vetnow.ba
```

Ako se ovaj flag zaboravi, aplikacija to prepozna i kaže na ekranu umjesto
da se svaki zahtjev ruši sa "provjeri konekciju". Ne oslanjaj se na to —
provjeri u Profil → Pomoć i dijagnostika, tamo piše na koji server build
gleda.

---

## 3. Verzija

`pubspec.yaml`, linija `version: 1.0.0+1`.

Broj iza `+` je Play-ov `versionCode` i mora rasti sa svakim uploadom i
nikad se ne smije ponoviti. Broj ispred je ono što korisnik vidi.

`AppInfo` u `lib/config/app_info.dart` mora pratiti isto — test to provjerava,
pa ako zaboraviš, suite pukne prije nego što build ode na Play.

---

## 4. Build

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.vetnow.ba
```

Rezultat: `build/app/outputs/bundle/release/app-release.aab`

Taj fajl je ~54MB jer sadrži sve procesorske arhitekture odjednom. Play iz
njega generiše po uređaju i stvarno preuzimanje je **~19MB** — nemoj se
uplašiti broja.

Uz njega sačuvaj i `build/app/outputs/mapping/release/mapping.txt`. To je
mapa za odmagljivanje stack traceova iz release builda; bez nje su
izvještaji o padovima nečitljivi. Play ima polje da se taj fajl uploaduje.

---

## 5. Play Console

Što traže, a nije kod:

- [ ] Google Play Developer nalog (jednokratno 25 USD)
- [ ] Naziv, kratki i dugi opis — gotov tekst je u [`STORE_LISTING.md`](STORE_LISTING.md)
- [ ] Ikona 512×512 PNG — izvor je `assets/icon/app_icon.png`
- [ ] Feature grafika 1024×500
- [ ] Najmanje 2 screenshota telefona (preporuka: 4–6)
- [ ] **Politika privatnosti na javnom URL-u** — tekst je u
      [`PRIVACY.md`](PRIVACY.md), treba ga samo objaviti na web stranici
- [ ] Data safety formular — šta se prikuplja; nacrt odgovora je na dnu
      `PRIVACY.md`
- [ ] Content rating upitnik
- [ ] Ciljna grupa i uzrast

---

## 6. Prije nego što pritisneš objavi

- [ ] `flutter analyze` — čisto
- [ ] `flutter test` — sve prolazi
- [ ] Instaliran release APK na **pravom telefonu**, ne emulatoru
- [ ] Prijava, rezervacija, otkazivanje i dodavanje ljubimca prođeni rukom
- [ ] Provjereno na malom ekranu (npr. 360×640) i s uvećanim fontom
- [ ] Tamna tema provjerena na istim ekranima
- [ ] Profil → Pomoć i dijagnostika pokazuje tačnu verziju i pravi server

Zadnje dvije stavke u prvoj grupi su jedine koje niko još nije odradio —
sve iza logina je do sada pokriveno samo testovima.
