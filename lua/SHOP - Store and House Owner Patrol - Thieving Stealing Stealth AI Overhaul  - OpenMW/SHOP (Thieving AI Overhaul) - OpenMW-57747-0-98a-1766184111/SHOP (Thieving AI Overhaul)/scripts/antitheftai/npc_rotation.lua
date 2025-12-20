--[[
SHOP - Store & House Owner Patrol (NPC in interiors AI overhaul) for OpenMW.
Copyright (C) 2025 Łukasz Walczak

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
----------------------------------------------------------------------
-- Anti-Theft Guard AI  •  v0.9 PUBLIC TEST  •  OpenMW ≥ 0.49
----------------------------------------------------------------------
-- NPC AI Handler - LOCAL SCRIPT for NPCs
-- Handles AI state save/restore for Anti-Theft system
----------------------------------------------------------------------
local settings = require('scripts.antitheftai.SHOPsettings')
local seenMessages = {}

local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local AI = require('openmw.interfaces').AI

local function log(...)
    if settings.general and settings.general:get('enableLogging') ~= false and settings.general:get('enableDebug') then
        local npcName = types.NPC.record(self).name or "Unknown"
        local args = {...}
        for i, v in ipairs(args) do
            if v == self.id then
                args[i] = npcName .. " (" .. v .. ")"
            end
            args[i] = tostring(args[i])
        end
        local msg = table.concat(args, " ")
        if not seenMessages[msg] then
            print("[NPC-AI]", table.unpack(args))
            seenMessages[msg] = true
        end
    end
end

-- Track if we're currently controlled by Anti-Theft
local isControlled = false
local hasDefaultBehavior = true

----------------------------------------------------------------------
-- Handle removing all AI packages
local function onRemoveAIPackages()
    log("Removing all AI packages for", self.id)
    AI.removePackages('all')
    isControlled = true
end

----------------------------------------------------------------------
-- Handle starting an AI package
local function onStartAIPackage(data)
    if not data then return end

    log("Starting AI package for", self.id, "- Type:", data.type)

    if data.cancelOther then
        AI.removePackages('all')
    end

    if data.type == 'Travel' then
        AI.startPackage({
            type = 'Travel',
            destPosition = data.destPosition,
            faceTarget = data.faceTarget  -- Support face target for keeping NPC facing player
        })
        isControlled = true
    elseif data.type == 'Wander' then
        AI.startPackage({
            type = 'Wander',
            distance = data.distance or 100,
            duration = data.duration or 10000
        })
        isControlled = true
    end
end

----------------------------------------------------------------------
-- Handle teleporting home
local function onTeleportHome(data)
    if not data or not data.homePosition then return end

    log("Teleporting", self.id, "home to:", data.homePosition)

    -- Build home rotation
    local util = require('openmw.util')
    local homeRotTransform = util.transform.rotateZ(data.homeRotation.z or 0) *
                             util.transform.rotateY(data.homeRotation.y or 0) *
                             util.transform.rotateX(data.homeRotation.x or 0)

    -- Teleport to home with correct rotation
    self:teleport(self.cell.name, data.homePosition, {
        rotation = homeRotTransform,
        onGround = true
    })

    log("✓ NPC", self.id, "teleported home successfully")

    -- Clear AI packages
    AI.removePackages('all')

    -- Send ready event to player script
    local player = require('openmw.world').players[1]
    if player then
        player:sendEvent('AntiTheft_NPCReady', { npcId = self.id })
        log("✓ Sent NPCReady event for", self.id)
    end
end

----------------------------------------------------------------------
-- Save original AI state (placeholder - engine handles defaults)
local function onSaveOriginalAIState()
    log("Marking", self.id, "as having default behavior to restore")
    hasDefaultBehavior = true
    isControlled = true
end

----------------------------------------------------------------------
-- Enable default AI behavior (let engine restore defaults)
local function onEnableDefaultAI()
    log("╔════════════════════════════════════════════════════════════╗")
    log("║ RESTORING DEFAULT AI FOR", self.id)
    log("╚════════════════════════════════════════════════════════════╝")
    
    -- Clear all custom packages
    AI.removePackages('all')
    
    -- Mark as no longer controlled
    isControlled = false
    
    -- The engine will automatically restore default behavior
    -- NPCs will resume their normal idle/wander patterns and player detection
    
    log("  ✓ Cleared all custom AI packages")
    log("  ✓ NPC is now using DEFAULT ENGINE AI")
    log("  ✓ Player detection ENABLED")
    log("════════════════════════════════════════════════════════════")
end

----------------------------------------------------------------------
-- Restore original AI state (same as enable default)
local function onRestoreOriginalAIState()
    onEnableDefaultAI()
end

----------------------------------------------------------------------
-- Handle setting hello value
local function onSetHello(data)
    if not data or data.value == nil then return end

    log("Setting hello value to", data.value, "for", self.id)
    local types = require('openmw.types')
    types.NPC.stats.ai.hello(self).base = data.value
    log("✓ Hello value set to", data.value)
end

----------------------------------------------------------------------
-- Handle setting alarm value
local function onSetAlarm(data)
    if not data or data.value == nil then return end

    log("Setting alarm value to", data.value, "for", self.id)
    local types = require('openmw.types')
    types.NPC.stats.ai.alarm(self).base = data.value
    log("✓ Alarm value set to", data.value)
end

----------------------------------------------------------------------
return {
    eventHandlers = {
        RemoveAIPackages = onRemoveAIPackages,
        StartAIPackage = onStartAIPackage,
        SaveOriginalAIState = onSaveOriginalAIState,
        RestoreOriginalAIState = onRestoreOriginalAIState,
        AntiTheft_EnableDefaultAI = onEnableDefaultAI,
        AntiTheft_SetHello = onSetHello,
        AntiTheft_SetAlarm = onSetAlarm
    }
}
