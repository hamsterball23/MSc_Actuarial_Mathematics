"""
scene.py -- Gaussian white noise W with intensity mu, in two linked panels.

Left column  -- what W *is*: for a set A split into disjoint A1, A2, the
                random variables W(A1), W(A2) are independent Gaussians and
                W(A) = W(A1) + W(A2), so Var(W(A)) = mu(A1) + mu(A2) no
                matter where the split point sits. The bottom-left pdfs
                animate their spread while the dashed total stays fixed --
                that invariance *is* sigma-additivity in distribution.

Right column -- the defining isometry: Cov(W(A), W(B)) = mu(A n B). A is
                held fixed and B slides across the base space; the
                bottom-right panel draws the joint law of (W(A), W(B)) as a
                covariance ellipse, which flattens onto a line exactly when
                B = A (perfect correlation) and opens into a circle-like
                shape as the overlap vanishes (independence, Cov = 0).

Both sweeps are driven by one normalised parameter t in [0,1] so a single
slider tells one story in two registers at once. Animation cost is kept low
by drawing the two density curves as static context and animating only the
four shaded regions, two pdf curves, one ellipse and two numeric-readout
text traces -- every one of them a handful of points, never the density
grid itself.
"""

import sys
from pathlib import Path

import numpy as np
import plotly.graph_objects as go
from plotly.subplots import make_subplots

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "_lib"))
from api import Frame, Scene  # noqa: E402
from theme import C, annotate  # noqa: E402


def trapezoid(a, b, lam0, lam1):
    """Corner points of the region under the linear density on [a, b]."""
    if not (b > a):
        return [np.nan] * 4, [np.nan] * 4
    return [a, a, b, b], [0.0, lam0 + lam1 * a, lam0 + lam1 * b, 0.0]


def gaussian_pdf(x, var):
    var = max(var, 1e-9)
    sigma = np.sqrt(var)
    return np.exp(-0.5 * x ** 2 / var) / (sigma * np.sqrt(2 * np.pi))


def cov_ellipse(var_a, var_b, cov, k=1.5, n=80):
    """Points of the k-sigma ellipse of a bivariate Gaussian with the given
    covariance matrix. When the matrix is (numerically) singular -- B = A,
    perfect correlation -- one eigenvalue is ~0 and the ellipse degenerates
    to a line segment, which is exactly the picture we want there."""
    Sigma = np.array([[var_a, cov], [cov, var_b]])
    eigval, eigvec = np.linalg.eigh(Sigma)
    eigval = np.clip(eigval, 0.0, None)
    theta = np.linspace(0, 2 * np.pi, n)
    circle = np.stack([np.cos(theta), np.sin(theta)])
    pts = eigvec @ (np.sqrt(eigval)[:, None] * circle) * k
    return pts[0], pts[1]


