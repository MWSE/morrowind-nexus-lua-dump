--[[
ErnOneStick for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local MOD_NAME = require("scripts.ErnOneStick.ns")
local pself = require("openmw.self")
local async = require("openmw.async")
local types = require('openmw.types')
local ui = require("openmw.interfaces").UI
local keytrack = require("scripts.ErnOneStick.keytrack")
local core = require("openmw.core")
local input = require('openmw.input')
local controls = require('openmw.interfaces').Controls

local toggleKey = keytrack.NewKey("toggle",
    function(dt) return input.getBooleanActionValue(MOD_NAME .. "ToggleButton") end)

local function canDoMagic()
    local hasSpell = (types.Actor.getSelectedEnchantedItem(pself) ~= nil) or (types.Actor.getSelectedSpell(pself) ~= nil)

    return hasSpell and types.Player.getControlSwitch(pself, types.Player.CONTROL_SWITCH.Magic) and
        (types.Player.isWerewolf(pself) ~= true)
end

local function canDoFighting()
    return types.Player.getControlSwitch(pself, types.Player.CONTROL_SWITCH.Fighting)
end

local function toggle()
    -- Nothing -> Spell -> Weapon -> Nothing
    if types.Actor.getStance(pself) == types.Actor.STANCE.Nothing then
        if canDoMagic() then
            types.Actor.setStance(pself, types.Actor.STANCE.Spell)
        elseif canDoFighting() then
            types.Actor.setStance(pself, types.Actor.STANCE.Weapon)
        end
        return
    end

    if types.Actor.getStance(pself) == types.Actor.STANCE.Spell then
        if canDoFighting() then
            types.Actor.setStance(pself, types.Actor.STANCE.Weapon)
        else
            types.Actor.setStance(pself, types.Actor.STANCE.Nothing)
        end
        return
    end

    if types.Actor.getStance(pself) == types.Actor.STANCE.Weapon then
        types.Actor.setStance(pself, types.Actor.STANCE.Nothing)
        return
    end
end

local function controlsAllowed()
    return not core.isWorldPaused()
        and types.Player.getControlSwitch(pself, types.Player.CONTROL_SWITCH.Controls)
        and not ui.getMode()
end

local longPressHandled = false
local pressedDuration = 0
local function onFrame(dt)
    toggleKey:update(dt)
    if controlsAllowed() == false then
        pressedDuration = 0
        longPressHandled = false
        return
    end
    if toggleKey.pressed then
        pressedDuration = pressedDuration + dt
    end
    if longPressHandled == false and pressedDuration > 0.2 then
        --settings.debugPrint("toggle sneak")
        pself.controls.sneak = not pself.controls.sneak
        longPressHandled = true
    end

    if toggleKey.fall then
        if longPressHandled == false then
            --settings.debugPrint("toggle stance")
            toggle()
        end
        pressedDuration = 0
        longPressHandled = false
    end
end

return {
    onFrame = onFrame
}
