#!/usr/bin/env python3
"""
plot_cycles.py  —  RISC-V Pipeline T-state Visualiser
======================================================
Reads the text output from tb_cycle_tracer.v and produces two figures:

  Figure 1: Pipeline waterfall Gantt chart
            Each instruction is a horizontal bar spanning its T-states.
            Stage bands (IF/ID/EX/MEM/WB) are overlaid.
            Stall cycles shown in red.

  Figure 2: Bar chart — average T-states and stall breakdown per instruction class.

Usage:
  python Scripts/plot_cycles.py trace_output.txt
  python Scripts/plot_cycles.py trace_output.txt --save          # saves PNGs
  python Scripts/plot_cycles.py trace_output.txt --max-instr 40  # show first N
  vvp sim_trace.out +PROG=... | python Scripts/plot_cycles.py -  # pipe mode
"""

import sys
import re
import argparse
import math
import os
from collections import defaultdict

try:
    import matplotlib
    matplotlib.use("TkAgg")          # change to "Agg" if no display available
    import matplotlib.pyplot as plt
    import matplotlib.patches as mpatches
    from matplotlib.patches import FancyBboxPatch
    import numpy as np
except ImportError:
    sys.exit("[ERROR] matplotlib + numpy required:  pip install matplotlib numpy")


# ---------------------------------------------------------------------------
#  Parser
# ---------------------------------------------------------------------------

# Trace line pattern:
# CYC    PC         OP[6:0]   TYPE     T-STATES HAZ    ALU    CACHE
# 4      0x00000000  0110111  LUI       4         0      0      0
_TRACE_RE = re.compile(
    r"^\s*(\d+)\s+"          # cycle
    r"0x([0-9a-fA-F]+)\s+"  # pc (hex without 0x)
    r"([01]+)\s+"            # opcode binary
    r"(\S+)\s+"              # type mnemonic
    r"(\d+)\s+"              # t-states
    r"(\d+)\s+"              # haz stalls
    r"(\d+)\s+"              # alu stalls
    r"(\d+)"                 # cache stalls
)

# Histogram line pattern (summary section):
# R-TYPE            7         28          4          0
_HIST_RE = re.compile(
    r"^(R-TYPE|I-ALU|LOAD|STORE|BRANCH|JAL\s|JALR|LUI|AUIPC|SYSTEM|FP-OP|CUSTOM|OTHER)"
    r"\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)"
)


def parse_trace(lines):
    instrs = []   # list of dicts
    hist   = []   # summary histogram rows
    in_summary = False

    for raw_line in lines:
        line = raw_line.strip()
        if "INSTRUCTION CLASS SUMMARY" in line:
            in_summary = True
            continue
        if in_summary:
            m = _HIST_RE.match(line)
            if m:
                hist.append({
                    "class":   m.group(1).strip(),
                    "count":   int(m.group(2)),
                    "tot_t":   int(m.group(3)),
                    "avg_t":   int(m.group(4)),
                    "tot_stall": int(m.group(5)),
                })
            continue

        m = _TRACE_RE.match(line)
        if m:
            instrs.append({
                "cyc":   int(m.group(1)),
                "pc":    int(m.group(2), 16),
                "op":    m.group(3),
                "type":  m.group(4),
                "t":     int(m.group(5)),
                "haz":   int(m.group(6)),
                "alu":   int(m.group(7)),
                "cache": int(m.group(8)),
            })

    return instrs, hist


# ---------------------------------------------------------------------------
#  Colours
# ---------------------------------------------------------------------------
STAGE_COLORS = {
    "IF":  "#4e79a7",
    "ID":  "#59a14f",
    "EX":  "#f28e2b",
    "MEM": "#e15759",
    "WB":  "#b07aa1",
}
STALL_COLOR   = "#d62728"
BG_COLOR      = "#1a1a2e"
TEXT_COLOR     = "#e0e0e0"
GRID_COLOR     = "#2a2a4a"
BAR_BASE       = "#4e79a7"
BAR_STALL      = "#e15759"
BAR_PERF       = "#59a14f"


# ---------------------------------------------------------------------------
#  Figure 1: Waterfall Gantt chart
# ---------------------------------------------------------------------------

