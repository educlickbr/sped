# SQL Standards and Best Practices

## UNION and UNION ALL

When using `UNION` or `UNION ALL`, strict adherence to the following rules is
required to precise mismatches and errors:

1. **NO SELECT ***: Never use `SELECT *` in any branch of a `UNION` or
   `UNION ALL`. The expansion of `*` depends on table definition order and can
   change unexpectedly.
2. **Explicit Column Listing**: Always explicitly list every column in the same
   order for all branches.
3. **Explicit Type Casting**: For `NULL` values or literals in a branch
   (especially when matching a typed column in another branch), ALWAYS use
   explicit casting (e.g., `NULL::uuid`, `NULL::jsonb`, `NULL::text`,
   `true::boolean`).
   - _Bad_: `SELECT id, NULL, ...`
   - _Good_: `SELECT id, NULL::text as description, ...`
4. **Column Names for Readability**: It is good practice to alias the columns in
   the second branch to match the first, even though SQL only uses the first
   branch's names. This aids readability and verification.

### Example

```sql
-- INCORRECT
SELECT * FROM table_a
UNION ALL
SELECT id, name, NULL FROM table_b;

-- CORRECT
SELECT 
    id, 
    name, 
    description,
    status
FROM table_a

UNION ALL

SELECT 
    id, 
    name, 
    NULL::text as description, -- Explicit cast matching table_a.description
    'pending'::text as status
FROM table_b;
```
