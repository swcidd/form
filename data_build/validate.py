#!/usr/bin/env python3
"""Validate the FORM fallback exercise dataset.

Run from the repository root:

    python3 data_build/validate.py

Exits 0 only when every rule below holds. It uses the standard library only so
the check can run in CI without installing anything.
"""

from __future__ import annotations

import json
import os
import re
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
FILES = ["taxonomy.json", "exercises.json", "sources.json", "mapping.json"]

MUSCLE = {
    "chest", "back", "shoulders", "biceps", "triceps", "forearms", "core",
    "quads", "hamstrings", "glutes", "calves", "other",
}
EQUIPMENT = {
    "barbell", "dumbbell", "machine", "cable", "bodyweight", "kettlebell",
    "band", "other",
}
MOVEMENT = {"push", "pull", "legs", "core", "other"}
TYPE = {"strength", "cardio", "mobility"}
MECHANIC = {"compound", "isolation"}
LEVEL = {"beginner", "intermediate", "advanced"}
SPLIT = {"push", "pull", "legs", "upper", "lower", "full_body", "custom"}
GOAL = {"strength", "hypertrophy", "endurance", "power", "general"}
STATUS = {"planned", "in_progress", "completed", "skipped"}
SOURCES = {"wger", "free-exercise-db", "exercemus"}
EVIDENCE = {"convention", "research-supported", "disputed"}

errors: list[str] = []


def fail(message: str) -> None:
    errors.append(message)


def check(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def load(name: str):
    path = os.path.join(HERE, name)
    try:
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)
    except Exception as exc:  # noqa: BLE001 - report the file, not a trace
        fail(f"{name}: cannot parse: {exc}")
        return None


def norm_name(value: str) -> str:
    value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode()
    value = value.lower().replace("&", " and ")
    value = re.sub(r"['\u2019]", "", value)
    value = re.sub(r"[^a-z0-9]+", " ", value)
    words = []
    for word in value.split():
        if len(word) > 3 and word.endswith("ies"):
            word = word[:-3] + "y"
        elif len(word) > 4 and word.endswith("ses"):
            word = word[:-2]
        elif len(word) > 3 and word.endswith("s") and not word.endswith(("ss", "us", "is")):
            word = word[:-1]
        words.append(word)
    return " ".join(words)


def check_sorted_unique(values, allowed, label: str) -> None:
    check(isinstance(values, list), f"{label}: not a list")
    if not isinstance(values, list):
        return
    check(all(isinstance(v, str) for v in values), f"{label}: non-string value")
    check(len(values) == len(set(values)), f"{label}: duplicate value")
    check(values == sorted(values), f"{label}: not sorted")
    for value in values:
        check(value in allowed, f"{label}: unknown value {value!r}")


