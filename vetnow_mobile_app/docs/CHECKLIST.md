# Šta je ostalo do Play Store-a

Stanje na dan **15.09.2026.**, nakon noćnog rada na mobilnoj aplikaciji.
Podijeljeno po tome ko to može uraditi.

---

## 1. Ne mogu ja — traži tvoj nalog, ključ ili domenu

| # | Šta | Zašto ja ne mogu | Koliko traje |
|---|---|---|---|
| 1 | **Keystore za potpisivanje** | Traži lozinku koju ti moraš držati, ne ja | 5 min |
| 2 | **Google Play Developer nalog** | Plaćanje 25 USD i tvoj identitet | 30 min + verifikacija |
| 3 | **Backend na javnoj HTTPS adresi** | Hosting i domena | zavisi |
| 4 | **Politika privatnosti objavljena na webu** | Tekst je gotov (`PRIVACY.md`), treba ga staviti na URL | 15 min |
| 5 | **`assetlinks.json` na domeni** | Traži SHA-256 otisak tvog ključa (`DEEP_LINKS.md` ima komandu) | 10 min |
| 6 | **Screenshotovi i feature grafika** | Treba ih snimiti na pravom telefonu s pravim podacima | 1 h |
| 7 | **Testiranje na pravom Androidu** | Nemam uređaj | 1–2 h |
| 8 | **Rotirati procureli Stripe ključ** | Tvoj Stripe nalog | 5 min |
| 9 | **Fontovi Inter i Italiana** | Binarni fajlovi za preuzimanje (`assets/fonts/README.md`) | 5 min |
| 10 | **E-mail za podršku** | Mora biti stvarna, praćena adresa; trenutno stoji `podrska@vetnow.ba` kao placeholder | — |

Redoslijed koji preporučujem: **1 → 3 → 4 → 2 → 7 → 6 → 5**.
Stavke 8, 9 i 10 mogu paralelno u bilo kojem trenutku.

---

## 2. Mogu ja, ali traži odluku ili nalog

| Šta | Šta mi treba od tebe |
|---|---|
| **Push notifikacije** (podsjetnik dan prije termina) | Firebase projekat + `google-services.json`. Traži i izmjene na backendu. |
| **Slanje padova na server** (Sentry / Crashlytics) | DSN ili Firebase projekat. Kuka u kodu već postoji — `CrashLog.onRecord`, jedna linija. |
| **Prijava recenzije preko servera** | Trenutno otvara e-mail. Pravo rješenje traži endpoint na backendu. |

---

## 3. Poznati nedostaci koje svjesno ostavljamo

- **Nema reda za ponovno slanje kad se vrati mreža.** Ako rezervacija padne
  jer nema interneta, korisnik mora ponoviti ručno. Namjerno: automatsko
  ponavljanje rezervacije riskira dupli termin.
- **`Vet.Speciality`, `Education`, `SpecialSkill`** postoje u bazi ali se ne
  prikazuju — backend ih ne šalje u projekciji. Backend je van opsega.
- **Nema testa na pravom uređaju.** 222 testa pokrivaju logiku i izgled,
  ali nijedan nije pokrenut na Androidu.
- **`https://` deep linkovi** još pitaju korisnika koju aplikaciju da
  otvori, dok se ne objavi `assetlinks.json`.

---

## 4. Provjera prije slanja

```bash
tool/build_release.sh https://api.vetnow.ba
```

Skripta sama odbija `http://` adresu i glasno kaže ako `key.properties`
ne postoji. Prije nego što pritisneš objavi, prođi i listu na dnu
[`RELEASE.md`](RELEASE.md).