def build(ctx):
    dens = ctx.load("density.csv")
    left = ctx.load("left.csv")
    right = ctx.load("right.csv")

    lam0 = float(ctx.param("lambda0", 1.0))
    lam1 = float(ctx.param("lambda1", 0.15))
    domain_max = float(ctx.param("domain_max", 16.0))
    a2, b2 = float(ctx.param("overlap_a_lo", 5.0)), float(ctx.param("overlap_a_hi", 11.0))
    n_frames = len(left)

    x_dens = dens["x"].to_numpy()
    y_dens = dens["lam"].to_numpy()
    y_max = float(y_dens.max()) * 1.15

    var_A_left = float(left["mu_A"].iloc[0])          # fixed total, left panel
    pdf_x = np.linspace(-4.2 * np.sqrt(var_A_left), 4.2 * np.sqrt(var_A_left), 260)
    pdf_y_max = gaussian_pdf(0.0, left["mu_A2"].min()) * 1.15  # tallest curve, narrowest sigma

    lim = 20.0  # fixed square range for the ellipse panel

    fig = make_subplots(
        rows=2, cols=2, vertical_spacing=0.14, horizontal_spacing=0.10,
        subplot_titles=(
            "Splitting A = A₁ ∪ A₂ under μ",
            "A fixed, B sliding under μ",
            "Var adds: W(A₁) ⊕ W(A₂) = W(A)",
            "Isometry: Cov(W(A),W(B)) = μ(A∩B)",
        ),
        row_heights=[0.42, 0.58],
    )

    # ---- static context: density curves, drawn once ----------------------
    for col in (1, 2):
        fig.add_trace(go.Scatter(
            x=x_dens, y=y_dens, mode="lines", line=dict(color=C.axis, width=1.4),
            fill="tozeroy", fillcolor="rgba(100,116,139,0.06)",
            name="μ density λ(x)" if col == 1 else None,
            showlegend=(col == 1), hoverinfo="skip",
        ), row=1, col=col)

    # A fixed (right panel) -- static shading, never moves
    xs, ys = trapezoid(a2, b2, lam0, lam1)
    fig.add_trace(go.Scatter(
        x=xs, y=ys, fill="toself", mode="lines",
        line=dict(color=C.theoretical, width=1.5),
        fillcolor="rgba(124,58,237,0.16)", name="A (fixed)", hoverinfo="skip",
    ), row=1, col=2)

    # W(A) total pdf (left panel) -- static, the invariant to check against
    fig.add_trace(go.Scatter(
        x=pdf_x, y=gaussian_pdf(pdf_x, var_A_left), mode="lines",
        line=dict(color=C.theoretical, width=2, dash="dash"),
        name=f"W(A), Var=μ(A)={var_A_left:.2f}", hoverinfo="skip",
    ), row=2, col=1)

    # diagonal reference in the ellipse panel: where B = A would sit
    fig.add_trace(go.Scatter(
        x=[-lim, lim], y=[-lim, lim], mode="lines",
        line=dict(color=C.threshold, width=1, dash="dot"),
        name="W(A) = W(B)", hoverinfo="skip",
    ), row=2, col=2)

    # ---- per-frame geometry: shared by the initial state and every frame --
    def frame_state(k):
        row_l, row_r = left.iloc[k], right.iloc[k]
        c, a, b = float(row_l["c"]), float(row_l["a"]), float(row_l["b"])
        mu_a1, mu_a2 = float(row_l["mu_A1"]), float(row_l["mu_A2"])

        b_lo, b_hi = float(row_r["b_lo"]), float(row_r["b_hi"])
        ov_lo, ov_hi = float(row_r["ov_lo"]), float(row_r["ov_hi"])
        mu_A, mu_B, mu_AB, rho = (float(row_r["mu_A"]), float(row_r["mu_B"]),
                                   float(row_r["mu_AB"]), float(row_r["rho"]))

        xs1, ys1 = trapezoid(a, c, lam0, lam1)
        xs2, ys2 = trapezoid(c, b, lam0, lam1)
        xsB, ysB = trapezoid(b_lo, b_hi, lam0, lam1)
        xsO, ysO = trapezoid(ov_lo, ov_hi, lam0, lam1)
        ex, ey = cov_ellipse(mu_A, mu_B, mu_AB)

        pdf_label = f"μ(A₁)={mu_a1:.2f}  μ(A₂)={mu_a2:.2f}  μ(A)={mu_a1 + mu_a2:.2f}"
        ell_label = f"μ(A)={mu_A:.2f}  μ(B)={mu_B:.2f}  Cov=μ(A∩B)={mu_AB:.2f}  ρ={rho:.2f}"

        return [
            go.Scatter(x=xs1, y=ys1),
            go.Scatter(x=xs2, y=ys2),
            go.Scatter(x=xsB, y=ysB),
            go.Scatter(x=xsO, y=ysO),
            go.Scatter(x=pdf_x, y=gaussian_pdf(pdf_x, mu_a1)),
            go.Scatter(x=pdf_x, y=gaussian_pdf(pdf_x, mu_a2)),
            go.Scatter(x=ex, y=ey),
            go.Scatter(text=[pdf_label]),
            go.Scatter(text=[ell_label]),
        ]

    init = frame_state(0)

    # ---- animated traces: remember their indices --------------------------
    targets = []

    def add_target(trace, row, col):
        targets.append(len(fig.data))
        fig.add_trace(trace, row=row, col=col)

    add_target(go.Scatter(fill="toself", mode="lines",
                           line=dict(color=C.empirical, width=1.5),
                           fillcolor="rgba(3,105,161,0.30)", name="A₁",
                           x=init[0].x, y=init[0].y), 1, 1)
    add_target(go.Scatter(fill="toself", mode="lines",
                           line=dict(color=C.diffusion, width=1.5),
                           fillcolor="rgba(13,148,136,0.30)", name="A₂",
                           x=init[1].x, y=init[1].y), 1, 1)
    add_target(go.Scatter(fill="toself", mode="lines",
                           line=dict(color=C.empirical, width=1.5),
                           fillcolor="rgba(3,105,161,0.22)", name="B",
                           x=init[2].x, y=init[2].y), 1, 2)
    add_target(go.Scatter(fill="toself", mode="lines",
                           line=dict(color=C.tail, width=1.5),
                           fillcolor="rgba(185,28,28,0.38)", name="A∩B",
                           x=init[3].x, y=init[3].y), 1, 2)
    add_target(go.Scatter(mode="lines", line=dict(color=C.empirical, width=2.1),
                           name="W(A₁)", x=init[4].x, y=init[4].y), 2, 1)
    add_target(go.Scatter(mode="lines", line=dict(color=C.diffusion, width=2.1),
                           name="W(A₂)", x=init[5].x, y=init[5].y), 2, 1)
    add_target(go.Scatter(mode="lines", fill="toself",
                           line=dict(color=C.diffusion, width=2),
                           fillcolor="rgba(13,148,136,0.10)", name="(W(A),W(B))",
                           x=init[6].x, y=init[6].y), 2, 2)
    add_target(go.Scatter(x=[-domain_max * 0.02], y=[pdf_y_max * 0.92], mode="text",
                           text=init[7].text, textposition="middle right",
                           textfont=dict(size=11, color=C.ink, family="monospace"),
                           showlegend=False, hoverinfo="skip"), 2, 1)
    add_target(go.Scatter(x=[-lim * 0.95], y=[lim * 0.88], mode="text",
                           text=init[8].text, textposition="middle right",
                           textfont=dict(size=11, color=C.ink, family="monospace"),
                           showlegend=False, hoverinfo="skip"), 2, 2)

    fig.update_xaxes(range=[0, domain_max], title_text="x", row=1, col=1)
    fig.update_xaxes(range=[0, domain_max], title_text="x", row=1, col=2)
    fig.update_yaxes(range=[0, y_max], title_text="λ(x)", row=1, col=1)
    fig.update_yaxes(range=[0, y_max], title_text="λ(x)", row=1, col=2)
    fig.update_xaxes(range=[pdf_x[0], pdf_x[-1]], title_text="w", row=2, col=1)
    fig.update_yaxes(range=[0, pdf_y_max], title_text="density", row=2, col=1)
    fig.update_xaxes(range=[-lim, lim], title_text="W(A)", row=2, col=2)
    fig.update_yaxes(range=[-lim, lim], title_text="W(B)", scaleanchor="x4",
                      scaleratio=1, row=2, col=2)
    fig.update_layout(
        height=760,
        legend=dict(orientation="h", y=1.13, x=1, xanchor="right", font=dict(size=10)),
    )
    annotate(fig, f"λ(x)={lam0}+{lam1}x   A(left)=[{left['a'].iloc[0]:.0f},"
                   f"{left['b'].iloc[0]:.0f}]   A(right)=[{a2:.0f},{b2:.0f}]   "
                   f"{n_frames} frames")

    # ---- frames -------------------------------------------------------
    frames = [
        Frame(name=f"t={k / (n_frames - 1):.2f}", data=frame_state(k), targets=targets)
        for k in range(n_frames)
    ]

    return Scene(
        figure=fig, frames=frames, axis_label="t =",
        caption=("Left: however A is cut into disjoint A₁, A₂, the variances "
                  "add and the total stays the dashed W(A) curve. Right: sliding B "
                  "across A traces Cov(W(A),W(B)) = μ(A∩B) directly -- the "
                  "ellipse collapses onto the diagonal exactly when B = A."),
    )
