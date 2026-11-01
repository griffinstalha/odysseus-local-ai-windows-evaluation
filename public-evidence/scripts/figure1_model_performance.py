from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


# ============================================================
# Paths
# ============================================================

ROOT = Path(__file__).resolve().parents[2]

DATA = (
    ROOT
    / "public-evidence"
    / "source-data"
    / "figure1_model_performance.csv"
)

OUTPUT = ROOT / "public-evidence" / "figures"

OUTPUT.mkdir(parents=True, exist_ok=True)


# ============================================================
# Load and validate data
# ============================================================

df = pd.read_csv(DATA)

required_columns = [
    "model",
    "median_tps",
    "mean_tps",
    "min_tps",
    "max_tps",
    "sd_tps",
    "median_ram_delta_gb",
    "median_vram_delta_mib",
    "processor_allocation",
    "run1_tps",
    "run2_tps",
    "run3_tps",
]

missing = [c for c in required_columns if c not in df.columns]

if missing:
    raise ValueError(f"Missing required columns: {missing}")


# ============================================================
# Data preparation
# ============================================================

models = df["model"].tolist()

medians = df["median_tps"].to_numpy()
mins = df["min_tps"].to_numpy()
maxs = df["max_tps"].to_numpy()

lower_error = medians - mins
upper_error = maxs - medians

x = list(range(len(models)))

run_columns = ["run1_tps", "run2_tps", "run3_tps"]
run_offsets = [-0.09, 0.0, 0.09]


# ============================================================
# Figure
# ============================================================

fig, ax = plt.subplots(figsize=(11.5, 7.4))


# Main bars: median throughput
bars = ax.bar(
    x,
    medians,
    width=0.55,
    linewidth=1.0,
    edgecolor="black",
)


# Min-max whiskers
ax.errorbar(
    x,
    medians,
    yerr=[lower_error, upper_error],
    fmt="none",
    capsize=7,
    linewidth=1.4,
    color="black",
)


# Individual benchmark runs
for i, row in df.iterrows():

    for offset, run_col in zip(run_offsets, run_columns):

        ax.scatter(
            i + offset,
            row[run_col],
            s=45,
            marker="o",
            edgecolor="black",
            linewidth=0.9,
            zorder=5,
        )


# ============================================================
# Median labels
# ============================================================

for i, bar in enumerate(bars):

    ax.text(
        bar.get_x() + bar.get_width() / 2,
        bar.get_height() + 4.0,
        f"{df.iloc[i]['median_tps']:.2f} tok/s",
        ha="center",
        va="bottom",
        fontsize=11,
        fontweight="bold",
    )


# ============================================================
# Axes
# ============================================================

ax.set_xticks(x)
ax.set_xticklabels(models, fontsize=11)

ax.set_ylabel(
    "Median generation throughput (tokens/s)",
    fontsize=11,
)

ax.set_ylim(
    0,
    max(maxs) * 1.30,
)

ax.grid(
    axis="y",
    linestyle="--",
    linewidth=0.6,
    alpha=0.35,
)

ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)


# ============================================================
# Title and subtitle
# ============================================================

fig.suptitle(
    "Local LLM Performance on Windows 11",
    fontsize=18,
    fontweight="bold",
    y=0.965,
)

ax.set_title(
    "RTX 3050 Laptop GPU (4 GB VRAM)",
    fontsize=11,
    pad=12,
)


# ============================================================
# Hardware/resource summaries
# ============================================================

left_text = (
    "Qwen3 1.7B\n"
    f"RAM Δ   {df.iloc[0]['median_ram_delta_gb']:.2f} GB\n"
    f"VRAM Δ  {df.iloc[0]['median_vram_delta_mib']:.0f} MiB\n"
    f"Execution  {df.iloc[0]['processor_allocation']}\n"
    f"Range  {df.iloc[0]['min_tps']:.2f}–{df.iloc[0]['max_tps']:.2f} tok/s"
)

right_text = (
    "Qwen3 4B\n"
    f"RAM Δ   {df.iloc[1]['median_ram_delta_gb']:.2f} GB\n"
    f"VRAM Δ  {df.iloc[1]['median_vram_delta_mib']:.0f} MiB\n"
    f"Execution  {df.iloc[1]['processor_allocation']}\n"
    f"Range  {df.iloc[1]['min_tps']:.2f}–{df.iloc[1]['max_tps']:.2f} tok/s"
)

fig.text(
    0.22,
    0.145,
    left_text,
    ha="left",
    va="center",
    fontsize=9.5,
    linespacing=1.35,
)

fig.text(
    0.62,
    0.145,
    right_text,
    ha="left",
    va="center",
    fontsize=9.5,
    linespacing=1.35,
)


# ============================================================
# Experimental configuration
# ============================================================

ratio = (
    df.iloc[0]["median_tps"]
    / df.iloc[1]["median_tps"]
)

fig.text(
    0.5,
    0.035,
    (
        "Ollama 0.34.4  ·  context 4096  ·  "
        "128 requested tokens  ·  temperature 0  ·  n = 3 runs/model\n"
        f"Observed median throughput ratio: "
        f"Qwen3 1.7B ≈ {ratio:.2f}× Qwen3 4B"
    ),
    ha="center",
    va="bottom",
    fontsize=8.5,
)


# ============================================================
# Layout
# ============================================================

plt.subplots_adjust(
    left=0.10,
    right=0.97,
    top=0.84,
    bottom=0.32,
)


# ============================================================
# Save
# ============================================================

plt.savefig(
    OUTPUT / "figure1_model_performance.png",
    dpi=300,
    bbox_inches="tight",
)

plt.savefig(
    OUTPUT / "figure1_model_performance.pdf",
    bbox_inches="tight",
)

plt.close()

print("Figure 1 created successfully.")