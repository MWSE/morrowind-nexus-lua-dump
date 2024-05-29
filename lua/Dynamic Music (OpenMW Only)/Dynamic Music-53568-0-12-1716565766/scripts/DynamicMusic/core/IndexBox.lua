local IndexBox = {}

function IndexBox.Create(sections, possibleEntries, validator)
    local cardIndex = {}
    cardIndex.contains = IndexBox.contains

    for _, section in pairs(sections) do
        for _, possibleEntry in ipairs(possibleEntries) do
            if validator(section, possibleEntry) then
                local entry = cardIndex[section]
                if not entry then
                    entry = {}
                    cardIndex[section] = entry
                end
                cardIndex[section][possibleEntry] = true
            end
        end
    end

    return cardIndex
end

function IndexBox.contains(self, section, entry)
    return self[section] and self[section][entry]
end

return IndexBox
