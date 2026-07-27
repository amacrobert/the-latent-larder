# the-latent-larder

A static [Jekyll](https://jekyllrb.com/) recipe site published on GitHub Pages.

There are two page types: one **home** page (`index.html`) and many **recipe**
pages (`_recipes/*.md`).

## Local development

The whole toolchain lives in Docker — Ruby 3.4 and Jekyll 4.4 run in the
container, so nothing needs to be installed on the host but Docker itself.

```bash
docker compose build                          # once, and after Dockerfile changes
docker compose run --rm site bundle install   # once, and after Gemfile changes
docker compose up                             # serve with livereload
```

Then open **<http://localhost:4000/>**.

Edits to any file trigger a rebuild and a browser reload. Press `Ctrl-C` to stop,
or `docker compose down` to remove the container.

To build once without serving:

```bash
docker compose run --rm site bundle exec jekyll build
```

## Adding a recipe

Create `_recipes/my-recipe.md`. The filename becomes the URL:
`/recipes/my-recipe/`. No date is needed in the filename, and
no `layout:` line is needed — `_config.yml` applies the `recipe` layout to
everything in the collection.

```markdown
---
title: Sourdough Focaccia
date: 2026-07-20
description: A one-line summary, used on the home page and for SEO.
image: /assets/images/focaccia.jpg   # optional
servings: 8
prep_time: 30 min
cook_time: 25 min
tags: [bread, baking]
ingredients:
  - 3¾ cups | strong white bread flour
  - 1½ cups | water, room temperature
method:
  - Mix the flour and water until no dry patches remain.
  - Cover and rest for 45 minutes.
---

Anything below the front matter is free-form Markdown and renders as a **Notes**
section at the bottom of the page — the story, substitutions, what went wrong.
```

Every field except `title` is optional; the layout omits any that are absent.
Individual `ingredients` and `method` entries may contain inline Markdown
(`**bold**`, links).

### The `|` in ingredients

A pipe splits an ingredient into **quantity** and **name**. The quantity gets its
own column, set bold in the accent colour with tabular figures, so amounts line
up into a rail you can scan mid-cook without reading the words.

```yaml
- 3¾ cups | strong white bread flour  # → "3¾ cups" in the rail, name alongside
- 2 cloves | garlic, thinly sliced
- A handful | chives, chopped         # works for loose amounts too
- Flaky salt, to finish               # no pipe → spans the full width
```

Keep the left side short — the column is about 5rem wide.

Measurements are imperial (cups, oz, tsp, tbsp), with loose amounts where a
precise one would read oddly: `2 cloves`, `½ lemon`, `A handful`, `4 slices`.

Use only the fractions `½`, `¼`, and `¾`. They live in Latin-1, which the
self-hosted font subsets cover; `⅓` and `⅔` sit outside the declared
`unicode-range` and would silently fall back to a system font mid-word.

### Images

The optional `image:` field is used in two places: as the hero on the recipe
page, and as a snapshot on the recipe's card on the home page. A recipe without
one still looks right — the card is simply blank ruling below the text, and
titles stay aligned across a row that mixes the two.

Put the web-ready file in `assets/images/` and reference it from the site root,
e.g. `/assets/images/focaccia.webp`.

Keep full-size originals in `assets/images/originals/`, which is gitignored and
excluded from the build. To make a web version from one:

```bash
cwebp -q 70 -resize 1400 0 -metadata none \
  assets/images/originals/My-Recipe.png -o assets/images/My-Recipe.webp
```

1400px covers the hero at 2x on the widest layout. It matters more than it
looks: the source PNGs are ~2.8 MB each, which would make the home page 5.6 MB;
as WebP they are ~230 KB and the page is 0.61 MB.

## Layout of the repo

| Path | Purpose |
|---|---|
| `index.html` | the home page |
| `_recipes/` | the content pages |
| `about.md` | a standalone page; add more via `header_pages` in `_config.yml` |
| `_layouts/default.html` | the HTML skeleton |
| `_layouts/home.html` | the recipe index |
| `_layouts/recipe.html` | the recipe page type |
| `_layouts/page.html` | plain pages like About |
| `_includes/recipe-card.html` | the index card on the home page |
| `_includes/illo.html` | the hand-drawn marks (`thyme`, `whisk`, `butter`, `wheat`, `bowl`, `spoon`) |
| `assets/main.scss` | the entire stylesheet |
| `assets/fonts/` | self-hosted Fraunces + Source Sans 3 |
| `_config.yml` | site metadata, collection config, colophon |

There is no theme gem — the layouts and CSS are self-contained, so nothing
overrides anything and every rule is in `assets/main.scss`.

## Design notes

Warm neutrals throughout, one burnt-orange accent, no stark white and no grey.
Colours are CSS custom properties at the top of `assets/main.scss`; changing
`--paper`, `--ink`, and `--accent` re-skins the whole site.

- **Type** — [Fraunces](https://fonts.google.com/specimen/Fraunces) for headings
  (its `SOFT` and `WONK` axes give the slightly-imperfect letterpress feel) and
  [Source Sans 3](https://fonts.google.com/specimen/Source+Sans+3) for body.
  Both are self-hosted variable fonts: no CDN request, no external dependency.
- **Illustrations** — hand-authored SVG paths in `_includes/illo.html`, drawn
  with deliberate irregularity. They carry a high `stroke-width` because a
  64-unit viewBox rendered at ~28px scales a thin stroke below one pixel and
  turns it into a smudge.
- **Light only** — the site is meant to look like paper, so there is no dark
  variant and `prefers-color-scheme` is not consulted. `:root` declares
  `color-scheme: light` so a visitor whose OS is dark still gets light
  scrollbars, form controls, and pre-paint canvas. Contrast is checked at
  WCAG AA; `--ink-faint` in particular is the darkest value that clears 4.5:1
  on both `--paper` and `--card`, since it is used on small text.
- **Print** — recipes print without nav, footer, or grain, with ingredients and
  method side by side and steps kept off page breaks.

To adjust the machine-written aside, edit `colophon.stamp` and `colophon.line`
in `_config.yml`.

## Deployment

Pushing to `main` triggers `.github/workflows/pages.yml`, which builds with the
same Jekyll version as local and publishes to GitHub Pages.

This requires **Settings → Pages → Source: GitHub Actions**. The older "Deploy
from a branch" option would ignore the `Gemfile` and build with GitHub's own
Jekyll 3.10 instead, producing a different site from the one tested locally.

Live at <https://thelatentlarder.com/>, a custom domain configured in
**Settings → Pages**. The site is served from the domain root, so `_config.yml`
sets an empty `baseurl` and the same paths work locally and in production.

### Gemfile.lock and CI

`Gemfile.lock` must list `x86_64-linux` (the CI runner) as well as the
`aarch64-linux` produced by an Apple Silicon container, or CI fails to install.
After changing dependencies:

```bash
docker compose run --rm site bundle lock --add-platform x86_64-linux
```
