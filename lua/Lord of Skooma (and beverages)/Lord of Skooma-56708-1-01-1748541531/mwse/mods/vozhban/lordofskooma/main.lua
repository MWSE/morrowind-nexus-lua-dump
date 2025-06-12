local menuApparatus = require("vozhban.lordofskooma.menuApparatus")
local distillation = require("vozhban.lordofskooma.distillation")
local apparatusState= require("vozhban.lordofskooma.apparatusState")
local ui = require("vozhban.lordofskooma.ui")
local values = require("vozhban.lordofskooma.values")

local apparatusId = "apparatus_skooma"
local currentApparatus = nil

local function onSimulate(e)
    distillation.updateAll()
    if currentApparatus then
        if not currentApparatus.sceneNode or currentApparatus.deleted then
            currentApparatus = nil
            return
        end
    end
    if currentApparatus and tes3ui.menuMode then
        local existing = tes3ui.findHelpLayerMenu("HelpMenu")
        if existing then
            existing:destroy()
            tes3ui.createTooltipMenu()
            local tooltip = tes3ui.findHelpLayerMenu("HelpMenu")
            if tooltip then
                ui.drawApparatusTooltip(tooltip, currentApparatus)
                tooltip:updateLayout()
            end
        end
    end
end

local function onActivate(e)
    if e.activator ~= tes3.player then return end

    if e.target.id == apparatusId and e.target.stackSize == 1 then

        local state = apparatusState.get(e.target)
        
        if not state.isRunning and (not state.storage or not next(state.storage)) and (tes3.worldController.inputController:isKeyDown(tes3.scanCode.leftShift)) then -- or tes3ui.menuModeand (not state.storage or state.storage == nil) 
        
            for i = 1, values.maxUpgradeSlots do
                local upgrade = state.upgrades and state.upgrades[i]
                if upgrade then
                    tes3.addItem{reference = tes3.player, item = upgrade, count = 1}
                end
            end

            apparatusState.clear(e.target, true)
            tes3.addItem{reference = tes3.player, item = e.target.id}
            e.target:disable()
            e.target:delete()
            return false
        end

        if state.isRunning and state.mode == 0 and tes3.worldController.inputController:isKeyDown(tes3.scanCode.leftShift) then
            apparatusState.setValue(e.target, "mode", 1)
            tes3.messageBox("Distillery will stop after this batch.")
            return false
        end

        menuApparatus.show(e.target)
        return false
    end
end

local function onTooltip(e)
    if e.object.id == "apparatus_skooma" and e.count < 2 then
        currentApparatus = e.reference
        ui.drawApparatusTooltip(e.tooltip, e.reference)
    else
        currentApparatus = nil
    end
end

local function initialized()
    mwse.log("Lord of Skooma initialized.")
    event.register("activate", onActivate, {priority = 200})
    event.register("simulate", onSimulate)
    event.register("uiObjectTooltip", onTooltip)
end

event.register("initialized", initialized)