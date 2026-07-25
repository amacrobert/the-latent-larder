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

Then open **<http://localhost:4000/the-latent-larder/>**.

Note the `/the-latent-larder/` path — the site sets a `baseurl` because it is
published to a project page rather than a domain root, and `jekyll serve`
honours it. The bare `http://localhost:4000/` will 404.

Edits to any file trigger a rebuild and a browser reload. Press `Ctrl-C` to stop,
or `docker compose down` to remove the container.

To build once without serving:

```bash
docker compose run --rm site bundle exec jekyll build
```

## Adding a recipe

Create `_recipes/my-recipe.md`. The filename becomes the URL:
`/the-latent-larder/recipes/my-recipe/`. No date is needed in the filename, and
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
  - 500g strong white bread flour
  - 375g water, room temperature
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

Images go in `assets/images/` and are referenced from the project root, e.g.
`/assets/images/focaccia.jpg` — the layouts add the `baseurl` prefix.

## Layout of the repo

| Path | Purpose |
|---|---|
| `index.html` | the home page |
| `_recipes/` | the content pages |
| `about.md` | a standalone page; add more via `header_pages` in `_config.yml` |
| `_layouts/home.html` | overrides minima's home layout to list recipes |
| `_layouts/recipe.html` | the recipe page type |
| `_includes/recipe-card.html` | recipe card used by the home listing |
| `assets/main.scss` | imports the minima theme and adds recipe styles |
| `_config.yml` | site metadata, `baseurl`, collection config |

Anything not overridden here comes from the
[minima](https://github.com/jekyll/minima) theme gem.

## Deployment

Pushing to `main` triggers `.github/workflows/pages.yml`, which builds with the
same Jekyll version as local and publishes to GitHub Pages.

This requires **Settings → Pages → Source: GitHub Actions**. The older "Deploy
from a branch" option would ignore the `Gemfile` and build with GitHub's own
Jekyll 3.10 instead, producing a different site from the one tested locally.

Live at <https://amacrobert.github.io/the-latent-larder/>.

### Gemfile.lock and CI

`Gemfile.lock` must list `x86_64-linux` (the CI runner) as well as the
`aarch64-linux` produced by an Apple Silicon container, or CI fails to install.
After changing dependencies:

```bash
docker compose run --rm site bundle lock --add-platform x86_64-linux
```
