#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "httpx>=0.27",
#   "rich>=13",
# ]
# ///
"""CLI tool manager - install and update tools via GitHub Releases or official installers."""

import argparse
import copy
import gzip
import json
import os
import platform
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterator

import httpx
from rich.console import Console
from rich.table import Table

BIN_DIR = Path(os.environ.get("XDG_BIN_HOME", Path.home() / ".local" / "bin"))
OPT_DIR = Path.home() / ".local" / "opt"
TOOLS_JSON = Path(__file__).parent / "tools.json"

console = Console()


@dataclass
class ToolSpec:
    name: str
    bin: str
    type: str  # "github_release" | "installer"
    version: str = "latest"
    version_cmd: list[str] = field(default_factory=list)
    version_regex: str = r"(\S+)"
    # github_release 専用
    repo: str = ""
    platforms: dict[str, str] = field(default_factory=dict)
    extract: str = "raw_binary"
    opt_dir: str = ""
    bin_path_in_archive: str = ""
    # installer 専用
    url: str = ""

    @classmethod
    def from_dict(cls, d: dict) -> "ToolSpec":
        known = {f for f in cls.__dataclass_fields__}
        return cls(**{k: v for k, v in d.items() if k in known})


def load_tools(path: Path = TOOLS_JSON) -> list[ToolSpec]:
    data = json.loads(path.read_text())
    return [ToolSpec.from_dict(t) for t in data["tools"]]


def detect_platform() -> str:
    os_name = platform.system().lower()
    machine = platform.machine().lower()
    if machine == "aarch64":
        machine = "arm64"
    return f"{os_name}-{machine}"


def get_installed_version(spec: ToolSpec) -> str | None:
    if not spec.version_cmd:
        return "installed" if shutil.which(spec.bin) else None
    try:
        out = subprocess.check_output(
            spec.version_cmd, stderr=subprocess.STDOUT, text=True
        )
        m = re.search(spec.version_regex, out)
        return m.group(1) if m else "unknown"
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None


def _github_headers() -> dict[str, str]:
    headers: dict[str, str] = {"Accept": "application/vnd.github+json"}
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def get_latest_tag(spec: ToolSpec, client: httpx.Client) -> str:
    if spec.version not in ("latest", "nightly"):
        return spec.version
    if spec.version == "nightly":
        return "nightly"
    url = f"https://api.github.com/repos/{spec.repo}/releases/latest"
    resp = client.get(url, headers=_github_headers())
    resp.raise_for_status()
    return resp.json()["tag_name"]


def _render_asset(template: str, tag: str) -> str:
    version = tag.lstrip("v")
    return template.replace("{tag}", tag).replace("{version}", version)


def resolve_asset_url(spec: ToolSpec, tag: str) -> str:
    plat = detect_platform()
    template = spec.platforms.get(plat)
    if template is None:
        raise RuntimeError(f"{spec.name}: no asset for platform '{plat}'")
    asset = _render_asset(template, tag)
    base = f"https://github.com/{spec.repo}/releases/download/{tag}"
    return f"{base}/{asset}"


def _download(url: str, dest: Path, client: httpx.Client) -> None:
    with client.stream("GET", url) as resp:
        resp.raise_for_status()
        dest.write_bytes(resp.read())


def _strip_top_component(members: list[tarfile.TarInfo]) -> Iterator[tarfile.TarInfo]:
    for m in members:
        parts = Path(m.name).parts
        if len(parts) <= 1:
            continue
        m2 = copy.copy(m)
        m2.name = str(Path(*parts[1:]))
        yield m2


def _extract_binary_from_tar(
    archive: Path, bin_name: str, dest: Path, xz: bool = False
) -> None:
    opener = tarfile.open(archive, "r:xz") if xz else tarfile.open(archive, "r:gz")
    with opener as tf:
        for member in tf.getmembers():
            if Path(member.name).name == bin_name and member.isfile():
                member_copy = copy.copy(member)
                member_copy.name = bin_name
                tf.extract(member_copy, dest, filter="data")
                return
    raise FileNotFoundError(f"{bin_name} not found in {archive}")


