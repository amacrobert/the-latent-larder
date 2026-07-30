---
description: Draft a new recipe for the larder (everything but the image)
argument-hint: [optional steer, e.g. "something with leeks" or "a weeknight soup"]
allowed-tools: Bash(grep:*), Bash(date:*), Bash(ls:*), Read, Write, Glob
---

# Add a recipe to The Latent Larder

Right now: !`date +'%Y-%m-%d %H:%M:%S %z'`

## Already in the larder

!`grep -rH -E '^(title|description|tags):' _recipes/ 2>/dev/null || echo '(the larder is empty)'`

## What to write

The user's steer, if they gave one: **$ARGUMENTS**

If they gave a steer, follow it. If they didn't, choose the dish yourself.

Judge a new recipe against the existing ones on three axes: its **main
ingredient**, its **cooking technique**, and its **role at the table**.
Overlapping on one or two of those is completely fine and expected — a larder
should have more than one chicken recipe, and more than one thing that gets
roasted. What to avoid is a dish that matches an existing recipe on all three
at once, because that's the same recipe under a different name.

Past that bar, lean toward filling gaps. Prefer something that brings in an
ingredient, a technique, or a course the collection doesn't have yet over a
third variation on what's already there, and vary the effort level — if the
larder is all quick sides, write something slow.

Create exactly one file: `_recipes/<slug>.md`. The filename becomes the URL, so
use lowercase words separated by hyphens (`_recipes/braised-white-beans.md` →
`/recipes/braised-white-beans/`). Do not touch any other file.

## The file

```yaml
---
title: Braised White Beans
date: <the full timestamp from above, copied exactly>
description: One dry, concrete line. What it is and why you'd make it.
servings: 4
prep_time: 10 min
cook_time: 40 min
tags: [beans, slow, vegetarian]
ingredients:
  - 2 cups | dried white beans, soaked overnight
  - ¼ cup | olive oil
  - 2 cloves | garlic, sliced
  - To finish | lemon zest and parsley
method:
  - One imperative step per line, in order.
  - Each step ends when something observable happens, not after a fixed time alone.
---

Two short paragraphs at most, below the front matter. These render as **Notes**.
```

**No `image:` field.** The photo gets added later; the card and the recipe page
both look right without one.

**No `layout:` line** either — `_config.yml` applies it to the whole collection.

## Rules that are easy to get wrong

**`date` needs the time and the offset**, not just the day — copy the timestamp
above verbatim. Several recipes are published a day, and the time is the only
thing that puts them in the order they appeared, on the home page and in both
feeds. Only the date is ever displayed, so the time costs the reader nothing.
Writing a bare `date: 2026-07-29` builds fine but lands the recipe at midnight,
below everything else published that day — which is the one thing the timestamp
is there to prevent.

**Imperial measurements only.** Cups, oz, lb, tsp, tbsp, and °F. Never grams,
millilitres, or °C anywhere — including inside method steps and notes.

**Loose amounts where a precise one would read oddly.** `2 cloves`, `½ lemon`,
`A handful`, `4 slices`, `1 bunch`, `To finish`, `To taste`. Don't write
`0.4 oz garlic`.

**Only the fractions `½`, `¼`, and `¾`.** Never `⅓`, `⅔`, `⅛`, or any other.
This is not a style preference: the site's self-hosted fonts declare a
`unicode-range` covering Latin-1, where `½ ¼ ¾` live. `⅓` and `⅔` sit outside
it and silently fall back to a system font mid-word, which looks broken. If a
quantity wants thirds, rewrite it — use a different amount, or `2 tbsp`, or a
loose measure.

**Convert ratios together, not ingredient by ingredient.** For anything where
the proportion is the recipe — bread hydration, a custard, a brine, a
vinaigrette — pick the cup amounts so the *ratio* survives, then round. Rounding
each ingredient independently drifts the thing that actually matters.

**Ingredients use a `qty | name` pipe split.** The left side lands in a narrow
column (about 4.9rem), so keep it to roughly ten characters — `1½ cups`,
`2 cloves`, `A handful` all fit; a long phrase wraps and breaks the rail. An
ingredient with no pipe spans the full width, which is right for things like
`Flaky salt, to finish`.

**Reuse existing tags** from the list above where they genuinely apply, so the
vocabulary stays small. Lowercase.

## Voice

Match the recipes already there. Confident, dry, and practical — someone who
has actually cooked this telling you the part that matters.

- `description` is one line. Concrete, faintly wry, never marketing copy.
- Method steps give a sensory cue for doneness: "until the edges have browned,"
  "until it smells nutty," not just "cook for 5 minutes."
- The notes explain the **why** — the one thing that makes or breaks the dish,
  and a substitution or a way to serve it. Not a story about your grandmother.
- No preamble before the ingredients. That's the whole premise of the site.

## Before you finish

Run these against the file you wrote. The first must return nothing, and the
second must print the `date:` line with a time and an offset on it:

```bash
grep -nE '⅓|⅔|⅛|⅜|⅝|⅞|[0-9] ?g\b|[0-9] ?ml\b|°C' _recipes/<slug>.md
grep -nE '^date: [0-9-]{10} [0-9:]{8} [-+][0-9]{4}$' _recipes/<slug>.md
```

Then report the path you created, the dish, and how it sits alongside what was
already in the larder. Mention that the `image:` field still needs adding, and
that `docker compose up` previews it at <http://localhost:4000/>.

Don't build, commit, or push unless the user asks.
