# Nästa steg: konkret genomförandeplan

Den här planen är avsedd för att snabbt få en första säljbar MVP live.

## Mål för MVP

- Publik sajt med tydlig förklaring av tjänsten och pricing.
- Konto/registrering med e-post.
- Stripe-prenumeration som styr plan (`standard` / `pro`).
- Inloggad dashboard som visar:
  - planstatus
  - senaste distribuerade versioner
  - (pro) uppladdning av MSI/EXE (kan vara feature-flag i första version)

## Definition of Done (MVP v1)

1. Ny användare kan registrera konto och logga in.
2. Användare kan köpa Standard-plan i Stripe testläge.
3. Webhook uppdaterar användarens plan i databasen (inkl. antal licensierade klienter).
4. Inloggad användare ser sin plan och grundläggande katalogdata.
5. Minst ett automatiserat jobb kan uppdatera en app-version i metadata.

## Datamodell (minimal)

- `users(id, email, password_hash, created_at)`
- `subscriptions(id, user_id, stripe_customer_id, stripe_subscription_id, plan, status, licensed_client_count, observed_client_count, compliance_status)`
- `catalogs(id, owner_type, owner_id, name)`
- `applications(id, catalog_id, name, vendor)`
- `versions(id, application_id, version, download_url, checksum, superseded_by, created_at)`
- `jobs(id, type, status, started_at, finished_at, log_ref)`

## API-endpoints (minimal)

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/billing/create-checkout-session`
- `POST /api/billing/webhook`
- `GET /api/me`
- `GET /api/catalog/latest`
- `POST /api/pro/uploads` (feature-flag i början)

## Sprint 1 (5 arbetsdagar)

- Dag 1: Projektsetup + auth + DB-anslutning.
- Dag 2: Pricing-sida + Stripe checkout.
- Dag 3: Stripe webhook + planuppdatering.
- Dag 4: Dashboard + API för latest versions.
- Dag 5: Deploy, testdata och smoke tests.

## Risker att hantera tidigt

- Säker filuppladdning (MSI/EXE) för Pro.
- Kodsignering/certifikat-hantering.
- Idempotens i automation (inte publicera dubbletter).
- Spårbarhet/loggning för support och felsökning.

## Beslut som behövs av dig nu

1. Vilken stack vill du låsa (Next.js/Supabase eller annan)?
2. Vill du att vi börjar med Standard-plan först och Pro i sprint 2?
3. Var ska första deploymenten ligga (t.ex. Azure App Service / Vercel)?

När dessa 3 beslut är tagna kan implementationen starta direkt.

## Stripe: konkret input som behövs

För exakt checklista över Stripe-konfiguration och vilka nycklar/ID:n som behövs, se `docs/stripe-onboarding.md`.