def plot_waterfall(instrs, ax, max_instr=None):
    if max_instr:
        instrs = instrs[:max_instr]
    if not instrs:
        return

    n = len(instrs)
    # Find the earliest issue cycle (retire - t + 1)
    # Each instr: retire at cyc, issued at (cyc - t + 1)
    # Perfect pipeline: 5 stages → IF=issue, ID=issue+1, EX=issue+2, MEM=issue+3, WB=retire

    ax.set_facecolor(BG_COLOR)
    ax.set_title("Pipeline Waterfall — T-state Gantt Chart",
                 color=TEXT_COLOR, fontsize=13, fontweight="bold", pad=10)
    ax.set_xlabel("Clock Cycle", color=TEXT_COLOR, fontsize=10)
    ax.set_ylabel("Instruction (by PC)", color=TEXT_COLOR, fontsize=10)
    ax.tick_params(colors=TEXT_COLOR)
    for spine in ax.spines.values():
        spine.set_edgecolor(GRID_COLOR)

    stages = ["IF", "ID", "EX", "MEM", "WB"]

    y_ticks = []
    y_labels = []

    all_cycles = []

    for idx, instr in enumerate(instrs):
        y = n - 1 - idx            # top to bottom
        retire_cyc = instr["cyc"]
        t_total    = instr["t"]
        issue_cyc  = retire_cyc - t_total + 1

        all_cycles.append(issue_cyc)
        all_cycles.append(retire_cyc)

        # Stall cycles distributed: put stall penalty between EX and WB
        stall_total = t_total - 5
        if stall_total < 0: stall_total = 0

        # Draw perfect 5 stage bands (equal width = 1 cycle each)
        # Stalls are inserted between EX and MEM (or wherever they occur)
        # For display purposes: IF(1), ID(1), EX(1), STALL(n), MEM(1), WB(1)
        stage_cycs = [1, 1, 1, 1 + stall_total, 1]  # stage durations
        c = issue_cyc
        for si, (sname, dur) in enumerate(zip(stages, stage_cycs)):
            color = STAGE_COLORS[sname]
            bar_alpha = 0.85
            # The stall portion within MEM is shown in red
            if sname == "MEM" and stall_total > 0:
                # draw stall first
                ax.barh(y, stall_total, left=c, height=0.6,
                        color=STALL_COLOR, alpha=0.9, edgecolor=BG_COLOR, linewidth=0.5)
                ax.text(c + stall_total / 2, y, f"+{stall_total}",
                        ha="center", va="center", color="white",
                        fontsize=6, fontweight="bold")
                # then MEM
                ax.barh(y, 1, left=c + stall_total, height=0.6,
                        color=color, alpha=bar_alpha,
                        edgecolor=BG_COLOR, linewidth=0.5)
                ax.text(c + stall_total + 0.5, y, sname[:2],
                        ha="center", va="center", color="white",
                        fontsize=5.5, fontweight="bold")
            else:
                ax.barh(y, dur, left=c, height=0.6,
                        color=color, alpha=bar_alpha,
                        edgecolor=BG_COLOR, linewidth=0.5)
                ax.text(c + dur / 2, y, sname[:2],
                        ha="center", va="center", color="white",
                        fontsize=5.5, fontweight="bold")
            c += dur

        y_ticks.append(y)
        y_labels.append(f"PC=0x{instr['pc']:06X}  {instr['type']}")

    ax.set_yticks(y_ticks)
    ax.set_yticklabels(y_labels, fontsize=7.5, color=TEXT_COLOR,
                       fontfamily="monospace")

    if all_cycles:
        ax.set_xlim(min(all_cycles) - 0.5, max(all_cycles) + 2)

    # Vertical grid every cycle
    cyc_range = range(min(all_cycles), max(all_cycles) + 3)
    for c in cyc_range:
        ax.axvline(c, color=GRID_COLOR, linewidth=0.4, zorder=0)

    # Legend
    legend_items = [mpatches.Patch(color=v, label=k) for k, v in STAGE_COLORS.items()]
    legend_items.append(mpatches.Patch(color=STALL_COLOR, label="STALL"))
    ax.legend(handles=legend_items, loc="lower right", fontsize=7,
              facecolor="#2a2a4a", labelcolor=TEXT_COLOR, framealpha=0.8)


# ---------------------------------------------------------------------------
#  Figure 2: Histogram bar chart
# ---------------------------------------------------------------------------

