local template = "bk_dagoth_urs_plans"
local types = require("openmw.types")
local world = require("openmw.world")

local logId

local function onSave()
    return { logId = logId, }
end

local function onLoad(data)
    if data then
        logId = data.logId
    end
end
local function createBook(plr)
    if not plr then plr = world.players[1] end
    local draft = types.Book.createRecordDraft({ template = types.Book.record(template), name = "Trainer Log", text =
    "", value = 0, enchantCapacity = 0 })
    local record = world.createRecord(draft)
    logId = record.id

    local recordBook =world.createObject(logId)

    recordBook:moveInto(plr)
    plr:sendEvent("setLogId",logId)
end
local function onPlayerAdded(plr)
    if not logId then
      createBook(plr)
    end
end
local function reducePlayerGold(amount)
    local playerGold = types.Actor.inventory(world.players[1]):find("gold_001")
    if playerGold and playerGold.count >= amount then
        playerGold:remove(amount)
    end
end
return {
    engineHandlers = { onSave = onSave, onLoad = onLoad, onPlayerAdded = onPlayerAdded },
    eventHandlers = {createBook = createBook,reducePlayerGold = reducePlayerGold,}
}
