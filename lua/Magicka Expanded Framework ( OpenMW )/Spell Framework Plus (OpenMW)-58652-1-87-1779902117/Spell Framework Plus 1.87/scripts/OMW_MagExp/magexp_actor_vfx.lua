-- ============================================================
-- magexp_actor_vfx.lua (LOCAL script — attached to NPC/Creature targets)
-- ============================================================

local self  = require('openmw.self')
local anim  = require('openmw.animation')
local core  = require('openmw.core')
local types = require('openmw.types')

local isParalyzed  = false

local function checkParalysis()
    local activeEffects = types.Actor.activeEffects(self)
    if not activeEffects then return false end
    
    local par = activeEffects:getEffect("paralyze")
    return (par ~= nil and par.magnitude > 0)
end

local function debugLog(msg)
    print("[MagExp VFX Actor] " .. tostring(msg))
end

return {
    engineHandlers = {
        onActive = function()
            --debugLog("Script activated on " .. (self.recordId or "unknown"))
        end,
        onUpdate = function(dt)
            local currentlyParalyzed = checkParalysis()

            if currentlyParalyzed then
                if not isParalyzed then
                    isParalyzed  = true
                    
                    -- 1. Natively disable standard AI (instantly stops wander, combat, and pathfinding packages)
                    pcall(function() self:enableAI(false) end)

                    -- 2. Zero out movement controls to let the engine naturally transition them to 'idle'
                    pcall(function()
                        if self.controls then
                            self.controls.movement = 0
                            self.controls.sideMovement = 0
                            self.controls.jump = false
                            self.controls.use = 0 -- Halt active weapons/attacks
                        end
                    end)
                else
                    -- Keep controls locked at zero during active paralysis
                    pcall(function()
                        if self.controls then
                            self.controls.movement = 0
                            self.controls.sideMovement = 0
                            self.controls.jump = false
                            self.controls.use = 0
                        end
                    end)
                end
            else
                if isParalyzed then
                    isParalyzed  = false
                    
                    -- 1. Re-enable NPC standard AI (engine smoothly resumes AI and scales walk/run animations natively)
                    pcall(function() self:enableAI(true) end)
                end
            end
        end
    },
    eventHandlers = {
        RemoveVfx = function(tag)
            --debugLog("RemoveVfx event received for tag: " .. tostring(tag) .. " on " .. (self.recordId or "unknown"))
            local ok, err = pcall(function()
                anim.removeVfx(self, tag)  -- Pass self as first argument
            end)
            if ok then
                --debugLog("Successfully removed VFX: " .. tostring(tag))
            else
                --debugLog("Failed to remove VFX: " .. tostring(err))
            end
        end,
        AddVfx = function(data)
            if not data or not data.model then
                --debugLog("AddVfx called with invalid data")
                return
            end
            --debugLog("AddVfx event received for model: " .. tostring(data.model))
            local opts = data.options or {}
            local ok, err = pcall(function()
                anim.addVfx(self, data.model, opts)  -- Pass self as first argument
            end)
            if ok then
                --debugLog("Successfully added VFX")
            else
                --debugLog("Failed to add VFX: " .. tostring(err))
            end
        end,
    }
}
