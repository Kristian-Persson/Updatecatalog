# Stripe-onboarding: vad du gör nu och vad jag behöver av dig

Den här checklistan gör att vi kan koppla Stripe snabbt och säkert till MVP:n.

## 1) Det du gör i Stripe (ca 20–40 min)

1. **Skapa produkter och priser (metered/licens per klient)**
   - Produkt: `Standard`
     - Pris: **2 USD eller 20 SEK per klient och år**
   - Produkt: `Pro`
     - Pris: **5 USD eller 50 SEK per klient och år**
   - Lägg pris som **årlig återkommande** med `quantity` = antal klienter.
   - Skapa separata Price IDs per valuta (USD/SEK).
2. **Hämta API-nycklar i testläge**
   - `STRIPE_SECRET_KEY` (server)
   - `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` (klient)
3. **Skapa webhook-endpoint (testläge)**
   - Event att lyssna på:
     - `checkout.session.completed`
     - `customer.subscription.updated`
     - `customer.subscription.deleted`
     - `invoice.paid`
     - `invoice.payment_failed`
   - Spara `STRIPE_WEBHOOK_SECRET`
4. **Kundportal (rekommenderat)**
   - Aktivera Stripe Billing Portal så kunder kan byta plan/avsluta själva.
5. **Skatt/kvitton (valfritt i MVP, bra tidigt)**
   - Aktivera skatteinställningar och kvittoinställningar om ni säljer B2B/B2C i flera länder.

## 2) Det jag behöver av dig för att bygga vidare

Skicka följande i säkert format (inte i publik chat om möjligt):

- `STRIPE_SECRET_KEY` (test)
- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` (test)
- `STRIPE_WEBHOOK_SECRET` (test)
- **Price IDs** för planerna:
  - `STRIPE_PRICE_STANDARD`
  - `STRIPE_PRICE_PRO`
- URL:er för redirect:
  - `SUCCESS_URL` (efter lyckad checkout)
  - `CANCEL_URL` (om användaren avbryter)

## 3) Affärsbeslut jag behöver innan implementation

1. **Pris per plan (bekräftat)**
   - Standard: **2 USD eller 20 SEK per klient och år**
   - Pro: **5 USD eller 50 SEK per klient och år**
2. **Client count-policy**
   - Minsta antal klienter vid köp: ___
   - Tillåt uppgradering av antal under perioden: ja/nej
   - Hantering av underlicensiering: grace period / blockering / auto-upgrade
3. **Trial eller ej**
   - Ingen trial / 7 dagar / 14 dagar
4. **Planbyte och uppsägning**
   - Tillåt upp-/nedgradering direkt eller vid nästa fakturaperiod?
5. **Moms/skatthantering**
   - Ska Stripe Tax aktiveras i MVP eller i fas 2?

## 4) Klartecken att köra när detta är ifyllt

När nycklar + price IDs + 4 affärsbeslut ovan är klara kan jag implementera:

- Pricing-sida med riktiga Stripe-priser
- Checkout per plan
- Webhook-flöde som sätter `standard`/`pro` i databasen
- Enkel abonnemangssida i dashboard (status, plan, förnya, avbryt)

## 5) Säkerhetsnotering

- Dela aldrig live-nycklar innan vi är redo för produktion.
- Börja i testläge, verifiera hela flödet, rotera nycklar vid behov.


## 6) Går det att kontrollera att antal klienter är verkligt?

Kort svar: **ja, delvis automatiskt och delvis via policy/revision**.

Rekommenderad modell i 3 nivåer:

1. **Självrapportering i checkout (Stripe quantity)**
   - Köparen anger antal klienter (`quantity`) vid köp och förnyelse.
2. **Teknisk usage-kontroll i tjänsten**
   - Mät faktiska aktiva klienter via t.ex. unik SCCM site + antal unika klient-ID:n som hämtat metadata/uppdateringar under perioden.
   - Spara månadsvis “observed_active_clients” i databasen.
3. **Compliance-regel**
   - Om observerat antal överstiger köpt antal (t.ex. >10% i 14 dagar):
     - visa varning i dashboard,
     - skicka e-post,
     - föreslå automatiskt planjustering (ny `quantity`) vid nästa period eller direkt proraterat.

Praktiskt viktigt: det är svårt att få 100% perfekt verifiering utan agent/telemetri. Därför kombinerar man vanligtvis:
- teknisk mätning,
- avtalsvillkor (rätt att revidera),
- tydlig policy för underlicensiering.

