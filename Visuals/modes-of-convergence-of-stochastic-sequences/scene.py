"""
scene.py -- four stacked panels driven by one shared step index t:

  row 1   X_n = running average of iid U(0,1)      -- almost sure convergence
  row 2   the moving interval I_n and the fixed omega -- context for row 3
  row 3   Y_n(omega) = 1{omega in I_n}              -- in probability, not a.s.
  row 4   Z_n = standardised sum of n iid U(0,1)    -- convergence in distribution

Each row uses its own mapping from the shared step t to its own "n", because
the three examples live on different natural scales (n up to 500, n up to
2^K - 1, and a short list of n's for the CLT histogram). The frame name shows
all three so the correspondence stays legible.

Static context (faint background paths, the theoretical targets, the omega
line) is drawn once. Only the highlighted paths, the moving interval, the
Y_n history and the current histogram are re-sent per frame.
"""

import sys
from pathlib import Path

import numpy as np
import plotly.graph_objects as go
from plotly.subplots import make_subplots

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "_lib"))
from api import Frame, Scene  # noqa: E402
from theme import C  # noqa: E402


def _normal_pdf(z):
    return np.exp(-0.5 * z ** 2) / np.sqrt(2 * np.pi)


def build(ctx):
    as_df = ctx.load("almost_sure.csv")
    prob_df = ctx.load("in_probability.csv")
    dist_df = ctx.load("in_distribution.csv")

    n_hi = int(ctx.param("n_paths", 6))
    hi_cols = [c for c in as_df.columns if c.startswith("hi_")][:n_hi]
    faint_cols = [c for c in as_df.columns if c.startswith("faint_")]
    n1 = as_df["n"].to_numpy()

    n2 = prob_df["n"].to_numpy()
    U = float(ctx.param("u_point", 0.37))

    n_values = sorted(dist_df["n"].unique().tolist())
    z_grid = np.linspace(-4, 4, 400)
    pdf_grid = _normal_pdf(z_grid)

    n_frames = int(ctx.param("n_frames", 32))

    fig = make_subplots(
        rows=4, cols=1, shared_xaxes=False, vertical_spacing=0.10,
        row_heights=[0.27, 0.15, 0.15, 0.27],
        subplot_titles=(
            "Almost sure convergence -- Xₙ = (1/n)Σ Uᵢ, Uᵢ iid Uniform(0,1)",
            "Convergence in probability, not a.s. (1/2) -- the moving interval Iₙ and ω",
            "Convergence in probability, not a.s. (2/2) -- Yₙ(ω) = 1{ω ∈ Iₙ}",
            "Convergence in distribution -- Zₙ = (Sₙ - n/2) / √(n/12)  →  N(0,1)",
        ),
    )

    # ======================================================================
    # row 1 -- SLLN: static faint ensemble + true mean, animated highlights
    # ======================================================================
    fig.add_trace(go.Scatter(
        x=[n1[0], n1[-1]], y=[0.5, 0.5], mode="lines",
        line=dict(color=C.theoretical, width=2, dash="dash"),
        name="limit = 1/2", hoverinfo="skip",
    ), row=1, col=1)

    for c in faint_cols:
        fig.add_trace(go.Scatter(
            x=n1, y=as_df[c].to_numpy(), mode="lines",
            line=dict(color="rgba(13,148,136,0.10)", width=0.8),
            hoverinfo="skip", showlegend=False,
        ), row=1, col=1)

    targets = []
    for i, c in enumerate(hi_cols):
        targets.append(len(fig.data))
        fig.add_trace(go.Scatter(
            x=n1, y=as_df[c].to_numpy(), mode="lines",
            line=dict(color=C.paths[i % len(C.paths)], width=1.8),
            name=f"path {i + 1}" if i == 0 else None,
            showlegend=False,
            hovertemplate="n=%{x}<br>Xₙ=%{y:.3f}<extra></extra>",
        ), row=1, col=1)

    # ======================================================================
    # row 2 -- the moving block I_n and the fixed point omega
    # ======================================================================
    fig.add_trace(go.Scatter(
        x=[n2[0], n2[-1]], y=[U, U], mode="lines",
        line=dict(color=C.drift, width=1.6, dash="dot"),
        name="ω", hoverinfo="skip",
    ), row=2, col=1)

    targets.append(len(fig.data))
    fig.add_trace(go.Scatter(
        x=[n2[0]], y=[prob_df["mid"].iloc[0]], mode="markers",
        marker=dict(size=9, color=C.empirical),
        error_y=dict(type="data", array=[prob_df["half_width"].iloc[0]],
                      visible=True, color=C.empirical, thickness=6, width=0),
        name="Iₙ", hoverinfo="skip", showlegend=False,
    ), row=2, col=1)

    # ======================================================================
    # row 3 -- Y_n(omega) history: spikes that thin out but never stop
    # ======================================================================
    targets.append(len(fig.data))
    fig.add_trace(go.Bar(
        x=[n2[0]], y=[prob_df["hit"].iloc[0]],
        marker=dict(color=C.tail), width=1.0,
        hovertemplate="n=%{x}<br>Yₙ=%{y}<extra></extra>", showlegend=False,
    ), row=3, col=1)

    # ======================================================================
    # row 4 -- CLT: theoretical N(0,1) static, current histogram animated
    # ======================================================================
    fig.add_trace(go.Scatter(
        x=z_grid, y=pdf_grid, mode="lines",
        line=dict(color=C.theoretical, width=2.2),
        name="N(0,1) density", hoverinfo="skip",
    ), row=4, col=1)

    d0 = dist_df[dist_df["n"] == n_values[0]]
    targets.append(len(fig.data))
    fig.add_trace(go.Bar(
        x=d0["z"], y=d0["density"], marker=dict(color=C.empirical, opacity=0.75),
        name="empirical", width=(z_grid[-1] - z_grid[0]) / 50,
        hovertemplate="z=%{x:.2f}<br>density=%{y:.3f}<extra></extra>",
    ), row=4, col=1)

    # ---- layout ----------------------------------------------------------
    # dtick=1 on a log axis shows only whole-decade ticks (1, 10, 100, ...);
    # the plotly default also labels every minor tick (1..9, 10..90, ...),
    # which crowds three stacked log axes into an unreadable comb of digits.
    fig.update_xaxes(type="log", dtick=1, title_text="n",
                      range=[0, np.log10(n1[-1])], row=1, col=1)
    fig.update_yaxes(title_text="Xₙ", row=1, col=1)

    fig.update_xaxes(type="log", dtick=1, range=[0, np.log10(n2[-1])],
                      row=2, col=1)
    fig.update_yaxes(title_text="[0, 1]", range=[-0.03, 1.03], row=2, col=1)

    fig.update_xaxes(type="log", dtick=1, title_text="n",
                      range=[0, np.log10(n2[-1])], row=3, col=1)
    fig.update_yaxes(title_text="Yₙ", range=[0, 1.15], tickvals=[0, 1],
                      row=3, col=1)

    fig.update_xaxes(title_text="z", range=[-4, 4], row=4, col=1)
    fig.update_yaxes(title_text="density", row=4, col=1)

    fig.update_layout(
        height=1180,
        barmode="overlay",
        legend=dict(orientation="h", y=1.045, x=1, xanchor="right"),
    )
    # theme.annotate()'s corner position is defined in each subplot's own
    # paper fraction, so on a 4-row figure it lands inside row 4's plot area
    # rather than below the whole figure -- keep the parameter note in the
    # caption instead of overlaying it on the histogram.
    param_note = (f"SLLN n≤{n1[-1]}   typewriter n≤{n2[-1]}   "
                  f"CLT n∈{{{', '.join(str(v) for v in n_values)}}}   "
                  f"seed={ctx.seed}")

    # ======================================================================
    # frames -- each row advances on its own natural scale
    # ======================================================================
    frac = np.linspace(0.0, 1.0, n_frames)
    idx1 = np.unique(np.round(np.exp(
        np.log(2) + frac * (np.log(n1[-1]) - np.log(2))
    )).astype(int))
    idx2 = np.unique(np.round(np.exp(
        np.log(1) + frac * (np.log(n2[-1]) - np.log(1))
    )).astype(int))
    idx2 = np.clip(idx2, 1, n2[-1])
    n_steps = max(len(idx1), len(idx2))
    # pad the shorter schedule by repeating its last value so both walk
    # in lockstep with the shared slider
    if len(idx1) < n_steps:
        idx1 = np.concatenate([idx1, np.full(n_steps - len(idx1), idx1[-1])])
    if len(idx2) < n_steps:
        idx2 = np.concatenate([idx2, np.full(n_steps - len(idx2), idx2[-1])])
    idx4 = np.round(np.linspace(0, len(n_values) - 1, n_steps)).astype(int)

    frames = []
    for k1, k2, k4 in zip(idx1, idx2, idx4):
        s1 = slice(0, int(k1))
        data = [go.Scatter(x=n1[s1], y=as_df[c].to_numpy()[s1], mode="lines",
                            line=dict(color=C.paths[i % len(C.paths)], width=1.8))
                for i, c in enumerate(hi_cols)]

        row_k2 = prob_df.iloc[int(k2) - 1]
        data.append(go.Scatter(
            x=[row_k2["n"]], y=[row_k2["mid"]], mode="markers",
            marker=dict(size=9, color=C.tail if row_k2["hit"] else C.empirical),
            error_y=dict(type="data", array=[row_k2["half_width"]],
                          visible=True,
                          color=C.tail if row_k2["hit"] else C.empirical,
                          thickness=6, width=0),
        ))

        hist = prob_df.iloc[:int(k2)]
        data.append(go.Bar(x=hist["n"].to_numpy(), y=hist["hit"].to_numpy(),
                            marker=dict(color=C.tail), width=1.0))

        n_now = n_values[int(k4)]
        d_now = dist_df[dist_df["n"] == n_now]
        data.append(go.Bar(x=d_now["z"], y=d_now["density"],
                            marker=dict(color=C.empirical, opacity=0.75)))

        frames.append(Frame(
            name=f"n₁={int(k1)}  n₂={int(k2)}  n(CLT)={n_now}",
            data=data, targets=targets,
        ))

    return Scene(
        figure=fig, frames=frames, axis_label="step:",
        caption=(
            "Row 1: every highlighted path settles at 1/2 -- almost sure "
            "convergence is a pathwise statement. Row 2-3: P(Yₙ=1) "
            "halves every block and → 0, yet ω gets hit again in "
            "every block forever, so Yₙ(ω) never settles -- "
            "convergence in probability does not imply a.s. convergence. "
            "Row 4: the histogram of Zₙ locks onto N(0,1) as n grows, "
            "but that says nothing about any single realisation of Zₙ -- "
            "convergence in distribution is a statement about laws, not paths."
            f"\n\n{param_note}"
        ),
    )
