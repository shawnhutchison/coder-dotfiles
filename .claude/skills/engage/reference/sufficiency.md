# Sufficiency check

Planalysis runs this check in step 4 and fills `plan.md`'s Sufficiency table. It sorts the ticket's gaps into the few that need the user and the many that take a recorded default.

Assume gaps. On 148 past tickets only 21 held enough to build without asking. Most had no acceptance criteria, so a missing list predicts nothing: write the criteria yourself as the verification recipe.

## Check each ask

1. **Outcome, surface and states.** What is true when it is done, which repos change, and which statuses the rule covers. For a frontend ask, confirm from a real response that the API returns every field the screen shows.
2. **Contract, data and owner.** Shapes and errors, an example record, and who decides each open item.
3. **Claims.** Anything the ticket says already exists, or calls frontend only. Check it in the code.
4. **Hedges.** Every TBD, "?", "maybe", "either ... or" and "to confirm" becomes a numbered question.
5. **Silent decisions.** A write that can fail halfway, a filter that lists no states, a limit with no number, a search with no columns.

For each screen, list each label, what empty, null and zero show, the default sort, the filters and export order, where errors show, the loading state, and the other screens that show the same value.

## Ask the user

Ask before "Engage." only when:

- two readings of an ask lead to different files;
- a new screen has no visual, from a design or a screenshot;
- the design is marked unreliable or out of date;
- a hedge names a business rule that only product or finance can set;
- the description is a link you cannot read.

Ask for the visual itself when one is missing. More visuals do not fix the other gaps: past tickets with visuals at creation still changed late about half the time.

## Default and record

Fill every other gap with a default. Record each one in Decisions as "recommended, not confirmed", and put it in the product comment that Planalysis drafts in step 5. The design system and the nearest existing screen win over these defaults.

- Null shows "-". A real zero shows 0. A missing amount never shows as zero money.
- A new table keeps the sort of the nearest similar table. An export follows the table's sort and filters.
- All validation errors show at once. A submit button shows its own loading state.
- A changed value changes on every screen that shows it.

A question sent with options got an answer the same day on past tickets. An open question waited 3 to 21 days.

## Signals of late change

Any one of these predicts changes at QA or acceptance:

- a design link marked unreliable;
- a ticket added mid-sprint, or flagged for early frontend review;
- a new or changed screen;
- hedge words in the description.

When one holds, recommend `Design pass: yes` and send the product comment before "Engage.".
