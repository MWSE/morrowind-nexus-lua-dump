local constants = require('akh.LimitedRestingWaitingAndRegen.Constants')
local config = require("akh.LimitedRestingWaitingAndRegen.Config")
local modInfo = require('akh.LimitedRestingWaitingAndRegen.ModInfo')
local spellFactory = require("akh.LimitedRestingWaitingAndRegen.util.SpellFactory")

-- define custom dummy spell to mark player for regen lock
local ID_SPELL_STUNTED_HEALTH = "LRWAR_StuntedHealth"

stuntedStatSpell = spellFactory.createStuntedStatSpell(ID_SPELL_STUNTED_HEALTH, "Stunted Health")
local stuntedStatValue = nil

local function onSpellTick(e)

    if e.source.id == ID_SPELL_STUNTED_HEALTH and e.target == tes3.player and stuntedStatValue ~= nil then
        tes3.setStatistic{
            reference = tes3.player,
            name = "health",
            current = stuntedStatValue
        }
    end

end

local function enableStuntedStat()
    stuntedStatValue = tes3.mobilePlayer.health.current
    mwscript.addSpell{ reference = tes3.mobilePlayer, spell = ID_SPELL_STUNTED_HEALTH}
end

local function disableStuntedStat()
    stuntedStatValue = nil
    mwscript.removeSpell{ reference = tes3.mobilePlayer, spell = ID_SPELL_STUNTED_HEALTH}
end

event.register("spellTick", onSpellTick)

-- remove the stunted attribute spell in case something went horribly wrong and player still has it
event.register("loaded", disableStuntedStat)

event.register(constants.event.PLAYER_REST, function()
    if config.healthRegenPreset == constants.config.healthRegenPreset.NO_REGEN then
        enableStuntedStat()
    end
end)

event.register(constants.event.PLAYER_RESTED, function()
    disableStuntedStat()
end)

event.register(constants.event.PLAYER_TRAVEL, function(e)
    if config.healthRegenPreset == constants.config.healthRegenPreset.NO_REGEN_ON_TRAVEL or config.healthRegenPreset == constants.config.healthRegenPreset.NO_REGEN then
        if e.npcClass ~= constants.npcClass.GUILD_GUIDE then
            enableStuntedStat()
        end
    end
end)

event.register(constants.event.PLAYER_TRAVELED, function()
    disableStuntedStat()
end)

print("[" .. modInfo.modName .. " " .. modInfo.modVersion .. "] Health Regen Module Loaded")