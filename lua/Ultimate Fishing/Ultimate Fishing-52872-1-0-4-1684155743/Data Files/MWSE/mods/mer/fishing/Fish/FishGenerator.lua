--[[
    This class will create an instance of a fish.
    The type of fish is determined by the region and time of day
    the player is fishing. The quality of the fish determined
    by the player's attributes and fishing skill.
]]
local common = require("mer.fishing.common")
local logger = common.createLogger("FishGenerator")
local FishingSkill = require("mer.fishing.FishingSkill")
local FishType = require("mer.fishing.Fish.FishType")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")

---@class Fishing.FishGenerator
local FishGenerator = {}

---@class Fishing.FishGenerator.Params
---@field depth number


---@class Fishing.FishGenerator.validFishTypes
---@field all Fishing.FishType[] @All fish that are active at this depth
---@field common Fishing.FishType[] @Common fish that are active at this depth
---@field uncommon Fishing.FishType[] @Uncommon fish that are active at this depth
---@field rare Fishing.FishType[] @Rare fish that are active at this depth
---@field legendary Fishing.FishType[] @Legendary fish that are active at this depth

---Generate a fish
---@return Fishing.FishGenerator.validFishTypes
local function getValidFish(depth)
    local validFishTypes ={
        all = {},
        common = {},
        uncommon = {},
        rare = {},
        legendary = {},
    }
    logger:debug("Picking fish")
    for id, fish in pairs(FishType.registeredFishTypes) do
        logger:trace("Checking fish %s", id)
        if fish.niche:isActive(depth) then
            logger:debug("- %s is active", id)
            table.insert(validFishTypes[fish.rarity], fish)
            table.insert(validFishTypes.all, fish)
        end
    end
    return validFishTypes
end

---Check the bait against the fish and roll for it
---@param fish Fishing.FishType
---@param frequencyMultipler number
local function attemptSnag(fish, frequencyMultipler, proportionEffect)
    logger:trace("Attempting to snag %s", fish.baseId)
    local fishingRod = FishingRod.getEquipped()
    if not fishingRod then
        logger:error("- No fishing rod equipped")
        return false
    end
    local bait = fishingRod:getEquippedBait()
    if not bait then
        logger:error("- No bait equipped")
        return false
    end

    local rarityEffect = fish:getRarityEffect()

    local baitEffect = bait:getType():getFishEffect(fish)

    logger:trace("\n- Bait effect: %s\n- Rarity effect: %s\n- FrequencyMultipler: %s",
        baitEffect, rarityEffect, frequencyMultipler)
    local needed = 0.5
    * baitEffect
    * rarityEffect
    * frequencyMultipler
    * proportionEffect
    local roll = math.random()

    logger:trace("- Roll: %s, needed: %s", roll, needed)

    local didSnag = roll < needed
    if didSnag then
        logger:debug("- Snagged %s", fish.baseId)
    end
    return didSnag
end

--The smaller the proportion of fish,
-- the larger the multiplier to make up for it
---@param fishList Fishing.FishGenerator.validFishTypes
---@param pick Fishing.FishType
local function getProportionEffect(fishList, pick)
    logger:trace("Getting proportion effect for %s", pick.baseId)
    local total = #fishList.all
    local rarity = pick.rarity
    local rarityCount = #fishList[rarity]
    logger:trace("%s: %s; total: %s", rarity, rarityCount, total)
    local proportion = rarityCount / total
    logger:trace("Proportion: %s", proportion)
    local proportionEffect = 1.0 + (1.0 - proportion)
    logger:trace("Proportion effect: %s", proportionEffect)
    return proportionEffect
end

---Generate a fish instance
---@param e Fishing.FishGenerator.Params
function FishGenerator.generate(e)
    local validFishTypes = getValidFish(e.depth)
    logger:debug("%s fish types available", #validFishTypes.all)

    ---A multiplier that increases with each attempt until a fish is caught
    local frequencyMultipler = 1.0
    local instance
    while #validFishTypes.all > 0 and not instance do
        local pick = table.choice(validFishTypes.all) --[[@as Fishing.FishType]]
        local proportionEffect = getProportionEffect(validFishTypes, pick)
        if attemptSnag(pick, frequencyMultipler, proportionEffect) then
            logger:debug("Picked %s", pick.baseId)
            instance = pick:instance()
            if not instance then
                logger:debug("%s is not a valid pick, trying again", pick.baseId)
                table.removevalue(validFishTypes.all, pick)
            end
        end
        frequencyMultipler = frequencyMultipler + 0.05
    end
    if not instance then
        logger:warn("No valid fish types available")
        return nil
    end
    return instance
end

return FishGenerator