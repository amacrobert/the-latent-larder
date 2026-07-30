---
description: Generate and attach photos for recipes that don't have one yet
argument-hint: [optional recipe slug, e.g. "slow-lamb-shoulder-with-anchovy" — omit to do all of them]
allowed-tools: Bash(./bin/recipes-without-images), Bash(./bin/generate-recipe-image:*), Bash(./bin/resize-recipe-image:*), Bash(dwebp:*), Bash(ls:*), Bash(file:*), Read, Edit
---

# Shoot the missing recipe photos

## Recipes with no photo

!`./bin/recipes-without-images`

## What to do

The user's steer, if they gave one: **$ARGUMENTS**

If they named a recipe, do only that one — but still confirm it appears in the
list above. If it doesn't, say so and stop; it already has a photo. If they
gave no steer, work through every recipe in the list, **one at a time, start to
finish**, before moving to the next. Don't batch up prompts or generations
across recipes; a half-finished recipe is much harder to untangle than a queue.

If the list is empty, say so and stop.

Generating costs money, so check `OPENAI_API_KEY` is set before writing a single
prompt — failing on the first recipe is better than failing on the fourth.

For each recipe, the loop is: write the prompt → generate the image → bring the
file into the repo → point the recipe at it.

---

## Step 1 — Write the image prompt

`Read` the recipe file in full. Then answer the prompt below **yourself** — you
are the prompt writer it addresses. Substitute the recipe's entire file
contents, front matter included, for `{{RECIPE}}`.

Its closing line ("Output only the image prompt") governs what you hand to the
image generator, not what you say to the user. Show the user the prompt you
wrote before you send it.

````
You write prompts for a photorealistic image generator. Given a recipe, produce a single image prompt describing the finished dish exactly as that recipe would actually produce it. First, read the recipe and determine:

* What it physically looks like when done. Derive color from the cooking method — braises go deep and glossy, boiled things stay pale, anything roasted or seared has uneven browning. Derive texture from technique. Derive volume from the yield.
* The correct vessel. A skillet recipe is photographed in the skillet. A braise is in a dutch oven. Soup is in a bowl. Do not plate something that was never plated.
* Garnishes and components that are actually in the ingredient list. Never add herbs, citrus, cream, or seeds the recipe doesn't call for.
* Portion state. Whole, sliced, served, or mid-serve — pick whichever best shows the recipe's defining quality (a layered bake gets a cut portion revealing the interior; a roast stays whole).
Then write the prompt as one dense paragraph in this order: the dish and its doneness → visible texture and color detail → vessel and surface → composition and camera angle → lighting → mood. Apply these constraints to every prompt you write:

* Home kitchen, not a restaurant or studio. Warm, lived-in, slightly imperfect — a crumb on the table, an uneven edge, a drip down the side of the bowl. Food that looks cooked by a person, not styled by an agency.
* Natural light only: soft diffused daylight from a window to one side, gentle falloff, soft shadows. Never harsh flash, never colored gels, never rim lighting.
* Warm neutral surroundings — worn wood, linen, ceramic, weathered enamel. Muted, warm color grading.
* Realistic camera language: 50mm or 85mm, shallow but not extreme depth of field, natural focus falloff. Choose the angle by dish — overhead for bowls, flat things, and anything with a top surface worth seeing; 45 degrees for plated food with height; low and near-level for stacks and layers.
* No hands, no people, no text, no labels, no logos, no watermarks.
* Avoid: excessive gloss or wetness, hyper-saturation, perfect symmetry, impossible cheese pulls, floating or levitating ingredients, steam that looks painted on, food that glows.
Output only the image prompt. No preamble, no explanation.
Recipe:
{{RECIPE}}
````

## Step 2 — Generate the image

This runs headless, with no browser and no logged-in ChatGPT session. Images
come from the OpenAI API via `bin/generate-recipe-image`, which needs
`OPENAI_API_KEY` in the environment. If it isn't set, stop and say so — don't
go looking for a key in the repo, in shell history, or in any dotfile.

The image name comes from the **recipe's slug**, with each hyphen-separated
word capitalised: `slow-lamb-shoulder-with-anchovy` →
`Slow-Lamb-Shoulder-With-Anchovy`. Call that `<Name>`.

Pass the prompt on **stdin via a quoted heredoc**, so nothing in it needs
escaping:

```bash
./bin/generate-recipe-image <Name> <<'PROMPT'
<the image prompt from step 1, verbatim>
PROMPT
```

Send **only the image prompt** — not the instructions that produced it, and not
the recipe. Quoting the heredoc delimiter (`<<'PROMPT'`) matters: unquoted, the
shell would expand backticks and `$` inside the prompt.

The script writes `assets/images/originals/<Name>.png` and prints the path. It
generates at 1536x1024, the API's landscape size and the only one wide enough to
reach the site's 1400px without upscaling. Cards centre-crop to 4:3 in CSS, so
keep the dish centred in the framing you describe.

A run takes up to a couple of minutes. **Never re-run it just because it feels
slow** — every call bills the user. If it exits non-zero it has already printed
why and written nothing; fix that cause rather than retrying blindly.

Model, size and quality can be overridden with `OPENAI_IMAGE_MODEL`,
`OPENAI_IMAGE_SIZE` and `OPENAI_IMAGE_QUALITY` if the user asks. Leave them
alone otherwise.

## Step 3 — Make the web versions

The PNG is already in place from step 2. Convert it:

```bash
bin/resize-recipe-image <Name>
```

The original PNG stays in `originals/` at full resolution — that's the archive,
and it's gitignored, so nothing this step writes ever touches it. Two files come
out, and both belong in the commit:

* `assets/images/<Name>.webp` — 1400px wide, the hero and the card. Should land
  somewhere around 200–250KB.
* `assets/images/<Name>-tall.webp` — a 2:3 centre crop for Pinterest, which the
  page references through `data-pin-media` but never displays.

The script prints both sizes. If the wide one is wildly bigger than 250KB, nudge
`LARDER_WEBP_QUALITY` down from 70; if it's tiny, the source was probably low-res
and worth regenerating.

Then **look at the tall crop**. It keeps the middle 2/3-by-height of a landscape
photo, so a centred dish survives and an off-centre composition does not. Decode
it and read it as an image:

```bash
dwebp -quiet assets/images/<Name>-tall.webp -o /tmp/<Name>-tall.png
```

If the crop has cut the dish in half or left the subject at the edge, the fix is
the prompt, not the crop — go back to step 1 and describe the dish as centred in
the frame, then regenerate. Don't hand-crop around a bad composition.

## Step 4 — Point the recipe at it

Add one line to the recipe's front matter, directly after `description:` and
before `servings:` — that's where it sits in the recipes that already have one:

```yaml
image: /assets/images/<Name>.webp
```

Use `Edit`. Change nothing else in the file. The path is site-root-relative,
with a leading slash.

## Before you finish

Re-run the finder. The recipes you just did must no longer be listed:

```bash
./bin/recipes-without-images
```

If one still appears with `(image missing: ...)`, the `image:` path and the file
on disk disagree — fix the mismatch rather than leaving it.

Then report, per recipe: the dish, the image prompt you wrote, and the webp path
with its dimensions from `file`. On a machine with a browser, `docker compose up`
previews the cards at <http://localhost:4000/>.

Don't build, commit, or push unless the user asks.
