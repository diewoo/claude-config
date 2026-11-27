---
name: hexagonal-field-propagation
description: Use when adding, renaming, or removing a field in a Hexagonal/DDD backend — database schema, entity, DTO, repository interface, repository implementation, or shared types. Any field change that touches one layer must be propagated to all layers before the task is considered done.
---

# Hexagonal Field Propagation

## Overview

When you add, rename, or remove a field in a Hexagonal/DDD codebase, **every layer owns a copy of that field**. Missing even one causes TypeScript errors, runtime bugs, or silent data loss. Complete the full checklist before marking the task done.

## The Checklist (mandatory, in order)

| # | Layer | What to update |
|---|-------|----------------|
| 1 | **DB schema** | Add column to table definition |
| 2 | **Migration** | Generate and apply migration (`generate` + `push/migrate`) |
| 3 | **Domain entity** | Add field to entity class |
| 4 | **Domain repository interface** | Add field to every relevant DTO (`CreateXDto`, `UpdateXDto`) AND to method signatures (`Pick<>` unions, return types) |
| 5 | **Infrastructure repository** | Add field to every row mapper (there may be 2-4 mappers per entity) and to `Pick<>` in the implementation |
| 6 | **Shared types** | Add field to `XEntity` and `UpdateXDto` in `@<org>/shared` |
| 7 | **Frontend types** | Verify the field flows through to any frontend form/store that reads or writes it |

## Red Flags — STOP, You Missed a Layer

- TypeScript error: `Property 'x' does not exist on type '...'`
- A mapper returns the entity but a test shows the field is always `undefined`
- The domain interface compiles but the implementation has a `Pick<>` that doesn't include the new field
- You updated `UpdateXDto` in shared but forgot `CreateXDto` in the domain interface

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Only updating the Drizzle implementation, not the domain interface | Always update interface AND implementation together |
| Updating shared `UpdateXDto` but not `CreateXDto` in domain | Both DTOs must carry the field |
| Forgetting one of multiple mappers in the repo (e.g. `findById` vs `findAll`) | Grep for `postalCode: row.` (or any existing sibling field) to find ALL mappers |
| Assuming `tsc` passed = done | `tsc` only catches what's in the graph — check DB push too |

## How to Find All Mappers

Search for a sibling field that already exists in all mappers:

```bash
rg "postalCode: row\." apps/api/src
```

Every match is a mapper that needs the new field.

## After Every Change

- [ ] `pnpm --filter @<org>/database run generate` → migration created
- [ ] `make db-push` → local DB updated
- [ ] push the schema to the target database (if deploying)
- [ ] `pnpm --filter @<org>/database run build` → dist types rebuilt
- [ ] Restart TS server in editor
