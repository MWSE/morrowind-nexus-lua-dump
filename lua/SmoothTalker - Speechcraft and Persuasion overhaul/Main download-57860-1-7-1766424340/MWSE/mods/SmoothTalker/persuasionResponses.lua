--[[
    Persuasion Response Generation Module
    Handles selection and generation of NPC responses to persuasion attempts
]]

local logger = require("logging.logger")
local log = logger.new{
    name = "SmoothTalker.PersuasionResponses",
    logLevel = "INFO"
}

local i18n = mwse.loadTranslations("SmoothTalker")
local responsesModule = i18n("responses.module")
local responsesAPI = require(responsesModule)
local responses = responsesAPI.responses
local patience = require("SmoothTalker.patience")

local persuasionResponses = {}

-- Category weights for response selection
local responseCategoryWeights = {
    faction = 50,
    race = 20,
    class = 20,
    generic = 10
}

--- Get the appropriate response category based on NPC attributes
--- @param npcRef tes3reference The NPC reference
--- @param action string The persuasion action
--- @param outcome string "success" or "failure"
--- @param tier string Disposition/bribe tier
--- @return string The selected category name
local function getResponseCategory(npcRef, action, outcome, tier)
    local npc = npcRef.object

    -- Build weighted list of available categories
    local categoryWeights = {}
    local totalWeight = 0

    -- Check each category and assign weights if responses exist
    local function addCategory(categoryName, weight)
        local responseList = responses[action]
            and responses[action][outcome]
            and responses[action][outcome][categoryName]
            and responses[action][outcome][categoryName][tier]

        if responseList and #responseList > 0 then
            table.insert(categoryWeights, {category = categoryName, weight = weight})
            totalWeight = totalWeight + weight
        end
    end

    if npc.faction then
        addCategory("faction_" .. npc.faction.id:lower(), responseCategoryWeights.faction)
    end

    if npc.race then
        addCategory("race_" .. npc.race.id:lower(), responseCategoryWeights.race)
    end

    if npc.class then
        addCategory("class_" .. npc.class.id:lower(), responseCategoryWeights.class)
    end

    -- Generic responses always available as fallback
    addCategory("generic", responseCategoryWeights.generic)

    -- If no categories found (shouldn't happen if generic is defined), use generic
    if totalWeight == 0 then
        return "generic"
    end

    -- Weighted random selection
    local roll = math.random() * totalWeight
    local currentWeight = 0

    for _, entry in ipairs(categoryWeights) do
        currentWeight = currentWeight + entry.weight
        if roll <= currentWeight then
            return entry.category
        end
    end

    -- Fallback to last category (should never reach here)
    return categoryWeights[#categoryWeights].category
end

--- Get a random response for a persuasion attempt
--- @param npcRef tes3reference The NPC reference
--- @param action string The persuasion action
--- @param success boolean Whether the attempt succeeded
--- @param bribeAmount number|nil The bribe amount (if action is bribe)
--- @return string The response text
function persuasionResponses.getRandomResponse(npcRef, action, success, bribeAmount)
    local disposition = npcRef.object.disposition
    local tier

    -- If patience is depleted, always use depleted tier for failures
    local patienceDepleted = patience.isDepleted(npcRef)
    if patienceDepleted and not success then
        tier = "depleted"
    elseif action == "bribe" then
        if bribeAmount < 100 then
            tier = "small"
        elseif bribeAmount < 500 then
            tier = "medium"
        else
            tier = "large"
        end
    else
        if disposition >= 70 then
            tier = "high"
        elseif disposition >= 40 then
            tier = "medium"
        else
            tier = "low"
        end
    end

    local outcome = success and "success" or "failure"

    local category = getResponseCategory(npcRef, action, outcome, tier)

    local responseList = responses[action]
        and responses[action][outcome]
        and responses[action][outcome][category]
        and responses[action][outcome][category][tier]

    -- Pick a random response from the list
    if responseList and #responseList > 0 then
        return responseList[math.random(#responseList)]
    else
        -- Fallback if no responses found
        log:warn("No response found for: %s/%s/%s/%s", action, outcome, category, tier)
        return string.format("[%s %s]", action, outcome)
    end
end

return persuasionResponses
