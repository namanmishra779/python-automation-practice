# Python Automation Practice

A beginner-friendly collection of Python exercises, ending with a disk and log health-check script.

## Lessons

- `hello.py`: strings, printing, and Python types
- `collections_lesson.py`: lists, dictionaries, tuples, sets, and loops
- `functions.py`: defining and calling a function
- `errors.py`: handling a missing file
- `files.py`: creating folders, writing files, and reading logs
- `sysops.py`: copying a file, checking disk space, and running a command
- `cleaner.py`: previewing old log files before cleanup

## Health-check project

`health_check.py` reports disk usage and finds `.log` files older than a chosen number of days in the `logs` folder. It previews matching files by default. Files are only deleted when `--apply` is supplied.

## Run on Windows

From this folder, create a virtual environment:

```powershell
python -m venv .venv
```

Run the health check using the virtual environment's Python:

```powershell
.\.venv\Scripts\python.exe health_check.py
```

Preview all `.log` files, including recently created ones:

```powershell
.\.venv\Scripts\python.exe health_check.py --days 0
```

The preview does not delete files. Only use `--apply` after carefully reviewing the preview and confirming the target folder:

```powershell
.\.venv\Scripts\python.exe health_check.py --days 7 --apply
```

The script uses only Python's standard library, so no third-party packages need to be installed. `requirements.txt` is intentionally empty.