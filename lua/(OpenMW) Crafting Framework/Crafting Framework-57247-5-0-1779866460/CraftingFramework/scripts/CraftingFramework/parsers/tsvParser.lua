return function(tsvContent)
    local lines = {}
    for line in tsvContent:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local professions = {}
    local invalidFactions = {}

    for i = 1, #lines do
        local line = lines[i]
        if line and trim(line) ~= "" and line:sub(1, #"Raw data from ") ~= "Raw data from " and line:sub(1, #"item code\tIn-Game Label") ~= "item code\tIn-Game Label" then
            local fields = {}
            local temp = line .. '\t'
            temp:gsub('([^\t]*)\t', function(field)
                table.insert(fields, field)
                return ''
            end)

            -- ingredients
            local ingredients = {}
            local materialFields = {
                { fields[20], fields[19] },
                { fields[22], fields[21] },
                { fields[24], fields[23] },
                { fields[26], fields[25] },
                { fields[28], fields[27] },
            }
            -- material aliases are legacy-only: resolve here, not in createRecipe
            for _, mat in ipairs(materialFields) do
                local id, count = mat[1], tonumber(mat[2]) or 0
                if id and id ~= "" and count > 0 then
                    table.insert(ingredients, { id = materialMapping[id:lower()] or id, count = count })
                end
            end

            -- tools
            local tools = {}
            local toolFields = { fields[39], fields[40]}
            for _, id in ipairs(toolFields) do
                if id and id ~= "" then
                    table.insert(tools, { id = id })
                end
            end

            -- stations
            local recipeStations = {}
            local stationFields = { fields[41]}
            for _, id in ipairs(stationFields) do
                if id and id ~= "" then
                    table.insert(recipeStations, { id = id })
                end
            end

            local recipe, category, profession = createRecipe({
                id = fields[1],
                craftingCategory = fields[11],
                types = fields[12],
                nameOpt = fields[13],
                level = fields[15],
                factionRank = fields[16],
                faction = fields[17],
                producedCountOpt = fields[18],
                ingredients = ingredients,
                tools = tools,
                stations = recipeStations,
                disabled = fields[30],
                craftingSound = fields[31],
                craftingTime = fields[32],
                experience = fields[33],
                skill = fields[34],
                secondLevel = fields[35],
                secondSkill = fields[36],
				craftingEvent = fields[42],     -- AP
				profession = fields[43],        -- AQ
				craftingInterval = fields[44],  -- AR
				hidden = fields[45],            -- AS
            }, invalidFactions)

            if recipe then
                professions[profession] = professions[profession] or {}
                professions[profession][category] = professions[profession][category] or {}
                table.insert(professions[profession][category], recipe)
            elseif (fields[1] or "") ~= "" then
                print("Skipped: " .. category)
            end
        end
    end

    printInvalidRecords(invalidFactions)
    return professions
end