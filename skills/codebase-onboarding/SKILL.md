---
name: codebase-onboarding
description: Generates a single, deeply researched ONBOARDING.md at the root of an open source (or internal) codebase, written for a brand-new contributor. Use this whenever someone wants to understand, explore, ramp up on, or document an unfamiliar repository — trigger phrases include "help me understand this codebase," "explain this repo," "onboard me to this project," "I just cloned this and I'm lost," "write an ONBOARDING.md," "what's the architecture here," "how is this repo organized," or any request to explain a project's purpose, tech stack, dependencies, architecture, or module layout. Also use it proactively whenever a user opens or references a repository they haven't worked in before and asks broad "what is this / how does this work" questions. Do NOT use this for narrow single-file explanations, API reference generation, or README-writing for a project the user is authoring themselves (that's promotional copy, not onboarding).
---

# Codebase Onboarding

## What this skill is for

A new contributor cloning an unfamiliar repo usually gets one of two things: a sparse README, or an AI-generated wall of bullet points that lists facts without ever explaining how they fit together. Neither actually helps someone _understand_ the project.

This skill produces something different: a single `ONBOARDING.md`, placed at the project root, that reads like a thoughtful senior engineer sat down with a new hire and walked them through the codebase — what it is, why it's built the way it is, where things live, and what you need to know before you touch the code. It is long. It is prose-heavy. It uses diagrams only where a diagram earns its place, and when it does, the diagram is precise and grounded in the actual code, not a generic box-and-arrow sketch.

The single biggest failure mode to avoid: **don't just enumerate facts**. Any tool can run `ls -R` and dependency-parse a manifest file. What makes this valuable is the connective tissue — explaining _why_ a dependency was chosen, _why_ the architecture is shaped this way, _how_ a request actually flows through the system end to end. If you find yourself writing "This project uses the following libraries:" followed by a bare bulleted list with one-line descriptions, stop — you've slipped into the failure mode this skill exists to avoid.

## Before you start: read the reference files

- `references/writing-style.md` — the conversational voice this document needs, with concrete before/after rewrites. Read this before drafting any prose, not after.
- `references/diagram-precision.md` — how to build architecture and flow diagrams that are actually accurate to the code (not generic), including the Mermaid patterns to use and the research you must do before drawing one.
- `references/onboarding-template.md` — the exact section structure to fill in.

Read all three now if you haven't already. They contain the detail that keeps this skill from producing generic output; don't skip them because the workflow below seems self-explanatory.

## Workflow

This is a research-heavy task. Budget real time for exploration before you write a single sentence of the output document — the quality of the final `ONBOARDING.md` is bounded entirely by how well you actually understood the codebase first. Work through these phases in order.

### Phase 1 — Orient yourself

Start broad, the way a human would poke around a new repo:

1. Read `README.md`, `CONTRIBUTING.md`, `docs/` (if present), `LICENSE`, and any `ARCHITECTURE.md`, `DESIGN.md`, or `RFCs/` directory. These often contain the project's own account of its purpose and design intent — mine them, but verify claims against the actual code rather than repeating marketing language uncritically.
2. Run a shallow directory listing (2-3 levels deep) to get the shape of the repo before diving into any one file.
3. Identify the manifest file(s) that define the project's ecosystem: `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`/`requirements.txt`, `pom.xml`/`build.gradle`, `Gemfile`, `mix.exs`, etc. There may be more than one in a monorepo — find all of them and note which part of the repo each governs.
4. Check `git log` (e.g. `git log --oneline -20`, `git shortlog -sn`) for a sense of project age, commit velocity, and the core group of maintainers. Look for a `MAINTAINERS.md`, `CODEOWNERS`, or `AUTHORS` file too.
5. Look for signals of **who uses this project and where**: an `ADOPTERS.md` or `USERS.md` file, "used by" sections in the README, case studies in docs, or — if you have web search available — a quick search for the project name plus terms like "who uses," "production," or "case study." Don't fabricate adoption claims; if you can't substantiate who uses it, say plainly that the maintainers/community weren't identifiable from available sources rather than inventing a user list.

By the end of this phase you should be able to describe, in your own words and without looking anything up again, what problem this project solves and for whom.

### Phase 2 — Understand the tech stack and dependencies with intent, not just inventory

For each manifest file, don't just list what's in it. For every dependency that's actually central to the project (as opposed to a minor dev-tooling dependency), open the code and find where it's actually used. You're trying to answer "why this library and not an obvious alternative?" — sometimes the answer is in a code comment, a CHANGELOG entry, or a linked design doc; sometimes you have to infer it from how deeply it's woven into the core versus used at the edges.

Group dependencies conceptually (e.g. "how it talks to the network," "how it persists state," "how it's tested") rather than dumping them in whatever order the manifest lists them — the grouping itself is part of what helps a reader build a mental model.

Skip trivial dev dependencies (formatters, linters) unless the project has done something unusual with them worth a sentence.

### Phase 3 — Reconstruct the architecture by reading code, not by guessing from folder names

This is the phase that actually determines whether the output is useful. Identify the real entry point(s) — the `main` function, the HTTP server bootstrap, the CLI's dispatch table — and trace outward from there. For a handful of the most important user-facing operations (a request handling an API call, a CLI command, a build step — whatever the project's core "unit of work" is), actually follow the call path through the source files. Note the concrete function and file names as you go; you'll need them for precise diagrams and for the prose explanation.

