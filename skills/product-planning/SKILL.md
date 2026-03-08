---
name: product-planning
metadata:
  compatible_agents: [claude-code]
  tags: [product, planning, roadmap, prd, user-stories, mvp, sprint]
description: >
  Product and project planning assistant for CTOs and software leads.
  Generates PRDs, roadmaps, user stories in BDD format, MVP scopes, and sprint plans.
  Trigger with: "write a PRD", "generate roadmap", "create user stories",
  "define MVP scope", "plan sprint", "write product requirements", "feature spec".
---

## Commands

| Command | Description |
|---------|-------------|
| `/product prd` | Generate a Product Requirements Document via interview |
| `/product roadmap` | Generate a phased project roadmap |
| `/product stories` | Generate user stories in BDD format |
| `/product mvp` | Define MVP scope with explicit in/out decisions |
| `/product sprint` | Plan a sprint with estimates and definition of done |

---

## `/product prd`

Interview the user then generate a complete PRD.

**Interview (ask all at once):**
1. What is the product or feature name?
2. What problem does it solve, and who has this problem?
3. What are the key goals and success metrics?
4. Who are the primary user personas?
5. What are the main capabilities required?
6. What are the constraints (tech stack, timeline, budget)?
7. What is explicitly out of scope?

**Output:** `docs/prd-[feature-name].md` following `references/prd-template.md`

**Rules:**
- Every feature section must include acceptance criteria
- Flag all assumptions explicitly in a dedicated section
- Success metrics must be measurable (avoid "improve UX")
- Requirements describe WHAT, never HOW — no implementation details
- Out of scope section is mandatory

---

## `/product roadmap`

Generate a phased roadmap from a product description or existing PRD.

**Input:** Product description or path to an existing PRD file.

**Output:** `docs/ROADMAP.md` with these phases:
- **Phase 0 — Foundation:** infra, tooling, auth, baseline scaffolding
- **Phase 1 — MVP:** core user loop, minimum viable value
- **Phase 2 — Growth:** integrations, secondary features, onboarding
- **Phase 3+ — Scale:** performance, enterprise features, open source

Each phase must include:
- Goal (one sentence)
- Deliverables (concrete, shippable items)
- Dependencies on prior phases
- Rough time estimate

**Rules:**
- MVP is one phase only — if it needs two phases it is not an MVP
- Each phase must have a clear "why this order" justification
- Dependencies between phases must be explicit, not implied

---

## `/product stories`

Generate user stories from a feature description or PRD.

**Format:**
```
As a [persona], I want to [action] so that [outcome].

Acceptance Criteria:
- Given [context], when [action], then [result]
- Given [context], when [edge case], then [result]
```

**Rules:**
- One story per discrete, independently testable behaviour
- At least one unhappy path per story
- Acceptance criteria in Gherkin (Given/When/Then) only
- Stories must not reference implementation (no "click button X")
- Group stories by feature/epic

---

## `/product mvp`

Define MVP scope from a product idea or candidate feature list.

**Interview:**
1. What is the core user problem being solved?
2. What is the minimum journey a user must complete to get value?
3. List all candidate features.

**Output:**
- **Core loop:** the single user journey that proves the product works
- **In MVP:** only what is essential to complete the core loop
- **Out of MVP:** everything else, each with a one-line reason
- **Open questions:** assumptions that need validation before building

**Rules:**
- If in doubt, cut it
- Every "in" item must map directly to the core loop
- "Nice to have" is always out of MVP
- The core loop should be expressible in one sentence

---

## `/product sprint`

Plan a sprint from a backlog or feature list.

**Input:** List of stories or tasks + sprint duration (default 2 weeks).

**Output:**
- Sprint goal (one sentence)
- Committed stories with T-shirt estimates (S/M/L/XL)
- Carry-over or parking lot items
- Risks and blockers
- Definition of Done checklist

---

## Trigger Phrases

`write a PRD`, `product requirements`, `feature spec`, `generate roadmap`,
`project roadmap`, `user stories`, `BDD stories`, `acceptance criteria`,
`define MVP`, `what's in scope`, `what's out of scope`, `plan sprint`,
`sprint planning`, `product spec`, `what should we build`

---

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| PRD includes implementation details | Requirements describe WHAT, not HOW |
| MVP with more than one core loop | One loop, ruthlessly cut everything else |
| User stories without acceptance criteria | Every story needs Given/When/Then |
| Roadmap phases without dependencies | Every phase must declare what it depends on |
| Vague success metrics ("improve performance") | Measurable targets ("p95 < 200ms") |
| No out-of-scope section | Always define boundaries explicitly |

---

## References

| File | Purpose |
|------|---------|
| `references/prd-template.md` | Full PRD document structure and section guidance |
| `references/user-stories.md` | Story patterns, BDD examples, anti-patterns |
| `references/roadmap-template.md` | Roadmap phases, milestone format, dependency notation |
