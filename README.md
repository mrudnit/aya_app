# Aya - Aplikácia pre analýzu stravovania a životného štýlu

Mobilná aplikácia vyvinutá v rámci bakalárskej práce na UKF v Nitre.  
Umožňuje zaznamenávať spánok, stravu, fyzickú aktivitu a hmotnosť  
a na základe štatistickej analýzy poskytuje personalizované odporúčania.

## Technológie

- **Frontend:** Flutter (iOS, Android, Web)
- **Backend:** Python, FastAPI, pandas, SciPy
- **Databáza:** Firebase Firestore
- **Autentifikácia:** Firebase Authentication (email + Google)
- **Nasadenie:** Railway (backend), Netlify (web)

## Funkcie

- Zaznamenávanie spánku, stravy, aktivity a hmotnosti
- Výpočet kalorického cieľa (rovnica Mifflin-St Jeor)
- Štatistická analýza: Pearsonova korelácia, Spearmanova korelácia,
  point-biseriálna korelácia, Welchov t-test
- Systém prahu dôvery - analýza sa zobrazí až po dostatočnom množstve dát
- Personalizované odporúčania zoradené podľa priority
- Podpora svetlého a tmavého režimu

## Spustenie projektu

### Požiadavky
- Flutter 3.x
- Python 3.10+
- Firebase projekt s Firestore a Authentication

### Inštalácia

```bash
git clone https://github.com/mrudnit/aya_app
cd aya_app
flutter pub get
flutter run
```

### Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

## Demo účet
Vopred nastavený demo účet na otestovanie všetkých funkcií.
**Prihlasovacie údaje:**
- E-mail: `demo@aya-app.com`
- Heslo: `UKF12345`

**Čo tento účet ukazuje:**
- 45 dní realistických údajov o životnom štýle (15 dní v minulosti + 30 dní v budúcnosti)
- Cieľ: udržať hmotnosť (muž, 23 rokov, 176 cm, 84 kg)
- Úroveň aktivity: Stredná
- Cieľový spánok: 8 hodín/noc
- Večera po 20:00 v 55% dní - jasný vzor neskorého jedenia
- Kvalita spánku výrazne horšia v noci po neskorej večeri

**Čo ukazuje analytika:**
- Večerné jedlá výrazne zhoršujú kvalitu spánku (2.2/5 vs 3.8/5)
- Odporúčanie: prestať jesť po 20:00
- Hmotnosť stabilná v súlade s cieľom udržania

**Ako získať prístup:**
1. Otvorte webovú verziu:(https://shiny-marigold-6863cc.netlify.app)
2. Prihláste sa pomocou vyššie uvedených prihlasovacích údajov
3. Prejdite na kartu Analytika na zobrazenie štatistík a odporúčaní

Aplikácia je k dispozícii aj ako súbor APK pre Android (https://drive.google.com/file/d/1XMT2MxovGlDU1x9WCW5eIrzeC5HvAPbe/view?usp=sharing)
a bola natívne testovaná na systéme iOS 26.2 (iPhone 13).
