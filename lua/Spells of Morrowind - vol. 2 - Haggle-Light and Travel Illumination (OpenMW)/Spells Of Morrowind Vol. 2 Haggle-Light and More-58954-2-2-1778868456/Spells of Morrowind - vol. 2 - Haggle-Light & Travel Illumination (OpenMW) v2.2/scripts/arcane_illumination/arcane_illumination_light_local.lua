-- ============================================================
-- Spells of Morrowind — LOCAL Script
-- Handles VFX on individual light objects
-- ============================================================

local self = require('openmw.self')
local anim = require('openmw.animation')

-- Track the active vfxId so StopVfx knows what to remove
local activeVfxId = nil

return {
    eventHandlers = {
        ArcaneLight_InitVfx = function(data)
            if not (data and data.model and data.model ~= '') then return end

            -- Store vfxId for later removal
            activeVfxId = data.vfxId or 'ArcaneLight_HangVfx'

            -- Apply scale via the object's world transform (the ONLY way to scale addVfx)
            -- anim.addVfx has no scale parameter; it inherits the parent object's scale.
            if data.scale and data.scale ~= 1.0 then
                pcall(function() self:setScale(data.scale) end)
            end

            pcall(function()
                anim.addVfx(self, data.model, {
                    loop            = true,
                    vfxId           = activeVfxId,
                    useAmbientLight = true,
                })
            end)
        end,

        ArcaneLight_StopVfx = function(data)
            if not self:isValid() then return end
            -- Use vfxId from data if provided, else fall back to stored active id
            local idToRemove = (data and data.vfxId) or activeVfxId or 'ArcaneLight_HangVfx'
            pcall(function()
                anim.removeVfx(self, idToRemove)
            end)
            activeVfxId = nil
        end,
    }
}