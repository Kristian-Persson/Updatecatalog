# Updatecatalog

Det här repot är ett tidigt proof-of-concept för en **third-party update catalog** till SCCM.
Preview https://kristian-persson.github.io/Updatecatalog/
## Nuvarande innehåll

- Enkel statisk startsida (`index.html`).
- PowerShell-script för att hämta Chrome MSI och uppdatera katalogmetadata.
- Ett exempel på `updatescatalog.xml` samt exempelartefakter i `Updates/`.

## Bedömning: återanvända eller börja om?

**Vi kan återanvända delar av nuvarande repo**, men webbplattformen för inloggning, abonnemang och kundspecifika kataloger behöver byggas om från grunden.

### Bra att återanvända

- Idén och flödet i scripten för automatisering av uppdateringar.
- Struktur för katalogfiler och CAB-relaterade artefakter.
- Grundläggande metadata i XML som utgångspunkt.

### Behöver göras om / byggas nytt

- Webapplikation med autentisering, konto- och rollhantering.
- Stripe-integration för prenumeration (Standard/Pro).
- Datamodell för kunder, planer, kataloger, paket, versioner och supersedence.
- Säker filuppladdning för Pro-kunder (MSI/EXE) och bearbetningspipeline.
- Produktionssäker automatisering med signering, schemaläggning och loggning.

## Rekommenderad målarkitektur (MVP)

1. **Frontend + webb**
   - Publik landningssida: tjänstebeskrivning, pris, CTA för registrering.
   - Inloggat läge:
     - Standard: åtkomst till delad katalog.
     - Pro: egen katalog + uppladdning av MSI/EXE.
2. **Backend/API**
   - Auth (email/password + verifiering + återställning).
   - Stripe billing + webhook-hantering.
   - Katalog-API för versionsinformation, nedladdningslänkar och status.
3. **Automationslager**
   - Dagliga jobb per applikation/kund.
   - Upptäckt av ny version -> nedladdning -> CAB -> cert-signering -> publicering.
   - Supersedence/utfasning av äldre versioner.
4. **Lagring**
   - Databas för metadata.
   - Blob/object storage för paket och CAB-filer.

## Föreslagen nästa sprint

- Sätta teknisk stack.
- Sätta datamodell och API-kontrakt.
- Implementera auth + Stripe först (utan full automation).
- Bygga dashboard-skelett för Standard och Pro.
- Flytta scriptlogik till en robust jobbpipeline.

Se även `docs/solution-outline.md` för mer detaljerad krav- och designskiss.
