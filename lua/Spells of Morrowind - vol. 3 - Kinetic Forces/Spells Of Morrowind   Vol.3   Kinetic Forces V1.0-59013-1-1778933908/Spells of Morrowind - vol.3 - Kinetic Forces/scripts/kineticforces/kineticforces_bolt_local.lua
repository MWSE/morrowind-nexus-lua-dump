-- ============================================================
-- Energy Bolt — Bolt Carrier LOCAL Script (CUSTOM type)
-- Attached to the Colony_Assassin_act carrier object during Phase 1.
-- Sole responsibility: manage the looping VFX visual on the carrier.
-- All positioning and rotation are handled by the global script.
-- ============================================================

local self = require('openmw.self')
local anim = require('openmw.animation')

local VFX_ID = 'EnergyBolt_HangVfx'

return {
    eventHandlers = {
        -- Attach the looping bolt VFX model once the script has initialised
        EnergyBolt_InitVfx = function(data)
            if data and data.model and data.model ~= '' then
                pcall(function()
                    anim.addVfx(self, data.model, {
                        loop            = true,
                        vfxId           = data.vfxId or VFX_ID,
                        useAmbientLight = true,
                    })
                end)
            end
        end,

        -- Remove the VFX before the carrier is destroyed (Phase 2 launch or cancel)
        EnergyBolt_StopVfx = function()
            if not self:isValid() then return end
            pcall(function()
                anim.removeVfx(self, VFX_ID)
            end)
        end,
    }
}
