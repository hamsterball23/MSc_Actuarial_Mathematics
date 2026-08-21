# Visual families

Across the whole MSc curriculum the visuals cluster into a handful of shapes.
Recognising which family a request belongs to settles most design questions
before any code is written.

The KU Actuarial Mathematics topics each family covers are listed so a request
phrased in course language maps quickly onto a build.

---

## 1. Path simulation

**Covers:** Brownian motion, Gaussian white noise, geometric Brownian motion,
Ornstein–Uhlenbeck, SDE solutions and their Euler–Maruyama discretisation,
jump diffusions (Merton, Bates), short-rate models (Vasicek, CIR, Hull–White),
total claim amount processes, Poisson and compound Poisson processes, ruin
processes, semi-Markov trajectories.

**Shape:** time on x, one or more realisations on y, usually with a
theoretical reference — a mean, a $\pm\sqrt{t}$ envelope, a stationary level,
a ruin barrier.

**Build notes.**
Simulate the whole ensemble once in `model.py` and store it wide (one column
per path plus a `t` column). Draw the ensemble faintly as static context, then
highlight two or three paths in `C.paths` colours — an individual trajectory is
legible, sixty are texture.

Animate along time with `Frame(targets=[...])` covering only the highlighted
paths and any moving cursor. Never animate the background.

For jump processes use `mode="lines"` with `line_shape="hv"` so jumps read as
discontinuities rather than steep ramps, and overlay jump times as markers in
`C.jump`.

For anything with a barrier — ruin, knock-out, first passage — draw the barrier
in `C.threshold` and colour the path segment after crossing in `C.tail`.

**Second panel, often.** The strongest visuals in this family pair the paths
with a derived quantity: running quadratic variation, running maximum, the
compensated martingale, the surplus process. The pairing is what turns a
picture of noise into an argument.

---

## 2. Distributional and statistical diagnostics

**Covers:** heavy-tailed claim severity distributions, maximum likelihood
surfaces, QQ-plots, mean excess plots, Hill plots, GEV and GPD fits, maximum
domains of attraction, Nelson–Aalen and Aalen–Johansen estimators, Kaplan–Meier
survival curves, copula dependence, elliptical distributions, extremal index
and extremogram.

**Shape:** empirical against theoretical. The claim is nearly always "the fit
is good here and breaks down there".

**Build notes.**
Plot the empirical object in `C.empirical` and the fitted or limiting object in
`C.theoretical`, always both. A fitted curve alone hides the residual
structure that is the actual content.

Confidence bands belong in a translucent fill of the same hue, not a separate
colour.

For QQ-plots draw the 45° line and let deviation speak; do not rescale axes to
flatter the fit.

Hill plots and mean excess plots are threshold-choice tools, so their whole
point is the region where the estimate stabilises. Shade the plausible
threshold window in `C.threshold` at low opacity and say in `notes.md` why that
window and not another.

Copulas want a two-panel layout: the copula scatter on the unit square beside
the same sample transformed back to the original margins. Dependence structure
and marginal shape look different, and separating them is the lesson.

**Animate** the parameter that controls tail behaviour — the shape parameter
$\xi$, the threshold $u$, the copula parameter — because the qualitative
regime change is what needs seeing.

---

## 3. Payoff, pricing and hedging structures

**Covers:** European and exotic option payoffs, Black–Scholes prices and
Greeks, implied and local volatility surfaces, the SVI parameterisation, delta
hedging and replication error, arbitrage bounds, complete versus incomplete
markets, unit-linked and with-profit contract payoffs.

**Shape:** payoff or price against underlying, or a surface over
(strike, maturity).

**Build notes.**
Always draw the payoff at maturity as a dashed reference in `C.theoretical`
alongside the price before maturity in `C.empirical`. The gap between them
*is* time value, and the picture should make that gap the visible object.

Mark the strike with a `C.threshold` vertical and label moneyness regions.

Surfaces: `go.Surface` with `C.surface`, but add contour projection onto the
base — a bare 3-D surface is impressive and hard to read numbers off. For
volatility surfaces put log-moneyness on one axis rather than raw strike, so
the smile is comparable across maturities.

Greeks work best as a small-multiple grid: delta, gamma, vega, theta over the
same underlying range, shared x-axis. Individually they are unremarkable;
together the relationships between them are the content.

Hedging visuals need a two-panel treatment: the hedged portfolio value against
the option value on top, the replication error below. Animate over rehedging
frequency to show the error shrinking — and where it stops shrinking.

---

## 4. Actuarial process and reserving structures

**Covers:** chain ladder and run-off triangles, development factors, reserving
alternatives, multivariate counting processes, multi-state Markov and
semi-Markov models, transition intensities, cash flow projections, prospective
reserves, surplus and dividend dynamics.

**Shape:** either a matrix (triangles), a graph (state models), or a projected
cash flow over time.

**Build notes.**
Run-off triangles are heatmaps with a hard visual break between observed and
projected cells — different opacity or an outline on the observed region, never
a different colourscale, since the values are comparable. Annotate cells with
values; the numbers matter here in a way they do not in a density plot.

Pair the triangle with a reserve-by-origin-year bar chart. The triangle shows
the method, the bars show the answer.

Multi-state models are node-and-edge diagrams. Plotly does these adequately
with `go.Scatter` markers plus annotation arrows, and it keeps the visual in
the same harness as everything else. Label edges with transition intensities
and size nodes by occupancy probability. Animate occupancy over age or time.

Cash flow projections are stacked areas: premiums, benefits, expenses, with
the net line drawn on top in `C.drift`.

---

## 5. Risk measures and tail quantities

**Covers:** Value-at-Risk, expected shortfall, coherence properties and
subadditivity failures, credit and operational risk loss distributions, large
deviation rate functions, Cramér's theorem, ruin probability asymptotics,
importance sampling efficiency.

**Shape:** a loss distribution with a region of it singled out.

**Build notes.**
The canonical figure: density in `C.body`, the tail beyond the quantile filled
in `C.tail`, a `C.threshold` vertical at VaR$_\alpha$, and expected shortfall
marked as the conditional mean of the shaded region. Showing both on one axis
makes the difference between them obvious in a way two separate plots never do.

Animate over $\alpha$. Watching ES pull away from VaR as $\alpha \to 1$ is the
single most useful thing this family does.

Subadditivity failure needs three panels — the two marginal losses and the
combined portfolio — with VaR marked on each, so the violation is arithmetic
the viewer can check rather than a claim.

Large deviation visuals pair the empirical log-probability decay against the
rate function $I(x)$. Use a log scale on probability, plot $-\frac{1}{n}\log P$
against the theoretical $I$, and animate over $n$ to show convergence.

---

## Choosing the panel layout

| Situation | Layout |
|---|---|
| One object, one claim | single panel |
| A process and a derived quantity | two rows, shared x-axis |
| Empirical vs theoretical | one panel, both curves |
| Several parameters, same structure | small-multiple grid, shared axes |
| Method and its output | two panels side by side |

Shared axes are worth insisting on. Small multiples with independent scales
invite exactly the wrong comparison.

---

## When not to animate

Animation costs file size, render time, and reader attention. It earns its
place when a swept parameter changes something qualitative — a regime change, a
convergence, a crossing. It does not earn its place for a progressive reveal of
a curve that is perfectly legible drawn all at once.

If in doubt, build the static version first and add frames only if the still
figure leaves the claim unmade.
