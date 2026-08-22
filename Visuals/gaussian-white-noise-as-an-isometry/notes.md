## In plain terms

Gaussian white noise $W$ is a machine that hands a random number $W(A)$ to every
subset $A \subset E$, with two rules:

- $W(A) \sim \mathcal{N}(0, \mu(A))$ — mean zero, variance equal to the "weighted
  length" of $A$.
- $\operatorname{Cov}(W(A), W(B)) = \mu(A \cap B)$ — two sets' noise values are
  correlated exactly in proportion to how much they *overlap*.

That's the whole object. The two panels make each rule visible:

- **Left panel — splitting a set doesn't change its total variance.** Cut a fixed
  interval $A$ into $A_1$ and $A_2$ at a point $c$ and drag $c$. The variances of
  $W(A_1)$ and $W(A_2)$ (solid curves) reshuffle — one grows, the other shrinks — but
  the variance of $W(A)$ (dashed curve) never moves. $A_1, A_2$ are disjoint, hence
  independent, and variances of independent things add:
  $\operatorname{Var}(W(A_1)) + \operatorname{Var}(W(A_2)) = \mu(A_1) + \mu(A_2) =
  \mu(A)$. Slicing a set doesn't create or destroy randomness, it only decides how a
  fixed pool of variance is split into two independent pieces.
- **Right panel — overlap = correlation, literally.** Fix $A$ and slide a same-width
  window $B$ across $E$; the ellipse is the joint law of $(W(A), W(B))$. Far apart
  (disjoint), the ellipse is round: uncorrelated, independent, $\mu(A \cap B) = 0$. As
  $B$ slides toward $A$ it tilts and thins, and when $B = A$ exactly it collapses onto
  the diagonal — perfect correlation, because at that point $W(A)$ and $W(B)$ are
  literally the same random variable, not just "very correlated."

The word "isometry" in the title is just the dictionary between the two panels: set
overlap on the left *is* covariance on the right, with no translation needed — a map
that turns lengths into variances and angles into correlation.

## What this shows

Let $(E, \mathcal{E}, \mu)$ be a measure space with $\mu$ $\sigma$-finite. **Gaussian
white noise with intensity $\mu$** is a centred Gaussian family
$\{W(A) : A \in \mathcal{E}, \mu(A) < \infty\}$ with

$$
\operatorname{Cov}\bigl(W(A), W(B)\bigr) = \mu(A \cap B), \qquad A, B \in \mathcal{E}.
$$

