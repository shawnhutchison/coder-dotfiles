# Review checklist

Every reviewer brief includes this file. The standing rules and the repo's conventions hold the rules. These items need a command or a query, not just a read. Mark each one pass, fail or not applicable. A fail is a finding that cites the item.

- **Edge data.** For each value the change reads from a record or a response, query dev or staging for null, zero, empty and legacy rows.
- **Query cost.** For each list endpoint or serializer the change touches, count the queries for a page of real size.
- **Static checks.** The repo's linters and type checks pass on the touched files, with no new suppressions.
- **PR body.** Every claim in the body is in the diff.
- **Silent decisions.** Each decision the code makes that no ask and no `plan.md` decision covers.
- **Siblings.** Each changed field, branch or caller has siblings that need the same change, or a reason they do not.
