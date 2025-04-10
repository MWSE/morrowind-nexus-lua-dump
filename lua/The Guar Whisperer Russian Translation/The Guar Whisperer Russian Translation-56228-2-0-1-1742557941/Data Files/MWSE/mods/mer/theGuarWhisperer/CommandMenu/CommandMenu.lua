--[[
    Handles state of command menu and calls UI code
]]

local ui = require("mer.theGuarWhisperer.CommandMenu.commandMenuView")
local GuarCompanion = require("mer.theGuarWhisperer.GuarCompanion")
local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("CommandMenuModel")

---@class GuarWhisperer.CommandMenu
---@field index number The index of the currently selected command
---@field commandList table[] A list of commands that can be performed
---@field activeCompanion GuarWhisperer.GuarCompanion The guar companion that is currently active
---@field targetData GuarWhisperer.Ability.TargetData The data about the target we're looking at
local CommandMenu = {}

CommandMenu.index = 1
CommandMenu.commandList = {}
CommandMenu.activeCompanion = nil
CommandMenu.targetData = {}

CommandMenu.pages = {
    main = require("mer.theGuarWhisperer.CommandMenu.commandLists.mainCommands"),
}
CommandMenu.currentPage = CommandMenu.pages.main

function CommandMenu:getActiveCommand()
    if self.index and self.commandList and #self.commandList > 0 then
        return self.commandList[self.index]
    end
end

function CommandMenu:showCommandMenu(guar)
    self.inMenu = true
    self.activeCompanion = guar
    ui.createCommandMenu(self)
end

function CommandMenu:showContextMenu()
    self.inMenu = false
    ui.createContextMenu(self)
end

function CommandMenu:destroy()
    if self.activeCompanion then
        self.activeCompanion.refData.commandActive = nil
    end
    self.currentPage = self.pages.main
    self.activeCommandList = {}
    self.targetData = {}
    self.activeCompanion = nil
    ui.destroyContextMenu()
    ui.destroyCommandMenu()
    event.unregister("simulate", self.checkCommandState)
end

function CommandMenu:performAction()
    local activeCommand = self:getActiveCommand()
    if activeCommand then
        activeCommand.command(self)

        --Some commands prevent reactivation right after
        common.data.skipActivate = true
        timer.start{
            duration = activeCommand.delay or 0.1,
            callback = function() common.data.skipActivate = false end
        }

        if activeCommand.keepAlive ~= true then
            logger:debug("Action performed, closing menu")
            self:destroy()
        else
            logger:debug("Keep alive")
        end
    end
end

function CommandMenu:filterCommands()
    self.commandList = {}
    for _, command in ipairs(self.activeCompanion.abilityList) do
        if command.requirements(self) then
            table.insert(self.commandList, command)
        end
    end
    table.insert(self.commandList,
        {
            id = "cancel",
            label = function(e)
                return "Отмена"
            end,
            description = "Выход",
            command = function(e) end,
            requirements = function(e) return true end
        }
    )
     self.index = 1
end

function CommandMenu:changePage(newPage, guar)
    self.currentPage = self.pages[newPage]
    self:checkCommandState()
    self:filterCommands()
    self:showCommandMenu(guar)
end


function CommandMenu:scrollUp()
    self.index = self.index + 1
    if self.index > #self.commandList then
        self.index = 1
    end
    self:showContextMenu()
end

function CommandMenu:scrollDown()
    self.index = self.index - 1
    if self.index < #self.commandList then
        self.index = 1
    end
    self:showContextMenu()
end

function CommandMenu:toggleCommandMenu()
    --command menu active, delete menu
    if self.activeCompanion then
        self:destroy()
    --command menu inactive, see if we're looking at a companion to turn the menu on
    else
        --Get player target
        local guar = GuarCompanion.get(tes3.getPlayerTarget())
        --otherwise do a ray cast
        if not guar then
            local ray = tes3.rayTest{
                position = tes3.getPlayerEyePosition(),
                direction = tes3.getPlayerEyeVector(),
                ignore = { tes3.player },
                accurateSkinned = true,
            }
            if ray then
                guar = GuarCompanion.get(ray.reference)
            end
        end

        if not guar then
            local ref = Rider.getRefBeingRidden()
            if ref then
                guar = GuarCompanion.get(ref)
            end
        end

        if guar and guar:canTakeAction() then
            self.activeCompanion = guar
            self.activeCompanion.refData.commandActive = true
            self.inMenu = false
            self:checkCommandState()
            event.register("simulate", self.checkCommandState )
            self:showContextMenu()
        end
    end
end


function CommandMenu.checkCommandState()
    local self = CommandMenu
    if not self.targetData then
        logger:debug("No target Data")
        self.targetData = {}
    end
    if self.activeCompanion then

        local ignoreList = { tes3.player }
        local inputController = tes3.worldController.inputController
        local isShiftDown = (
            inputController:isKeyDown(tes3.scanCode.lShift) or
            inputController:isKeyDown(tes3.scanCode.rShift)
        )
        if isShiftDown then
            table.insert(ignoreList, self.activeCompanion.reference)
        end

        local ray = tes3.rayTest{
            position = tes3.getPlayerEyePosition(),
            direction = tes3.getPlayerEyeVector(),
            ignore = ignoreList,
            accurateSkinned = true,
        }

        local newTargetData = ray and { reference = ray.reference, intersection = ray.intersection:copy() } or {}
        newTargetData.playerTarget = tes3.getPlayerTarget()
        --Changed our target, update commandlist and UI
        local targetChanged = (
            ( not not newTargetData.intersection ~= not not self.targetData.intersection ) or
            ( not not newTargetData.reference ~= not not self.targetData.reference ) or
            ( newTargetData.reference ~= self.targetData.reference ) or
            ( self.targetData.playerTarget ~=  newTargetData.playerTarget )
        )
        logger:trace("Target Changed, updating command list")
        if targetChanged then
            self.targetData = newTargetData
            self:filterCommands()
            if not self.inMenu then
                self:showContextMenu()
            end
        end
        self.targetData.intersection = newTargetData.intersection
    else
        logger:trace("No active Companion")
    end
end

return CommandMenu