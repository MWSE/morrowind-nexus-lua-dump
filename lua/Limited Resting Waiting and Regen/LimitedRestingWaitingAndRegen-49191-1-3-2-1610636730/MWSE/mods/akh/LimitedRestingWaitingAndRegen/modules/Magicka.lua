local constants = require('akh.LimitedRestingWaitingAndRegen.Constants')
local config = require("akh.LimitedRestingWaitingAndRegen.Config")
local modInfo = require('akh.LimitedRestingWaitingAndRegen.ModInfo')
local spellFactory = require("akh.LimitedRestingWaitingAndRegen.util.SpellFactory")

-- define custom dummy spell to mark player for regen lock
local ID_SPELL_STUNTED_MAGICKA = "LRWAR_StuntedMagicka"

stuntedStatSpell = spellFactory.createStuntedStatSpell(ID_SPELL_STUNTED_MAGICKA, "Stunted Magicka")
local stuntedStatValue = nil

local function onSpellTick(e)

    if e.source.id == ID_SPELL_STUNTED_MAGICKA and e.target == tes3.player and stuntedStatValue ~= nil then
        tes3.setStatistic{
            reference = tes3.player,
            name = "magicka",
            current = stuntedStatValue
        }
    end

end

local function enableStuntedStat()
    stuntedStatValue = tes3.mobilePlayer.magicka.current
    mwscript.addSpell{ reference = tes3.mobilePlayer, spell = ID_SPELL_STUNTED_MAGICKA}
end

local function disableStuntedStat()
    stuntedStatValue = nil
    mwscript.removeSpell{ reference = tes3.mobilePlayer, spell = ID_SPELL_STUNTED_MAGICKA}
end

event.register("spellTick", onSpellTick)

-- remove the stunted attribute spell in case something went horribly wrong and player still has it
event.register("loaded", disableStuntedStat)

event.register(constants.event.PLAYER_TRAVEL, function(e)
    if config.magickaRegenPreset == constants.config.magickaRegenPreset.NO_REGEN_ON_TRAVEL then
        if e.npcClass ~= constants.npcClass.GUILD_GUIDE then
            enableStuntedStat()
        end
    end
end)

event.register(constants.event.PLAYER_TRAVELED, function()
    disableStuntedStat()
end)

print("[" .. modInfo.modName .. " " .. modInfo.modVersion .. "] Magicka Regen Module Loaded")