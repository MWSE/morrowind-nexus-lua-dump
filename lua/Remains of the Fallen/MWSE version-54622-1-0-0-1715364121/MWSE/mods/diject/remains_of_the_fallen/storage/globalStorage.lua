
local storageName = "RemainsOfTheFallenByDiject"

local this = {}

this.data = mwse.loadConfig(storageName)
if this.data == nil then this.data = {} end

function this.save()
    mwse.saveConfig(storageName, this.data)
end

function this.reset()
    this.data = {}
    mwse.saveConfig(storageName, this.data)
end

return this