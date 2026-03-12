require("scripts.MeritsOfService.utils.random")

function PickRewardType(possibleRewards, settingsMap, prevWeights)
    local weights = prevWeights

    -- populate weights if it's the first iteration
    if not weights then
        weights = {}
        for rewardType, _ in pairs(possibleRewards) do
            local weight = settingsMap[rewardType].weightGetter()
            weights[rewardType] = weight ~= 0 and weight
        end
    end

    local rewardType = WeightedRandom(weights)
    -- if all weights are 0
    -- OR if the table is empty
    if not rewardType then return nil end

    local condition = settingsMap[rewardType].condition
    local conditionSatisfied = true
    -- condition is optional and true by default
    if condition then
        conditionSatisfied = condition(possibleRewards[rewardType])
        -- removing current item from weights in case we will go into recursion
        weights[rewardType] = nil
    end

    return conditionSatisfied
        and rewardType
        or PickRewardType(possibleRewards, settingsMap, weights)
end
