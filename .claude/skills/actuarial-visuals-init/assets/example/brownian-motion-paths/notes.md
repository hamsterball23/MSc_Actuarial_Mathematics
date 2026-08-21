## What this shows

Sixty independent standard Brownian paths on $[0,1]$, simulated on a uniform
partition with $n = 500$ steps, together with the running quadratic variation
of each path along that same partition.

## The maths

$W$ is standard Brownian motion: $W_0 = 0$, independent increments, and

$$
W_{t} - W_{s} \sim \mathcal{N}(0,\, t-s), \qquad 0 \le s < t,
$$

with continuous sample paths. The simulation is exact at the grid points --
no discretisation error enters the paths themselves, only the quadratic
variation, which is defined as a limit over refining partitions.

For a partition $\pi_n = \{0 = t_0 < t_1 < \cdots < t_n = t\}$ with mesh
$\|\pi_n\| \to 0$,

$$
[W]^{(n)}_t \;=\; \sum_{t_k \le t} \bigl(W_{t_{k+1}} - W_{t_k}\bigr)^2
\;\xrightarrow{\;\mathbb{P}\;}\; t .
$$

Each squared increment has mean $\Delta t$ and variance $2(\Delta t)^2$, so the
sum has mean $t$ and variance $2t\,\Delta t \to 0$. The fluctuation vanishes
because the *variance* of the sum shrinks linearly in the mesh even though the
number of terms grows.

## What to notice

- The cross-section spreads exactly like $\sqrt{t}$ -- the grey envelope is
  $\pm\sqrt{t}$, not a fitted band. Roughly 68% of paths sit inside it at each $t$.
- The bottom panel is the striking one. Every path, without exception, tracks
  the diagonal. Quadratic variation is not a statement about the average path;
  it holds pathwise, almost surely.
- Contrast this with total variation, which is infinite on every interval. BM
  is rough enough that first-order variation blows up, yet regular enough that
  second-order variation is deterministic. That gap is exactly the room in
  which Ito calculus lives.
- The convergence is in probability over refining partitions, not pathwise
  along a fixed sequence, unless you impose $\sum_n \|\pi_n\| < \infty$.

## Why it matters downstream

The identity $dW_t \cdot dW_t = dt$ is the whole content of the Ito correction
term. In Ito's formula,

$$
df(t, W_t) = \Bigl(\partial_t f + \tfrac{1}{2}\partial_{xx} f\Bigr)dt
             + \partial_x f \, dW_t ,
$$

the $\tfrac{1}{2}\partial_{xx}f$ term appears only because the second-order
Taylor term does not vanish -- and it does not vanish precisely because
$[W]_t = t$ rather than $0$. Ordinary calculus is the special case where the
driving path has zero quadratic variation.

## Assumptions and limits

- Quadratic variation is partition-dependent for general processes. The clean
  limit here relies on the mesh going to zero; a fixed coarse grid gives a
  biased picture.
- The picture shows convergence for one particular refining sequence. It is
  evidence, not proof.
- Increments are simulated as exactly Gaussian, so this shows the theory, not
  the behaviour of any real price series.
