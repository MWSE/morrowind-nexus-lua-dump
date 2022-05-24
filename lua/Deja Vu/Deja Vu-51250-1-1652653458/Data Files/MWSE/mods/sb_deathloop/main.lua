---@class table
---@field stats number[]
---@field attributes number[]
---@field skills number[]
---@field inventory tes3item[]
local deathloopStats = {
    met        = 0,
    count      = 1,
    stats      = {},
    attributes = {},
    skills     = {},
    spells     = {},
    topics     = {},
    inventory  = {}
}

local function saveDeathloop()
    if (tes3.player.data.sb_deathloop) then
        deathloopStats.met = tes3.getGlobal("sb_deathloop_met")

        deathloopStats.count = tes3.player.data.sb_deathloop + 1

        deathloopStats.stats = { tes3.mobilePlayer.health.base, tes3.mobilePlayer.magicka.base, tes3.mobilePlayer.fatigue.base, tes3.player.object.level }

        for statistic, _ in pairs(tes3.mobilePlayer.attributes) do
            deathloopStats.attributes[statistic] = tes3.mobilePlayer.attributes[statistic].base
        end

        for skill, _ in pairs(tes3.mobilePlayer.skills) do
            deathloopStats.skills[skill] = tes3.mobilePlayer.skills[skill].base
        end

        for _, spell in ipairs(tes3.player.object.spells) do
            deathloopStats.spells[_] = spell
        end

        for topic in tes3.iterate(tes3.mobilePlayer.dialogueList) do
            deathloopStats.topics = topic.id
        end

        ---@param item tes3item
        -- for item in tes3.iterate(tes3.player.object.inventory.items) do
        --     if (deathloopStats.inventory[item]) then
        --         deathloopStats.inventory[item] = deathloopStats.inventory[item] - 1
        --         if (deathloopStats.inventory[item] == -1) then
        --             deathloopStats.inventory[item] = nil
        --         end
        --     end
        -- end
    end
end

local function restartDeathloop()
    tes3.playSound { sound = "sb_deathloop_reset", reference = tes3.player }
    timer.start { duration = 6, type = timer.real, callback = function()
        tes3.loadGame("sb_deathloop.ess")

        tes3.setGlobal("sb_deathloop_met", deathloopStats.met)

        tes3.player.data.sb_deathloop = deathloopStats.count

        tes3.mobilePlayer.health.base = deathloopStats.stats[1]
        tes3.mobilePlayer.health.current = deathloopStats.stats[1]

        tes3.mobilePlayer.magicka.base = deathloopStats.stats[2]
        tes3.mobilePlayer.magicka.current = deathloopStats.stats[2]

        tes3.mobilePlayer.fatigue.base = deathloopStats.stats[3]
        tes3.mobilePlayer.fatigue.current = deathloopStats.stats[3]

        tes3.player.object.level = deathloopStats.stats[4]

        for statistic, _ in pairs(deathloopStats.attributes) do
            tes3.mobilePlayer.attributes[statistic].base = deathloopStats.attributes[statistic]
            tes3.mobilePlayer.attributes[statistic].current = deathloopStats.attributes[statistic]
        end

        for skill, _ in pairs(deathloopStats.skills) do
            tes3.mobilePlayer.skills[skill].base = deathloopStats.skills[skill]
            tes3.mobilePlayer.skills[skill].current = deathloopStats.skills[skill]
        end

        for _, spell in ipairs(deathloopStats.spells) do
            tes3.player.object.spells:add(spell)
        end

        for _, topic in ipairs(deathloopStats.topics) do
            tes3.runLegacyScript { command = string.format("addTopic \"%s\"", topic) }
        end

        tes3.mobilePlayer:updateDerivedStatistics()
    end }
end

--- @param e simulateEventData
local function simulateCallback(e)
    if (tes3.player.data.sb_deathloop) then
        local elderScroll = tes3.getReference("sb_deathloop_dummy")
        if (elderScroll.cell ~= tes3.player.cell) then
            elderScroll.position = tes3.player.position
        end

        if (tes3.getJournalIndex { id = "C3_DestroyDagoth" } < 20) then
            if (tes3.player.data.sb_deathloop_start > 0 and tes3.getSimulationTimestamp() - tes3.player.data.sb_deathloop_start >= 24) then
                tes3.player.data.sb_deathloop_start = 0
                saveDeathloop()
                restartDeathloop()
            end
        end
    end
end

--- @param e equipEventData
local function equipCallback(e)
    if (e.item.id == "sb_deathloop_scroll") then
        tes3.getReference("sb_deathloop_dummy").mobile:startDialogue()
    end
end

--- @param e damagedEventData
local function damagedCallback(e)
    if (tes3.getJournalIndex { id = "C3_DestroyDagoth" } < 20) then
        if (tes3.player.data.sb_deathloop and e.reference == tes3.player and e.killingBlow) then
            saveDeathloop()
            restartDeathloop()
        end
    end
end

