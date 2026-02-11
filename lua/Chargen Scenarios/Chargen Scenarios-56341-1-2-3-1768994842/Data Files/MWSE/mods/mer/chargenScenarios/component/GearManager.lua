local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("GearManager")

---@class (exact) ChargenScenarios.GearManager
---@field gearLists table<string, string[]> Lists of starter gear that can be used in conjunction with ItemPick.pickBestForClass
---@field getBestItemForClass fun(itemIds: string[]): tes3object? Get the best item for the player's class from a list of item ids
local GearManager = {}


local armorRatingToSkillMapping = {
    [tes3.armorWeightClass.light] = tes3.skill.lightArmor,
    [tes3.armorWeightClass.medium] = tes3.skill.mediumArmor,
    [tes3.armorWeightClass.heavy] = tes3.skill.heavyArmor,
}

---@param item tes3weapon|tes3armor|tes3item
local function getSkillForItem(item)
    if item.objectType == tes3.objectType.weapon then
        return item.skill.id
    elseif item.objectType == tes3.objectType.armor then
        return armorRatingToSkillMapping[item.weightClass]
            or tes3.skill.unarmored
    end
end

---@param itemIds tes3item[]
---@return tes3object?
function GearManager.getBestItemForClass(itemIds)

    ---Matches major skill = 2 points
    ---Matches minor skill = 1 point
    local class = tes3.player.object.class
    logger:debug("Picking item for class %s", class.name)

    local majorItems = {}
    local minorItems = {}
    local miscItems = {}

    local majorSkills = table.invert(class.majorSkills)
    local minorSkills = table.invert(class.minorSkills)
    for _, item in ipairs(itemIds) do

        --get relevant skill
        local skill = getSkillForItem(item)
        logger:debug(" - Item: %s, skill: %s", item and item.id or "nil", skill or "nil")

        --Insert into appropriate list
        if skill and majorSkills[skill] then
            table.insert(majorItems, item)
        elseif skill and minorSkills[skill] then
            table.insert(minorItems, item)
        else
            table.insert(miscItems, item)
        end
    end

    --Pick from best list
    local choice
    if #majorItems > 0 then
        logger:debug("Found major skills")
        choice =  table.choice(majorItems)
    elseif #minorItems > 0 then
        logger:debug("Found minor skills")
        choice = table.choice(minorItems)
    elseif #miscItems > 0 then
        choice = table.choice(miscItems)
    end
    logger:debug("Picked %s for class %s", choice and choice.id or "nothing", class.name)
    return choice
end


return GearManager