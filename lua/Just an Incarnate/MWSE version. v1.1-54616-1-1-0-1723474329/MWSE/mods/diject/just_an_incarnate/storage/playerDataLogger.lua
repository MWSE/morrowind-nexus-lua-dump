local storage = include("diject.just_an_incarnate.storage.localStorage")
local log = include("diject.just_an_incarnate.utils.log")

local this = {}

local priority = -9999
local logerLabel = "logger"

---@enum dataLogger.eventTypes
this.eventTypes = {
    ["levelUp"] = 1,
    ["skillRaised"] = 2,
    ["spellLearned"] = 3,
}

---@class dataLogger.data.struct
---@field time integer
---@field event dataLogger.eventTypes
---@field value any
---@field skillId tes3.skill|nil
---@field raiseSource tes3.skillRaiseSource|nil
---@field attributes table<number>|nil
---@field health number|nil the value by which health has changed
---@field spellId string|nil

function this.playerData()
    if not storage.data[logerLabel] then this.initPlayer() end
    return storage.data[logerLabel]
end

function this.initPlayer()
    local object = tes3.player.baseObject
    local attributes = {}
    for _, attr in ipairs(tes3.mobilePlayer.attributes) do
        table.insert(attributes, 0)
    end
    storage.data[logerLabel] = {{event = this.eventTypes.levelUp, time = tes3.getSimulationTimestamp(), value = object.level,
        attributes = attributes, health = 0},}
end

---@param e skillRaisedEventData
local function skillRaisedCallback(e)
    if not storage.isReady() then return end
    ---@type dataLogger.data.struct
    local data = {event = this.eventTypes.skillRaised, time = tes3.getSimulationTimestamp(), value = e.level, raiseSource = e.source, skillId = e.skill}
    table.insert(this.playerData(), data)
    log("skill raised: source", e.source, "skill", e.skill, "level", e.level)
end
event.register(tes3.event.skillRaised, skillRaisedCallback, {priority = priority})

local levelupAttributes = {}
local levelupHealth = 0
---@param e preLevelUpEventData
local function preLevelUpCallback(e)
    levelupAttributes = {}
    for _, attr in ipairs(tes3.mobilePlayer.attributes) do
        table.insert(levelupAttributes, attr.base)
    end
    levelupHealth = tes3.mobilePlayer.health.base
end
event.register(tes3.event.preLevelUp, preLevelUpCallback)

---@param e levelUpEventData
local function levelUpCallback(e)
    if not storage.isReady() then return end
    local attributes = {}
    for id, attr in ipairs(tes3.mobilePlayer.attributes) do
        table.insert(attributes, levelupAttributes[id] and (attr.base - levelupAttributes[id]) or 0)
    end
    ---@type dataLogger.data.struct
    local data = {event = this.eventTypes.levelUp, time = tes3.getSimulationTimestamp(), value = e.level,
        attributes = attributes, health = tes3.mobilePlayer.health.base - levelupHealth}
    table.insert(this.playerData(), data)
    log("New level:", e.level)
end
event.register(tes3.event.levelUp, levelUpCallback, {priority = priority})


local spellsBeforeTrainer = {}
---@type mwseTimer|nil
local spellsTimer
local spellsTimerRunning = false
local function updateSpellsTimer()
    if not spellsTimer or spellsTimer.state == timer.expired then
        spellsTimerRunning = true
        spellsTimer = timer.delayOneFrame(function(e)
            local spells = tes3.player.object.spells
            for _, spell in pairs(spells) do
                if spell.castType == tes3.spellType.spell and not spellsBeforeTrainer[spell.id] then
                    ---@type dataLogger.data.struct
                    local data = {event = this.eventTypes.spellLearned, time = tes3.getSimulationTimestamp(), spellId = spell.id}
                    table.insert(this.playerData(), data)
                    log("spell learned: id", spell.id)
                end
            end
            spellsBeforeTrainer = {}
            spellsTimerRunning = false
        end)
    end
end

--- @param e calcSpellPriceEventData
local function calcSpellPriceCallback(e)
    if not storage.isReady() then return end
    if not spellsTimerRunning then
        for _, spell in pairs(tes3.player.object.spells) do
            if spell.castType == tes3.spellType.spell then
                spellsBeforeTrainer[spell.id] = true
            end
        end
        updateSpellsTimer()
    end
end
event.register(tes3.event.calcSpellPrice, calcSpellPriceCallback)

---@param e itemDroppedEventData
local function itemDroppedCallback(e)
end
event.register(tes3.event.itemDropped, itemDroppedCallback, {priority = priority})

return this