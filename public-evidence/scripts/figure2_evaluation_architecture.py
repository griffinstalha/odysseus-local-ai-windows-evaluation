from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch


# ============================================================
# Paths
# ============================================================

ROOT = Path(__file__).resolve().parents[2]

DATA = (
    ROOT
    / "public-evidence"
    / "source-data"
    / "figure2_architecture.csv"
)

OUTPUT = ROOT / "public-evidence" / "figures"

OUTPUT.mkdir(parents=True, exist_ok=True)


# ============================================================
# Load source data
# ============================================================

df = pd.read_csv(DATA)


def get_detail(section, item):
    result = df[
        (df["section"] == section)
        & (df["item"] == item)
    ]

    if result.empty:
        return ""

    return str(result.iloc[0]["details"])


# ============================================================
# Drawing helpers
# ============================================================

def draw_box(
    ax,
    x,
    y,
    width,
    height,
    title,
    body="",
    title_size=10,
    body_size=8.5,
    linewidth=1.2,
):

    patch = FancyBboxPatch(
        (x, y),
        width,
        height,
        boxstyle="round,pad=0.025",
        linewidth=linewidth,
        edgecolor="black",
        facecolor="white",
    )

    ax.add_patch(patch)

    ax.text(
        x + width / 2,
        y + height * 0.72,
        title,
        ha="center",
        va="center",
        fontsize=title_size,
        fontweight="bold",
    )

    if body:

        ax.text(
            x + width / 2,
            y + height * 0.37,
            body,
            ha="center",
            va="center",
            fontsize=body_size,
            linespacing=1.25,
        )


def arrow(
    ax,
    start,
    end,
    connectionstyle="arc3,rad=0",
    linewidth=1.1,
):

    patch = FancyArrowPatch(
        start,
        end,
        arrowstyle="-|>",
        mutation_scale=11,
        linewidth=linewidth,
        color="black",
        connectionstyle=connectionstyle,
    )

    ax.add_patch(patch)


# ============================================================
# Canvas
# ============================================================

fig, ax = plt.subplots(figsize=(16, 10))

ax.set_xlim(0, 16)
ax.set_ylim(0, 10)

ax.axis("off")


# ============================================================
# Title
# ============================================================

ax.text(
    8,
    9.72,
    "Odysseus Local Evaluation Workflow",
    ha="center",
    va="center",
    fontsize=19,
    fontweight="bold",
)

ax.text(
    8,
    9.37,
    "Evaluation-oriented schematic — not a complete internal software architecture",
    ha="center",
    va="center",
    fontsize=8.5,
    style="italic",
)


# ============================================================
# Environment strip
# ============================================================

environment_body = (
    "Windows 11 Pro (build 26200)  ·  "
    "AMD Ryzen 7 5800H  ·  "
    "15.86 GB RAM  ·  "
    "RTX 3050 Laptop GPU (4 GB VRAM)"
)

draw_box(
    ax,
    1.0,
    8.45,
    14.0,
    0.62,
    "TEST ENVIRONMENT",
    environment_body,
    title_size=10,
    body_size=8.5,
)


# ============================================================
# Layer labels
# ============================================================

ax.text(
    0.25,
    7.35,
    "INPUTS",
    rotation=90,
    fontsize=8,
    fontweight="bold",
    va="center",
)

ax.text(
    0.25,
    5.4,
    "RUNTIME",
    rotation=90,
    fontsize=8,
    fontweight="bold",
    va="center",
)

ax.text(
    0.25,
    2.8,
    "EVALUATION",
    rotation=90,
    fontsize=8,
    fontweight="bold",
    va="center",
)

ax.text(
    0.25,
    0.75,
    "OUTPUT",
    rotation=90,
    fontsize=8,
    fontweight="bold",
    va="center",
)


# ============================================================
# Inputs
# ============================================================

input_body = (
    "RAG\n"
    "SILVER-MOON-482\n"
    "AURORA-NODE\n"
    "927451\n\n"
    "Memory: COBALT-RIVER-731\n"
    "Agent: ORBIT-GLASS-219\n"
    "CSV: sample_data.csv"
)

draw_box(
    ax,
    0.75,
    5.95,
    3.25,
    2.05,
    "SYNTHETIC INPUTS",
    input_body,
    title_size=10,
    body_size=7.2,
)


# ============================================================
# Odysseus
# ============================================================

