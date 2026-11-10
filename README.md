# proximity.guru

Public website for Proximity Software Factory LLC. Plain HTML and CSS, no build step.

| File | Purpose |
|---|---|
| `index.html` | Home page |
| `privacy.html` | Privacy policy (linked from App Store listings) |
| `support.html` | Support page (linked from App Store listings) |
| `404.html` | Not-found page served by GitHub Pages |
| `styles.css` | All styles |
| `assets/` | Logo mark and lockup |
| `CNAME` | Custom domain for GitHub Pages |

## Editing

Edit the HTML directly and open it in a browser. The header and footer blocks are
identical on all four pages and the checks fail when they drift. Copy on the home
page follows `STYLE.md` in `~/git/ai-agents` (third person, present tense, no filler);
extract the prose and run that repo's `tests/style_lint.py` on it after a copy change.
When an app ships, add it to the Apps section of `index.html` with its App Store link,
and update the date at the top of `privacy.html` if the policy changed.

Facts on the home page come from the capability statement and executive summary in
the company documents folder, which is not in the repo. Do not add hardware, model
names, internal system names, revenue figures, or a street address.

## Checks

```sh
bats tests/site.bats
```

Verifies pages, links, anchors, identical header and footer and nav across pages,
metadata and Open Graph tags, JSON-LD, the diagram's text alternative, no third-party
resources, and that no barred internal term appears on any page.

## Hosting

Served by GitHub Pages from the `main` branch root. The `CNAME` file pins the
custom domain; DNS at GoDaddy points `proximity.guru` at GitHub Pages.
