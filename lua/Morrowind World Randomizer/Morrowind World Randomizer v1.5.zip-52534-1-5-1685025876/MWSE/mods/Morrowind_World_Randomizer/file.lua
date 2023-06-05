local this = {}

this.save = {}
this.load = {}

---@param path string
---@param object table
function this.save.table(path, object)
    toml.saveFile(path, object)
end

---@param fileName string
---@param object table
function this.save.toSaveDirectory(fileName, object)
    this.save.table("Saves/"..fileName, object)
end

---@param path string
function this.load.table(path)
    local data, error = toml.loadFile(path)
    return data
end

---@param fileName string
function this.load.fromSaveDirectory(fileName)
    return this.load.table("Saves/"..fileName)
end

return this