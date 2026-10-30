# Home Board

Family dashboard for the kitchen tablet and both phones.

**Tabs:** Today · Baby · Household · Money

## What's here

- `index.html` — the whole app in one file (no build step). Open it in a browser to try it.
- `supabase/schema.sql` — database tables and access rules for the shared Supabase project.

## Status

- [x] UI for all four tabs, with example data
- [x] Baby logging: feeds (timer, sides, bottle), nappies, sleep, medicines with early-dose warning, temperature, growth chart, appointments and vaccines, questions for the nurse or GP
- [x] Household: shopping list, to-dos, dog / home / car reminders, bin dates from a repeating schedule
- [x] Money: debits, renewals (flagged 30 days out), annual bills, subscriptions; amounts hidden by default
- [x] Night mode (red, dim)
- [ ] Separate Supabase project (EU region) + run `schema.sql`
- [ ] Sign-in for household members; swap local storage for Supabase with live sync
- [ ] Calendars via private iCal links
- [x] Hosted on GitHub Pages: https://endafla.github.io/Home-Dashboard/
- [ ] Install on tablet and phones (Add to Home screen)

## Notes

- Data currently saves in the browser of the device you're using only.
- No bank logins or account numbers are stored, by design.
