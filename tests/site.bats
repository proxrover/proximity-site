#!/usr/bin/env bats
# Static checks for the proximity.guru site.

PAGES="index.html privacy.html support.html 404.html"

setup() {
  SITE="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$SITE"
}

@test "all pages and assets exist" {
  for f in $PAGES styles.css CNAME .nojekyll assets/proximity-mark.png assets/proximity-lockup.jpg; do
    [ -f "$f" ]
  done
}

@test "CNAME is the production domain" {
  [ "$(cat CNAME)" = "proximity.guru" ]
}

@test "every local href and src resolves to a file" {
  missing=""
  for page in $PAGES; do
    refs=$(grep -oE '(href|src)="[^"]+"' "$page" | sed -E 's/^(href|src)="//; s/"$//' \
      | grep -vE '^(https?:|mailto:|#)' || true)
    for ref in $refs; do
      path="${ref%%#*}"
      path="${path#/}"
      [ -z "$path" ] && path="index.html"
      [ -f "$path" ] || missing="$missing $page->$ref"
    done
  done
  [ -z "$missing" ] || { echo "missing:$missing"; false; }
}

@test "home page sections exist with the anchors the nav uses" {
  for id in work build engagement team apps contact; do
    grep -q "<section id=\"$id\"" index.html
  done
}

@test "primary nav is identical on every page and points at existing anchors" {
  nav_of() { sed -n '/<nav aria-label="Primary">/,/<\/nav>/p' "$1" | sed 's/^[[:space:]]*//'; }
  ref="$(nav_of index.html)"
  [ -n "$ref" ]
  for page in $PAGES; do
    [ "$(nav_of "$page")" = "$ref" ] || { echo "nav differs in $page"; false; }
  done
  for label in Work Process Team Apps Contact; do
    echo "$ref" | grep -q ">$label<"
  done
  echo "$ref" | grep -oE 'href="/#[a-z]+"' | sed -E 's/href="\/#//; s/"//' | while read -r id; do
    grep -q "<section id=\"$id\"" index.html || { echo "nav anchor #$id has no section"; return 1; }
  done
}

@test "header and footer markup is identical on every page" {
  block() { sed -n "/<$2 class=\"site-$2\">/,/<\/$2>/p" "$1" | sed 's/^[[:space:]]*//'; }
  for kind in header footer; do
    ref="$(block index.html $kind)"
    [ -n "$ref" ]
    for page in $PAGES; do
      [ "$(block "$page" $kind)" = "$ref" ] || { echo "$kind differs in $page"; false; }
    done
  done
}

@test "the pipeline section has the diagram with a text alternative and six stages" {
  grep -q '<svg[^>]*role="img"[^>]*aria-labelledby="diagram-title diagram-desc"' index.html
  grep -q '<title id="diagram-title">' index.html
  grep -q '<desc id="diagram-desc">' index.html
  [ "$(grep -c '<g class="d-stage">' index.html)" -eq 6 ]
  [ "$(sed -n '/<ol class="stages">/,/<\/ol>/p' index.html | grep -c '<h3>')" -eq 6 ]
}

@test "the engagement section lists scope, build, validate, hand over in order" {
  seq=$(sed -n '/<ol class="steps">/,/<\/ol>/p' index.html | grep -oE '<h3>[^<]+</h3>' | sed -E 's/<\/?h3>//g' | tr '\n' '|')
  [ "$seq" = "Scope|Build|Validate|Hand over|" ]
}

@test "the demo hint line is gone" {
  ! grep -qi 'move your cursor' index.html
}

@test "contact addresses are present where they should be" {
  grep -q 'mailto:info@proximity.guru' index.html
  grep -q 'mailto:support@proximity.guru' support.html
  grep -q 'mailto:support@proximity.guru' privacy.html
  grep -q 'business days' index.html
}

@test "legal name appears on every page" {
  for page in $PAGES; do
    grep -q 'Proximity Software Factory LLC' "$page"
  done
}

@test "pages declare language, viewport, title, description, canonical, and Open Graph tags" {
  for page in $PAGES; do
    grep -q '<html lang="en">' "$page"
    grep -q 'name="viewport"' "$page"
    grep -q '<title>' "$page"
    grep -q 'name="description"' "$page"
    grep -q 'rel="canonical"' "$page"
    for prop in og:title og:description og:image og:url og:type; do
      grep -q "property=\"$prop\"" "$page" || { echo "$page lacks $prop"; false; }
    done
  done
}

@test "home page carries JSON-LD Organization data that parses" {
  python3 - <<'PY'
import re, json, sys
html = open("index.html").read()
m = re.search(r'<script type="application/ld\+json">(.*?)</script>', html, re.S)
assert m, "no JSON-LD block"
d = json.loads(m.group(1))
assert d["@type"] == "Organization", d
assert d["legalName"] == "Proximity Software Factory LLC"
assert d["address"]["addressLocality"] == "Spokane"
assert d["url"] == "https://proximity.guru/"
PY
}

@test "no third-party scripts, stylesheets, or fonts are loaded" {
  for page in $PAGES; do
    ! grep -qE '<script[^>]+src=' "$page"
    ! grep -E '<link[^>]+rel="stylesheet"' "$page" | grep -qE 'href="https?://'
    ! grep -qiE 'fonts\.googleapis|fonts\.gstatic|cdn\.|analytics|gtag|plausible' "$page"
  done
  ! grep -qiE '@import|url\(https?:' styles.css
}

@test "barred internal terms appear on no page" {
  # hardware inventory, models under evaluation, internal system and product names,
  # revenue figures, the private address, and the non-public location
  barred='kitsap|thornwood|watson|gpt-oss|nemotron|nvidia|rtx|macbook|mac studio|mac mini|unified memory|delphi|paper street|\bDIA\b|revenue|subscriber|\$[0-9]|gun tracker|immigration|reproductive|mormon|high-control|minio|cloudflare'
  for page in $PAGES; do
    if grep -qiE "$barred" "$page"; then
      grep -niE "$barred" "$page"
      false
    fi
  done
}

@test "reduced-motion handling and focus styles are present" {
  grep -q 'prefers-reduced-motion: reduce' index.html
  grep -q 'prefers-reduced-motion' styles.css
  grep -q 'focus-visible' styles.css
}

@test "location is Silverdale on every page and the mailing address is on the home page" {
  for page in index.html privacy.html support.html 404.html; do
    grep -q 'Silverdale, Washington' "$page"
  done
  grep -q '522 W Riverside Ave Ste N' index.html
  grep -q '99201-0581' index.html
}

@test "company documents folder is ignored by git" {
  grep -q '^proximitysoftwarefactoryllc/$' .gitignore
}
