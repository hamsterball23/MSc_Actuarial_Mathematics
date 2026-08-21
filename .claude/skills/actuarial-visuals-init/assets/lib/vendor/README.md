# vendor/

Third-party JS and CSS, downloaded here so the gallery works offline and
does not depend on a CDN still existing in a few years.

Populate it with:

    python _lib/viz.py vendor

Until then, pages fall back to CDN links, which means they need an internet
connection to render. Everything else works either way.

Files fetched: plotly.min.js, marked.min.js, katex.min.js, katex.min.css,
katex-auto-render.min.js.
