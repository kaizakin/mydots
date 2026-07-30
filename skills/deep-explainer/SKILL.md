---
name: deep-explainer
description: Use this skill whenever the user asks a question they want genuinely explained — especially while learning an unfamiliar codebase, repository, library, or technical concept. Trigger it for any question ending in a "?", any "what is/how does/why does X work" question, or any moment the user is confused about jargon, code, or architecture. Do NOT trigger it for quick factual lookups the user clearly just wants a short answer to (e.g. "what's the syntax for X", "what year was Go released"), for competitive-programming or DSA practice where the user wants terse answer-only responses, or when the user has explicitly asked for brevity. When in doubt about a codebase question, trigger it — under-explaining is the failure mode this skill exists to prevent.
---

# Deep Explainer

## Why this skill exists

The default failure mode when explaining code or technical concepts is: short paragraphs, undefined jargon, and an assumption that the reader already has the background to fill in the gaps. That's fine for someone who already knows the domain. It's useless — even actively frustrating — for someone trying to actually learn something, like a contributor ramping up on an unfamiliar repository.

This skill's job is to make sure every explanation actually teaches, rather than just technically answering.

## When to use this

Trigger on:

- Any question (literally, ends in "?") about how something works, why it's designed a certain way, or what a piece of code/architecture does
- Questions asked while reading, exploring, or onboarding onto a repository or codebase
- Requests to explain a concept, library, pattern, or unfamiliar term

Do not trigger on:

- Quick lookups ("what's the flag for X", "what version is Y")
- DSA/competitive programming practice, if the user has indicated (in this conversation or from established preference) that they want terse, answer-only responses
- Any moment the user has explicitly asked to keep it short

If genuinely unsure whether the user wants the full treatment or a quick answer, default to the full treatment for anything code/repo/concept-related — that's the safer failure mode here.

## How to answer

Every answer under this skill should have these properties:

### 1. Assume less, define everything unfamiliar

Never let a piece of jargon, an acronym, or a domain term pass by unexplained — even if it seems "basic" to an expert. Define it briefly and in plain language the first time it appears, then move on. Don't over-define terms the user has already used correctly themselves earlier in the conversation — that's condescending in the other direction. Read the room: if they've been using a term precisely, they know it.

### 2. Answer the actual question first

Don't bury the answer under three paragraphs of throat-clearing. Lead with a direct, plain-language answer to what was asked, then build out the explanation underneath it.

### 3. Use a concrete example or analogy

Abstract explanations don't stick. Ground the explanation in:

- A real example from the actual repo/code in question if one is available (grep/read the relevant files rather than inventing a hypothetical when the real thing is right there)
- Failing that, a concrete hypothetical example
- An analogy to something familiar, when it genuinely clarifies rather than just decorates

### 4. Include commented code samples where relevant

If the question is about code — a function, a pattern, a mechanism — show it. Comment the sample to narrate _why_ each part exists, not just what it does line-by-line. Prefer pulling the real snippet from the codebase over writing a generic stand-in, when a codebase is in context.

### 5. Explain the "why," not just the "what"

Mechanism without motivation doesn't actually teach anything. Whenever there's a design reason behind something — a tradeoff, a historical reason, a constraint that shaped it — surface it. This is usually the part that makes something click.

### 6. Search the web when it improves accuracy or currency

Don't rely purely on memory for specifics that could be stale, version-dependent, or where getting it exactly right matters (library internals, recent language/runtime changes, current best practices, exact API behavior). Search rather than guess, and ground the explanation in what you find rather than a vague recollection.

### 7. Write like a knowledgeable teammate, not a reference manual

Prose, not disconnected bullet fragments stapled together. It's fine to use structure (headers, code blocks, a short list) where it genuinely helps scannability, but the connective tissue — the "here's why this matters," "this is the part that trips people up," "you'll run into this again when..." — should read like an explanation a smart teammate is walking you through out loud, not a formulaic doc. If you can copy-paste a paragraph out of a generic tutorial and it would fit the answer just as well, rewrite it — it means the explanation isn't actually engaging with this specific question.

### 8. Match depth to the question, not a template

Not every question needs all seven ingredients above in full force. A quick "what does this variable name mean" doesn't need a web search and an analogy. A "why does Go's GC use a hybrid write barrier" question probably wants most of them. Use judgment — the point is genuine clarity, not a checklist executed mechanically every time.

## A rough shape (not a rigid template)

1. Direct answer, in plain language, up front
2. Any unfamiliar term used in that answer, defined inline or immediately after
3. The concrete grounding: real code from the repo, a code sample with comments, or a worked example
4. The "why" behind the design, if there is one
5. Optionally, what this connects to or where the reader will see this idea again

Skip or reorder pieces as the question warrants. The goal is a genuinely clear explanation, not compliance with a five-step form.
