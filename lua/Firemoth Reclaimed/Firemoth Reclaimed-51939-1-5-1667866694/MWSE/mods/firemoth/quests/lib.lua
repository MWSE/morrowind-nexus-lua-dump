local this = {}

local quest = assert(tes3.dataHandler.nonDynamicData:findDialogue("fm_2022"))

--[[
    Quest Events
--]]

local events = {
    [200] = "firemoth:questAccepted",
    [300] = "firemoth:travelAccepted",
    [400] = "firemoth:backdoorEntered",
    [450] = "firemoth:companionsRecalled",
    [500] = "firemoth:grurnDefeated",
}

---@param e journalEventData
local function onJournalUpdated(e)
    if (e.topic.id == quest.id) and events[e.index] then
        event.trigger(events[e.index])
    end
end
event.register(tes3.event.journal, onJournalUpdated)

--[[
    Quest Persistent References
--]]

---@type table<string, tes3reference>
this.npcs = {} -- set in loaded event

---@type table<string, tes3reference>
this.clutter = {} -- set in loaded event

local function onLoaded()
    this.npcs.mara = assert(tes3.getReference("fm_mara"))
    this.npcs.aronil = assert(tes3.getReference("fm_aronil"))
    this.npcs.hjrondir = assert(tes3.getReference("fm_hjrondir"))
    this.npcs.silmdar = assert(tes3.getReference("fm_silmdar"))

    this.npcs.hjrondirUndead = assert(tes3.getReference("fm_hjrondir_undead"))
    this.npcs.hjrondirUndead.data.fm_skeletonsIgnore = true

    this.clutter.seydaBoat = assert(tes3.getReference("fm_seyda_boat"))
    this.clutter.mudcrabDead = assert(tes3.getReference("fm_mudcrab_dead"))

    if not this.questAccepted() then
        this.setClutterReferencesDisabled(true)
        this.setPersistentReferencesDisabled(true)
    end

    if this.travelFinished() then
        this.setClutterReferencesDisabled(true)
    end

    local ref = tes3.getReference("fm_grurn")
    if ref then
        ref.data.fm_skeletonsIgnore = true
    end
end
event.register(tes3.event.loaded, onLoaded, { priority = 7000 })

--[[
    Utility Functions
--]]

local function setDisabled(ref, disabled)
    if disabled and not ref.disabled then
        ref:disable()
    elseif ref.disabled and not disabled then
        ref:enable()
    end
end

function this.setClutterReferencesDisabled(disabled)
    for _, ref in pairs(this.clutter) do
        setDisabled(ref, disabled)
    end
end

function this.setPersistentReferencesDisabled(disabled)
    for _, ref in pairs(this.npcs) do
        setDisabled(ref, disabled)
    end
end

function this.companionReferences()
    return coroutine.wrap(function()
        coroutine.yield(this.npcs.mara)
        coroutine.yield(this.npcs.aronil)
        if not this.backdoorEntered() then
            coroutine.yield(this.npcs.hjrondir)
        end
    end)
end

function this.questAccepted()
    return quest.journalIndex >= 200
end

function this.travelFinished()
    return quest.journalIndex >= 300
end

function this.diversionStarted()
    return quest.journalIndex >= 350
end

function this.backdoorEntered()
    return quest.journalIndex >= 400
end

function this.companionsRecalled()
    return quest.journalIndex >= 450
end

function this.undeadHjrondir()
    return quest.journalIndex >= 475
end

function this.setDiversionStarted()
    tes3.updateJournal({ id = quest.id, index = 350, showMessage = true })
end

function this.setBackdoorEntered()
    tes3.updateJournal({ id = quest.id, index = 400, showMessage = true })
end

function this.setCompanionsRecalled()
    tes3.updateJournal({ id = quest.id, index = 450, showMessage = true })
end

function this.setGrurnDefeated()
    tes3.updateJournal({ id = quest.id, index = 500, showMessage = true })
end

local function recallCompanions(e)
    for ref in this.companionReferences() do
        if ref.cell ~= tes3.player.cell then
            tes3.positionCell({ reference = ref, position = tes3.player.position, cell = tes3.player.cell })
            return
        end
        if ref.disabled then
            ref:enable()
            return
        end
        tes3.setAIFollow({ reference = ref, target = tes3.player })
    end

    tes3.removeItem({ reference = tes3.player, item = "fm_sc_recall" })

    e.timer:cancel()
end
timer.register("firemoth:recallCompanions", recallCompanions)


return this