--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
    if (deathloopStats.inventory[e.object]) then
        local label = e.tooltip:createLabel { id = "HelpMenu_deathloop_count", text = "Loops Remaining: " .. tostring(deathloopStats.inventory[e.object]) }
        label.borderTop = 6
    end
end

--- @param e uiActivatedEventData
local function uiMenuStatActivatedCallback(e)
    if (tes3.player and tes3.player.data.sb_deathloop) then
        if (e.newlyCreated) then
            local labelBlock = e.element:findChild("MenuStat_general_frame"):createBlock { id = "sb_deathloop_count" }
            labelBlock.widthProportional = 1
            labelBlock.autoHeight = true
            labelBlock.parent:reorderChildren(0, -1, 1)

            local title = labelBlock:createLabel { text = "Loop Count" }
            title.color = { 0.875, 0.788, 0.624 }

            local label = labelBlock:createLabel { id = "count", text = tostring(deathloopStats.count) }
            label.absolutePosAlignX = 1
        else
            e.element:findChild("MenuStat_general_frame"):findChild("sb_deathloop_count"):findChild("count").text = tostring(deathloopStats.count)
        end
    end
end

--- @param e uiActivatedEventData
local function uiMenuOptionsActivatedCallback(e)
    if (e.newlyCreated and tes3.player == nil) then
        e.element.absolutePosAlignX = 96 / 2048
        e.element.absolutePosAlignY = 1 - 96 / 1024
        e.element.autoWidth = true
        e.element.autoHeight = true

        ---@param element tes3uiElement
        for _, element in ipairs(e.element:getContentElement().children[1].children) do
            local contentPath = element.name:find("_New") and "newgame" or
                element.name:find("_Load") and "loadgame" or
                element.name:find("_Options") and "options" or
                element.name:find("_MCM") and "modconfig" or
                element.name:find("_Credits") and "credits" or
                element.name:find("_Exit") and "exitgame"
            if (contentPath) then
                element.autoWidth = true
                element.autoHeight = true
                element.borderTop = 16
                for i = 1, 3 do
                    element.children[i].width = 128
                    element.children[i].height = 32
                    if (i == 2) then
                        element.children[i].contentPath = ("Textures\\sb_deathloop\\menu_%s.tga"):format(contentPath .. "_over")
                    else
                        element.children[i].contentPath = ("Textures\\sb_deathloop\\menu_%s.tga"):format(contentPath)
                    end
                end
            end
        end

        e.element:updateLayout()
    end
end

--- @param e uiActivatedEventData
local function uiMenuJournalSaveActivatedCallback(e)
    if (e.newlyCreated) then
        if (e.element:findChild("MenuMessage_message").text:find("You should probably check out Arrille's Tradehouse up on the left.")) then
            e.element:registerAfter(tes3.uiEvent.destroy, function()
                timer.delayOneFrame(function()
                    tes3.setGlobal("TimeScale", tes3.player.data.sb_deathloop)
                    tes3.player.data.sb_deathloop = 1
                    tes3.saveGame { file = "sb_deathloop", name = "sb_deathloop" }
                end)
            end)
        elseif (e.element:findChild("MenuMessage_message").text:find("recent Save Game")) then
            e.element.visible = false
        end
    end
end

--- @param e uiActivatedEventData
local function uiMenuLoadActivatedCallback(e)
    for _, child in ipairs(e.element:findChild("MenuLoad_SaveScroll").widget.contentPane.children) do
        if (child.text == "sb_deathloop") then
            child.visible = false
        end
    end
end

--- @param e cellActivatedEventData
local function cellActivatedCallback(e)
    if (tes3.worldController.charGenState.value == -1) then
        event.unregister(tes3.event.cellActivated, cellActivatedCallback)
    end
end

--- @param e loadedEventData
local function loadedCallback(e)
    if (e.newGame) then
        event.unregister(tes3.event.cellActivated, cellActivatedCallback)
        tes3.player.data.sb_deathloop = tes3.getGlobal("TimeScale")
        tes3.player.data.sb_deathloop_start = tes3.getSimulationTimestamp()
        tes3.setGlobal("TimeScale", 0)
        event.register(tes3.event.cellActivated, cellActivatedCallback)
    end
end

--- @param e initializedEventData
local function initializedCallback(e)
    event.register(tes3.event.simulate, simulateCallback)
    event.register(tes3.event.equip, equipCallback)
    event.register(tes3.event.damaged, damagedCallback)
    -- event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)
    event.register(tes3.event.uiActivated, uiMenuStatActivatedCallback, { filter = "MenuStat" })
    event.register(tes3.event.uiActivated, uiMenuOptionsActivatedCallback, { filter = "MenuOptions" })
    event.register(tes3.event.uiActivated, uiMenuJournalSaveActivatedCallback, { filter = "MenuMessage" })
    event.register(tes3.event.uiActivated, uiMenuLoadActivatedCallback, { filter = "MenuLoad" })
    event.register(tes3.event.loaded, loadedCallback)
end

event.register(tes3.event.initialized, initializedCallback)
