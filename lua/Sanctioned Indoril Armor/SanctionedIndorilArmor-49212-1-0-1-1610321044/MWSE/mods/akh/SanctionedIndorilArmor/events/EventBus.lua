local constants = require('akh.SanctionedIndorilArmor.Constants')
local modInfo = require('akh.SanctionedIndorilArmor.ModInfo')
local config = require("akh.SanctionedIndorilArmor.Config")
local util = require("akh.SanctionedIndorilArmor.Util")

local templeRank = -1

event.register("equipped", function(e)

    if (e.reference ~= tes3.player) then
        return
    end

    if e.item.objectType == tes3.objectType.armor and string.startswith(e.item.id, "indoril") == true then
        event.trigger(constants.event.PLAYER_EQUIPPED_INDORIL, { slot = e.item.slot })
    elseif e.item.objectType == tes3.objectType.clothing and e.item.slot == tes3.clothingSlot.robe then
        event.trigger(constants.event.PLAYER_EQUIPPED_ROBE, { slot = e.item.slot })
    end

end)

event.register("unequipped", function(e)

    if (e.reference ~= tes3.player) then
        return
    end

    if e.item.objectType == tes3.objectType.armor and string.startswith(e.item.id, "indoril") == true then
        event.trigger(constants.event.PLAYER_UNEQUIPPED_INDORIL, { slot = e.item.slot })
    elseif e.item.objectType == tes3.objectType.clothing and e.item.slot == tes3.clothingSlot.robe then
        event.trigger(constants.event.PLAYER_UNEQUIPPED_ROBE, { slot = e.item.slot })
    end

end)

event.register("infoResponse", function(e)

    if string.find(e.command, constants.command.PC_RAISE_RANK) or string.find(e.command, constants.command.PC_LOWER_RANK) then
        templeRank = tes3.getFaction(constants.faction.TEMPLE).playerRank
    end

end)

event.register("postInfoResponse", function(e)

    if string.find(e.command, constants.command.PC_RAISE_RANK) or string.find(e.command, constants.command.PC_LOWER_RANK) then
        if tes3.getFaction(constants.faction.TEMPLE).playerRank ~= templeRank then
            event.trigger(constants.event.TEMPLE_RANK_CHANGED)
        end
    end

    if config.requiredQuestCompletion then
        local id, index = util.splitRequiredQuestCompletion(config.requiredQuestCompletion)
        if string.find(e.command, id) then
            event.trigger(constants.event.REQUIRED_QUEST_JOURNAL_CHANGED)
        end
    end

end)

print("[" .. modInfo.modName .. " " .. modInfo.modVersion .. "] Event Bus Loaded")