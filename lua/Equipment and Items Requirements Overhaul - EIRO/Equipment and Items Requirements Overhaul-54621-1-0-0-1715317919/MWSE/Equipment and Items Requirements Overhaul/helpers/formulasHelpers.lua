--Formula Helpers
local function getMaxWeaponDamage(item)
    local chopMax = item.chopMax or 0
    local slashMax = item.slashMax or 0
    local thrustMax = item.thrustMax or 0

    -- Determine the maximum damage value among chop, slash, and thrust
    local maxDamage = math.max(chopMax, slashMax, thrustMax)
    return maxDamage
end


local function getXword(inputString, wordList)
    for _, word in ipairs(wordList) do
        -- Escape any Lua pattern special characters in word to treat them as plain text
        local escapedWord = word:gsub("([%p])", "%%%1")
        -- Try to find the word in the input string
        if inputString:find(escapedWord) then
            return word
        end
    end
    return nil -- return nil if no match is found
end

local function rFPN(value)
    if value < 0 then
        return 0
    else
        return value
    end
end


return {
    getMaxWeaponDamage = getMaxWeaponDamage,
    getXword = getXword,
    rFPN = rFPN
}
