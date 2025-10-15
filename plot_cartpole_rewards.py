import argparse
import csv
import glob
import os
import re
import sys

try:
    import matplotlib  # type: ignore
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt  # type: ignore
    HAS_MPL = True
except Exception:
    HAS_MPL = False


def find_latest_log() -> str:
    candidates = sorted(glob.glob(os.path.join("logs_*", "run_cartpole_with_reward.log")))
    return candidates[-1] if candidates else ""


def parse_rewards(path: str):
    # Detect encoding: PowerShell Tee-Object writes UTF-16 LE on Windows
    with open(path, "rb") as f:
        raw = f.read()
    
    # Check for UTF-16 LE BOM
    if raw.startswith(b'\xff\xfe'):
        text = raw.decode("utf-16-le", errors="replace")
    else:
        text = raw.decode("utf-8", errors="replace")
    
    # First pass: regex over whole file for robustness
    pat = re.compile(r"(\d+)\s*:\s*cumulative\s+rewards\s*([-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)")
    matches = pat.findall(text)
    rewards = [(int(ep), float(val)) for ep, val in matches]
    if rewards:
        rewards.sort(key=lambda t: t[0])
        return rewards

    # Fallback: scan lines and split without regex (handles odd unicode/ansi artifacts)
    out = []
    for line in text.split("\n"):
        if "cumulative rewards" in line:
            # Try to split around the first colon
            try:
                left, right = line.split(":", 1)
                ep_s = ''.join(ch for ch in left if ch.isdigit())
                # Extract the last number on the right side
                tokens = re.findall(r"[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?", right)
                if ep_s and tokens:
                    out.append((int(ep_s), float(tokens[-1])))
            except Exception:
                continue
    out.sort(key=lambda t: t[0])
    return out


def main():
    parser = argparse.ArgumentParser(description="Plot CartPole cumulative rewards from log file")
    parser.add_argument("--log", dest="log_path", type=str, default=None, help="Path to run_cartpole_with_reward.log")
    parser.add_argument("--out", dest="out_png", type=str, default="cartpole_rewards.png", help="Output PNG path")
    parser.add_argument("--csv", dest="out_csv", type=str, default="cartpole_rewards.csv", help="Output CSV path")
    args = parser.parse_args()

    log_path = args.log_path or find_latest_log()
    if not log_path or not os.path.exists(log_path):
        print("Could not find log file. Provide via --log <path>.")
        sys.exit(1)

    rewards = parse_rewards(log_path)
    if not rewards:
        print(f"No rewards found in log: {log_path}")
        sys.exit(2)

    # Save CSV
    with open(args.out_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["episode", "cumulative_reward"]) 
        for ep, r in rewards:
            w.writerow([ep, r])

    # Always write a lightweight SVG (no external deps)
    def write_svg(points, out_path: str):
        width, height = 960, 480
        margin = 50
        xs = [p[0] for p in points]
        ys = [p[1] for p in points]
        min_x, max_x = min(xs), max(xs)
        min_y, max_y = min(ys), max(ys)
        if max_x == min_x:
            max_x = min_x + 1
        if max_y == min_y:
            max_y = min_y + 1
        def sx(x):
            return margin + (x - min_x) * (width - 2 * margin) / (max_x - min_x)
        def sy(y):
            # SVG y grows downward
            return height - margin - (y - min_y) * (height - 2 * margin) / (max_y - min_y)
        poly = " ".join(f"{sx(x):.2f},{sy(y):.2f}" for x, y in points)
        # simple axes
        x0, y0 = margin, height - margin
        x1, y1 = width - margin, margin
        svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}">
  <rect x="0" y="0" width="{width}" height="{height}" fill="#ffffff"/>
  <line x1="{x0}" y1="{y0}" x2="{x1}" y2="{y0}" stroke="#333" stroke-width="1"/>
  <line x1="{x0}" y1="{y0}" x2="{x0}" y2="{y1}" stroke="#333" stroke-width="1"/>
  <polyline fill="none" stroke="#1f77b4" stroke-width="2" points="{poly}"/>
  <text x="{width/2:.0f}" y="20" text-anchor="middle" font-family="Arial" font-size="16">CartPole Cumulative Rewards per Episode</text>
  <text x="{width/2:.0f}" y="{height-10}" text-anchor="middle" font-family="Arial" font-size="12">Episode</text>
  <text x="15" y="{height/2:.0f}" transform="rotate(-90, 15, {height/2:.0f})" text-anchor="middle" font-family="Arial" font-size="12">Cumulative Reward</text>
</svg>'''
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(svg)

    svg_out = os.path.splitext(args.out_png)[0] + ".svg"
    write_svg(rewards, svg_out)

    # If matplotlib is available, also write PNG
    if HAS_MPL:
        episodes, values = zip(*rewards)
        plt.figure(figsize=(10, 5))
        plt.plot(episodes, values, marker="o", linewidth=1)
        plt.xlabel("Episode")
        plt.ylabel("Cumulative Reward")
        plt.title("CartPole Cumulative Rewards per Episode")
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(args.out_png, dpi=150)
        print(f"Wrote {len(rewards)} rows to {args.out_csv}, SVG to {svg_out}, and PNG to {args.out_png} from {log_path}")
    else:
        print(f"Wrote {len(rewards)} rows to {args.out_csv} and SVG to {svg_out} (matplotlib not available) from {log_path}")


if __name__ == "__main__":
    main()
