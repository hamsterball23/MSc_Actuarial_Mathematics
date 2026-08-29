# Modes of convergence of stochastic sequences

## What this shows

Three classic, minimal constructions, animated on one shared step slider, each
built to isolate exactly one mode of convergence and to show why the others
fail for it:

1. **Almost sure convergence.** $X_n = \frac{1}{n}\sum_{i=1}^n U_i$ for iid
   $U_i \sim \mathrm{Unif}(0,1)$. The strong law of large numbers gives
   $X_n \to 1/2$ *for almost every* $\omega$ — watch six individual sample
   paths, each one a fixed $\omega$, settle at the limit.
2. **Convergence in probability, but not almost surely** — the "typewriter"
   (moving block) sequence. Fix one outcome $\omega = U$. Enumerate
   $n = 1, 2, 3, \dots$ by sweeping through blocks $k = 0, 1, 2, \dots$; block
   $k$ has $2^k$ disjoint intervals $I_{k,j} = [j/2^k, (j+1)/2^k)$ partitioning
   $[0,1]$. Set $Y_n = \mathbf 1\{\omega \in I_n\}$.
3. **Convergence in distribution.** $S_n = \sum_{i=1}^n U_i$,
   $Z_n = \dfrac{S_n - n/2}{\sqrt{n/12}}$. The central limit theorem gives
   $Z_n \xrightarrow{d} N(0,1)$: the *histogram* of $Z_n$ over many independent
   replications locks onto the standard normal density as $n$ grows.

## The maths

**Definitions**, for random variables $X_n, X$ on a common probability space
(distributional convergence needs no common space, but it is convenient here):

$$
X_n \xrightarrow{\text{a.s.}} X \iff \mathbb P\Big(\lim_{n\to\infty} X_n = X\Big) = 1
$$

$$
X_n \xrightarrow{P} X \iff \forall \varepsilon>0,\ \ \mathbb P(|X_n - X| > \varepsilon) \to 0
$$

$$
X_n \xrightarrow{d} X \iff \mathbb E[f(X_n)] \to \mathbb E[f(X)] \ \text{ for all bounded continuous } f
$$

**Implications:** a.s. $\Rightarrow$ in probability $\Rightarrow$ in
distribution. None reverses in general; the typewriter sequence is the
standard counterexample to the first reversal, and $Z_n$ in row 4 is a
standard example where convergence in distribution holds while the notion of
"the same $\omega$ converging" does not even apply cleanly (the $Z_n$ here are
built from independent Monte-Carlo draws at each $n$, not one running path).

**The typewriter sequence, worked out.** For the fixed $\omega$, block $k$
contributes *exactly one* $n$ with $Y_n(\omega) = 1$ (the one sub-interval of
$[0,1]$ that contains $\omega$), so
$$
\mathbb P(Y_n = 1) = 2^{-k(n)} \longrightarrow 0 \quad\Rightarrow\quad Y_n \xrightarrow{P} 0,
$$
where $k(n) = \lfloor \log_2(n+1) \rfloor$. But for *every* $\omega$, this
means $Y_n(\omega) = 1$ infinitely often — the gaps between hits merely grow
geometrically ($2^k$ steps between the hit in block $k$ and the hit in block
$k+1$). So $\limsup_n Y_n(\omega) = 1 \neq 0 = \liminf_n Y_n(\omega)$ for every
$\omega$: $Y_n$ converges nowhere pointwise, hence not almost surely, even
though it converges to $0$ in probability.

## What to notice

- **Row 1** — every highlighted path is one fixed $\omega$, followed across
  $n$. All of them visibly home in on $1/2$: that pathwise settling, for
  (almost) every $\omega$ simultaneously, is what "almost sure" means.
- **Row 2–3** — the interval $I_n$ (row 2) shrinks and wanders, and only
  occasionally still contains $\omega$; the spike train $Y_n(\omega)$ (row 3)
  shows those hits directly. On the log-$n$ axis the hits look roughly evenly
  spaced — that regularity *is* the geometric gap structure, and it is the
  visual proof that hits never actually stop, just as $P(Y_n=1)$ keeps
  halving.
- **Row 4** — no single path is drawn at all; only aggregate histograms over
  20,000 independent replications per $n$. That is the content of the
  definition: convergence in distribution is a statement about laws, not
  about any specific $\omega$. Watch the empirical histogram tighten onto the
  $N(0,1)$ curve, with the visible skew of $\mathrm{Unif}(0,1)$ sums (heavier
  one side at small $n$) washing out by $n \approx 30$–$50$.

## Why it matters downstream

The strict ordering a.s. $\Rightarrow$ P $\Rightarrow$ d is exactly what
licenses swapping between limit theorems in practice: an a.s. SLLN result can
always be weakened to a WLLN-style "in probability" statement, and any
in-probability result can always be weakened to a distributional (CLT-style)
one, but never the other way without extra structure (e.g. Skorokhod's
representation theorem, or uniform integrability for moment convergence). The
typewriter counterexample is the standard one cited whenever someone asks "can
I upgrade convergence in probability to almost sure convergence?" — the answer
is: not in general, but a subsequence always can (a fact provable directly
from this construction by thinning out the blocks).

## Assumptions and limits

- Rows 2–3 fix a *single* $\omega = 0.37$; the picture of "convergence in
  probability" is a property of the whole sequence of laws
  $\mathcal L(Y_n)$, not of this one path — the point of the example is
  precisely that the single path looks nothing like convergence.
- Row 4's $Z_n$ at different $n$ are *independent Monte Carlo batches*, not a
  running process — there is no meaningful "path" of $Z_n$ to draw, which is
  itself part of the lesson: distributional convergence does not presuppose a
  coupling between the $X_n$.
- The CLT histogram uses 20,000 replications per $n$ purely for a smooth
  display; the theoretical convergence rate is the Berry–Esseen bound
  $O(1/\sqrt n)$ in Kolmogorov distance, not visible directly from the
  histogram bin width chosen here.
