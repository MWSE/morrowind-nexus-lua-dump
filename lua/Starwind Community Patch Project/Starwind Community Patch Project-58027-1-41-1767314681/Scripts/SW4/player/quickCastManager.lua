local animation = require 'openmw.animation'
local async = require 'openmw.async'
local input = require 'openmw.input'
local gameSelf = require 'openmw.self'

local I = require('openmw.interfaces')

local ModInfo = require('scripts.sw4.modinfo')

local GlobalManagement

---@enum QuickStates
local QuickStates = {
    Begin = 1,
    CastStart = 2,
    Casting = 3,
    CastFinish = 4,
    WeaponTransition = 5,
    None = 6,
}

--- Put this into its own file
--- Add a setting for whether to enable it and whether to skip equipping animations
---@class QuickCastManager:ProtectedTable
---@field QuickCastEnable boolean
---@field QuickCastNoTransition boolean
---@field QuickWithKeys boolean
local Quick = I.StarwindVersion4ProtectedTable.new {
    modName = ModInfo.name,
    logPrefix = ModInfo.logPrefix,
    inputGroupName = 'SettingsGlobal' .. ModInfo.name .. 'QuickActionsGroup',
}

local currentStance = gameSelf.type.getStance(gameSelf)
Quick.state = {
    prevStance = currentStance ~= gameSelf.type.STANCE.Spell and currentStance or gameSelf.type.STANCE.Nothing,
    status = QuickStates.None,
}

function Quick:canQuickCast()
    local canCast = Quick.state.status == QuickStates.None and Quick.QuickCastEnable

    local SW4 = I.StarwindV4_PlayerController
    if SW4 then
        ---@type CursorController
        local Cursor = SW4.Subsystems.Cursor
        local MountFunctions = SW4.Subsystems.MountFunctions

        canCast = canCast and not MountFunctions.hasSpeederEquipped()
        canCast = canCast and not Cursor:getCursorVisible()
    end

    return canCast
end

function Quick:onFrameBegin(dt, Managers)
    if not self:canQuickCast() then return end

    local prevStance = gameSelf.type.getStance(gameSelf)

    if prevStance == gameSelf.type.STANCE.Spell then
        Quick.state.prevStance = gameSelf.type.STANCE.Nothing
        gameSelf.type.setStance(gameSelf, Quick.state.prevStance)
    else
        Quick.state.prevStance = prevStance
    end
end

function Quick:onFrame(dt, Managers)
    if Quick.state.status == QuickStates.CastStart then
        gameSelf.controls.use = 1
    elseif Quick.state.status == QuickStates.Begin then
        gameSelf.type.setStance(gameSelf, gameSelf.type.STANCE.Spell)
    elseif Quick.state.status == QuickStates.CastFinish then
        gameSelf.type.setStance(gameSelf, Quick.state.prevStance)
        gameSelf.controls.use = 0
    elseif Quick.state.status == QuickStates.None and gameSelf.type.getStance(gameSelf) == gameSelf.type.STANCE.Spell then
        gameSelf.type.setStance(gameSelf, gameSelf.type.STANCE.Nothing)
    end
end

function Quick.handleQuickCast(group, key)
    if not Quick.QuickCastEnable then return end

    if group == 'spellcast' and not GlobalManagement.MountFunctions.hasSpeederEquipped() then
        if key == 'equip stop' and Quick.state.status == QuickStates.Begin then
            Quick.state.status = QuickStates.CastStart
            -- Once we figure out a formula to ramp the cast speed on, use this
            -- elseif key:find('start') then
            --   animation.setSpeed(gameSelf, group, 50)
        elseif key:find('release') then
            Quick.state.status = QuickStates.CastFinish
        end
    elseif key == 'cast start' and Quick.state.status == QuickStates.CastStart then
        gameSelf.controls.use = 0
        Quick.state.status = QuickStates.Casting
    elseif group:find('idle') and key == 'start' and Quick.state.status == QuickStates.CastFinish then
        Quick.state.status = QuickStates.None
    end

    if Quick.state.status ~= QuickStates.None and key:find('equip start') and Quick.QuickCastNoTransition then
        animation.setSpeed(gameSelf, group, 60)
    end
end

function Quick.trigger()
    local canCast = Quick:canQuickCast()

    if canCast then
        Quick.state.status = QuickStates.Begin
    end

    return canCast
end

---@return QuickStates
function Quick.castState()
    return Quick.state.status
end

---@return table
function Quick.stateTypes()
    return QuickStates
end

input.registerTriggerHandler('ToggleSpell', async:callback(Quick.trigger))

I.AnimationController.addTextKeyHandler('', Quick.handleQuickCast)

---@param globalManagement ManagementStore
---@return QuickCastManager
return function(globalManagement)
    assert(globalManagement)
    GlobalManagement = globalManagement
    return Quick
end
