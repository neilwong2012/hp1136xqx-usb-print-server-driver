#!/usr/bin/env python3
import argparse
import os
import shutil
import subprocess
from pathlib import Path


def run(*args: str) -> str:
    return subprocess.run(args, check=True, text=True, capture_output=True).stdout


def raw_deps(path: Path) -> list[str]:
    lines = run("otool", "-L", str(path)).splitlines()[1:]
    result: list[str] = []
    for line in lines:
        dep = line.strip().split(" ", 1)[0]
        result.append(dep)
    return result


def search_dirs(homebrew_prefix: Path) -> list[Path]:
    dirs = [homebrew_prefix / "lib"]
    opt = homebrew_prefix / "opt"
    if opt.exists():
        dirs.extend(sorted(path / "lib" for path in opt.iterdir() if (path / "lib").is_dir()))
    return dirs


def resolve_homebrew_dep(dep: str, homebrew_prefix: Path, dirs: list[Path]) -> Path | None:
    if dep.startswith(str(homebrew_prefix) + "/"):
        return Path(dep)
    if dep.startswith("@rpath/"):
        name = dep.split("/", 1)[1]
        for directory in dirs:
            candidate = directory / name
            if candidate.exists():
                return candidate
    return None


def collect(start: Path, homebrew_prefix: Path) -> list[Path]:
    dirs = search_dirs(homebrew_prefix)
    seen: set[str] = set()
    queue = [start]
    ordered: list[Path] = []
    while queue:
        item = queue.pop(0)
        for dep in raw_deps(item):
            resolved = resolve_homebrew_dep(dep, homebrew_prefix, dirs)
            if resolved is None:
                continue
            key = str(resolved.resolve())
            if key not in seen:
                seen.add(key)
                ordered.append(resolved.resolve())
                queue.append(resolved.resolve())
    return ordered


def main() -> None:
    parser = argparse.ArgumentParser(description="Bundle Ghostscript and Homebrew dylib dependencies.")
    parser.add_argument("--gs", required=True, help="Path to Homebrew Ghostscript binary")
    parser.add_argument("--out", required=True, help="Output directory for bundled gs and hp1136libs")
    parser.add_argument("--final-libdir", default="/usr/libexec/cups/filter/hp1136libs")
    parser.add_argument("--homebrew-prefix", default=os.environ.get("HOMEBREW_PREFIX", "/opt/homebrew"))
    args = parser.parse_args()

    gs_src = Path(args.gs)
    out = Path(args.out)
    libdir = out / "hp1136libs"
    gs_out = out / "gs"
    final_libdir = Path(args.final_libdir)
    homebrew_prefix = Path(args.homebrew_prefix)
    dirs = search_dirs(homebrew_prefix)

    if not gs_src.exists():
        raise SystemExit(f"Ghostscript binary not found: {gs_src}")

    if out.exists():
        shutil.rmtree(out)
    libdir.mkdir(parents=True)

    shutil.copy2(gs_src, gs_out)
    os.chmod(gs_out, 0o755)

    by_name: dict[str, Path] = {}
    dep_paths = collect(gs_src, homebrew_prefix)
    for dep in dep_paths:
        name = dep.name
        if name in by_name and by_name[name].resolve() == dep.resolve():
            continue
        if name in by_name and by_name[name] != dep:
            raise SystemExit(f"duplicate dylib basename: {name}: {by_name[name]} and {dep}")
        by_name[name] = dep
        shutil.copy2(dep, libdir / name)
        os.chmod(libdir / name, 0o755)

    all_files = [gs_out] + sorted(libdir.iterdir())
    for target in all_files:
        for dep in raw_deps(target):
            resolved = resolve_homebrew_dep(dep, homebrew_prefix, dirs)
            if resolved is None:
                continue
            subprocess.run(
                [
                    "install_name_tool",
                    "-change",
                    dep,
                    str(final_libdir / resolved.name),
                    str(target),
                ],
                check=True,
            )

    for lib in sorted(libdir.iterdir()):
        subprocess.run(
            ["install_name_tool", "-id", str(final_libdir / lib.name), str(lib)],
            check=True,
        )

    for target in all_files:
        subprocess.run(["codesign", "-f", "-s", "-", str(target)], check=True)

    print(f"bundled {len(dep_paths)} dylibs")


if __name__ == "__main__":
    main()
