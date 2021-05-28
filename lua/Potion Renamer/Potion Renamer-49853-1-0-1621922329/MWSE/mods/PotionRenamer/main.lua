local modInfo = require("PotionRenamer.modInfo")
local config = require("PotionRenamer.config")
local data = require("PotionRenamer.data")

local function onInitialized()
    if config.enable then

        -- Go through all potions in the data table one at a time.
        for _, dataPotion in ipairs(data.potions) do
            local id = dataPotion.id
            local potion = tes3.getObject(id)

            if potion then

                -- Change the name only if the potion is not blacklisted, and, in the case of alcohol or spoiled
                -- potions, only if the mod is configured to do so.
                if ( not config.blacklist[id] )
                and ( config.alcohol or not dataPotion.alcohol )
                and ( config.spoiled or not dataPotion.spoiled ) then
                    potion.name = dataPotion.name
                end
            end
        end
    end

    mwse.log(string.format("[%s %s] Initialized.", modInfo.mod, modInfo.version))
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\PotionRenamer\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)