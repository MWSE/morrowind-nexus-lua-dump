local constants = require('akh.SanctionedIndorilArmor.Constants')
local modInfo = require('akh.SanctionedIndorilArmor.ModInfo')
local config = require("akh.SanctionedIndorilArmor.Config")
local util = require("akh.SanctionedIndorilArmor.Util")

mwse.overrideScript(config.armorScript, function() end)

local uniform = {
    slots = {
        cuirass = false,
        other = {},
        robe = false
    }
}

function uniform.isWearingVisibleIndorilArmor(self)

    local isWearingOther = false
    for key, value in pairs(self.slots.other) do
        if value then
            isWearingOther = true
            break
        end
    end

    local isWearingCuirass = self.slots.cuirass
    if config.inconspicuousRobes and self.slots.robe then
        isWearingCuirass = false
    end

    return isWearingOther or isWearingCuirass
end

local function isAllowedToWearIndorilArmor()


    local templeRankRequirementMet = true
    local questCompletionRequirementMet = true

    if config.requiredTempleRank > -1 then
        local templeRank = tes3.getFaction(constants.faction.TEMPLE).playerRank
        templeRankRequirementMet = templeRank >= config.requiredTempleRank
    end

    if config.requiredQuestCompletion then
        local id, index = util.splitRequiredQuestCompletion(config.requiredQuestCompletion)
        questCompletionRequirementMet = (tes3.getJournalIndex({ id = id }) or -1) >= tonumber(index)
    end

    return templeRankRequirementMet and questCompletionRequirementMet
end

local function updateWearingOrdinatorUni()

    if not isAllowedToWearIndorilArmor() and uniform:isWearingVisibleIndorilArmor() then
        tes3.setGlobal(config.greetingCheckGlobal, 1)
    else
        tes3.setGlobal(config.greetingCheckGlobal, 0)
    end

end

local function updateUniformStatus()

    for _, stack in pairs(tes3.player.object.equipment) do

        local item = stack.object

        if item.objectType == tes3.objectType.armor and util.isItemIndoril(item) == true then

            if item.slot == tes3.armorSlot.cuirass then
                uniform.slots.cuirass = true
            else
                uniform.slots.other[item.slot] = true
            end

        elseif item.objectType == tes3.objectType.clothing and item.slot == tes3.clothingSlot.robe then
            uniform.slots.robe = true
        end

    end

    updateWearingOrdinatorUni()

end

event.register(constants.event.PLAYER_EQUIPPED_INDORIL, function(e)
    if e.slot == tes3.armorSlot.cuirass then
        uniform.slots.cuirass = true
    else
        uniform.slots.other[e.slot] = true
    end
    updateWearingOrdinatorUni()
end)

event.register(constants.event.PLAYER_UNEQUIPPED_INDORIL, function(e)
    if e.slot == tes3.armorSlot.cuirass then
        uniform.slots.cuirass = false
    else
        uniform.slots.other[e.slot] = false
    end
    updateWearingOrdinatorUni()
end)

event.register(constants.event.PLAYER_EQUIPPED_ROBE, function(e)
    uniform.slots.robe = true
    updateWearingOrdinatorUni()
end)

event.register(constants.event.PLAYER_UNEQUIPPED_ROBE, function(e)
    uniform.slots.robe = false
    updateWearingOrdinatorUni()
end)

event.register("loaded", function()
    updateUniformStatus()
    event.register(constants.event.CONFIG_CHANGED, updateUniformStatus)
end)

event.register(constants.event.TEMPLE_RANK_CHANGED, function()
    updateUniformStatus()
end)

event.register(constants.event.REQUIRED_QUEST_JOURNAL_CHANGED, function()
    updateUniformStatus()
end)

event.register("uiObjectTooltip", function(e)

    if util.isItemIndoril(e.object) then
        local tooltip = e.tooltip
        local text
        if isAllowedToWearIndorilArmor() then
            text = config.strings.labelSanctionedToWear
        else
            text = config.strings.labelProhibitedToWear
        end
        local label = tooltip:createLabel( { id = tes3ui.registerID("akh:sil:IndorilTooltip_prohibited"), text = text })
        label.wrapText = true
    end

end)

local function onInventoryTileUpdated(e)

    if not config.cautiousMerchants then
        return
    end

    local barterMenu = tes3ui.findMenu(tes3ui.registerID("MenuBarter"))
    if not barterMenu then
        return
    end

    local item = e.item
    local element = e.element

    element:register("mouseClick", function(e)
        if util.isItemIndoril(item) then
            tes3.playSound({ sound = "Item Armor Medium Down" })
            tes3.messageBox(tes3.findGMST(tes3.gmst.sBarterDialog4).value)
        else
            element:forwardEvent(e)
        end
    end)

end
event.register("itemTileUpdated", onInventoryTileUpdated, { filter = "MenuInventory" })

print("[" .. modInfo.modName .. " " .. modInfo.modVersion .. "] Ordinator Uniform Module Loaded")