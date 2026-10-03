"""Load infra/.env without overriding variables already present in the process."""
import os

_LOADED = False


def load_env(path=None):
    global _LOADED
    if path is None:
        if _LOADED:
            return
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    if not os.path.isfile(path):
        _LOADED = True
        return
    with open(path, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            if line.startswith("export "):
                line = line[7:].strip()
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip()
            if not key or " " in key:
                continue
            if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
                value = value[1:-1]
            os.environ.setdefault(key, value)
    _LOADED = True


def value(name, fallback):
    load_env()
    raw = os.environ.get(name)
    if raw is None or raw.strip() == "":
        return fallback
    return raw.strip()