draw_box(
    ax,
    5.7,
    6.45,
    4.6,
    1.25,
    "ODYSSEUS",
    "Self-hosted local agentic AI workspace",
    title_size=11,
    body_size=9,
)

arrow(
    ax,
    (4.0, 6.95),
    (5.7, 6.95),
)


# ============================================================
# Runtime services
# ============================================================

service_y = 4.55
service_h = 1.25

draw_box(
    ax,
    2.4,
    service_y,
    3.0,
    service_h,
    "OLLAMA",
    (
        "Generation: qwen3:1.7b / qwen3:4b\n"
        "Embeddings: all-minilm:l6-v2"
    ),
)

draw_box(
    ax,
    6.45,
    service_y,
    3.0,
    service_h,
    "CHROMADB",
    "Local vector database\nRAG + memory",
)

draw_box(
    ax,
    10.5,
    service_y,
    3.0,
    service_h,
    "AGENT TOOLS",
    "ReadFile  ·  WriteFile\nBash  ·  Python",
)


# Odysseus -> runtime
arrow(
    ax,
    (7.35, 6.45),
    (3.9, 5.8),
)

arrow(
    ax,
    (8.0, 6.45),
    (7.95, 5.8),
)

arrow(
    ax,
    (8.65, 6.45),
    (12.0, 5.8),
)


# ============================================================
# Evaluation modules
# ============================================================

eval_y = 2.0
eval_h = 1.55

evaluation_boxes = [
    (
        0.6,
        2.55,
        "MODEL BENCHMARK",
        "Throughput\nRAM / VRAM\nProcessor allocation",
    ),
    (
        3.4,
        2.35,
        "RAG",
        "Exact retrieval\nSemantic retrieval\nRestart persistence",
    ),
    (
        6.05,
        2.55,
        "VECTOR MEMORY",
        "Storage\nCross-chat recall\nPersistence",
    ),
    (
        8.95,
        2.65,
        "AGENT RELIABILITY",
        "Natural invocation\nForced protocol\nBackend execution",
    ),
    (
        11.95,
        3.25,
        "SECURITY BOUNDARY",
        "Dedicated file tools\nvs.\nBash / Python",
    ),
]

for x, width, title, body in evaluation_boxes:

    draw_box(
        ax,
        x,
        eval_y,
        width,
        eval_h,
        title,
        body,
        title_size=9.5,
        body_size=8,
    )


# ============================================================
# Runtime -> evaluation connections
# ============================================================

# Ollama -> benchmark
arrow(
    ax,
    (3.9, service_y),
    (1.87, eval_y + eval_h),
)

# ChromaDB -> RAG
arrow(
    ax,
    (7.6, service_y),
    (4.57, eval_y + eval_h),
)

# ChromaDB -> Memory
arrow(
    ax,
    (8.25, service_y),
    (7.32, eval_y + eval_h),
)

# Agent tools -> reliability
arrow(
    ax,
    (11.55, service_y),
    (10.27, eval_y + eval_h),
)

# Agent tools -> security
arrow(
    ax,
    (12.4, service_y),
    (13.57, eval_y + eval_h),
)


# ============================================================
# Reproducible outputs
# ============================================================

draw_box(
    ax,
    1.0,
    0.38,
    14.0,
    0.85,
    "REPRODUCIBLE OUTPUTS",
    (
        "Structured CSV / JSON results  ·  experiment_manifest.json  ·  "
        "SHA256SUMS.txt  ·  REPRODUCIBILITY.md  ·  TEST_METHODS.md"
    ),
    title_size=10,
    body_size=8.3,
)


# Each evaluation module gets its own target point.
output_targets = [
    2.0,
    4.5,
    7.0,
    10.0,
    13.2,
]

eval_centers = [
    0.6 + 2.55 / 2,
    3.4 + 2.35 / 2,
    6.05 + 2.55 / 2,
    8.95 + 2.65 / 2,
    11.95 + 3.25 / 2,
]

for center_x, target_x in zip(
    eval_centers,
    output_targets,
):

    arrow(
        ax,
        (center_x, eval_y),
        (target_x, 1.23),
    )


# ============================================================
# Save
# ============================================================

plt.savefig(
    OUTPUT / "figure2_evaluation_architecture.png",
    dpi=300,
    bbox_inches="tight",
)

plt.savefig(
    OUTPUT / "figure2_evaluation_architecture.pdf",
    bbox_inches="tight",
)

plt.close()

print("Figure 2 created successfully.")