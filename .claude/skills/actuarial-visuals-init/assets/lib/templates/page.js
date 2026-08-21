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
  var notes = document.getElementById("notes");
  if (notes && NOTES && window.marked) {
    marked.setOptions({ mangle: false, headerIds: false });
    notes.innerHTML = marked.parse(NOTES);
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

  function esc(s) {
    return String(s).replace(/[&<>"]/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c];
    });
  }
})();
