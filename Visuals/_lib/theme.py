"""
theme.py -- one visual language for the whole gallery.

The point of a shared theme is not prettiness, it is that a colour means
the same thing in every figure. When drift is always slate and diffusion is
always teal, you stop re-reading legends and start reading the picture.

Visuals should reference these names rather than hard-coding hex values:

    from theme import C
    go.Scatter(..., line=dict(color=C.drift))
"""

from __future__ import annotations

import plotly.graph_objects as go
import plotly.io as pio

TEMPLATE_NAME = "actuarial"


class C:
    """Semantic palette. Chosen to stay distinguishable in greyscale print
    and under the common forms of colour blindness."""

    # --- structural roles in a stochastic model ---
    drift = "#334155"        # slate  -- deterministic part, mean, trend
    diffusion = "#0d9488"    # teal   -- the noise / Brownian part
    jump = "#c2410c"         # burnt  -- jumps, shocks, discontinuities
    theoretical = "#7c3aed"  # violet -- closed-form / limit / target
    empirical = "#0369a1"    # blue   -- simulated or observed

    # --- risk and tails ---
    tail = "#b91c1c"         # red    -- exceedances, the bad region
    threshold = "#a16207"    # amber  -- VaR level, barrier, retention u
    body = "#94a3b8"         # grey   -- the uninteresting bulk

    # --- multi-path / multi-series ramps ---
    paths = ["#0d9488", "#0369a1", "#7c3aed", "#c2410c", "#059669",
             "#4f46e5", "#db2777", "#0891b2"]

    # --- surfaces ---
    surface = "Viridis"
    diverging = "RdBu"

    # --- chrome ---
    grid = "#e2e8f0"
    axis = "#64748b"
    ink = "#0f172a"
    paper = "#ffffff"
    muted = "#64748b"


_FONT = ("ui-sans-serif, -apple-system, 'Segoe UI', Inter, "
         "Helvetica, Arial, sans-serif")
_MONO = "ui-monospace, 'SF Mono', Menlo, Consolas, monospace"


def _build_template() -> go.layout.Template:
    return go.layout.Template(
        layout=go.Layout(
            font=dict(family=_FONT, size=13, color=C.ink),
            title=dict(font=dict(size=16, color=C.ink), x=0.0, xanchor="left"),
            paper_bgcolor=C.paper,
            plot_bgcolor=C.paper,
            colorway=C.paths,
            margin=dict(l=64, r=24, t=48, b=56),
            hovermode="closest",
            hoverlabel=dict(font=dict(family=_MONO, size=12),
                            bgcolor="#ffffff", bordercolor=C.grid),
            legend=dict(bgcolor="rgba(255,255,255,0.85)",
                        bordercolor=C.grid, borderwidth=1,
                        font=dict(size=12)),
            xaxis=dict(gridcolor=C.grid, zerolinecolor=C.grid,
                       linecolor=C.axis, ticks="outside", ticklen=4,
                       tickcolor=C.axis, title=dict(font=dict(size=13))),
            yaxis=dict(gridcolor=C.grid, zerolinecolor=C.grid,
                       linecolor=C.axis, ticks="outside", ticklen=4,
                       tickcolor=C.axis, title=dict(font=dict(size=13))),
            colorscale=dict(sequential=C.surface, diverging=C.diverging),
        )
    )


def install() -> None:
    """Register the template and make it the default. Called by the harness
    before ``scene.build`` runs, so visuals inherit it for free."""
    pio.templates[TEMPLATE_NAME] = _build_template()
    pio.templates.default = TEMPLATE_NAME


def apply(fig: go.Figure) -> go.Figure:
    """Apply house layout to a finished figure without clobbering anything
    the visual deliberately set."""
    fig.update_layout(template=TEMPLATE_NAME)
    return fig


def annotate(fig: go.Figure, text: str, *, x=0.99, y=0.02,
             align="right") -> go.Figure:
    """Small monospace corner note -- parameter values, seed, sample size.
    Worth using: six months later you will want to know what n was."""
    fig.add_annotation(
        text=text, xref="paper", yref="paper", x=x, y=y,
        xanchor=align, yanchor="bottom", showarrow=False,
        font=dict(family=_MONO, size=11, color=C.muted),
    )
    return fig
