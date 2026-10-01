## What this shows

A single ensemble of $P$-Brownian paths $B$, turned into $X_t = B_t + ct$ (a
Brownian motion with drift $c$ under $P$), together with the exponential
martingale $D_t$ that reweights this ensemble into one where $X$ is
*driftless*. Top panel: the drifted paths. Middle panel: $D_t$ for the same
highlighted paths. Bottom panel: the unweighted (P) and $D$-weighted (Q)
empirical mean of $X_t$, over the whole time axis.

## The maths

Let $B$ be a real $(\mathcal{F}_t)$-Brownian motion under $P$, and fix
$c \in \mathbb{R}$. Set $L_t = -cB_t$, a continuous local martingale with
$\langle L,L\rangle_t = c^2 t$, and let

$$
D_t = \mathcal{E}(L)_t = \exp\Big(-cB_t - \tfrac12 c^2 t\Big).
$$

By Proposition 5.11, $D$ is a nonnegative continuous local martingale with
$D_0 = 1$ and $E_P[D_t] = 1$ for all $t$ (it is in fact a true martingale
here, since $B$ is bounded on compacts and $D$ has finite exponential
moments). It is the density process of some $Q \ll P$ on $\mathcal{F}_t$ for
every finite $t$. Girsanov's theorem (Theorem 5.22) then says that

$$
\tilde B_t = B_t - \langle B, L\rangle_t = B_t + ct = X_t
$$

is a continuous local martingale under $Q$ with $\langle X,X\rangle_t = t$,
hence a $Q$-Brownian motion by Lévy's characterisation (Theorem 5.12). So the
same process that has drift $c$ under $P$ is driftless under $Q$: the drift
has not been removed from any single path (a path is just a fixed function
of $\omega$), it has been removed from the *law*, by changing which paths
carry the probability mass.

Concretely, for any bounded functional $\Phi$ of the path up to time $t$,

$$
E_Q[\Phi(X)] = E_P[\Phi(X)\, D_t].
$$

The bottom panel estimates both sides directly: $E_P[X_t]$ is the plain
Monte Carlo mean over the $P$-sample, and $E_Q[X_t]$ is the same sample
reweighted by $D_t^{(i)}$ (importance sampling, using the terminal weight
$D_T$ since $D$ is a martingale and $X_t$ is $\mathcal{F}_t$-measurable for
$t \le T$).

## What to notice

- No path in the top panel is special -- every single one really does drift
  upward like a $P$-Brownian motion with drift $c$ should. Girsanov does not
  edit the paths; it edits the measure that puts weight on them.
- The highlighted paths in the top two panels are chosen as the ones with the
  *largest* terminal weight $D_T$ -- and they are visibly the paths that drift
  the least. $D_t$ is large precisely where $B_t$ is very negative, i.e.
  where $X_t = B_t + ct$ undershoots the drift. Reweighting by $D$ therefore
  systematically favours the paths that look driftless and penalises the
  ones that drifted with the crowd.
- $D_t$ itself is a $P$-martingale with mean 1 at every $t$ (middle panel,
  dashed line) -- it has no drift on average, it only redistributes mass
  across paths.
- The bottom panel is the payoff: the unweighted empirical mean of $X_t$
  tracks $ct$ (as it must, since $B$ really is drifted under $P$), while the
  $D$-weighted mean sits flat at 0 across the whole interval, matching the
  theorem's claim that $X$ is a *driftless* $Q$-Brownian motion.
- The $\pm 1$ empirical-sd bands widen like $\sqrt{t}$ in both panels, exactly
  as for ordinary Brownian motion -- changing the drift under Girsanov leaves
  the quadratic variation, hence the diffusive spread, untouched. Girsanov
  changes drift, never volatility.

## Why it matters downstream

This is the mechanism behind every change-of-measure argument in
mathematical finance: moving from the physical measure $P$ to a
risk-neutral (or forward, or $T$-forward) measure $Q$ is exactly this
construction, with $c$ playing the role of a market price of risk. Corollary
5.24 (Cameron--Martin) and the SDE-construction proposition in this chapter
(Section 5.6) are the same identity with $c$ replaced by a path-dependent
drift $b(t,X_t)$. The Black--Scholes risk-neutral measure, the forward
measure in interest-rate models, and Esscher-type tilts of claim severity
distributions in insurance are all instances of reweighting an ensemble by an
exponential martingale to relocate its drift.

## Assumptions and limits

- The weights are estimated from a finite Monte Carlo sample ($n$ paths
  given in the corner annotation), so the bottom panel's $Q$-mean is an
  estimate, not an exact 0 -- it has its own Monte Carlo error, visible as
  small wobble rather than a perfectly flat line.
- Novikov's criterion (Theorem 5.23) is needed in general to guarantee that
  $D$ is a *true* martingale (so that $E_Q$ is a genuine probability
  measure) rather than merely a supermartingale. For this particular $L$ it
  holds trivially since $E_P[\exp(\frac12\langle L,L\rangle_\infty)]$ would
  need $\langle L,L\rangle_\infty < \infty$; here we only ever use $D$ on the
  finite window $[0,T]$, where the criterion is immediate.
- Importance weights with large variance (heavy right tail of $D_T$) make
  the weighted mean noisy for larger $|c|$ or longer horizons $T$ -- a few
  paths can dominate the sum. This is the same effective-sample-size issue
  that shows up in any importance-sampling estimator, not a defect of
  Girsanov's theorem itself.
