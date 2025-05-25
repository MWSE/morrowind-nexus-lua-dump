local logger = require("logging.logger").new{
    name = string.format("Lucid Disturbing Dreams"),
    logLevel = "INFO",
    includeTimestamp = true
}

---@type string
local dream1 = "detd_PCsleeps_dream1a"
---@type string
local dream2 = "detd_PCsleeps_dream2"
---@type string
local dream3 = "detd_PCsleeps_dream3"
---@type string
local dream4 = "detd_PCsleeps_dream4"

---@type string[]
local dreams = {
    dream1,
    dream2,
    dream3,
    dream4
}

---@type { [string]: string | nil }
local originalCells = {}

---@type { [string]: tes3vector3 | nil }
local originalPositions = {}

---@type { [string]: string }
local dreamCells = {
    [dream1] = "A Disturbing Dream",
    [dream2] = "A Second Disturbing Dream",
    [dream3] = "A Third Disturbing Dream",
    [dream4] = "A Fourth Disturbing Dream",
}

---@type { [string]: tes3vector3 }
local dreamPositions = {
    [dream1] = tes3vector3.new(3416.178, 2361.969, 15194.559),
    [dream2] = tes3vector3.new(4150.526, 5595.308, 14816.161),
    [dream3] = tes3vector3.new(3918.398, 3760.345, 14329.185),
    [dream4] = tes3vector3.new(3859.445, 4097.344, 12117.257)
}

---@type { [string]: integer }
local dreamJournalIndices = {
    [dream1] = 1,
    [dream2] = 5,
    [dream3] = 10,
    [dream4] = 15,
}

---@class LucidDisturbingDreamsManager
local this = {}

---@param dreamId string
function this.startDream(dreamId)
    if originalCells[dreamId] then
        -- Dream has already started
        return
    end

    originalCells[dreamId] = tes3.getPlayerCell().id
    originalPositions[dreamId] = tes3.player.position:copy()

    local removed = tes3.removeSpell({ reference = tes3.player, spell = dreamId, updateGUI = true })
    if not removed then
        logger:error("Could not remove spell '%s'!", dreamId)
    end
    tes3.positionCell({ reference = tes3.player, cell = dreamCells[dreamId], position = dreamPositions[dreamId] })

    event.unregister(tes3.event.spellTick, this.onDreamSpellAdded, { filter = (dreamId):lower() })
end

---@param e spellCastedEventData
function this.onDreamSpellAdded(e)
    this.startDream(e.source.id)
end

---@param e journalEventData
function this.onJournalUpdated(e)
    if e.topic.id:lower() ~= "a1_dreams" then
        -- Not relevant quest
        return
    end

    for dreamId, index in pairs(dreamJournalIndices) do
        if e.index == index then
            local originalPosition = originalPositions[dreamId]
            if not originalPosition then
                logger:error("Original player position for '%s' not found!", dreamId)
                return
            end
            tes3.positionCell({
                reference = tes3.player, cell = originalCells[dreamId],
                -- for some reason it's necessary to construct an entirely new vector for persisted position to work correctly
                position = tes3vector3.new(originalPosition.x, originalPosition.y, originalPosition.z)
            })
            return
        end
    end

    if e.index >= dreamJournalIndices[dream4] then
        -- Last dream has finished
        event.unregister(tes3.event.journal, this.onJournalUpdated)
    end
end

function this.loadOriginalData()
    ---@type { [string]: string | nil }
    local persistedOriginalCells = tes3.player.data.lucidDisturbingDreamsOriginalCells
    if persistedOriginalCells then
        originalCells = persistedOriginalCells
    end

    ---@type { [string]: tes3vector3 | nil }
    local persistedOriginalPositions = tes3.player.data.lucidDisturbingDreamsOriginalPositions
    if persistedOriginalPositions then
        originalPositions = persistedOriginalPositions
    end
end

function this.registerJournalEvent()
    local index = tes3.getJournalIndex({ id = "A1_Dreams" })
    if index and index >= dreamJournalIndices[dream4] then
        -- Last dream has finished, no reason to register this event
        return
    end
    if not event.isRegistered(tes3.event.journal, this.onJournalUpdated) then
        event.register(tes3.event.journal, this.onJournalUpdated)
    end
end

function this.registerDreamEvents()
    this.registerJournalEvent()
    for _, dream in ipairs(dreams) do
        local index = tes3.getJournalIndex({ id = "A1_Dreams" })
        if index and index < dreamJournalIndices[dream] then
            event.register(tes3.event.spellTick, this.onDreamSpellAdded, { filter = (dream):lower() })
        end
    end
end

function this.saveOriginalData()
    tes3.player.data.lucidDisturbingDreamsOriginalCells = originalCells
    tes3.player.data.lucidDisturbingDreamsOriginalPositions = originalPositions
end

function this.onLoaded()
    this.loadOriginalData()
    this.registerDreamEvents()
end

function this.onSave()
    this.saveOriginalData()
end

event.register(tes3.event.save, this.onSave)
event.register(tes3.event.loaded, this.onLoaded)