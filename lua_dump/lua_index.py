from __future__ import annotations

from asyncio import gather
from datetime import datetime, timedelta
from pathlib import Path
from typing import Iterator, Optional

from aiohttp import ClientResponseError
from aionexusmods import Mod, ModUpdate
from pydantic import BaseModel

from .extract import DOWNLOADS_PATH, LUA_PATH, extract_all_parellel
from .logger import logger
from .morrowind_nexus import MorrowindNexus


class LuaFile(BaseModel):
    file_id: int
    name: str
    version: str


class LuaMod(BaseModel):
    mod_id: int
    name: str
    author: str
    files: list[LuaFile]
    indexed_timestamp: int

    def iter_missing_files(self) -> Iterator[LuaFile]:
        """
        Iterator over listed files that aren't yet on disk.
        """
        for file in self.files:
            # check if the archive is already downloaded
            archive_path = DOWNLOADS_PATH / self.name / file.name
            if archive_path.exists():
                continue

            # check if the lua mod folder already exists
            extract_path = LUA_PATH / self.name / archive_path.stem
            if extract_path.exists():
                continue

            # neither exist, so consider file as missing
            yield file

    async def download_missing_files(self, nexusmods: MorrowindNexus) -> None:
        """
        Download everything in the mod's files list that isn't already on disk.
        """
        futures = [self.download_file(nexusmods, f) for f in self.iter_missing_files()]
        await gather(*futures)

    async def download_file(self, nexusmods: MorrowindNexus, file: LuaFile) -> None:
        """
        Download the given file and save the results to disk.
        """
        path = DOWNLOADS_PATH / self.name / file.name

        # get download links
        logger.info(f"Requesting download links for {self.mod_id}:{file.file_id}")
        try:
            download_links = await nexusmods.get_download_links(self.mod_id, file.file_id)
        except ClientResponseError as e:
            logger.error(f"Failed to retrieve download links for {self.mod_id}:{file.file_id}\n{e}")
            if e.status not in (403, 404):  # (Forbidden, NotFound)
                raise e
            return
        logger.info(f"Recieved download links for {self.mod_id}:{file.file_id}")

        # download from link
        logger.info(f"Attempting to download {self.mod_id}:{file.file_id} to '{path}'")
        try:
            await nexusmods.download(download_links[0].URI, path)
        except (ClientResponseError, OSError) as e:
            logger.error(f"Failed to download {self.mod_id}:{file.file_id}\n{e}")
            raise e
        logger.info(f"Recieved download for {self.mod_id}:{file.file_id} -> {path}")

    async def update_files_index(self, nexusmods: MorrowindNexus) -> None:
        """
        Update the files index for this mod entry using current data from nexus mods.
        """
        files = await nexusmods.get_current_files_with_lua_content(self.mod_id)
        removed = {f.file_id for f in self.files}
        self.files = [
            LuaFile(
                file_id=entry.file_id,
                name=entry.file_name,
                version=entry.mod_version or "",
            )
            for entry in files
        ]
        self.indexed_timestamp = round(datetime.timestamp(datetime.now()))
        removed -= {f.file_id for f in self.files}
        if self.files or removed:
            logger.info(f"Updated files index for {self.name} -> removed={[*removed]}")

    async def remove_deprecated_files_from_disk(self) -> None:
        import shutil

        # valid archives are those with a name that exists in our index
        valid_archives = {f.name for f in self.files}

        # valid lua directories are the same, but without file suffixes
        valid_lua_dirs = {Path(a).stem for a in valid_archives}

        # remove old archives
        archives_dir = DOWNLOADS_PATH / self.name
        if archives_dir.exists():
            for path in [*archives_dir.iterdir()]:
                if path.name not in valid_archives:
                    logger.info(f"Removing deprecated archive '{path}'")
                    try:
                        path.unlink()
                    except OSError as e:
                        logger.error(f"Failed to remove archive '{path}'\n{e}")

        # remove old lua mods
        lua_mods_dir = LUA_PATH / self.name
        if lua_mods_dir.exists():
            for path in [*lua_mods_dir.iterdir()]:
                if path.name not in valid_lua_dirs:
                    logger.info(f"Removing deprecated lua mod '{path}'")
                    try:
                        shutil.rmtree(path)
                    except OSError as e:
                        logger.error(f"Failed to remove lua mod '{path}'\n{e}")

        # remove empty folders
        for path in (archives_dir, lua_mods_dir):
            if path.exists() and not any(path.iterdir()):
                logger.info(f"Removing empty directory '{path}'")
                try:
                    path.rmdir()
                except OSError as e:
                    logger.error(f"Failed to remove empty directory '{path}'\n{e}")

    @staticmethod
    def create_from_nexus_mod(mod: Mod) -> LuaMod:
        return LuaMod(mod_id=mod.mod_id, name=mod.name, author=mod.author, files=[], indexed_timestamp=0)