def _install_tar(spec: ToolSpec, url: str, client: httpx.Client) -> None:
    opt_dir = Path(spec.opt_dir).expanduser()
    backup = opt_dir.with_name(opt_dir.name + ".bak")

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir) / "archive.tar.gz"
        console.print(f"  Downloading {url}")
        _download(url, tmp_path, client)

        if opt_dir.exists():
            opt_dir.rename(backup)
        opt_dir.mkdir(parents=True, exist_ok=True)

        try:
            with tarfile.open(tmp_path, "r:gz") as tf:
                tf.extractall(
                    opt_dir,
                    members=list(_strip_top_component(tf.getmembers())),
                    filter="data",
                )
        except Exception:
            if backup.exists():
                shutil.rmtree(opt_dir, ignore_errors=True)
                backup.rename(opt_dir)
            raise

        if backup.exists():
            shutil.rmtree(backup)

    BIN_DIR.mkdir(parents=True, exist_ok=True)
    bin_source = opt_dir / spec.bin_path_in_archive
    bin_link = BIN_DIR / spec.bin
    bin_link.unlink(missing_ok=True)
    bin_link.symlink_to(bin_source)


def _install_tar_binary(
    spec: ToolSpec, url: str, client: httpx.Client, xz: bool = False
) -> None:
    suffix = ".tar.xz" if xz else ".tar.gz"
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir) / f"archive{suffix}"
        console.print(f"  Downloading {url}")
        _download(url, tmp_path, client)

        BIN_DIR.mkdir(parents=True, exist_ok=True)
        _extract_binary_from_tar(tmp_path, spec.bin, BIN_DIR, xz=xz)

    dest = BIN_DIR / spec.bin
    dest.chmod(dest.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def _install_gz_binary(spec: ToolSpec, url: str, client: httpx.Client) -> None:
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_gz = Path(tmpdir) / "archive.gz"
        console.print(f"  Downloading {url}")
        _download(url, tmp_gz, client)

        BIN_DIR.mkdir(parents=True, exist_ok=True)
        dest = BIN_DIR / spec.bin
        with gzip.open(tmp_gz, "rb") as gz_in:
            dest.write_bytes(gz_in.read())

    dest.chmod(dest.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def _install_zip_binary(spec: ToolSpec, url: str, client: httpx.Client) -> None:
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_zip = Path(tmpdir) / "archive.zip"
        console.print(f"  Downloading {url}")
        _download(url, tmp_zip, client)

        BIN_DIR.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(tmp_zip) as zf:
            for info in zf.infolist():
                if Path(info.filename).name == spec.bin and not info.is_dir():
                    data = zf.read(info.filename)
                    dest = BIN_DIR / spec.bin
                    dest.write_bytes(data)
                    dest.chmod(
                        dest.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH
                    )
                    return
    raise FileNotFoundError(f"{spec.bin} not found in zip archive")


def _install_raw_binary(spec: ToolSpec, url: str, client: httpx.Client) -> None:
    BIN_DIR.mkdir(parents=True, exist_ok=True)
    dest = BIN_DIR / spec.bin
    console.print(f"  Downloading {url}")
    _download(url, dest, client)
    dest.chmod(dest.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def _install_github_release(spec: ToolSpec, client: httpx.Client) -> None:
    tag = get_latest_tag(spec, client)
    url = resolve_asset_url(spec, tag)
    match spec.extract:
        case "tar":
            _install_tar(spec, url, client)
        case "tar_binary":
            _install_tar_binary(spec, url, client)
        case "tar_xz_binary":
            _install_tar_binary(spec, url, client, xz=True)
        case "gz_binary":
            _install_gz_binary(spec, url, client)
        case "zip_binary":
            _install_zip_binary(spec, url, client)
        case "raw_binary":
            _install_raw_binary(spec, url, client)
        case _:
            raise ValueError(f"Unknown extract type: {spec.extract}")


def _install_installer(spec: ToolSpec) -> None:
    console.print(f"  Running installer from {spec.url}")
    subprocess.run(
        f"curl -fsSL {shlex.quote(spec.url)} | sh",
        shell=True,
        check=True,
    )


def do_install(spec: ToolSpec, client: httpx.Client) -> None:
    console.print(f"[bold cyan]Installing {spec.name}[/bold cyan]")
    try:
        match spec.type:
            case "github_release":
                _install_github_release(spec, client)
            case "installer":
                _install_installer(spec)
            case _:
                raise ValueError(f"Unknown type: {spec.type}")
        console.print(f"  [green]Done.[/green] {get_installed_version(spec) or ''}")
    except Exception as e:
        console.print(f"  [red]Failed: {e}[/red]")


def cmd_install(
    tools: list[ToolSpec], target: str | None, client: httpx.Client
) -> None:
    targets = [t for t in tools if target is None or t.name == target]
    if not targets:
        console.print(f"[red]Tool not found: {target}[/red]")
        sys.exit(1)
    for spec in targets:
        installed = get_installed_version(spec)
        if installed is not None and target is None:
            console.print(
                f"[dim]  {spec.name}: already installed ({installed}), skipping[/dim]"
            )
            continue
        do_install(spec, client)


def cmd_update(tools: list[ToolSpec], target: str | None, client: httpx.Client) -> None:
    targets = [t for t in tools if target is None or t.name == target]
    if not targets:
        console.print(f"[red]Tool not found: {target}[/red]")
        sys.exit(1)
    for spec in targets:
        do_install(spec, client)


def cmd_list(tools: list[ToolSpec]) -> None:
    table = Table(title="Managed Tools")
    table.add_column("Name", style="cyan")
    table.add_column("Bin")
    table.add_column("Type")
    table.add_column("Version Config")
    table.add_column("Installed")

    for spec in tools:
        installed = get_installed_version(spec)
        installed_str = installed if installed else "[red]not installed[/red]"
        table.add_row(spec.name, spec.bin, spec.type, spec.version, installed_str)

    console.print(table)


def cmd_check(tools: list[ToolSpec], client: httpx.Client) -> None:
    table = Table(title="Version Check")
    table.add_column("Name", style="cyan")
    table.add_column("Installed")
    table.add_column("Latest")
    table.add_column("Status")

    for spec in tools:
        installed = get_installed_version(spec)
        installed_str = installed or "[red]not installed[/red]"

        if spec.type == "installer":
            table.add_row(spec.name, installed_str, "-", "[dim]installer[/dim]")
            continue

        if spec.version == "nightly":
            table.add_row(
                spec.name, installed_str, "nightly", "[dim]always latest[/dim]"
            )
            continue

        try:
            tag = get_latest_tag(spec, client)
            latest = tag.lstrip("v")
        except Exception as e:
            table.add_row(spec.name, installed_str, f"[red]error: {e}[/red]", "")
            continue

        if installed is None:
            status = "[red]not installed[/red]"
        elif installed == latest or installed.lstrip("v") == latest:
            status = "[green]up-to-date[/green]"
        else:
            status = "[yellow]outdated[/yellow]"

        table.add_row(spec.name, installed_str, latest, status)

    console.print(table)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="CLI tool manager - install/update tools via GitHub Releases or official installers"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    p_install = subparsers.add_parser(
        "install", help="Install tools (skip if already installed)"
    )
    p_install.add_argument("tool", nargs="?", help="Tool name (default: all)")

    p_update = subparsers.add_parser("update", help="Update tools to latest version")
    p_update.add_argument("tool", nargs="?", help="Tool name (default: all)")

    subparsers.add_parser("list", help="List all tools with installed version")
    subparsers.add_parser("check", help="Compare installed vs latest version")

    args = parser.parse_args()
    tools = load_tools()

    if args.command == "list":
        cmd_list(tools)
        return

    with httpx.Client(follow_redirects=True, timeout=120.0) as client:
        match args.command:
            case "install":
                cmd_install(tools, getattr(args, "tool", None), client)
            case "update":
                cmd_update(tools, getattr(args, "tool", None), client)
            case "check":
                cmd_check(tools, client)


if __name__ == "__main__":
    main()
