def load_config(path):
    try:
        with open(path, encoding="utf-8") as file:
            return file.read()
    except FileNotFoundError:
        print(f"{path} was not found; using defaults")
        return "{}"

config = load_config("settings.json")
print("Config:", config)