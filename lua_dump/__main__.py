from __future__ import annotations

import os
import asyncio
import multiprocessing
from pathlib import Path
from typing import Awaitable, Callable

from typer import Argument, Option, Typer

from lua_dump.extract import LUA_PATH
from lua_dump.logger import init_logger
from lua_dump.lua_index import LuaIndex
from lua_dump.morrowind_nexus import MorrowindNexus

# generate cli
_help = """Interface for gathering lua mods from the Morrowind Nexus.

    Requires a valid Nexus Mods Personal API Key. You can get yours from:
    https://www.nexusmods.com/users/myaccount?tab=api

    Pass your key to the program by saving it to a file at `/secrets/API_Key`.
    (The secrets directory is skipped via .gitignore for obvious reasons)

    Downloaded archives are saved to `/downloads/mod-name/` directory.
    Extracted lua files are saved to `/lua/mod-name/` directory.

    Run a command without arguments (or with --help) for more info.
"""
app = Typer(no_args_is_help=True, add_completion=False, help=_help)


@app.command(no_args_is_help=True)
def scan_added_mods(
    scan: str = Argument(..., help="Start scanning? y/n"),
    force: bool = Option(False, help="Bypass once-per-hour guard."),
) -> None:
    """Scan for new mods released since the last run.

    This command uses the nexus api to retrieve the mod id of the most
    recently added mod. It then iterates through each mod id between the
    prevously highest known mod id (according to our index) and the latest
    mod id (according to nexus). For each mod id in that range it requests
    a content preview of the mod files and determines if they contain lua
    content. Mods that are found to have lua content are then added to our
    index.
    """
    if scan not in ("y", "Y"):
        print('scan-added-mods: Aborted. Pass "Y" parameter to start.')
        return

    async def update(index: LuaIndex, nexus: MorrowindNexus) -> None:
        await index.create_entries_for_added_mods(nexus, force)

    execute(update)


@app.command(no_args_is_help=True)
def scan_updated_mods(
    period: str = Argument(..., help='Accepted values are "1d", "1w" or "1m".'),
    force: bool = Option(False, help="Bypass once-per-hour guard."),
) -> None:
    """Scan for mods updated within the given period.

    This command uses the nexus api to retrieve a list of mod updates.
    It then goes through each update and compares their timestamps with
    the timestamps stored in our index. If their updates are more recent
    than our own, it will send additional api requests to retrieve the
    content previews for the given mod files and determine if they contain
    any lua content. Mods that are found to hpythave lua content are then added
    to our index (or updated if already present in the index).
    """
    valid_periods = ("1d", "1w", "1m")
    if period not in valid_periods:
        print(f"scan-updated-mods: Aborted. Period not in {valid_periods}.")
        return

    async def update(index: LuaIndex, nexus: MorrowindNexus) -> None:
        await index.refresh_entries_for_updated_mods(nexus, period, force)

    execute(update)


@app.command(no_args_is_help=True)
def download_mods(
    download: str = Argument(..., help="Start downloading? y/n"),
) -> None:
    """Download all mods that aren't already on disk.

    Files that already exist in the form of an archive in /downloads/ or
    an identically named directory in /lua/ will be skipped. Running this
    command multiple times does not trigger unnecessary api requests.
    """
    if download not in ("y", "Y"):
        print('download-mods: Aborted. Pass "Y" parameter to start.')
        return

    async def update(index: LuaIndex, nexus: MorrowindNexus) -> None:
        await index.download_all_missing_files(nexus)

    execute(update)


@app.command(no_args_is_help=True)
def extract_mods(
    extract: str = Argument(..., help="Start extracting? y/n"),
) -> None:
    """Extract the lua files from all downloaded mods.

    Files are extracted to a lua folder with the same name as the archive.

    Since mod archives may come in a variety of compression formats we must
    extract the entire archive and then delete non-lua content. This may be
    problematic as the operating system often will prevent deletion of some
    file types (e.g. DLL files). In any case the repository gitignore file
    is configured to ignore non-lua files in the lua directory, which means
    pushing updates without manually cleaning is safe.

    This command skips archives that appear to have been already extracted
    based on the presence of a similarly named folder in the lua directory.
    As such it is safe and cheap to re-run the command repeatedly until
    operating system errors are satsified.
    """
    if extract not in ("y", "Y"):
        print('extract-mods: Aborted. Pass "Y" parameter to start.')
        return

    async def update(index: LuaIndex, _nexus: MorrowindNexus) -> None:
        await index.extract_all_lua_files()

    execute(update)


@app.command(no_args_is_help=True)
def remove_old_mods(
    remove: str = Argument(..., help="Start removing? y/n"),
) -> None:
    """Remove old files for mods that have been updated.

    This command uses the local index data to remove any old files the
    are still present in the current `/downloads/` or `/lua/` directories.

    This is purely a local operation. No requests are sent to Nexus Servers.
    Be sure to run this command after you have executed `scan-updated-mods`.
    """
    if remove not in ("y", "Y"):
        print('remove-old-mods: Aborted. Pass "Y" parameter to run')
        return

    async def update(index: LuaIndex, _nexus: MorrowindNexus) -> None:
        await index.remove_deprecated_mods_and_files_from_disk()

    execute(update)


T = Callable[[LuaIndex, MorrowindNexus], Awaitable]


async def apply(index: LuaIndex, update: T) -> None:
    # read api key
    api_key = Path("secrets/API_KEY").read_text().rstrip()
    assert len(api_key), "error: invalid secrets/API_KEY file"

    # read lua dir
    assert any(LUA_PATH.iterdir()), "error: invalid /lua/ directory"

    # update index
    async with MorrowindNexus(api_key) as nexus:
        await update(index, nexus)


def execute(update: T) -> None:
    logger = init_logger()
    index = LuaIndex.load()
    try:
        if os.name == "nt":
            asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
        asyncio.run(apply(index, update))
    finally:
        index.save()
    logger.success("Finished!")


if __name__ == "__main__":
    multiprocessing.freeze_support()
    app()
