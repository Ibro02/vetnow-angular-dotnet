# Deep linkovi

Aplikacija zna otvoriti tačnu stranicu iz linka. Dvije adrese znače isto:

```
vetnow://clinic/3          ← radi odmah, bez ičega na serveru
https://vetnow.ba/clinic/3 ← traži jedan fajl na domeni (vidi ispod)
```

Podržane putanje:

| Link | Otvara |
|---|---|
| `clinic/{id}` ili `klinika/{id}` | stranicu te klinike |
| `appointments` ili `termini` | tab Termini |
| `profile` ili `profil` | tab Profil |
| `explore` ili `istrazi` | tab Istraži |
| bilo šta drugo | aplikaciju (Istraži) |

Neispravan link nikad ne otvara pogrešnu stranicu — `clinic/abc` vodi na
Istraži, ne na kliniku broj 0.

## Testiranje na uređaju

Sa spojenim telefonom:

```bash
adb shell am start -a android.intent.action.VIEW -d "vetnow://clinic/3" ba.vetnow.app
```

## Da https:// linkovi otvaraju aplikaciju bez pitanja

Android trenutno pita korisnika koju aplikaciju da koristi. Da prestane
pitati, domena mora poslužiti jedan fajl — to je jedini korak koji ja
nisam mogao odraditi, jer traži otisak vašeg ključa za potpisivanje.

1. Uzmi SHA-256 otisak upload ključa:

```bash
keytool -list -v -keystore android/vetnow-upload.jks -alias vetnow
```

   Iz ispisa prepiši liniju `SHA256:`.

2. Objavi ovaj sadržaj na **`https://vetnow.ba/.well-known/assetlinks.json`**
   (mora biti HTTPS, bez redirekcije, `Content-Type: application/json`):

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "ba.vetnow.app",
      "sha256_cert_fingerprints": ["OVDJE_SHA256_OTISAK"]
    }
  }
]
```

3. Ako se koristi Play App Signing (a hoće se, uključeno je po defaultu),
   Google potpisuje aplikaciju **svojim** ključem, ne tvojim. Tada otisak
   treba uzeti iz Play Console → Setup → App integrity → App signing key
   certificate, i staviti **oba** otiska u listu.

4. Provjera:

```bash
adb shell am start -a android.intent.action.VIEW -d "https://vetnow.ba/clinic/3"
```

   Ako se otvori aplikacija bez pitanja — radi.

## Šta je već urađeno

- Intent filteri u `AndroidManifest.xml`, uključujući `android:autoVerify="true"`
- Parsiranje linkova (`lib/services/deep_links.dart`), pokriveno sa 13 testova
- Hvatanje linka i pri hladnom startu i dok aplikacija radi
- Navigacija u `RootShell`, pokrivena sa 3 testa

Jedino što fali je `assetlinks.json` iz koraka 2.
