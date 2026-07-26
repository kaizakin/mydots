# Writing Style Guide for ONBOARDING.md

The single biggest way this document fails is by turning into a stack of disconnected bullet points and topic headers with no throughline. AI-generated technical docs tend to do this because bullets are "safe" — they let you dump facts without committing to how those facts relate to each other. That's exactly the crutch to avoid here.

## The core instruction

Write like you're explaining the codebase out loud to a new teammate sitting next to you, and someone transcribed it into Markdown afterward. That means:

- Full sentences, connected by transitions ("Because of this...", "Which is why...", "The tricky part here is...", "You'll notice that...").
- Reasoning stated explicitly, not left implicit. Don't just say what's true — say why it's true, or why it matters to someone about to write code here.
- Second person, directly addressing the contributor ("you'll spend most of your time in `internal/scheduler`," not "developers typically work in `internal/scheduler`").
- Paragraphs, not bullet lists, as the default unit of explanation. Bullets are fine for genuinely enumerable, parallel items (a list of dependencies, a list of directories) — but even then, each bullet should carry a full explanatory clause, and the list should be introduced and often followed by a sentence of connective prose, not left to speak for itself.

## Before / after examples

**Bad (bullet dump, no connective reasoning):**

> ### Tech Stack
>
> - Go 1.22
> - gRPC
> - PostgreSQL
> - Redis
> - Prometheus

This tells the reader nothing they couldn't get from the manifest file themselves. It doesn't explain relationships or reasoning.

**Good (same facts, explained):**

> The core service is written in Go, which makes sense once you see how much of this project leans on goroutines for concurrent connection handling — the scheduler in `internal/worker` spins up one goroutine per incoming job, and Go's lightweight threading model is really what makes that design affordable at the scale this project runs at. Services talk to each other over gRPC rather than REST, mostly because the project needs typed, versioned contracts between the scheduler and the workers, and the `.proto` definitions in `api/proto/` double as the source of truth for that contract. State that needs to survive a restart — job definitions, user accounts — lives in PostgreSQL, accessed through the `internal/store` package, while Redis is used purely as an ephemeral queue for jobs waiting to be picked up, which is why you won't find any Redis calls outside `internal/queue`. Prometheus metrics are wired in throughout, most usefully in `internal/worker/metrics.go` if you want to see what the team considers worth measuring.

Notice the second version says _why_ each choice was made, _where_ it shows up in the code, and connects the pieces to each other — the goroutine-per-job model connects to why Go was chosen, Redis's role is explained by contrast with Postgres's role, and so on.

**Bad (architecture description as a bullet outline):**

> ### Architecture
>
> - API Gateway
>   - Handles auth
>   - Routes requests
> - Worker Pool
>   - Processes jobs
>   - Reports status
> - Database Layer
>   - Stores results

**Good:**

> When a request comes in, it hits the API gateway first (`cmd/gateway/main.go`), which does exactly two things before handing off: it validates the JWT against the auth service, and it figures out which worker pool should own this job based on the `job_type` field. That routing decision is the interesting part — it's not a simple round robin, it's a consistent-hash lookup in `internal/router/hash.go`, which is why you'll want to read that file before adding a new job type, since getting the hash key wrong there silently sends jobs to the wrong pool. Once a job lands on a worker, `internal/worker/pool.go` owns its lifecycle end to end: claiming it off the Redis queue, running it, and writing the result back through `internal/store`, which is the only package allowed to talk to Postgres directly — that boundary is enforced by convention, not by tooling, so it's worth respecting even though nothing will stop you from breaking it.

## When bullets are actually fine

Bullets are appropriate for:

- A literal directory listing (the tree itself).
- A flat list of dependency names where each item gets a full explanatory sentence or two, not a fragment.
- Step-by-step "do this to get set up locally" instructions, where sequence matters more than narrative flow.

Even in these cases, introduce the list with a sentence of context and, where useful, follow it with a sentence tying it back to the bigger picture. Never let a header be followed immediately by an unintroduced bullet list with no surrounding prose.

## Tone calibration

Conversational doesn't mean sloppy or overly casual. Avoid forced jokes, exclamation points, or false enthusiasm ("Let's dive into this awesome codebase!"). The tone to aim for is: a competent, slightly informal senior engineer who respects the reader's intelligence and wants them to actually understand the system, not just skim a checklist. Confident, direct, willing to say "this part is a bit gnarly" or "you don't need to understand this yet" when that's true.

## Length

There is no target word count and no reason to pad. Write as much as it takes to actually explain something well, and no more. A section explaining a genuinely simple utility module might be three sentences. A section explaining the core scheduling algorithm might be several paragraphs. Let the complexity of what you're explaining set the length, not a target.
