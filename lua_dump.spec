# -*- mode: python ; coding: utf-8 -*-

# -- Copy Assets --

import shutil
shutil.rmtree("dist", ignore_errors=True)
shutil.copytree("lua", "dist/lua")
shutil.copyfile("index.json", "dist/index.json")

# -- Secrets Hint --

import pathlib
api_key_path = pathlib.Path("dist/secrets/API_KEY")
api_key_path.parent.mkdir(parents=True)
api_key_path.touch()
assert api_key_path.stat().st_size == 0  # just placeholder hint for users

# -- Begin PyInstaller --

from PyInstaller.utils.hooks import collect_all

datas = []
binaries = []
hiddenimports = []

tmp_ret = collect_all('aiolimiter')
datas += tmp_ret[0]; binaries += tmp_ret[1]; hiddenimports += tmp_ret[2]

tmp_ret = collect_all('patoolib')
datas += tmp_ret[0]; binaries += tmp_ret[1]; hiddenimports += tmp_ret[2]

datas +=  [("./index.json", ".")]

a = Analysis(['lua_dump\\__main__.py'],
             pathex=[],
             binaries=binaries,
             datas=datas,
             hiddenimports=hiddenimports,
             hookspath=[],
             runtime_hooks=[],
             excludes=[
                "pytest"
                "mypy"
                "black"
             ],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=None,
             noarchive=False)
pyz = PYZ(a.pure,
          a.zipped_data,
          cipher=None)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          [],
          name='lua-dump',
          debug=False,
          bootloader_ignore_signals=False,
          strip=False,
          upx=True,
          upx_exclude=[],
          runtime_tmpdir=None,
          console=True )

# -- Package Archive --

import shutil
shutil.make_archive("build/lua-dump", "zip", "dist")
shutil.move("build/lua-dump.zip", "dist/lua-dump.zip")
