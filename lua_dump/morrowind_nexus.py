from __future__ import annotations

from asyncio import gather
from itertools import compress
from typing import Optional

from aiohttp import ClientResponseError
from aionexusmods import File, Mod, NexusMods

from .logger import logger


class MorrowindNexus(NexusMods):
    """NexusMods that defaults to Morrowind and provides a couple utility methods."""

    def __init__(self, api_key: str):
        super().__init__(api_key, "morrowind")

    async def __aenter__(self) -> MorrowindNexus:
        await super().__aenter__()
        return self

    async def get_current_files_with_lua_content(self, mod_id: int) -> list[File]:
        """Retrieve files that contain lua content."""
        files = await self.get_current_files(mod_id)
        futures = map(self.has_lua_content, files)
        results = await gather(*futures)
        return list(compress(files, results))

    async def has_lua_content(self, file: File) -> bool:
        """
        Check the given file's nexus preview to see if it has lua content.
        """
        logger.info(f"Requesting content preview for {file.file_id}")
        try:
            content_preview = await self.get_content_preview(file.content_preview_link)
        except ClientResponseError as e:
            if e.status not in (403, 404):  # (Forbidden, NotFound)
                logger.error(f"Failed to retrieve content preview for {file.file_id}\n{e}")
                raise e
            logger.debug(f"No content preview was found for {file.file_id}")
            return False
        logger.info(f"Recieved content preview for {file.file_id}")

        # Recurse through all file paths and see if any are lua scripts.
        for node in content_preview.children_recursive():
            if str(node.path).lower().endswith(".lua"):
                logger.info(f"Found lua content for {file.file_id} -> '{node.path}'")
                return True

        return False

    async def get_current_files(self, mod_id: int) -> list[File]:
        """
        Retrieve the current files for the specified mod.
        (i.e. the most recent version of each named file)
        """
        logger.info(f"Requesting files for {mod_id}")
        try:
            files, _ = await self.get_files_and_updates(mod_id)
        except ClientResponseError as e:
            logger.error(f"Failed to retrieve files for {mod_id}\n{e}")
            return []
        logger.info(f"Recieved files for {mod_id}")

        # group files by their names
        groups: dict[str, list[File]] = {}
        for file in files:
            if file.category_id not in (4, 6):  # 4=DELETED, 6=OLD_VERSION
                if file.category_name != "OLD_VERSION":  # maybe redundant
                    groups.setdefault(file.name, []).append(file)

        # sort files by their dates
        for group in groups.values():
            group.sort(key=lambda f: f.uploaded_timestamp)

        # take only the latest versions
        files = [group[-1] for group in groups.values()]

        return files

    async def get_mod_if_available(self, mod_id: int) -> Optional[Mod]:
        logger.info(f"Requesting mod entry for {mod_id}")
        try:
            mod = await self.get_mod(mod_id)
        except ClientResponseError as e:
            if e.status not in (403, 404):  # (Forbidden, NotFound)
                logger.error(f"Failed to retrieve mod entry for {mod_id}\n{e}")
                raise e
            logger.debug(f"No mod entry was found for {mod_id}")
        else:
            logger.info(f"Recieved mod entry for {mod_id} -> available={mod.available}")
            if mod.available and mod.name and mod.author:
                return mod
        return None
