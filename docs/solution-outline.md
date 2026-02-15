# Solution outline: SCCM third-party update catalog as a subscription service

## 1) Målbild

Tjänsten ska låta betalande kunder konsumera en third-party update catalog för SCCM.

- **Publik webb:** förklaring av tjänsten, pris, funktioner och registrering.
- **Standard-kund:** åtkomst till befintlig delad katalog.
- **Pro-kund:** egen katalog samt uppladdning av MSI/EXE för kundspecifika uppdateringar.
- **Automation:** dagliga kontroller av nya versioner, automatiserad paketering/signering/publicering och supersedence av äldre versioner.

## 2) Vad i repot som kan användas direkt

### Återanvändbara delar

- `Scripts/update_chrome.ps1`: visar grundflöde för hämtning och versionsdetektion.
- `Scripts/update_catalog.ps1`: visar uppdatering av katalogmetadata.
- `Updates/updatescatalog.xml`: fungerar som referens för fält som behöver representeras.

### Begränsningar i nuvarande läge

- Webbplatsen är statisk (`index.html`) och saknar auth, billing och kundspecifik data.
- Scripten är PoC och behöver göras robusta (felhantering, idempotens, validering, signering, spårbarhet).
- XML-strukturen är inkonsekvent och behöver normaliseras.

## 3) Rekommenderad implementation i faser

### Fas 1: Grundplattform

- Välj webbstack och backendramverk.
- Implementera konto (email/password), sessionshantering och roller (`standard`, `pro`, `admin`).
- Implementera Stripe produkter/priser, checkout och webhookar.

### Fas 2: Katalogdomän

- Datamodell:
  - `users`, `organizations`, `subscriptions`
  - `catalogs`, `applications`, `packages`, `versions`
  - `jobs`, `artifacts`, `signatures`, `supersedence_links`
- API för:
  - listning av tillgängliga applikationer/versioner
  - senaste distribuerad version
  - nedladdningslänkar till CAB/metadata

### Fas 3: Pro-uppladdning

- Uppladdning av MSI/EXE via signerad URL.
- Antivirus/filtypvalidering.
- Köhantering för bearbetning (extract metadata -> skapa package -> signera -> publicera).

### Fas 4: Automation

- Daglig scheduler per applikation/katalog.
- Version discovery mot vendor-källor.
- Vid ny version:
  - ladda ner
  - skapa CAB
  - certifikatsignera
  - uppdatera katalog + markera superseded versioner
  - uppdatera webbstatus

## 4) Säkerhet och drift

- Secrets i vault (inte i repo).
- Full audit-logg för uppladdningar, signering och publicering.
- Rollbaserad åtkomst till kunddata.
- Isolerad exekvering för filbearbetning.

## 5) Slutsats

Ni har en bra teknisk startpunkt i automatiseringsidéerna och vissa artefakter.
För den produkt ni beskriver (inloggning + Stripe + Standard/Pro + kundspecifik katalog) är det bäst att behålla repo/idé men bygga webb- och backenddelen strukturerat från grunden och sedan migrera in scriptlogik i en kontrollerad pipeline.
