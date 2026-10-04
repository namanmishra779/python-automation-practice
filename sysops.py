from pathlib import Path
import shutil
import subprocess

log_file = Path("logs") / "app.log"
shutil.copy(log_file, "logs/app.log.bak")
print("Created backup: logs/app.log.bak")

disk = shutil.disk_usage(Path.cwd().anchor)
used_percent = disk.used / disk.total * 100
free_gib = disk.free / (1024 ** 3)
print(f"Disk: {used_percent:.1f}% used, {free_gib:.1f} GiB free")

result = subprocess.run(
    ["python", "--version"],
    capture_output=True,
    text=True,
    check=True,
)
print("Python:", (result.stdout or result.stderr).strip())
print("Exit code:", result.returncode)