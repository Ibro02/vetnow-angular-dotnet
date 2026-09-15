# Politika privatnosti — VetNow

**Zadnja izmjena:** 15.09.2026.

> **Napomena za tim:** ovo je nacrt koji odgovara onome što aplikacija
> *stvarno* radi na dan pisanja — provjereno kroz kod, ne pretpostavljeno.
> Google Play traži da bude objavljen na javnom URL-u i da taj URL stoji u
> Play Console listingu. Prije objave popuni kontakt e-mail i naziv pravnog
> subjekta na dnu, i ponovo provjeri ovaj tekst ako se doda bilo šta novo
> (push notifikacije, plaćanje, analitika, mape) — svaka od tih stvari
> mijenja odgovore.

---

## Ukratko

VetNow je aplikacija za pronalazak veterinarskih klinika i zakazivanje
pregleda. Možeš je koristiti i bez naloga — pregled klinika, radnog
vremena, usluga i recenzija ne traži prijavu i ne traži nikakve tvoje
podatke.

Nalog je potreban samo da bi rezervisao termin, jer termin mora imati ime.

Ne prodajemo podatke. Nemamo reklame. Nemamo analitiku koja te prati.

---

## Šta prikupljamo

### Kada koristiš aplikaciju bez naloga

Ništa. Nema registracije, nema identifikatora uređaja, nema praćenja.

Aplikacija na tvom telefonu čuva:

- izbor teme (svijetla / tamna / kao na uređaju) i jezika
- kopiju liste klinika, da se aplikacija otvori odmah i radi kad si
  nakratko bez interneta
- posljednjih deset grešaka, ako do njih dođe

Sve to ostaje **na tvom telefonu**. Ništa od toga se ne šalje nama niti
bilo kome drugom. Brisanjem podataka aplikacije ili njenim deinstaliranjem
sve to nestaje.

### Kada napraviš nalog

Podaci koje sam upišeš:

- ime i prezime
- e-mail adresa
- broj telefona
- korisničko ime i lozinka

Podaci koje upišeš o svojim ljubimcima:

- ime, vrsta, pasmina, datum rođenja, spol

Podaci koji nastaju korištenjem:

- tvoje rezervacije: klinika, zaposlenik, usluga, datum i vrijeme
- ocjene i recenzije koje ostaviš

### Šta ne prikupljamo

Aplikacija ne traži i ne može pristupiti:

- tvojoj lokaciji
- kameri ili mikrofonu
- kontaktima
- fotografijama ili fajlovima
- popisu instaliranih aplikacija

Jedina dozvola koju aplikacija traži je pristup internetu.

---

## Zašto to koristimo

| Podatak | Zašto |
|---|---|
| Ime, e-mail, telefon | Da klinika zna ko dolazi i da te može kontaktirati ako se termin mijenja |
| Lozinka | Prijava. Čuva se hashirana (bcrypt) — ni mi ne možemo pročitati tvoju lozinku |
| Podaci o ljubimcu | Da veterinar zna koga prima na pregled |
| Rezervacije | Da bi imao pregled svojih termina i da ih klinika vidi |
| Recenzije | Prikazuju se javno uz kliniku, uz tvoje ime |

Ne koristimo ništa od ovoga za profilisanje, reklame ni prodaju trećim
stranama.

---

## Ko to vidi

- **Klinika koju izabereš** vidi tvoje ime, kontakt, ljubimca i termin.
  Vidi samo svoje rezervacije, ne i tvoje rezervacije kod drugih klinika.
- **Ostali korisnici** vide recenzije koje objaviš, s tvojim imenom.
- **Niko treći.** Ne dijelimo podatke s oglašivačima, brokerima podataka
  ni analitičkim servisima.

---

## Sigurnost

- Lozinke se čuvaju hashirane algoritmom bcrypt. Original se ne čuva nigdje.
- Sesijski token se na telefonu drži u sistemskom sigurnom spremniku
  (Android Keystore), a ne u običnom fajlu.
- Token je isključen iz Google Drive backupa i iz prenosa na novi telefon,
  tako da tvoja prijava ne može "procuriti" na drugi uređaj.
- Sva komunikacija ide preko HTTPS-a. Aplikacija u objavljenoj verziji
  odbija nešifrovanu vezu.

Nijedan sistem nije apsolutno siguran, ali ovo su mjere koje primjenjujemo.

---

## Koliko dugo čuvamo

- Podaci naloga: dok imaš nalog.
- Historija termina: čuva se i nakon obavljenog pregleda, jer je to tvoja
  medicinska historija i historija klinike.
- Zapisi o greškama na telefonu: posljednjih deset, starije se automatski
  brišu. Možeš ih obrisati i sam u Profil → Pomoć i dijagnostika.

---

## Tvoja prava

Možeš tražiti:

- uvid u podatke koje imamo o tebi
- ispravku netačnih podataka (dio možeš i sam u Profil → Lični podaci)
- brisanje naloga i podataka
- kopiju podataka u čitljivom formatu

Javi se na kontakt ispod. Odgovaramo u roku od 30 dana.

---

## Djeca

Aplikacija nije namijenjena osobama mlađim od 16 godina i svjesno ne
prikupljamo njihove podatke.

---

## Izmjene

Ako se politika mijenja, novi datum stoji na vrhu. Značajne izmjene
najavljujemo u aplikaciji prije nego što stupe na snagu.

---

## Kontakt

**[NAZIV PRAVNOG SUBJEKTA]**
**[ADRESA]**
E-mail: **[KONTAKT E-MAIL]**

---
---

# Nacrt odgovora za Play "Data safety" formular

Google traži da se ovo popuni odvojeno od politike privatnosti, i mora se
slagati s njom. Ovo su odgovori koji odgovaraju stanju koda.

**Da li aplikacija prikuplja ili dijeli podatke korisnika?** Da, prikuplja.
Ne dijeli s trećim stranama.

**Da li se podaci šifruju u prenosu?** Da (HTTPS, obavezan u release buildu).

**Da li korisnik može tražiti brisanje podataka?** Da.

| Kategorija | Prikuplja | Obavezno | Svrha |
|---|---|---|---|
| Ime | Da | Samo za nalog | Funkcionalnost aplikacije, upravljanje nalogom |
| E-mail adresa | Da | Samo za nalog | Funkcionalnost aplikacije, upravljanje nalogom |
| Broj telefona | Da | Samo za nalog | Funkcionalnost aplikacije |
| Korisničko ime i lozinka | Da | Samo za nalog | Upravljanje nalogom |
| Ostali korisnički sadržaj (ljubimci, recenzije) | Da | Ne | Funkcionalnost aplikacije |
| Lokacija | **Ne** | — | — |
| Kontakti, fotografije, fajlovi | **Ne** | — | — |
| Identifikatori uređaja ili oglašivača | **Ne** | — | — |
| Podaci o padovima / dijagnostika | **Ne šalje se** | — | Ostaje na uređaju |

> Zadnji red je važan: aplikacija **bilježi** greške, ali ih ne šalje
> nikome. Ako se ikad doda Crashlytics ili Sentry, taj red se mijenja u
> "Da / Dijagnostika" i politika privatnosti gore mora dobiti novi odjeljak.
