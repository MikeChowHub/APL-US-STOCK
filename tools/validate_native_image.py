#!/usr/bin/env python3
"""Read-only validator for one Native Image Artifact Contract v2 record."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import math
import re
import struct
import sys
from pathlib import Path
from typing import Any


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
REQUIRED_FIELDS = {
    "artifact_type",
    "native_size",
    "aspect_ratio",
    "tolerance",
    "source_sha256",
    "provider",
    "workflow",
    "generation_time",
    "capture_stage",
    "transformation",
}
ROLE_POLICY = {
    "cover": ("4:5", 4.0 / 5.0, "portrait"),
    "seo": ("16:9", 16.0 / 9.0, "landscape"),
}
SHA256_RE = re.compile(r"^[0-9A-F]{64}$")


class ValidationError(Exception):
    """Expected fail-closed validation error."""


def require_nonempty_string(value: Any, name: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValidationError(f"{name} must be a non-empty string")
    return value


def require_positive_integer(value: Any, name: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise ValidationError(f"{name} must be a positive integer")
    return value


def read_png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as stream:
        header = stream.read(24)
    if len(header) != 24 or header[:8] != PNG_SIGNATURE:
        raise ValidationError("image is not a valid PNG header")
    chunk_length = struct.unpack(">I", header[8:12])[0]
    if header[12:16] != b"IHDR" or chunk_length != 13:
        raise ValidationError("PNG does not begin with a valid IHDR chunk")
    width, height = struct.unpack(">II", header[16:24])
    return require_positive_integer(width, "decoded width"), require_positive_integer(
        height, "decoded height"
    )


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def validate_generation_time(value: Any) -> None:
    text = require_nonempty_string(value, "generation_time")
    normalized = text[:-1] + "+00:00" if text.endswith("Z") else text
    try:
        parsed = dt.datetime.fromisoformat(normalized)
    except ValueError as exc:
        raise ValidationError("generation_time must be an ISO-8601 date-time") from exc
    if parsed.tzinfo is None:
        raise ValidationError("generation_time must include a UTC offset")


def validate_contract(image_path: Path, contract_path: Path) -> dict[str, Any]:
    if not image_path.is_file():
        raise ValidationError(f"image file does not exist: {image_path}")
    if not contract_path.is_file():
        raise ValidationError(f"contract file does not exist: {contract_path}")
    if image_path.stat().st_size <= 0:
        raise ValidationError("image file is empty")

    try:
        with contract_path.open("r", encoding="utf-8") as stream:
            contract = json.load(stream)
    except (UnicodeError, json.JSONDecodeError) as exc:
        raise ValidationError(f"contract is not valid UTF-8 JSON: {exc}") from exc

    if not isinstance(contract, dict):
        raise ValidationError("contract root must be an object")
    missing = REQUIRED_FIELDS - set(contract)
    extra = set(contract) - REQUIRED_FIELDS
    if missing:
        raise ValidationError(f"contract missing fields: {', '.join(sorted(missing))}")
    if extra:
        raise ValidationError(f"contract contains unsupported fields: {', '.join(sorted(extra))}")

    artifact_type = contract["artifact_type"]
    if artifact_type not in ROLE_POLICY:
        raise ValidationError("artifact_type must be cover or seo")
    expected_ratio_name, target_ratio, orientation = ROLE_POLICY[artifact_type]
    if contract["aspect_ratio"] != expected_ratio_name:
        raise ValidationError(
            f"aspect_ratio must be {expected_ratio_name} for {artifact_type}"
        )
    tolerance = contract["tolerance"]
    if isinstance(tolerance, bool) or not isinstance(tolerance, (int, float)):
        raise ValidationError("tolerance must be numeric")
    if not math.isclose(float(tolerance), 0.001, rel_tol=0.0, abs_tol=1e-12):
        raise ValidationError("tolerance must be exactly 0.001")
    if contract["transformation"] != "none":
        raise ValidationError("transformation must be none; transformed assets are forbidden")

    native_size = contract["native_size"]
    if not isinstance(native_size, dict) or set(native_size) != {"width", "height"}:
        raise ValidationError("native_size must contain only width and height")
    declared_width = require_positive_integer(native_size["width"], "native_size.width")
    declared_height = require_positive_integer(native_size["height"], "native_size.height")

    require_nonempty_string(contract["provider"], "provider")
    require_nonempty_string(contract["workflow"], "workflow")
    validate_generation_time(contract["generation_time"])
    if contract["capture_stage"] != "ImmediateGenerationOutput":
        raise ValidationError("capture_stage must be ImmediateGenerationOutput")
    declared_sha = contract["source_sha256"]
    if not isinstance(declared_sha, str) or not SHA256_RE.fullmatch(declared_sha):
        raise ValidationError("source_sha256 must be 64 uppercase hexadecimal characters")

    size_before = image_path.stat().st_size
    sha_before = sha256_file(image_path)
    actual_width, actual_height = read_png_dimensions(image_path)
    if (declared_width, declared_height) != (actual_width, actual_height):
        raise ValidationError(
            "dimension mismatch: "
            f"declared={declared_width}x{declared_height} "
            f"actual={actual_width}x{actual_height}"
        )
    if declared_sha != sha_before:
        raise ValidationError("source_sha256 mismatch")

    actual_ratio = actual_width / actual_height
    difference = abs(actual_ratio - target_ratio)
    if difference > float(tolerance):
        raise ValidationError(
            f"aspect ratio mismatch: actual={actual_ratio:.9f} "
            f"target={target_ratio:.9f} difference={difference:.9f}"
        )
    if orientation == "portrait" and actual_width >= actual_height:
        raise ValidationError("cover must be portrait")
    if orientation == "landscape" and actual_width <= actual_height:
        raise ValidationError("seo must be landscape")

    size_after = image_path.stat().st_size
    sha_after = sha256_file(image_path)
    if size_before != size_after or sha_before != sha_after:
        raise ValidationError("image changed during validation")

    return {
        "status": "PASS",
        "artifact_type": artifact_type,
        "width": actual_width,
        "height": actual_height,
        "actual_ratio": round(actual_ratio, 9),
        "target_ratio": round(target_ratio, 9),
        "difference": round(difference, 9),
        "tolerance": float(tolerance),
        "source_sha256": sha_before,
        "transformation": "none",
        "mutated": False,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate one Native Image Artifact Contract v2 without modifying it."
    )
    parser.add_argument("image_file", type=Path)
    parser.add_argument("artifact_contract", type=Path)
    args = parser.parse_args()
    try:
        result = validate_contract(args.image_file, args.artifact_contract)
    except ValidationError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1
    except OSError as exc:
        print(f"FAIL: file access error: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
