require('akh.SoullessCreatures.MCM')
local modInfo = require('akh.SoullessCreatures.ModInfo')
local config = require("akh.SoullessCreatures.Config")

local function onInitialized()

    -- In theory calcSoulValue event should be more fitting this case but in practice it doesn't work nearly as good.
    -- While setting soulValue = 0 in the calcSoulValue event does prevent the soul from being trapped, it has a side effect
    -- of incorrectly showing message that the soul has been trapped anyway. It seems that said event fires too late in the pipeline
    -- for the game to properly recognize that given creature has no soul. Setting soul value on spellTick event was the closest
    -- I could get to vanilla behavior when zeroing creature's soul value in an ESP mod
    event.register("spellTick", function(e)

        if e.target ~= tes3.player and e.effectId == tes3.effect.soultrap then
            local obj = e.target.baseObject or e.target.object
            if config.creatures[string.lower(obj.id)] and obj.soul > 0 then
                obj.soul = 0
            end
        end
    end)

    print("[" .. modInfo.modName .. " " .. modInfo.modVersion .. "] Initialized")
end

event.register("initialized", onInitialized)