# Patchr.Studio

Det här repot är ett tidigt proof-of-concept för en **third-party update catalog** till SCCM.

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

För Stripe-specifik startchecklista, se `docs/stripe-onboarding.md`.


## Kom vidare direkt (praktisk start)

Om målet är att gå från idé till körbar MVP snabbt, gör detta i ordning:

1. **Lås stack (1 beslutsmöte, max 60 min)**
   - Frontend/webb: Next.js
   - Backend/API: Next.js API routes eller separat Node API
   - Databas: PostgreSQL
   - Auth: NextAuth eller Supabase Auth
   - Billing: Stripe subscriptions + webhooks
   - Lagring: Blob storage (Azure/AWS) för CAB/MSI/EXE

2. **Bygg “vertical slice” först (vecka 1)**
   - Landningssida med tjänstebeskrivning + CTA
   - Registrering/inloggning med e-post
   - Pris-sida + Stripe checkout (testmode)
   - Enkel dashboard där plan (standard/pro) visas

3. **Lägg katalogdata i DB (vecka 2)**
   - Tabeller för users, subscriptions, catalogs, applications, versions
   - Visa senaste version per applikation i dashboard
   - Public API-endpoint för katalogmetadata

4. **Automation stegvis (vecka 3+)**
   - Flytta befintliga PowerShell-flöden till schemalagt jobb
   - Ny version => hämta => CAB => signera => publicera => uppdatera metadata
   - Markera superseded versioner

5. **Pro-funktion (efter stabil standard)**
   - Uppladdning av MSI/EXE
   - Validering + bearbetningskö
   - Egen katalog per pro-kund

### Rekommenderad första leverans (7 dagar)

- Dag 1: Initiera app + auth-sidor.
- Dag 2: Stripe produkter/priser + checkout.
- Dag 3: Webhook som sätter plannivå (`standard`/`pro`).
- Dag 4: Dashboard med planstatus och plats för katalogdata.
- Dag 5: Databasmodell + migrationer.
- Dag 6: Enkel “latest versions”-vy.
- Dag 7: Deploy + smoke-test + backlog för automation.