def main() -> int:
    taxonomy = load("taxonomy.json")
    exercises = load("exercises.json")
    sources = load("sources.json")
    mapping = load("mapping.json")

    # ---------------------------------------------------------------- taxonomy
    if taxonomy:
        check(taxonomy.get("schema_version") == "1.0", "taxonomy: schema_version")
        for key, allowed in (
            ("muscle", MUSCLE), ("equipment", EQUIPMENT), ("movement", MOVEMENT),
            ("type", TYPE), ("mechanic", MECHANIC), ("level", LEVEL),
        ):
            block = taxonomy.get(key)
            check(isinstance(block, list), f"taxonomy.{key}: missing list")
            values = {item.get("value") for item in block} if isinstance(block, list) else set()
            check(values == allowed, f"taxonomy.{key}: values differ from the controlled vocabulary")
            for item in block if isinstance(block, list) else []:
                check(item.get("display_label"), f"taxonomy.{key}.{item.get('value')}: display_label")
        workout = taxonomy.get("workout") or {}
        for key, allowed in (("split", SPLIT), ("goal", GOAL), ("status", STATUS)):
            block = workout.get(key)
            check(isinstance(block, list), f"taxonomy.workout.{key}: missing list")
            values = {item.get("value") for item in block} if isinstance(block, list) else set()
            check(values == allowed, f"taxonomy.workout.{key}: values differ")
            for item in block if isinstance(block, list) else []:
                check(item.get("display_label"), f"taxonomy.workout.{key}.{item.get('value')}: label")
                definition = (item.get("definition") or "").strip()
                check(definition.endswith("."), f"taxonomy.workout.{key}.{item.get('value')}: definition")
                check(item.get("evidence") in EVIDENCE,
                      f"taxonomy.workout.{key}.{item.get('value')}: evidence label")
                check(not re.search(r"\b\d+\s*(?:-\s*\d+)?\s*(?:reps?|sets?)\b", definition, re.I),
                      f"taxonomy.workout.{key}.{item.get('value')}: definition states reps or sets")

    # ---------------------------------------------------------------- sources
    source_entries = (sources or {}).get("sources") or []
    check({entry.get("name") for entry in source_entries} == SOURCES,
          "sources: must contain exactly wger, free-exercise-db and exercemus")
    counts: dict[str, int] = {}
    for entry in source_entries:
        name = entry.get("name")
        for field in ("url", "license", "license_url", "attribution_text", "retrieved_at"):
            check(isinstance(entry.get(field), str) and entry[field].strip(),
                  f"sources.{name}: {field} missing")
        check(isinstance(entry.get("record_count"), int) and entry["record_count"] >= 0,
              f"sources.{name}: record_count")
        counts[name] = entry.get("record_count", 0)

    # ---------------------------------------------------------------- mapping
    source_map = (mapping or {}).get("sources") or {}
    check(set(source_map) == SOURCES, "mapping: missing a source")
    for name in SOURCES:
        block = source_map.get(name) or {}
        for kind, allowed in (("muscle", MUSCLE), ("equipment", EQUIPMENT), ("category", TYPE)):
            table = block.get(kind)
            check(isinstance(table, dict), f"mapping.{name}.{kind}: missing object")
            for raw, target in (table or {}).items():
                check(isinstance(raw, str) and raw, f"mapping.{name}.{kind}: empty source value")
                check(target in allowed,
                      f"mapping.{name}.{kind}: {raw!r} -> {target!r} is outside the taxonomy")

    # ---------------------------------------------------------------- records
    if exercises:
        check(exercises.get("schema_version") == "1.0", "exercises: schema_version")
        check(isinstance(exercises.get("data_version"), str) and exercises["data_version"],
              "exercises: data_version")
        records = exercises.get("exercises")
        check(isinstance(records, list), "exercises: missing list")
        if not isinstance(records, list):
            records = []

        ids: set[str] = set()
        keys: dict[str, str] = {}
        provenance_counts = {name: 0 for name in SOURCES}
        for index, record in enumerate(records):
            rid = record.get("id", f"#{index}")
            check(isinstance(rid, str) and re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", rid) is not None,
                  f"{rid}: id is not a lowercase hyphenated slug")
            check(rid not in ids, f"{rid}: duplicate id")
            ids.add(rid)

            name = record.get("name")
            check(isinstance(name, str) and name.strip(), f"{rid}: name")
            check(isinstance(record.get("aliases"), list), f"{rid}: aliases")
            aliases = record.get("aliases") or []
            check(all(isinstance(a, str) and a.strip() for a in aliases), f"{rid}: alias value")
            check(len(aliases) == len(set(aliases)), f"{rid}: duplicate alias")

            primary = record.get("primary_muscles")
            secondary = record.get("secondary_muscles")
            equipment = record.get("equipment")
            check_sorted_unique(primary, MUSCLE, f"{rid}.primary_muscles")
            check_sorted_unique(secondary, MUSCLE, f"{rid}.secondary_muscles")
            check_sorted_unique(equipment, EQUIPMENT, f"{rid}.equipment")
            check(bool(primary), f"{rid}: primary_muscles is empty")
            check(bool(equipment), f"{rid}: equipment is empty")

            check(record.get("movement") in MOVEMENT, f"{rid}: movement")
            check(record.get("type") in TYPE, f"{rid}: type")
            check(record.get("mechanic") is None or record.get("mechanic") in MECHANIC,
                  f"{rid}: mechanic")
            check(record.get("level") is None or record.get("level") in LEVEL,
                  f"{rid}: level")

            instructions = record.get("instructions")
            if instructions is not None:
                check(isinstance(instructions, list), f"{rid}: instructions")
                instructions = instructions if isinstance(instructions, list) else []
                check(0 < len(instructions) <= 6, f"{rid}: instructions must have 1-6 steps")
                for step in instructions:
                    check(isinstance(step, str) and step.strip(), f"{rid}: empty step")
                    check(len(step.split()) <= 40, f"{rid}: step longer than 40 words")
                    check(not re.search(r"\b(?:calorie|calories|injur\w*|medical|doctor|diagnos\w*)\b",
                                        step, re.I),
                          f"{rid}: step contains excluded medical/calorie content")

            provenance = record.get("provenance")
            check(isinstance(provenance, list) and provenance, f"{rid}: no provenance")
            for entry in provenance if isinstance(provenance, list) else []:
                src = entry.get("source")
                check(src in SOURCES, f"{rid}: provenance source {src!r}")
                check(isinstance(entry.get("source_id"), str) and entry["source_id"],
                      f"{rid}: provenance source_id")
                check(isinstance(entry.get("license"), str) and entry["license"].strip(),
                      f"{rid}: provenance license")
                check(entry.get("author") is None or
                      (isinstance(entry.get("author"), str) and entry["author"].strip()),
                      f"{rid}: provenance author")
                check(isinstance(entry.get("license_url"), str) and
                      entry["license_url"].startswith(("http://", "https://")),
                      f"{rid}: provenance license_url")
                if src in provenance_counts:
                    provenance_counts[src] += 1
                if "SA" in (entry.get("license") or "") or "Share Alike" in (entry.get("license") or ""):
                    check(entry.get("share_alike") is True,
                          f"{rid}: share-alike license without share_alike flag")
                    check(entry.get("author"), f"{rid}: share-alike record has no author")
                else:
                    check(entry.get("share_alike") is not True,
                          f"{rid}: share_alike set on a non-share-alike license")

            key = f"{norm_name(name)}|{','.join(equipment)}"
            check(key not in keys, f"{rid}: duplicate of {keys.get(key)} by name+equipment")
            keys[key] = rid

        for name in SOURCES:
            check(counts.get(name) == provenance_counts[name],
                  f"sources.{name}.record_count is {counts.get(name)}, provenance has {provenance_counts[name]}")

    # ---------------------------------------------------------------- files
    for name in FILES + ["validate.py", "report.md"]:
        path = os.path.join(HERE, name)
        check(os.path.isfile(path), f"{name}: missing")
        if os.path.isfile(path):
            raw = open(path, "rb").read()
            check(b"\r" not in raw, f"{name}: not LF-only")
            try:
                text = raw.decode("utf-8")
            except UnicodeDecodeError:
                fail(f"{name}: not UTF-8")
                continue
            for number, line in enumerate(text.split("\n"), 1):
                check(line == line.rstrip(), f"{name}:{number}: trailing whitespace")

    if errors:
        print(f"FAIL ({len(errors)} problem{'s' if len(errors) != 1 else ''})")
        for message in errors:
            print(f"  - {message}")
        return 1

    print("PASS")
    print(f"  records: {len(exercises['exercises'])}")
    print(f"  provenance: {counts}")
    for name in FILES + ["validate.py"]:
        print(f"  {name}: {os.path.getsize(os.path.join(HERE, name))} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
