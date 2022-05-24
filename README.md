# `lua-dump`

This branch contains source code for the `lua-dump` program which was used to generate the repository data.

You can grab the pre-compiled program from the [releases](https://github.com/MWSE/morrowind-nexus-lua-dump/releases) page or run it directly from the source code provided.

---

## Overview

Run the program from the commandline with no arguments or with `--help` to get started.

```
Usage: lua-dump.exe [OPTIONS] COMMAND [ARGS]...

  Interface for gathering lua mods from the Morrowind Nexus.

  Requires a valid Nexus Mods Personal API Key. You can get yours from:
  https://www.nexusmods.com/users/myaccount?tab=api

  Pass your key to the program by saving it to a file at `/secrets/API_KEY`.
  (The secrets directory is skipped via .gitignore for obvious reasons)

  Downloaded archives are saved to `/downloads/mod-name/` directory.
  Extracted lua files are saved to `/lua/mod-name/` directory.

  Run a command without arguments (or with --help) for more info.

Options:
  --help  Show this message and exit.

Commands:
  download-mods      Download all mods that aren't already on disk.
  extract-mods       Extract the lua files from all downloaded mods.
  remove-old-mods    Remove old files for mods that have been updated.
  scan-added-mods    Scan for new mods released since the last run.
  scan-updated-mods  Scan for mods updated within the given period.
```

---

## Instructions for updating repository data

For those wanting to update the repository data, you should run the following commands in order:

*Note: You can run any of the commands below with --help for more information about their internals*

**IMPORTANT**: Make sure your `/lua/` folder is placed in the same directory as the `lua-dump.exe`.

1. > `lua-dump scan-added-mods Y`

This updates [index.json](https://github.com/MWSE/morrowind-nexus-lua-dump/blob/source/index.json) with information about lua mods that have been published since the last time the command was ran.

2. > `lua-dump scan-updated-mods 1d`

This updates [index.json](https://github.com/MWSE/morrowind-nexus-lua-dump/blob/source/index.json) with information about lua mods that have been updated within the given period. Supported parameters are `1h`, `1d`, or `1m` (1 hour, 1 day, 1 month).

4. > `lua-dump download-mods Y`

Now that [index.json](https://github.com/MWSE/morrowind-nexus-lua-dump/blob/source/index.json) is updated, this command will download any files known to have content more recent than whats in our `/lua/` directory. The results are saved to the `/downloads/` directory.

5. > `lua-dump extract-mods Y`

With the archives from the previous step now available in `/downloads/`. This command can be used to extracts their lua contents to the appropriate `/lua/` directory.

6. > `lua-dump remove-old-mods Y`

As a last step this command will take care of cleaning up any older versions of mods or files that have been deprecated or replaced.

---

## Instructions for working with source code

If, for what ever reason, using `lua-dump.exe` was not viable or not preferred, you can instead use the source code provided.

The project is written in [python](https://www.python.org/), which you will need a valid copy of installed on your system. Python version `3.6.1` or newer should work. (Development was done on version `3.9.4`, so try using that if you run into issues.)

To simplify dependency management, the package is set up as [poetry](https://python-poetry.org/) project. You will need to download and install that as detailed on the linked page.

Once you have both [python](https://www.python.org/) and [poetry](https://python-poetry.org/) you can run `poetry install` from within the source directory to automatically set up a virtual environment with all the necessary dependencies.

You can run the program with `poetry run python -m lua_dump`. Or open the project in [vscode](https://code.visualstudio.com/) and utilize the provided [tasks](https://code.visualstudio.com/docs/editor/tasks). If you're going to be working on the source code directly, installing the [python extension](https://marketplace.visualstudio.com/items?itemName=ms-python.python) and [pylance extension](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance) is highly recommended to make use of the project's type annotations for better code navigation, autocomplete, error checking, etc.
