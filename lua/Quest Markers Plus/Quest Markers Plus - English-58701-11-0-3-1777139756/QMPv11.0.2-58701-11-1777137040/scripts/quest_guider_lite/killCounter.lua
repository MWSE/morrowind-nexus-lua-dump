local core = require('openmw.core')
local commonData = require("scripts.quest_guider_lite.common")

local this = {}

---@type table<string, integer> by object record id
this.data = {}

function this.init(data)
    this.data = data or {}
end

function this.initByStorageData(storageData)
    this.data = storageData[commonData.killCounterDataLabel] or {}
    core.sendGlobalEvent("QGL:updateKillCounter", this.data)
end

function this.registerKill(ref)
    this.data[ref.recordId] = (this.data[ref.recordId] or 0) + 1
end


---@return integer
function this.getKillCount(id)
    return this.data[id] or 0
end

return this