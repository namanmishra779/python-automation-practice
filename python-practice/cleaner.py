from pathlib import Path
import time


def clean_logs(directory, days=7, dry_run=True):
    cutoff = time.time() - days * 86400

    for log_file in Path(directory).glob("*.log"):
        try:
            if log_file.stat().st_mtime < cutoff:
                action = "would delete" if dry_run else "deleted"

                if not dry_run:
                    log_file.unlink()

                print(f"{action}: {log_file}")
        except OSError as error:
            print(f"skip {log_file}: {error}")


if __name__ == "__main__":
    clean_logs("logs", days=0, dry_run=True)