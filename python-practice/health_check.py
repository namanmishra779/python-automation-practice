import argparse
import shutil
import time
from pathlib import Path


def check_disk(warn_pct=80):
    mount = Path.cwd().anchor
    total, used, free = shutil.disk_usage(mount)
    used_pct = used / total * 100

    return {
        "mount": mount,
        "used_pct": round(used_pct, 1),
        "status": "WARN" if used_pct > warn_pct else "OK",
    }


def clean_logs(directory, days=7, dry_run=True):
    cutoff = time.time() - days * 86400
    matched = []

    for log_file in Path(directory).glob("*.log"):
        try:
            if log_file.is_file() and log_file.stat().st_mtime < cutoff:
                if dry_run:
                    print(f"would delete: {log_file}")
                else:
                    log_file.unlink()
                    print(f"deleted: {log_file}")

                matched.append(str(log_file))
        except OSError as error:
            print(f"skip {log_file}: {error}")

    return matched


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--days", type=int, default=7)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="actually delete matching log files",
    )
    args = parser.parse_args()

    if args.days < 0:
        parser.error("--days cannot be negative")

    print(check_disk())
    matches = clean_logs("logs", days=args.days, dry_run=not args.apply)
    print("matching logs:", matches)