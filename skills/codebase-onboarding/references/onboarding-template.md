# ONBOARDING.md Structure

Use this as the section skeleton. Every section is written as connected prose per `writing-style.md`, not as a bullet outline — the headers below are just the scaffolding, not a list of things to bullet-point under.

Adapt section names to fit the project (e.g. "Who Uses This" might become "Where You'll See This in the Wild" if that reads more naturally for the specific project) but keep the underlying coverage. Skip a section only if it's genuinely not applicable (e.g. a brand-new project with zero adopters yet — say so honestly rather than omitting silently).

---

```markdown
# Onboarding to <Project Name>

A short, warm framing paragraph (not a bullet list) that says what this document is and who it's for: someone who just cloned this repo and wants to actually understand it before their first PR, not just skim an API reference.

## What This Project Actually Is

Explain the problem the project solves, in plain language, before any jargon. Then get more specific: what does it do day to day, what does a "unit of work" look like for someone using it. Avoid restating README marketing copy uncritically — ground this in what you actually observed in the code.

## Where It's Used, and By Whom

Honest account of adoption/usage context — companies, projects, or communities known to depend on it, drawn from ADOPTERS/USERS files, README mentions, or (if available) a quick web search. If you genuinely can't substantiate this, say so plainly rather than inventing detail. Include the core maintainer/contributor picture here too (small team vs. large foundation-backed project, how active development is, where discussion happens — Discord, mailing list, GitHub Discussions).

## Tech Stack

The languages, runtimes, and major frameworks, explained with reasoning — why this stack, what tradeoffs it implies, how the pieces relate to each other. See writing-style.md's before/after example for the target density of explanation per fact.

## Libraries and Why They're Here

Grouped conceptually (not manifest order), each significant dependency explained in terms of what role it plays and, where you could determine it, why it was chosen over an obvious alternative. Skip trivial dev-tooling deps unless there's something specifically noteworthy.

## Core Architecture

The two or three central abstractions/concepts that make the rest of the system click, explained clearly and in order of dependency (concept A before concept B if B assumes A). Then walk through how the major components fit together, in prose, before any diagram — the diagram should reinforce an explanation the reader already has a head start on, not be the first time they encounter the shape of the system.

### Architecture Diagram

The high-level diagram from diagram-precision.md's first pattern — real component names, real file paths, labeled edges.

## How Data/Requests Actually Flow Through the System

Pick the one or two most important real operations in the project and narrate them start to finish in prose, citing real files and functions as you go, including what happens on error paths and any branch points that would otherwise confuse a newcomer.

### Flow Diagram(s)

One sequence or flowchart diagram per distinct flow you narrated above, following diagram-precision.md.

## Repository Layout — What Lives Where

The real directory tree (from the actual repo), each significant entry followed by an explanation of what a contributor would go there to do, not just what it "contains." Introduce the tree with a sentence of context; follow it with any cross-cutting notes (e.g. "code generation output lives in `gen/` — never edit those files directly, edit the `.proto` source instead").

## What You Should Know Before You Start

Project-specific prerequisite concepts derived from what you actually saw while tracing the architecture — algorithms, protocols, or domain knowledge a contributor needs before the code will make sense, not generic advice. Be honest about what's genuinely required versus merely helpful.

## Getting Your Bearings for a First Contribution

A short closing section, in the same conversational voice, suggesting where a newcomer might reasonably look for a first small task, and pointing to CONTRIBUTING.md / issue labels ("good first issue," etc.) if the project has them.
```

---

Do not add a rigid "Table of Contents" with dozens of sub-bullet anchors — GitHub/most Markdown renderers auto-generate a TOC from headers, and an additional hand-written one usually just adds more list clutter without helping. If the project is genuinely enormous and a manual TOC would help navigation, keep it to the top-level section names only, in one short line, not a nested outline.
