local interop = require("mer.characterBackgrounds.interop")

---@params file string
local function isLuaFile(file)
    return file:sub(-4, -1) == ".lua"
end

---@params file string
local function isInitFile(file)
    return file == "init.lua"
end

local function getBackgrounds()
    local backgrounds = {}
    local path = "Data Files/MWSE/mods/mer/characterBackgrounds/backgrounds"
    for file in lfs.dir(path) do
        if isLuaFile(file) and not isInitFile(file) then
            local background = dofile(path .. "/" .. file)
            if background then
                table.insert(backgrounds, background)
            end
        end
    end
    return backgrounds
end


interop.addBackground{
    id = "none",
    name = "-None-",
    description = "No Background Selected",
    doOnce = function() end
}
for _, background in ipairs(getBackgrounds()) do
    interop.addBackground(background)
end