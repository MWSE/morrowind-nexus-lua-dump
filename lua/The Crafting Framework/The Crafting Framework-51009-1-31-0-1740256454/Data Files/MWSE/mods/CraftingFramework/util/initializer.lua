---@class Merlord.Initializer.params
---@field logger mwseLogger
---@field modPath string

---@class Merlord.Initializer : Merlord.Initializer.params
local Initializer = {}

---@param params Merlord.Initializer.params
---@return Merlord.Initializer
function Initializer:new(params)
    local o = table.copy(params)
    setmetatable(o, self)
    self.__index = self
    return o
end

---@params file string
local function isLuaFile(file)
    return file:sub(-4, -1) == ".lua"
end

---@params file string
local function isInitFile(file)
    return file == "init.lua"
end

---@param path string
function Initializer:initAll(path)
    local scripts = {}
    self.logger:debug("Initialising %s", path)
    path = string.format("Data Files/MWSE/%s/%s/", self.modPath, path)
    self.logger:debug("Path: %s", path)
    for file in lfs.dir(path) do
        self.logger:debug("File: %s", file)
        if isLuaFile(file) and not isInitFile(file) then
            local filename = file:sub(1, -5)
            self.logger:debug("Executing file: %s", filename)
            scripts[filename] = dofile(path .. file)
            self.logger:debug("%s: %s", filename, scripts[filename])
        end
    end
    self.logger:debug("Excecuted %d files", table.size(scripts))
    return scripts
end

return Initializer