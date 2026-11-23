# Verification

[Español](../VERIFICACION.md) · [English](VERIFICACION.md) · [Français](../fr/VERIFICACION.md) · [Index](README.md)

From the repository root, `./scripts/test.ps1` runs the `Rugby.Test.Suite` groups and builds the frontend. IRIS cases roll back their data after completion. Integrations that create or advance games require a disposable instance.

Coverage includes competitions, seasons, line-ups, training, morale, injuries, cards, matches, wages, finances, the market, security and idempotency:

- Line-ups: swaps, availability, captain, validation and morale penalties.
- Contracts: duration, age preferences, counteroffers, initial expiry dates, promotions, renewals and retries, including non-increasing renewals above the wage limit.
- Competition: cup groups, dates, venues, bonuses, knockouts, standings and schedule generation.
- Training and statistics: weekly plans, age progression, season totals and score reconciliation.
- Market: up to twenty generated agents, club listings, weekly foreign intake, lowest-average exits, negotiation and competition between clubs.
- Staff: three candidates per role, hiring, vacancy replacement and contract history.
- Matches: individual and batch commands, pauses, injuries, cards, statistics and state persistence.

HTTP integrations use `RUGBY_API_BASE`; outputs go to `RUGBY_TEST_ARTIFACTS`. Screenshots and temporary files live outside the project. Operations are audited in the IRIS message viewer.

Visual checks cover desktop and mobile line-ups, training, contracts, calendar, finances, match controls and languages.

From `rugby-frontend`, `npx playwright test advanceUntilEvent.spec.ts` checks meetings, matches, cancellation, schedule refresh, errors and day limits. `npx playwright test i18n.spec.ts` checks language catalogues, placeholders, terminology and API errors.

`Rugby.Test.AdaptiveTactics` checks leads, comebacks, fatigue, independent reviews and reproducible abbreviated scores. `Rugby.Test.AISubstitutions` covers compatible replacements, exclusions, limits and final energy. Result mode and statistics tests verify integration.
