local common = require("scripts.quest_guider_lite.common")
local localStorage = require("scripts.quest_guider_lite.storage.localStorage")
local timeLib = require("scripts.quest_guider_lite.timeLocal")


local this = {}


---@type table<string, {tm: number, id: string}>
this.data = {}


function this.init()
    local dt = localStorage.data[common.dialogueTimeDataLabel]
    if not dt then
        dt = {}
        localStorage.data[common.dialogueTimeDataLabel] = dt
    end
    this.data = dt
end


function this.updateDialogue(diaId)
    if not diaId then return end

    local dt = this.data[diaId]
    if not dt then
        dt = {id = diaId}
        this.data[diaId] = dt
    end

    dt.tm = timeLib.getGlobalTimestamp()
end


---@return number
function this.getTimestamp(diaId)
    local dt = this.data[diaId]
    if not dt then return 0 end

    return dt.tm or 0
end


return this