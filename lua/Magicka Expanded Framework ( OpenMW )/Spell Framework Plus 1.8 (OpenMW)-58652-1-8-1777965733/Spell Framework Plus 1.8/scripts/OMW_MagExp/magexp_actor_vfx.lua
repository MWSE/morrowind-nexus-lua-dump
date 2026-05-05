-- ============================================================
-- magexp_actor_vfx.lua (LOCAL script — attached to NPC/Creature targets)
-- ============================================================

local self = require('openmw.self')
local anim = require('openmw.animation')

local function debugLog(msg)
    print("[MagExp VFX Actor] " .. tostring(msg))
end

return {
    engineHandlers = {
        onActive = function()
            --debugLog("Script activated on " .. (self.recordId or "unknown"))
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