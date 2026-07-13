#!/usr/bin/env python3
import json
import re
import sys


def slug(value, limit):
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")[:limit]


def main():
    if len(sys.argv) != 3:
        return 2

    path, profile = sys.argv[1:]
    with open(path, encoding="utf-8") as stream:
        document = json.load(stream)

    metrics = []
    used = set()
    for result in document.get("results", {}).values():
        description = result.get("description") or result.get("title") or "result"
        description_slug = slug(description, 48) or "result"
        for value_entry in result.get("results", {}).values():
            value = value_entry.get("value")
            if not isinstance(value, (int, float)) or isinstance(value, bool):
                continue
            base = f"pts-{profile}-{description_slug}"[:90].rstrip("-")
            name = base
            suffix = 2
            while name in used:
                tail = f"-{suffix}"
                name = base[: 90 - len(tail)].rstrip("-") + tail
                suffix += 1
            used.add(name)
            units = re.sub(
                r"[^a-zA-Z0-9%./_-]+", "-", result.get("scale") or "score"
            ).strip("-") or "score"
            metrics.append((name, value, units))

    for metric in metrics:
        print(*metric, sep="\t")
    return 0 if metrics else 1


if __name__ == "__main__":
    sys.exit(main())
