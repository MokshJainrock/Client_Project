# Client Revenue Risk & Retention Analytics Dashboard

I built this to answer a simple business question with real data: when a company
can't afford to chase every customer who stops buying, which ones are actually
worth keeping?

Built with Python (cleaning and loading), MySQL (database and analysis), and
Power BI (dashboard).

## The question

A retailer has a limited retention budget. They can't win back everyone who's
gone quiet. So the useful question isn't "who churned" — it's "which of the
customers slipping away are valuable enough to be worth the effort, and is it
smarter to target them or run a broad campaign?"

## What I found

- The top 20% of clients bring in about 77% of the revenue. Customers aren't
  equal, so spending the same on all of them doesn't make sense.
- About half the clients (50.9%) haven't bought anything in 90+ days.
- 208 clients are both high-value and at risk. That's only 3.5% of all clients,
  but they account for £1.55M of revenue that's slipping away.

So the recommendation is to focus retention on those 208 clients instead of
spreading the budget across all ~3,000 at-risk customers.

Here's the rough math behind that:

| Approach | Clients | Cost | Revenue recovered | Return |
|----------|---------|------|-------------------|--------|
| Targeted | 208     | £2,080  | ~£464K | ~222x |
| Broad    | 2,989   | £29,890 | ~£339K | ~10x  |

These numbers assume £10 to reach each client, a 30% win-back rate on the
targeted (more personal) approach, and 10% on the broad one. They're estimates
to show the tradeoff, not real company results.

## The data

Online Retail II from the UCI repository (public domain) — real transactions from
a UK online gift shop between Dec 2009 and Dec 2011.

- 1,067,371 raw rows, cleaned down to 779,425
- 5,878 customers across 41 countries
- £17.4M in total revenue

## How it's built

**Database (MySQL).** Four tables instead of one big flat file: `clients`,
`products`, `transactions`, and `transaction_items`. Splitting them this way
avoids repeating product and customer details on every row. ER diagram is in
`/docs`.

**Cleaning and loading (Python).** `etl.py` reads the raw file and cleans it before
anything goes into the database:
- dropped cancelled orders (invoices starting with "C")
- dropped returns and bad rows (negative or zero quantity/price)
- dropped rows with no customer ID, since you can't tie those to a client
- fixed data types and removed duplicates
- loaded the tables in the right order so the foreign keys hold

**Analysis (SQL).** Queries in MySQL to work out each client's total value and how
long since they last bought, then split everyone into four groups by value and
risk. That's where the 208 worth-saving clients come from.

**Dashboard (Power BI).** An interactive dashboard with value and status filters,
five KPI cards (clients, revenue, churn rate, worth-saving clients, worth-saving
revenue), bar charts for clients and revenue by segment, revenue by country, and
a plain-language recommendation. Built on six DAX measures and a segment column.
Screenshot in `/docs`.

## Files

```
etl.py              clean the raw data and load it into MySQL
export.py           pull the clients table out for the dashboard
sql/schema.sql      the CREATE TABLE statements
sql/analysis.sql    the analysis queries
docs/               ER diagram and dashboard screenshot
```

## A note on the numbers

The data is public. The ROI figures are estimates based on the assumptions above,
not actual results from a real company.
