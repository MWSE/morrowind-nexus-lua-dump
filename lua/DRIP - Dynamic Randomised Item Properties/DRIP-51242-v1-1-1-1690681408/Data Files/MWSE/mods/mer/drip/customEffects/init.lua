local dir = 'Data Files\\MWSE\\mods\\mer\\drip\\customEffects\\effects'

--Initialise all custom effects
for file in lfs.dir(dir) do
    local path = string.format("%s/%s", dir, file)
    ---@type any
    local fileAttributes = lfs.attributes(path)
    local isValidLuaFile = fileAttributes
        and fileAttributes.mode
        and fileAttributes.mode == "file"
        and file:sub(-4, -1) == ".lua"
    if isValidLuaFile then
        dofile(path)
    end
end