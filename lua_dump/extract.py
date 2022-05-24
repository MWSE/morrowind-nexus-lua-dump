from __future__ import annotations

from subprocess import run
from pathlib import Path

from lua_dump import *

LUA_PATH = Path("lua")
LUA_PATH.mkdir(parents=True, exist_ok=True)

DOWNLOADS_PATH = Path("downloads")
DOWNLOADS_PATH.mkdir(parents=True, exist_ok=True)

logger = None


def set_logger(to):  # type: ignore
    global logger
    logger = to


def fix_encodings_for_lua_files(mod_path: Path) -> None:
    for lua_file in mod_path.rglob("*.lua"):
        try:
            contents = lua_file.read_bytes()
            contents.decode("utf-8")
        except OSError as e:
            logger.error(f"Failed to read '{lua_file}'\n{e}")
        except UnicodeDecodeError:
            logger.info(f"Stripping invalid characters from '{lua_file}'")
            try:
                lua_file.write_text(
                    contents.decode(encoding="cp1251", errors="replace").replace("\r", ""),
                    encoding="utf-8",
                    errors="replace",
                )
            except OSError as e:
                logger.error(f"Failed to strip '{lua_file}'\n{e}")


def remove_non_lua_files(mod_path: Path) -> None:
    # ensure we're being called on expected folder
    assert mod_path.parts[0] == LUA_PATH.name

    # the paths that we will remove
    paths_to_remove = set(mod_path.rglob("*"))

    # preserve all lua script paths
    for lua_file in mod_path.rglob("*.lua"):
        # preserve the lua file
        paths_to_remove.remove(lua_file)
        # preserve parent paths
        for parent in lua_file.parents:
            if parent in paths_to_remove:
                paths_to_remove.remove(parent)
            else:
                break

    # bail if all contents were lua
    if not paths_to_remove:
        return

    logger.info(f"Removing non-lua content from '{mod_path}'")

    # remove anything not preserved
    for path in sorted(paths_to_remove, key=lambda p: len(p.parts), reverse=True):
        if path.exists():
            try:
                # logger.info(f"Removing non-lua path '{path}'")  # too much log spam
                if path.is_file():
                    path.unlink()
                elif path.is_dir():
                    path.rmdir()
            except OSError as e:
                logger.debug(f"Failed to remove non-lua path '{path}'\n{e}")


def extract_lua_files(lua_mod: LuaMod) -> None:
    for file in lua_mod.files:
        archive_path = DOWNLOADS_PATH / lua_mod.name / file.name
        extract_path = LUA_PATH / lua_mod.name / archive_path.stem

        if not extract_path.exists():
            if not archive_path.exists():
                logger.error(f"Mod file for '{archive_path}' not found")
                continue

            logger.info(f"Attempting to extract '{archive_path}'")
            try:
                run(f'7z x -o"{str(extract_path)}" "{str(archive_path)}"')
            except Exception as e:
                logger.error(f"Failed to extract '{archive_path}'\n{e}")

        fix_encodings_for_lua_files(extract_path)
        remove_non_lua_files(extract_path)


async def extract_all_parellel(index: LuaIndex) -> None:
    """Parellel extraction of lua files for all archives specified in the index."""
    from concurrent.futures import ProcessPoolExecutor
    from .logger import logger

    with ProcessPoolExecutor(initializer=set_logger, initargs=(logger,)) as executor:
        for _ in executor.map(extract_lua_files, index.lua_mods, timeout=300):
            pass