Equivalently (Le Gall's route): $W$ is a centred Gaussian process indexed by
$L^2(E,\mu)$ via $W(A) := W(\mathbf{1}_A)$, and the map
$\mathbf{1}_A \mapsto W(A)$ extends to an **isometry**

$$
L^2(E,\mu) \longrightarrow L^2(\Omega), \qquad
\mathbb{E}\bigl[W(f)\, W(g)\bigr] = \langle f, g\rangle_{L^2(\mu)} = \int_E f g \, d\mu .
$$

Taking $f = \mathbf{1}_A$, $g = \mathbf{1}_B$ recovers
$\mathbb{E}[W(A)W(B)] = \mu(A\cap B)$, and taking $A=B$ gives
$W(A) \sim \mathcal{N}(0, \mu(A))$.

The base space here is $E = [0, 16]$ with intensity $\mu(dx) = \lambda(x)\,dx$,
$\lambda(x) = 1 + 0.15x$ (drawn as the grey density curve) — deliberately not flat,
so $\mu(A)$ reads as "area under $\lambda$ over $A$", not "length of $A$".

- **Left column.** $A = A_1 \cup A_2$, a fixed interval cut at a moving point $c$.
  The bottom pdfs are $W(A_1) \sim \mathcal{N}(0,\mu(A_1))$ and
  $W(A_2)\sim\mathcal{N}(0,\mu(A_2))$; the dashed curve is $W(A) \sim \mathcal{N}(0,\mu(A))$,
  fixed regardless of $c$.
- **Right column.** $A$ is fixed; $B$ is a same-width interval sliding across $E$.
  The bottom-right ellipse is the joint law of $(W(A), W(B))$, with covariance
  matrix $\begin{pmatrix}\mu(A) & \mu(A\cap B) \\ \mu(A\cap B) & \mu(B)\end{pmatrix}$.

## The maths

**Independent scattering.** If $A_1, \dots, A_n \in \mathcal{E}$ are pairwise disjoint,
$W(A_1), \dots, W(A_n)$ are independent, and

$$
W\Bigl(\bigcup_{i=1}^n A_i\Bigr) = \sum_{i=1}^n W(A_i) \quad \text{a.s.}
$$

This is $\sigma$-additivity carried by the isometry: for disjoint $A_1,A_2$,
$\langle \mathbf{1}_{A_1}, \mathbf{1}_{A_2}\rangle_{L^2(\mu)} = 0$, so
$\operatorname{Cov}(W(A_1),W(A_2)) = \mu(A_1\cap A_2) = 0$ — independence, since jointly
Gaussian and uncorrelated coincide. Variance then adds because
$\mathbf{1}_{A_1\cup A_2} = \mathbf{1}_{A_1} + \mathbf{1}_{A_2}$ is linear in $L^2(\mu)$:

$$
\operatorname{Var}\bigl(W(A_1) + W(A_2)\bigr)
= \mu(A_1) + \mu(A_2) + 2\mu(A_1\cap A_2) = \mu(A_1) + \mu(A_2) = \mu(A_1 \cup A_2).
$$

**The isometry.** For $f, g \in L^2(E,\mu)$ (simple functions first, then extended by
$L^2$-continuity), $W(f) := \sum_i a_i W(A_i)$ for $f = \sum_i a_i \mathbf{1}_{A_i}$, and

$$
\mathbb{E}[W(f)W(g)] = \int_E fg \, d\mu, \qquad
\mathbb{E}[W(f)^2] = \|f\|_{L^2(\mu)}^2.
$$

This is exactly why it is called an isometry: the linear map $f \mapsto W(f)$ sends
the inner product of $L^2(\mu)$ to the covariance structure of a Gaussian family in
$L^2(\Omega)$, preserving "lengths" ($\|f\|^2 \leftrightarrow \operatorname{Var}$) and "angles"
($\langle f,g\rangle \leftrightarrow \operatorname{Cov}$).

## What to notice

- In the left panel, dragging $c$ redistributes variance between $A_1$ and $A_2$ but
  the dashed total $W(A)$ never moves — splitting a set never changes the variance of
  its white noise, it only chooses how to decompose it into an independent sum.
- In the right panel, watch the ellipse: it is a circle-like shape when $A,B$ are
  disjoint ($\rho=0$, uncorrelated, independent), and it collapses onto the diagonal
  $W(A)=W(B)$ exactly when $B=A$ ($\rho=1$) — perfect correlation is not a limit here,
  it is attained, because $B=A$ literally makes them the same random variable.
- $\mu(B)$ drifts slightly even though $B$ has constant width, because $\lambda$ is
  not flat — a reminder that "intensity measure" is doing real work beyond length.
- Nothing here is simulated. $\mu(A)$, $\mu(B)$, $\mu(A\cap B)$ are exact integrals;
  the only randomness is in what $W(A)$ *would* realise as a draw, which is why the
  figure shows distributions (pdfs, ellipses) rather than sample paths.

## Why it matters downstream

This construction is the model behind the **Wiener integral** and, more generally,
**Itô's isometry**. Standard Brownian motion is recovered as
$B_t := W([0,t])$ under Lebesgue intensity $\mu = \text{Leb}$: independent increments
follow directly from independent scattering on disjoint intervals, and
$\operatorname{Var}(B_t) = \mu([0,t]) = t$. The isometry
$\mathbb{E}[W(f)W(g)] = \int fg\,d\mu$ is precisely the $L^2$ identity that lets
stochastic integrals $\int f\,dW$ be *defined* as the isometric extension of the map
on simple functions — the same trick reappears verbatim as
$\mathbb{E}\bigl[(\int_0^t f\,dB)(\int_0^t g\,dB)\bigr] = \int_0^t fg\,ds$.

## Assumptions and limits

- The picture fixes a single deterministic intensity $\lambda(x) = 1+0.15x$; the
  definition itself only needs $\mu$ $\sigma$-finite, and works verbatim for
  $E = \mathbb{R}^d$ or an abstract measure space, not just an interval.
- The ellipse is the $1.5\sigma$ contour of the *exact* bivariate Gaussian law, not a
  Monte Carlo estimate — there is no sampling noise to read into its shape.
- "Independent scattering" needs $A_1, A_2$ literally disjoint as sets; overlapping
  regions correlate by exactly the shared $\mu$-measure, never more or less, which is
  the content of the isometry and not a separate assumption.
