/* page.js -- renders notes.md (with maths) and the parameter strip. */
(function () {
  "use strict";

  // ---- parameter chips ---------------------------------------------------
  var box = document.getElementById("params");
  if (box && META) {
    var chips = [];
    (META.courses || []).forEach(function (c) {
      chips.push('<span class="chip"><b>' + esc(c) + "</b></span>");
    });
    var p = META.params || {};
    Object.keys(p).forEach(function (k) {
      chips.push('<span class="chip">' + esc(k) + " = <b>" + esc(p[k]) + "</b></span>");
    });
    if (META.seed !== undefined && META.seed !== null) {
      chips.push('<span class="chip">seed = <b>' + esc(META.seed) + "</b></span>");
    }
    if (META.source) {
      chips.push('<span class="chip">' + esc(META.source) + "</span>");
    }
    if (chips.length) box.innerHTML = '<div class="row">' + chips.join("") + "</div>";
  }

  // ---- notes -------------------------------------------------------------
  // Math is stashed behind placeholders before Markdown runs, and restored
  // verbatim afterwards. Without this, marked's underscore-emphasis rule
  // mangles any $...$ span with more than one underscore in it (t_k, t_{k+1},
  // \mathbf{1}_{A_1} ...) -- extremely common in this domain's notation --
  // before KaTeX ever sees the source.
  var notes = document.getElementById("notes");
  if (notes && NOTES && window.marked) {
    marked.setOptions({ mangle: false, headerIds: false });
    var stashed = stashMath(NOTES);
    var html = marked.parse(stashed.text);
    stashed.store.forEach(function (math, i) {
      html = html.split(mathToken(i)).join(math);
    });
    notes.innerHTML = html;
  }

  // ---- maths -------------------------------------------------------------
  if (window.renderMathInElement) {
    renderMathInElement(document.body, {
      delimiters: [
        { left: "$$", right: "$$", display: true },
        { left: "\\[", right: "\\]", display: true },
        { left: "$", right: "$", display: false },
        { left: "\\(", right: "\\)", display: false }
      ],
      throwOnError: false,
      ignoredTags: ["script", "noscript", "style", "textarea", "pre", "code"]
    });
  }

  // ---- downloads ---------------------------------------------------------
  var dl = document.getElementById("downloads");
  if (dl) {
    var links = [];
    (META.formats || []).forEach(function (f) {
      if (f === "png") links.push('<a href="thumb.png" download>PNG</a>');
      if (f === "mp4") links.push('<a href="clip.mp4" download>MP4</a>');
    });
    links.push('<a href="../notes.md">notes.md</a>');
    links.push('<a href="../scene.py">scene.py</a>');
    dl.innerHTML = links.join("");
  }

  function mathToken(i) {
    // Wrapped in private-use-area code points so the token can never
    // collide with real notes text or be reinterpreted by marked; it
    // survives marked.parse as an opaque, un-mangled text run.
    return "MATH" + i + "";
  }

  // Pull every $$...$$, \[...\], $...$ and \(...\) span out of the source,
  // replacing each with an opaque token, so Markdown's emphasis/underscore
  // handling never sees the raw LaTeX. Display forms are matched first and
  // may span blank lines; inline forms stop at a blank line (a paragraph
  // break), matching how KaTeX's own auto-render delimiters behave.
  function stashMath(src) {
    var store = [];
    function take(match) {
      store.push(match);
      return mathToken(store.length - 1);
    }
    var out = src
      .replace(/\$\$[\s\S]+?\$\$/g, take)
      .replace(/\\\[[\s\S]+?\\\]/g, take)
      .replace(/\\\((?:[^\n]|\n(?!\n))+?\\\)/g, take)
      .replace(/\$(?:[^$\n]|\n(?!\n))+?\$/g, take);
    return { text: out, store: store };
  }

  function esc(s) {
    return String(s).replace(/[&<>"]/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c];
    });
  }
})();