class LuaIndex(BaseModel):
    lua_mods: list[LuaMod]
    last_scan_for_added_mods_timestamp: int
    last_scan_for_updated_mods_timestamp: int
    highest_validated_mod_id: int

    @classmethod
    def load(cls) -> LuaIndex:
        return cls.parse_file("index.json")

    def save(self) -> None:
        self.remove_duplicates()
        Path("index.json").write_text(self.json(indent=4))

    def get_lua_mod(self, mod_id: int) -> Optional[LuaMod]:
        return next((m for m in self.lua_mods if m.mod_id == mod_id), None)

    async def extract_all_lua_files(self) -> None:
        """Extract the lua files from all archives in the downloads directory.

        Files are extracted to a lua folder with the same name as the archive.

        Since mod archives may come in a variety of compression formats we must
        extract the entire archive and then delete non-lua content. This may be
        problematic as the operating system often will prevent deletion of some
        file types (e.g. DLL files). In any case the repository gitignore file
        is configured to ignore non-lua files in the lua directory, which means
        pushing updates without manually cleaning is safe.

        This function skips archives that appear to have been already extracted
        based on the presence of a similarly named folder in the lua directory.
        As such it is safe and cheap to re-run the function repeatedly until
        operating system errors are satsified.
        """
        if DOWNLOADS_PATH.exists() and any(DOWNLOADS_PATH.iterdir()):
            await extract_all_parellel(self)
        else:
            logger.info("No archives found in downloads directory.")

    async def remove_deprecated_mods_and_files_from_disk(self) -> None:
        futures = [m.remove_deprecated_files_from_disk() for m in self.lua_mods]
        await gather(*futures)

    async def refresh_entries_for_all_mods(self, nexusmods: MorrowindNexus) -> None:
        """Refresh the entires of all mods in our index.

        Warning: Calling this may exceed the nexus api daily request's quota.
        This function should not be needed for typical use. Instead perfer to
        use other functions such as `refresh_entries_for_updated_mods`.
        """
        futures = [m.update_files_index(nexusmods) for m in self.lua_mods]
        await gather(*futures)

    async def download_all_missing_files(self, nexusmods: MorrowindNexus) -> None:
        """Download everything in all mod's files list that isn't already on disk.

        Files that already exist in the form of an archive in /downloads/ or
        a identically named directory in /lua/ will be skipped. Thus running
        this function multiple times won't trigger unnecessary api requests.
        """
        futures = [m.download_missing_files(nexusmods) for m in self.lua_mods]
        await gather(*futures)

    async def create_entries_for_added_mods(self, nexusmods: MorrowindNexus, force: bool = False) -> None:
        """Create index entries for mods added to nexus since our last run.

        This function uses the nexus api to retrieve the mod id of the most
        recently added mod. It then iterates through each mod id between the
        prevously highest known mod id (according to our index) and the latest
        mod id (according to nexus). For each mod id in that range it requests
        a content preview of the mod files and determines if they contain lua
        content. Mods that are found to have lua content are then added to our
        index.
        """
        # restrict to running only once per hour
        timestamp, delta = self.get_timestamp_and_delta_since(self.last_scan_for_added_mods_timestamp)
        if not force and delta <= timedelta(hours=1):
            logger.info("Aborting scan for added mods. Wait one hour between scans, or pass force=True.")
            return

        logger.info("Requesting latest added mods")
        added_mods = await nexusmods.get_latest_added_mods()
        logger.info("Recieved latest added mods")

        # there may have been mods released between the last
        # mod we checked and the oldest of the 'latest mods'
        # so do a lookup for each mod id in that range
        start = self.highest_validated_mod_id + 1
        stop = min(m.mod_id for m in added_mods if m.mod_id)
        if start < stop:
            futures = map(nexusmods.get_mod_if_available, range(start, stop))
            added_mods.extend(await gather(*futures))
        else:
            logger.info(f"No mods were added since last run")
            return

        # filter out any unavailable mods
        added_mods = [m for m in added_mods if m and m.available and m.name and m.author]

        # now go through the mods and check if they have lua content
        async def process(mod: Mod):
            lua_mod = LuaMod.create_from_nexus_mod(mod)
            await lua_mod.update_files_index(nexusmods)
            # if it had some lua files we add it to the mods list
            if lua_mod.files:
                self.lua_mods.append(lua_mod)
            else:
                logger.info(f"Latest added mod {mod.mod_id} has no lua content")

        await gather(*map(process, added_mods))

        # update relevant index fields
        self.last_scan_for_added_mods_timestamp = timestamp
        self.highest_validated_mod_id = max(m.mod_id for m in added_mods if m and m.mod_id)

    async def refresh_entries_for_updated_mods(
        self, nexusmods: MorrowindNexus, period: str, force: bool = False
    ) -> None:
        """Refresh the index entries for mods updated in the specified period.

        This function uses the nexus api to retrieve a list of mod updates.
        It then goes through each update and compares their timestamps with
        the timestamps stored in our index. If their updates are more recent
        than our own, it will send additional api requests to retrieve the
        content previews for the given mod files and determine if they contain
        any lua content. Mods that are found to have lua content are then added
        to our index (or updated if already present in the index).
        """
        # restrict to running only once per hour
        timestamp, delta = self.get_timestamp_and_delta_since(self.last_scan_for_updated_mods_timestamp)
        if not force and delta <= timedelta(hours=1):
            logger.info("Aborting scan for updated mods. Wait one hour between scans, or pass force=True.")
            return

        logger.info("Requesting latest added mods")
        mod_updates = await nexusmods.get_mod_updates(period)
        logger.info(f"Recieved latest added mods {[update.mod_id for update in mod_updates]}")

        async def process(mod_update: ModUpdate) -> None:
            # get existing entry for the mod if it's already indexed
            lua_mod = self.get_lua_mod(mod_update.mod_id)
            indexed = lua_mod is not None

            # if it wasn't already indexed, build a new entry for it
            if not indexed:
                mod = await nexusmods.get_mod_if_available(mod_update.mod_id)
                if not (mod and mod.available and mod.name and mod.author):
                    return
                lua_mod = LuaMod.create_from_nexus_mod(mod)
            assert lua_mod is not None

            # compare our indexed timestamp with the update timestamp
            if mod_update.latest_file_update > lua_mod.indexed_timestamp:
                # this mod update is more recent than our index entry
                # rebuild the internal files list with new nexus data
                await lua_mod.update_files_index(nexusmods)
                # if the update added lua files add this to our index
                if lua_mod.files and not indexed:
                    self.lua_mods.append(lua_mod)
                    logger.info(f"Added mod {lua_mod.mod_id} to the index")
                # if the update removed all lua files, remove from it
                if indexed and not lua_mod.files:
                    self.lua_mods.remove(lua_mod)
                    logger.info(f"Removed mod {lua_mod.mod_id} remove the index")
                # otherwise it's just a lame non-lua mod that updated
                if not lua_mod.files:
                    logger.info(f"Updated mod {lua_mod.mod_id} has no lua content")

        await gather(*map(process, mod_updates))

        # all done! store timestamp of this scan
        self.last_scan_for_updated_mods_timestamp = timestamp

    @staticmethod
    def get_timestamp_and_delta_since(timestamp: int) -> tuple[int, timedelta]:
        now = datetime.now()
        delta = now - datetime.fromtimestamp(timestamp)
        return round(datetime.timestamp(now)), delta

    def remove_duplicates(self):
        entries: dict[int, list[LuaMod]] = {}

        for lua_mod in self.lua_mods:
            entry = entries.setdefault(lua_mod.mod_id, [])
            entry.append(lua_mod)
            if len(entry) > 1:
                logger.warning(f"Found duplicate entry for mod id {lua_mod.mod_id}")
                entry.sort(key=lambda x: x.indexed_timestamp, reverse=True)

        self.lua_mods = [entries[k][0] for k in sorted(entries)]
