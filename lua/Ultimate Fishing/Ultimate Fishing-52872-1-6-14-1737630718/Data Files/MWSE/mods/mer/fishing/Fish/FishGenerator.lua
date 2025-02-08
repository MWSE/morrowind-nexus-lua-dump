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

---@class Fishing.FishGenerator.validFishTypes.rarities
---@field common Fishing.FishType[] @Common fish that are active for this class
---@field uncommon Fishing.FishType[] @Uncommon fish that are active for this class
---@field rare Fishing.FishType[] @Rare fish that are active for this class
---@field legendary Fishing.FishType[] @Legendary fish that are active for this class
---@field all Fishing.FishType[] @All fish that are active for this class

---@class Fishing.FishGenerator.validFishTypes
---@field small Fishing.FishGenerator.validFishTypes.rarities @Small fish that are active at this depth
---@field medium Fishing.FishGenerator.validFishTypes.rarities @Medium fish that are active at this depth
---@field large Fishing.FishGenerator.validFishTypes.rarities @Large fish that are active at this depth
---@field loot Fishing.FishGenerator.validFishTypes.rarities @Loot that is active at this depth

---Generate a fish
---@param depth number? If not provided, depth check is skipped
---@return Fishing.FishGenerator.validFishTypes
function FishGenerator.getValidFish(depth)
    ---@type Fishing.FishGenerator.validFishTypes
    local validFishTypes ={
        small = {
            common = {},
            uncommon = {},
            rare = {},
            legendary = {},
            all = {},
        },
        medium = {
            common = {},
            uncommon = {},
            rare = {},
            legendary = {},
            all = {},
        },
        large = {
            common = {},
            uncommon = {},
            rare = {},
            legendary = {},
            all = {},
        },
        loot = {
            common = {},
            uncommon = {},
            rare = {},
            legendary = {},
            all = {},
        },
    }
    logger:debug("Picking fish")
    for id, fishType in pairs(FishType.registeredFishTypes) do
        if tes3.getObject(fishType.baseId) then
            logger:trace("Checking fish %s", id)
            if fishType:isActive(depth) then
                logger:trace("- %s is active", id)
                local rarity = fishType.rarity
                local class = fishType.class
                logger:trace("- Rarity: %s, class: %s", rarity, class)
                table.insert(validFishTypes[class][rarity], fishType)
                table.insert(validFishTypes[class].all, fishType)
            end
        else
            logger:trace("%s object does not exist", id)
        end
    end
    return validFishTypes
end

function FishGenerator.getFishById(id)
    return FishType.registeredFishTypes[id]
end


---Check the bait against the fish and roll for it
---@param fish Fishing.FishType
---@param frequencyMultipler number
function FishGenerator.attemptSnag(fish, frequencyMultipler, proportionEffect)
    logger:debug("Attempting to snag %s", fish.baseId)
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
    logger:debug("\n- Bait effect: %s\n- Rarity effect: %s\n- FrequencyMultipler: %s",
        baitEffect, rarityEffect, frequencyMultipler)
    local needed = 0.5
    * baitEffect
    * rarityEffect
    * proportionEffect
    * frequencyMultipler
    local roll = math.random()

    logger:debug("- Roll: %s, needed: %s", roll, needed)

    local didSnag = roll < needed
    if didSnag then
        logger:debug("- Snagged %s", fish.baseId)
    end
    return didSnag
end

--The smaller the proportion of fish,
-- the larger the multiplier to make up for it
---@param fishList Fishing.FishGenerator.validFishTypes.rarities
---@param pick Fishing.FishType
---@return number
function FishGenerator.getProportionEffect(fishList, pick)
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

--[[
    Select class based on bait
    Select rarity
]]

---@param validFishTypes Fishing.FishGenerator.validFishTypes
---@param classCatchChances Fishing.BaitType.classCatchChances
---@return string|nil
local function pickClass(validFishTypes, classCatchChances)
    logger:debug("Picking class using class catch chances: %s", require("inspect").inspect(classCatchChances))
    -- Calculate the total chance by summing up all the chances in the classCatchChances table
    local totalChance = 0
    for class, chance in pairs(classCatchChances) do
        logger:debug("- %s: %s", class, chance)
        totalChance = totalChance + chance
    end
    logger:debug("- Total chance: %s", totalChance)

    local roll = math.random()
    logger:debug("- Roll: %s", roll)

    -- Calculate the class based on the random value and the chances
    local cumulativeChance = 0
    for class, chance in pairs(classCatchChances) do
        cumulativeChance = cumulativeChance + chance / totalChance
        if roll <= cumulativeChance then
            logger:debug("- Picked class %s", class)
            -- log fish in this class
            for _, fish in ipairs(validFishTypes[class].all) do
                logger:debug("- %s", fish.baseId)
            end
            return class
        else
            logger:trace("- Did not pick class %s. Roll: %s, cumulativeChance: %s", class, roll, cumulativeChance)
        end
    end
    logger:error("No class picked")
end

---Generate a fish instance
---@param e Fishing.FishGenerator.Params
function FishGenerator.generate(e)
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

    local validFishTypes = FishGenerator.getValidFish(e.depth)
    local class = pickClass(validFishTypes, bait:getType().classCatchChances)
    ---@type Fishing.FishGenerator.validFishTypes.rarities
    local classList = validFishTypes[class]
    if classList == nil or #classList.all == 0 then
        logger:debug("No valid fish in class %s", class)
        return nil
    end

    ---A multiplier that increases with each attempt until a fish is caught
    local frequencyMultipler = 1.0
    local instance --[[@as Fishing.FishType.instance]]

    local override = tes3.player.tempData.mer_fish_override
    if override and FishType.registeredFishTypes[override] then
        instance = FishType.registeredFishTypes[override]:instance()
    end

    while (#classList.all > 0) and (instance == nil) do
        local pick = table.choice(classList.all) --[[@as Fishing.FishType]]
        local proportionEffect = FishGenerator.getProportionEffect(classList, pick)
        if FishGenerator.attemptSnag(pick, frequencyMultipler, proportionEffect) then
            logger:debug("Picked %s", pick.baseId)
            instance = pick:instance()
            if not instance then
                logger:debug("%s is not a valid pick, trying again", pick.baseId)
                table.removevalue(classList.all, pick)
            end
        end
        frequencyMultipler = frequencyMultipler + 0.05
    end

    if not instance then
        logger:warn("No valid fish types available")
        return nil
    end

    if tes3.player and tes3.player.data.merDebugEnabled then
        tes3.messageBox("Picked %s", instance:getName())
    end

    return instance
end

return FishGenerator