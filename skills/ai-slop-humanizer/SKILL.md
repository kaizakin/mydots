---
name: ai-slop-humanizer
description: A voice translation skill that strips away sterile, overly polished, or robotic AI-slop framing and rewrites text into an engaging, natural, and authentic human developer voice. It infuses structural variety, conversational asides, real-world physical analogies, and a relaxed peer-to-peer tone. Use this skill whenever the user says "humanize this", "make this sound human", "remove the AI smell", "de-ai this", "rewrite casually", "sound like a developer", or shares an AI-generated paragraph, draft, or technical summary and asks to make it readable and authentic. The skill accepts input as pasted text, a file path, or a URL. Output is the re-voiced version of the same content, retaining all core technical facts while completely transforming the delivery into a living human style.
---

# Human Voice Normalizer Skill

An architectural and voice re-writer. Walks the input top to bottom and strips away the rigid, highly predictable patterns characteristic of AI engines (balanced "on one hand/on the other hand" arguments, academic transitions, uniform paragraph structures). It replaces them with the varied pacing, concrete physical analogies, and casual cadence of an experienced systems developer writing a personal blog post or a community guide.

The goal is to keep every technical fact, metric, code snippet, and architectural constraint perfectly intact, but alter the delivery so it feels like it was punched out on a mechanical keyboard by an engineer who cares deeply about the subject.

## Identifying the AI Smells to Kill

The skill scans for and systematically dismantles the following robotic patterns:

- **Perfect symmetry**: Intro paragraphs that preview exactly three points, followed by uniform paragraphs, capped with an "In conclusion, X is a powerful tool for engineers..." summary.
- **Academic transition padding**: Words like _Furthermore, Consequently, Moreover, It is imperative to note, In summary, Alternatively,_ and _Therefore_ used as structural crutches.
- **Sterile neutrality**: Text that refuses to state an opinion clearly, balancing minor trade-offs with excessive hedging rather than making a definitive architectural recommendation.
- **Narrative distance**: Phrasings that talk _at_ the reader rather than _with_ them (e.g., "When a system administrator encounters latency..." versus "When your server starts chugging...").
- **Code echo**: Passive text immediately following a code block that mechanically restates exactly what the code does line-by-line without adding architectural intent or context.

## The Humanization Blueprint

The skill applies these active transformations to the text:

- **Lead with an analogy**: Replace textbook definitions with a high-speed physical analogy before introducing the formal name of the concept (e.g., explaining caching using items on a desk versus a back-room storage unit).
- **Vary the rhythm**: Mix short, sharp statements with long, conversational sentences that feature minor run-on explanations or parenthetical thoughts—mimicking how people actually talk when they are excited about a topic.
- **Inject peer meta-commentary**: Use light, casual self-referential notes, common dev expressions, or punctuation habits (e.g., parentheticals like `(your friends ofc)`, informal markers like `Yeahh LinkedIN XDD`, or casual contextual disclaimers like `(if any, yeah I am delusional)`).
- **Conversational bridge transitions**: Replace formal transitions with natural setups (e.g., _"Lets first start with..."_, _"Now that we understand the blocks..."_, _"As an engineer you should get this question..."_).
- **Informal emphasis**: Use casual bolding inside text blocks to guide the eye toward core concepts naturally, rather than relying strictly on heavy nested Markdown header trees.
- **Warm community wrap-up**: Conclude the text with a brief, encouraging peer sign-off rather than a corporate summary (e.g., _"Hope I was able to add few value to your today's learning :)"_).

## Input Handling

The skill accepts input in three formats:

1. **Pasted text**: Raw text within the conversation window.
2. **File path**: Paths pointing to local text files (`.txt`, `.md`).
3. **URL**: Links to articles, blog drafts, or documentation pages.

## Transformation Rules

1. **Protect the Muscle**: Never drop or dilute technical metrics, memory sizes, algorithmic complexities ($O(1)$, $O(n^2)$), configuration names (`appendfsync`), system calls (`epoll`, `kqueue`), structural limits, or raw code examples.
2. **Re-skin the Scaffolding**: Keep headers and code blocks intact, but rewrite the text inside and around them completely to match the target voice.
3. **No Artificial Diffing**: Output only the completed, transformed human-written piece. Do not add metadata notes, change logs, or text explaining what words were swapped out.

## Output Structure

Begin with a single line stating the transformation focus:
`Humanizing text: injecting engineering voice and removing structural slop.`

Print a horizontal line divider:

---

Render the fully re-voiced content from start to finish. Ensure all code blocks and structural anchors remain intact, but completely alter the prose to flow conversationally.

Conclude with the signature human sign-off:

---

Hope I was able to add few value to your today's learning :)
