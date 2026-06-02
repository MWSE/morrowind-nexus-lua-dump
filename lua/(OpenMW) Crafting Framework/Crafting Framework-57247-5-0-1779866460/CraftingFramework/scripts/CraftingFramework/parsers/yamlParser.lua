local markup = require('openmw.markup')

local this = {}

function this.parseYamlRecipes(yamlString)
    local data = markup.decodeYaml(yamlString)
    if not data then
        print("Error parsing YAML")
        return {}
    end

    local professions = {}
    local invalidFactions = {}

    for i, record in ipairs(data) do
        local recipe, category, profession = createRecipe({
			id = record.id,
			craftingCategory = record.craftingCategory,
			types = record.types,
			nameOpt = record.nameOpt or record.name,
			level = record.level,
			factionRank = record.factionRank,
			faction = record.faction,
			producedCountOpt = record.count,
			disabled = record.disabled,
			hidden = record.hidden,
			craftingSound = record.craftingSound,
			craftingTime = record.craftingTime,
			craftingInterval = record.craftingInterval,
			experience = record.experience,
			skill = record.skill,
			secondLevel = record.secondLevel,
			secondSkill = record.secondSkill,
			preserveRecordId = record.preserveRecordId,
			ingredients = record.ingredients,
			tools = record.tools,
			stations = record.stations,
			craftingEvent = record.craftingEvent,
			qualityFunc = record.qualityFunc,
			expFunc = record.expFunc or record.xpFunc,
			statsFunc = record.statsFunc,
			enchantmentFunc = record.enchantmentFunc,
			valueFunc = record.valueFunc,
			resultFunc = record.resultFunc,
			countFunc = record.countFunc,
			nameFunc = record.nameFunc,
			ingredientsFunc = record.ingredientsFunc,
			timeFunc = record.timeFunc,
			finalizeCraftFunc = record.finalizeCraftFunc,
			userData = record.userData,
			profession = record.profession,
			manualProgress = record.manualProgress,
			additionalProducts = record.additionalProducts,
		}, invalidFactions)
        if recipe then
            professions[profession] = professions[profession] or {}
            professions[profession][category] = professions[profession][category] or {}
            table.insert(professions[profession][category], recipe)
        elseif (record.id or "") ~= "" then
            print("Skipped " .. i .. ": " .. category)
        end
    end

    printInvalidRecords(invalidFactions)
    return professions
end

return this