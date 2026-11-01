from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.patches import FancyBboxPatch


# ============================================================
# Paths
# ============================================================

ROOT = Path(__file__).resolve().parents[2]

SECURITY_DATA = (
    ROOT
    / "public-evidence"
    / "source-data"
    / "figure3_security_boundary.csv"
)

AGENT_DATA = (
    ROOT
    / "public-evidence"
    / "source-data"
    / "figure3_agent_reliability.csv"
)

OUTPUT = ROOT / "public-evidence" / "figures"

OUTPUT.mkdir(parents=True, exist_ok=True)


# ============================================================
# Load source data
# ============================================================

security = pd.read_csv(SECURITY_DATA)
agent = pd.read_csv(AGENT_DATA)


# ============================================================
# Helpers
# ============================================================

def status_box(
    ax,
    x,
    y,
    text,
    width=0.12,
    height=0.038,
):

    patch = FancyBboxPatch(
        (x, y - height / 2),
        width,
        height,
        boxstyle="round,pad=0.008",
        facecolor="white",
        edgecolor="black",
        linewidth=1.0,
    )

    ax.add_patch(patch)

    ax.text(
        x + width / 2,
        y,
        text,
        ha="center",
        va="center",
        fontsize=8,
        fontweight="bold",
    )


def separator(ax, y):
    ax.plot(
        [0.04, 0.96],
        [y, y],
        linewidth=0.55,
        color="black",
        alpha=0.35,
    )


# ============================================================
# Figure canvas
# ============================================================

fig, ax = plt.subplots(figsize=(14, 10))

ax.set_xlim(0, 1)
ax.set_ylim(0, 1)

ax.axis("off")


# ============================================================
# Title
# ============================================================

ax.text(
    0.5,
    0.965,
    "Security Boundary and Agent-Tool Behavior",
    ha="center",
    va="top",
    fontsize=18,
    fontweight="bold",
)

ax.text(
    0.5,
    0.925,
    "Controlled evaluation of workspace boundaries and agent tool invocation",
    ha="center",
    va="top",
    fontsize=9,
    style="italic",
)


# ============================================================
# Section A
# ============================================================

ax.text(
    0.04,
    0.875,
    "A. Filesystem boundary behavior",
    fontsize=13,
    fontweight="bold",
)


# Column headings
ax.text(
    0.05,
    0.825,
    "Tool",
    fontsize=9,
    fontweight="bold",
)

ax.text(
    0.23,
    0.825,
    "Controlled operation",
    fontsize=9,
    fontweight="bold",
)

ax.text(
    0.59,
    0.825,
    "Observed result",
    fontsize=9,
    fontweight="bold",
)

ax.text(
    0.76,
    0.825,
    "Interpretation",
    fontsize=9,
    fontweight="bold",
)

separator(ax, 0.81)


# ============================================================
# Group source results by tool
# ============================================================

security_rows = [
    (
        "ReadFileTool",
        "Relative + absolute outside-workspace read",
        "BLOCKED",
        "Workspace boundary enforced",
    ),
    (
        "WriteFileTool",
        "Relative + absolute outside-workspace write",
        "BLOCKED",
        "Workspace boundary enforced",
    ),
    (
        "BashTool",
        "Outside-workspace read + write",
        "ALLOWED",
        "Normal host permissions",
    ),
    (
        "PythonTool",
        "Outside read: tested\nOutside write: not tested",
        "READ ALLOWED",
        "Write behavior not claimed",
    ),
]

security_y = [
    0.765,
    0.695,
    0.625,
    0.555,
]


for (
    tool,
    operation,
    status,
    interpretation,
), y in zip(
    security_rows,
    security_y,
):

    ax.text(
        0.05,
        y,
        tool,
        fontsize=9,
        va="center",
        fontweight="bold",
    )

    ax.text(
        0.23,
        y,
        operation,
        fontsize=8.6,
        va="center",
        linespacing=1.25,
    )

    status_box(
        ax,
        0.59,
        y,
        status,
        width=0.13,
    )

    ax.text(
        0.76,
        y,
        interpretation,
        fontsize=8.5,
        va="center",
    )

    separator(
        ax,
        y - 0.038,
    )


# Python write caveat
ax.text(
    0.04,
    0.49,
    (
        "Boundary interpretation: dedicated ReadFile/WriteFile tools enforced "
        "the tested workspace boundary. Bash and Python should not be treated "
        "as operating-system filesystem sandboxes."
    ),
    fontsize=8.6,
    va="top",
    wrap=True,
)


# ============================================================
# Section B
# ============================================================

ax.text(
    0.04,
    0.405,
    "B. Agent tool-invocation reliability",
    fontsize=13,
    fontweight="bold",
)


ax.text(
    0.05,
    0.36,
    "Scenario",
    fontsize=9,
    fontweight="bold",
)

ax.text(
    0.55,
    0.36,
    "Result",
    fontsize=9,
    fontweight="bold",
)

ax.text(
    0.70,
    0.36,
    "Observation",
    fontsize=9,
    fontweight="bold",
)

separator(ax, 0.345)


agent_y = [
    0.305,
    0.26,
    0.215,
    0.17,
    0.125,
]


for (_, row), y in zip(
    agent.iterrows(),
    agent_y,
):

    ax.text(
        0.05,
        y,
        row["scenario"],
        fontsize=8.6,
        va="center",
    )

    status_box(
        ax,
        0.55,
        y,
        row["status"],
        width=0.10,
        height=0.032,
    )

    ax.text(
        0.70,
        y,
        row["observation"],
        fontsize=8.4,
        va="center",
    )

    separator(
        ax,
        y - 0.026,
    )


# ============================================================
# Notes
# ============================================================

ax.text(
    0.04,
    0.075,
    (
        "Interpretation: natural task failures indicate protocol-emission "
        "unreliability in this controlled test; they do not imply that "
        "Qwen3 models generally cannot use tools."
    ),
    fontsize=8.2,
    va="top",
)

ax.text(
    0.04,
    0.035,
    (
        "Frontend observation: the shell UI appeared disabled while an "
        "Agent-intent request contained allow_bash=true. End-to-end shell "
        "execution from that disabled UI state was not demonstrated."
    ),
    fontsize=8.2,
    va="top",
)


# ============================================================
# Save
# ============================================================

plt.savefig(
    OUTPUT / "figure3_security_agent_summary.png",
    dpi=300,
    bbox_inches="tight",
)

plt.savefig(
    OUTPUT / "figure3_security_agent_summary.pdf",
    bbox_inches="tight",
)

plt.close()

print("Figure 3 created successfully.")