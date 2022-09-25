local interop = {}


interop.lua = {

}

interop.esp = {

}

--- Registers a Lua mod. This should be called during the MWSE 'initalized' event.
---When a Mod is registered and active, Physical Journal no longer gives the Journal to the player during Chargen.
---To give it from your end, create a book object with id "spa_IJ_Journal" and give that to the player.
---@param path string The path to the Lua mod folder.
function interop:registerLua(path)
    table.insert(interop.lua, path)
end
--- Registers an ESP/ESM mod. This should be called during the MWSE 'initalized' event.
---When a Mod is registered and active, Physical Journal no longer gives the Journal to the player during Chargen.
---To give it from your end, create a book object with id "spa_IJ_Journal" and give that to the player.
---@param name string Name of the ESP/ESM file, including the extension.
function interop:registerEsp(name)
    table.insert(interop.esp, name)
end

return interop