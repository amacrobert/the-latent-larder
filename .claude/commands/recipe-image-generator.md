---
description: Generate and attach photos for recipes that don't have one yet
argument-hint: [optional recipe slug, e.g. "slow-lamb-shoulder-with-anchovy" — omit to do all of them]
allowed-tools: Bash(./bin/recipes-without-images), Bash(cwebp:*), Bash(ls:*), Bash(mv:*), Bash(file:*), Bash(sips:*), Read, Edit, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer, mcp__claude-in-chrome__read_page, mcp__claude-in-chrome__find
---

# Shoot the missing recipe photos

## Recipes with no photo

!`./bin/recipes-without-images`

## What to do

The user's steer, if they gave one: **$ARGUMENTS**

If they named a recipe, do only that one — but still confirm it appears in the
list above. If it doesn't, say so and stop; it already has a photo. If they
gave no steer, work through every recipe in the list, **one at a time, start to
finish**, before moving to the next. Don't batch up prompts or downloads across
recipes; a half-finished recipe is much harder to untangle than a queue.

If the list is empty, say so and stop.

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

## Step 2 — Generate the image in ChatGPT

Send **only the image prompt** from step 1 — not the instructions that produced
it, not the recipe.

1. Call `tabs_context_mcp` first. Never reuse a tab id from an earlier session.
2. Open a new tab on <https://chatgpt.com/>. If it lands on a logged-out page,
   stop and ask the user to sign in — don't try to authenticate.
3. Type the image prompt into the composer and submit it. Prefix it with
   `Generate an image:` so ChatGPT reaches for the image tool instead of
   discussing the prompt.
4. Image generation takes a while. Screenshot every 15–20 seconds until the
   image is fully rendered. Don't re-submit because it looks slow — a duplicate
   generation costs the user real money.
5. Hover the finished image and click its download button. ChatGPT saves to
   `~/Downloads`.

Never click anything that could raise a browser dialog. If the page won't
cooperate after two or three attempts, stop and tell the user what you tried
rather than clicking around.

## Step 3 — Bring the file into the repo

Find what just landed:

```bash
ls -t ~/Downloads | head -3
```

Take the newest file only, and sanity-check it's an image of a plausible size
with `file`. If nothing new arrived, the download didn't happen — go back to
step 2 rather than guessing at a filename.

The image name comes from the **recipe's slug**, with each hyphen-separated
word capitalised: `slow-lamb-shoulder-with-anchovy` →
`Slow-Lamb-Shoulder-With-Anchovy`. Call that `<Name>`.

```bash
mv ~/Downloads/<downloaded-file> assets/images/originals/<Name>.png
cwebp -q 70 -resize 1400 0 -metadata none \
  assets/images/originals/<Name>.png -o assets/images/<Name>.webp
```

The original PNG stays in `originals/` at full resolution — that's the archive,
and it's why `-resize` only ever touches the webp. Every published image in this
repo is 1400px wide; `-resize 1400 0` keeps the aspect ratio. The webp should
land somewhere around 200–250KB. If it's wildly bigger, nudge `-q` down; if it's
tiny, the source was probably low-res and worth regenerating.

## Step 4 — Point the recipe at it

Add one line to the recipe's front matter, directly after `description:` and
before `servings:` — that's where it sits in the recipes that already have one:

```yaml
image: /assets/images/<Name>.webp
```

Use `Edit`. Change nothing else in the file. The path is site-absolute with a
leading slash, and it does **not** include the `the-latent-larder` prefix —
Jekyll adds the baseurl at render time.

## Before you finish

Re-run the finder. The recipes you just did must no longer be listed:

```bash
./bin/recipes-without-images
```

If one still appears with `(image missing: ...)`, the `image:` path and the file
on disk disagree — fix the mismatch rather than leaving it.

Then report, per recipe: the dish, the image prompt you wrote, the webp path and
its dimensions. Mention that `docker compose up` previews the cards at
<http://localhost:4000/the-latent-larder/>.

Don't build, commit, or push unless the user asks.