def plot_histogram(hist, instrs, ax1, ax2):
    if not hist:
        # fall back to computing from raw instrs
        summary = defaultdict(lambda: {"count": 0, "tot_t": 0, "tot_stall": 0})
        for ins in instrs:
            s = summary[ins["type"]]
            s["count"]     += 1
            s["tot_t"]     += ins["t"]
            s["tot_stall"] += max(0, ins["t"] - 5)
        hist = [{"class": k, "count": v["count"],
                 "tot_t": v["tot_t"],
                 "avg_t": v["tot_t"] // max(v["count"], 1),
                 "tot_stall": v["tot_stall"]}
                for k, v in summary.items()]

    classes   = [h["class"]           for h in hist]
    avg_ts    = [h["tot_t"] / max(h["count"], 1) for h in hist]
    avg_stall = [h["tot_stall"] / max(h["count"], 1) for h in hist]
    avg_perf  = [max(0, t - s) for t, s in zip(avg_ts, avg_stall)]

    x = np.arange(len(classes))
    w = 0.5

    # Stacked bar: perfect + stall
    ax1.set_facecolor(BG_COLOR)
    ax1.set_title("Average T-States per Instruction Class",
                  color=TEXT_COLOR, fontsize=12, fontweight="bold")
    ax1.set_ylabel("Average T-States (IF→WB)", color=TEXT_COLOR)
    ax1.tick_params(colors=TEXT_COLOR)
    for spine in ax1.spines.values():
        spine.set_edgecolor(GRID_COLOR)
    ax1.yaxis.grid(True, color=GRID_COLOR, linewidth=0.5, zorder=0)

    bars_perf  = ax1.bar(x, avg_perf,  w, label="Pipeline (perfect)",
                          color=BAR_PERF,  alpha=0.85, zorder=3)
    bars_stall = ax1.bar(x, avg_stall, w, bottom=avg_perf, label="Stall overhead",
                          color=BAR_STALL, alpha=0.85, zorder=3)

    # Annotate totals
    for xi, (ap, as_) in enumerate(zip(avg_perf, avg_stall)):
        ax1.text(xi, ap + as_ + 0.05, f"{ap+as_:.1f}",
                 ha="center", va="bottom", color=TEXT_COLOR, fontsize=8,
                 fontweight="bold")

    ax1.axhline(5, color="#aaaaaa", linestyle="--", linewidth=0.8,
                label="Ideal CPI=5 (5-stage)", zorder=2)

    ax1.set_xticks(x)
    ax1.set_xticklabels(classes, rotation=30, ha="right",
                         color=TEXT_COLOR, fontsize=9)
    ax1.legend(fontsize=8, facecolor="#2a2a4a", labelcolor=TEXT_COLOR)

    # Instruction count bar (secondary)
    ax2.set_facecolor(BG_COLOR)
    ax2.set_title("Instruction Count by Class",
                  color=TEXT_COLOR, fontsize=12, fontweight="bold")
    ax2.set_ylabel("# Instructions Retired", color=TEXT_COLOR)
    ax2.tick_params(colors=TEXT_COLOR)
    for spine in ax2.spines.values():
        spine.set_edgecolor(GRID_COLOR)
    ax2.yaxis.grid(True, color=GRID_COLOR, linewidth=0.5, zorder=0)

    counts = [h["count"] for h in hist]
    ax2.bar(x, counts, w, color=BAR_BASE, alpha=0.85, zorder=3)
    for xi, c in enumerate(counts):
        ax2.text(xi, c + 0.05, str(c),
                 ha="center", va="bottom", color=TEXT_COLOR, fontsize=9)
    ax2.set_xticks(x)
    ax2.set_xticklabels(classes, rotation=30, ha="right",
                         color=TEXT_COLOR, fontsize=9)


# ---------------------------------------------------------------------------
#  Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="RISC-V cycle trace visualiser")
    parser.add_argument("trace", nargs="?", default="-",
                        help="trace_output.txt from tb_cycle_tracer (or '-' for stdin)")
    parser.add_argument("--save",      action="store_true",
                        help="Save figures to PNG instead of showing interactively")
    parser.add_argument("--outdir",    type=str, default=".",
                        help="Output directory for saved PNGs")
    parser.add_argument("--max-instr", type=int, default=60,
                        help="Max instructions shown in waterfall (default 60)")
    parser.add_argument("--no-waterfall", action="store_true",
                        help="Skip the waterfall chart (faster for large traces)")
    args = parser.parse_args()

    # Read input
    if args.trace == "-":
        lines = sys.stdin.readlines()
    else:
        try:
            with open(args.trace, "rb") as f:
                raw_bytes = f.read()
            if b'\x00' in raw_bytes:
                lines = raw_bytes.decode('utf-16').splitlines()
            else:
                lines = raw_bytes.decode('utf-8', errors='replace').splitlines()
        except FileNotFoundError:
            sys.exit(f"[ERROR] File not found: {args.trace}")

    instrs, hist = parse_trace(lines)
    if not instrs:
        sys.exit("[ERROR] No trace data found. Run with +PROG=<file>.hex")

    print(f"[PLOT] Parsed {len(instrs)} retired instructions, "
          f"{len(hist)} histogram classes.")

    # ---- Figure 1: Waterfall ----
    plt.style.use("dark_background")

    if not args.no_waterfall:
        n_show = min(args.max_instr, len(instrs))
        fig_h  = max(6, n_show * 0.35 + 2)
        fig1, ax_water = plt.subplots(figsize=(16, fig_h))
        fig1.patch.set_facecolor(BG_COLOR)
        plot_waterfall(instrs, ax_water, max_instr=n_show)
        fig1.tight_layout()
        if args.save:
            outpath = os.path.join(args.outdir, "waterfall.png")
            fig1.savefig(outpath, dpi=150, bbox_inches="tight",
                         facecolor=BG_COLOR)
            print(f"[PLOT] Saved {outpath}")
        else:
            plt.show(block=False)

    # ---- Figure 2: Histogram ----
    fig2, (ax_bar, ax_cnt) = plt.subplots(1, 2, figsize=(14, 5))
    fig2.patch.set_facecolor(BG_COLOR)
    fig2.suptitle("RISC-V Pipeline Performance Summary",
                  color=TEXT_COLOR, fontsize=14, fontweight="bold")
    plot_histogram(hist, instrs, ax_bar, ax_cnt)
    fig2.tight_layout()
    if args.save:
        outpath = os.path.join(args.outdir, "cycle_report.png")
        fig2.savefig(outpath, dpi=150, bbox_inches="tight",
                     facecolor=BG_COLOR)
        print(f"[PLOT] Saved {outpath}")
    else:
        plt.show()


if __name__ == "__main__":
    main()
