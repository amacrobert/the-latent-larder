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

### Mass appeal

There's a fourth axis, and it pulls the other way: **how many people actually
want to cook this**. The first three keep the larder varied; this one keeps it
useful. A collection that is all guanciale and dashi is a collection nobody
cooks from.

The buckets that carry real, recurring volume:

- **Weeknight dinners and 30-minute meals.** The largest evergreen category by
  far, because it's a need that recurs every week rather than an aspiration.
- **Chicken.** The most-searched protein, and breasts, thighs, and wings each
  hold up their own subcategory.
- **Ground beef and budget dinners.** High demand, and thinly served — the
  aspirational end of food writing mostly ignores it.
- **Pasta.** Near-universal, endlessly variable, and it photographs well.
- **Desserts and baking.** Cookies, brownies, banana bread. Huge, with sharp
  seasonal spikes.

Two framings cut across all of those and are closer to how people actually
search:

- **Appliance or vessel.** Air fryer, slow cooker, Instant Pot, sheet pan,
  one pot. "Air fryer chicken thighs" pulls harder than "chicken thighs."
- **Occasion.** Holiday tentpoles (Thanksgiving sides, Christmas cookies, Super
  Bowl dips), party appetizers, potluck dishes. Spiky, but enormous when they
  spike.

On dietary framing: high-protein is currently the strongest, vegetarian and
gluten-free are stable, keto is well past its peak. Use it as a frame on a dish
that stands up on its own, never as the reason for the dish.

Weigh this against the gap-filling instinct rather than letting either win
outright. If the last several recipes have been narrow — an unusual cut, an
imported ingredient, a two-day project — take the high-appeal option this time.
If the larder is already ten chicken traybakes deep, the appeal argument has
been made and you can go somewhere stranger. A high-appeal dish still has to
clear the distinctness bar above; volume is not a licence to write the same
sheet-pan chicken twice.

## The title

The title is the recipe's whole surface area — it's the card, the search
result, and the thing someone repeats to a friend. Write it deliberately.

**Keep an intact, searchable core phrase.** The core is the thing a person
would actually type: "chicken thighs," "banana bread," "lentil soup."
Modifiers wrap around that phrase; they never replace it. "Chicken Thighs" can
become "Crispy Skillet Chicken Thighs in Garlic Butter." It must not become
"Weeknight Wonder."

**Prefer modifiers that carry information.** Texture (crispy, silky, fudgy),
technique (skillet, braised, no-knead), a defining ingredient (brown butter,
gochujang, lemon-dill), or a real constraint (one-pan, 20-minute,
freezer-friendly). Each modifier should tell the reader something they'd
otherwise have to open the recipe to learn.

**Ban empty superlatives.** Never *ultimate*, *best-ever*, *amazing*,
*delicious*, *mouthwatering*, *to-die-for*, *game-changing*, or *secret*. They
describe the writer's enthusiasm, not the food.

**Two modifiers maximum, and keep the title under about 60 characters.** A
third modifier is the ingredient list leaking into the title.

**Every modifier must be true of the recipe as written.** If nothing gets
browned, it isn't "caramelized." If it uses two pans, it isn't "one-pan." If
the total time is 35 minutes, it isn't "20-minute."

Before and after:

| Bare | Titled |
| --- | --- |
| Chicken Thighs | Crispy Skillet Chicken Thighs in Garlic Butter |
| Baked Ziti | One-Pan Baked Ziti with Hot Sausage |
| Banana Bread | Brown Butter Banana Bread with Walnuts |
| Chili | 30-Minute Ground Beef Chili |
| Pulled Pork | Slow Cooker Pulled Pork with Cider Vinegar |
| Brownies | Fudgy Espresso Brownies |
| Roasted Carrots | Sheet-Pan Roasted Carrots with Honey Butter |
| Lentil Soup | Smoky Red Lentil Soup with Lemon |

Reject these:

- *The Ultimate Chicken Thighs* — "ultimate" is an empty superlative and says
  nothing about how the dish is cooked or what it tastes like.
- *Weeknight Wonder* — the core phrase is gone. Nobody searches for it, and
  nobody can tell what they'd be eating.
- *Grandma's Sunday Sauce* — nostalgia in place of a dish. "Sauce" isn't a
  searchable core, and the modifier carries no information about the food.
- *Easy Delicious Amazing Pasta Bake* — three empties stacked in front of a
  perfectly good core phrase.
- *Crispy Caramelized Miso-Butter Sheet-Pan Chicken Thighs* — over the
  two-modifier cap; the title is now doing the ingredient list's job.
- *Slow-Braised Short Ribs with Red Wine, Star Anise, and Orange Zest* — 66
  characters, and it truncates on the card before it reaches the point.
- *Caramelized Leek Tart* on a recipe where the leeks are sweated in butter
  and never take on colour — the modifier is simply false.

Create exactly one file: `_recipes/<slug>.md`. The filename becomes the URL, so
use lowercase words separated by hyphens (`_recipes/braised-white-beans.md` →
`/recipes/braised-white-beans/`). Do not touch any other file. The slug is
allowed to be shorter than the title — build it from the core phrase plus at
most one modifier, and drop the rest. "Brown Butter Banana Bread with Walnuts"
becomes `brown-butter-banana-bread.md`.

## The file

```yaml
---
title: Slow-Braised White Beans with Lemon
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
