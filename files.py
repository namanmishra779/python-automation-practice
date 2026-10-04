from pathlib import Path

logs = Path("logs")
logs.mkdir(exist_ok=True)

(logs / "app.log").write_text(
    "Started\nFinished\n",
    encoding="utf-8",
)
(logs / "notes.txt").write_text("Not a log file\n", encoding="utf-8")

print("Logs folder exists:", logs.is_dir())

for log_file in logs.glob("*.log"):
    print(log_file.name, "->", log_file.stat().st_size, "bytes")

with open(logs / "app.log", encoding="utf-8") as file:
    for line in file:
        print("read:", line.strip())