Identify the project's core abstractions — the two or three concepts that, once understood, make the rest of the codebase click into place. Every well-designed system has these (Go's goroutine scheduler has the G-M-P model; a web framework has request/middleware/handler; a compiler has AST/pass/codegen). Name them explicitly and explain them before describing how modules are organized — module layout only makes sense once the reader has the concepts.

### Phase 4 — Diagrams

Read `references/diagram-precision.md` in full if you haven't already, and follow it exactly. In short: every diagram must be built from what you actually traced in Phase 3 (real function/file/module names), never a generic "Client → Server → Database" placeholder shape. Plan on at least two diagrams — one showing the high-level architecture (the major components and how they're wired together) and one or more showing the flow of a specific, real operation through the system step by step. If the project has multiple genuinely distinct flows worth understanding (e.g. read path vs. write path, or request handling vs. background job processing), diagram each separately rather than cramming them into one crowded picture.

### Phase 5 — Map the repository, module by module

Produce a directory tree (real, from the actual repo — not invented) annotated with what lives in each significant top-level and second-level directory. For each one, write a sentence or two of _why_ it's organized that way and what a contributor would go there to do — not just "contains utility functions," but "this is where you'd add a new output format if you were extending the CLI."

### Phase 6 — Prerequisites specific to this project

Think about what genuinely trips up a newcomer to _this specific_ codebase, as opposed to generic advice like "know Git." Examples of the right level of specificity: "you should understand how tricolor mark-and-sweep garbage collection works before touching `runtime/mgc.go`," "this project assumes familiarity with Kubernetes custom resources and controller-runtime's reconcile loop," "you need to understand CRDTs before the sync engine will make sense." Derive these from what you actually saw while tracing the architecture in Phase 3 — don't pad this section with generic career advice.

### Phase 7 — Write ONBOARDING.md

Follow the structure in `references/onboarding-template.md` and the voice in `references/writing-style.md`. Write the whole thing as connected prose organized under headers, not as a slide deck of bullet points. Length is not a constraint here — thoroughness matters more than brevity, but every sentence should still be saying something specific about _this_ project, not filler.

Place the finished file at the project's root as `ONBOARDING.md` (if a file of that name already exists, ask the user whether to overwrite, merge, or pick a different name before proceeding).

### Phase 8 — Sanity check before finishing

Before presenting the result, reread it and check for the failure modes this skill is designed to avoid:

- Did any section degrade into a loose list of unconnected bullet points instead of explained prose? Fix it.
- Are the diagrams generic, or do they use real names pulled from the actual code? If you can't point to the specific file/function a diagram box represents, it's not precise enough yet — go back and trace it.
- Does the "who uses this" section contain anything you couldn't actually substantiate? Remove speculation.
- Would a new contributor, after reading this once, be able to explain the project's core abstractions back to you in their own words? If not, the architecture section needs more explanation, not more facts.

Once you're satisfied, present the file to the user.
