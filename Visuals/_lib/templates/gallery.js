/* gallery.js -- filter + render the visual index. Pure vanilla, no build step. */
(function () {
  "use strict";

  var active = { courses: new Set(), topics: new Set() };
  var grid = document.getElementById("grid");
  var empty = document.getElementById("empty");
  var count = document.getElementById("count");
  var q = document.getElementById("q");

  function uniq(key) {
    var s = new Set();
    MANIFEST.forEach(function (v) { (v[key] || []).forEach(function (x) { s.add(x); }); });
    return Array.from(s).sort();
  }

  function buildFilters(elId, key, label) {
    var el = document.getElementById(elId);
    var vals = uniq(key);
    if (!vals.length) { el.style.display = "none"; return; }
    el.innerHTML = '<span class="lbl">' + label + "</span>" +
      vals.map(function (v) {
        return '<span class="tag" data-k="' + key + '" data-v="' + esc(v) + '">' + esc(v) + "</span>";
      }).join("");
    el.querySelectorAll(".tag").forEach(function (t) {
      t.addEventListener("click", function () {
        var set = active[key], v = t.dataset.v;
        if (set.has(v)) { set.delete(v); t.classList.remove("on"); }
        else { set.add(v); t.classList.add("on"); }
        render();
      });
    });
  }

  function matches(v) {
    if (active.courses.size &&
        !(v.courses || []).some(function (c) { return active.courses.has(c); })) return false;
    if (active.topics.size &&
        !(v.topics || []).some(function (t) { return active.topics.has(t); })) return false;
    var term = (q.value || "").trim().toLowerCase();
    if (!term) return true;
    return (v.haystack || "").indexOf(term) !== -1;
  }

  function card(v) {
    var thumb = v.has_png
      ? '<div class="thumb"><img loading="lazy" src="../' + esc(v.dir) + '/out/thumb.png" alt=""></div>'
      : '<div class="thumb"><div class="ph">' + esc(v.title) + "</div></div>";
    var pills = (v.courses || []).map(function (c) {
      return '<span class="pill">' + esc(c) + "</span>";
    }).concat((v.topics || []).slice(0, 3).map(function (t) {
      return '<span class="pill t">' + esc(t) + "</span>";
    }));
    if (v.has_mp4) pills.push('<span class="pill f">mp4</span>');
    return '<article class="card"><a href="../' + esc(v.dir) + '/out/index.html">' +
      thumb + '<div class="body"><h3>' + esc(v.title) + "</h3>" +
      "<p>" + esc(v.summary || "") + "</p>" +
      '<div class="meta">' + pills.join("") + "</div></div></a></article>";
  }

  function render() {
    var shown = MANIFEST.filter(matches);
    grid.innerHTML = shown.map(card).join("");
    empty.style.display = shown.length ? "none" : "block";
    count.textContent = shown.length + " of " + MANIFEST.length + " visuals";
  }

  function esc(s) {
    return String(s == null ? "" : s).replace(/[&<>"]/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c];
    });
  }

  buildFilters("f-courses", "courses", "Course");
  buildFilters("f-topics", "topics", "Topic");
  q.addEventListener("input", render);
  render();
})();
