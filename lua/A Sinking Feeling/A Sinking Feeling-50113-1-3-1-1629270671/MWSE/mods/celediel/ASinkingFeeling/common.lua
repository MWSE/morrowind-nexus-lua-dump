local this = {}

this.modName = "A Sinking Feeling"
this.author = "Celediel"
this.modInfo = "No longer can you swim in heavy plate; now your armour, equipment, or carried items drag you down while swimming.\n\n" ..
	"Options exist for formulas based on equipped armour weight class, total equipment weight or encumbrance percentage.\n\n" ..
	"What is dead may never die."
this.version = "1.3.1"
this.configString = string.gsub(this.modName, "%s+", "")
this.modes = {
	{
		mode = "equippedArmour",
		description = "Actors are pulled down by their combined armour class (Light = 1, Medium = 2, Heavy = 3) multiplied by a tenth of " ..
		"the down-pull multiplier. Default of 100 makes it impossible to surface in all heavy armour for all but the most Athletic.",
	},
	{
		mode = "allEquipment",
		description = "Actors are pulled down by double the weight of all equipped gear multiplied by a hundredth of the down-pull multiplier.",
	},
	{
		mode = "allEquipmentNecroEdit",
		description = "Actors are pulled down by double the weight of all equipped gear multiplied by a hundredth of the down-pull multiplier, " ..
		"except any weight above 135 only counts 10%. Lessens the gap between the lightest and heaviest heavy armours.",
	},
	{
		mode = "encumbrancePercentage",
		description = "Actors are pulled down by their encumbrance percentage multiplied by triple the down-pull multiplier.",
	},
	{
		mode = "worstCaseScenario",
		description = "Calculates results from all formulas, and uses the highest value.",
	},
	{
		mode = "bestCaseScenario",
		description = "Calculates results from all formulas, and uses the lowest value.",
	}
}

this.log = function(...) mwse.log("[%s] %s", this.modName, string.format(...)) end

this.camelCaseToWords = function(str)
    local function spaceBefore(word)
        return " " .. word
    end

    local function titleCase(first, rest)
        return first:upper() .. rest:lower()
    end

    local words = str:gsub("%u", spaceBefore)
    return words:gsub("(%a)([%w_']*)", titleCase)
end

-- picks the key of the largest value out of a key:whatever, value:number table
this.keyOfLargestValue = function(t)
    local picked
    local largest = -math.huge
    for key, value in pairs(t) do
        if value > largest then
            largest = value
            picked = key
        end
    end
    return picked
end

-- picks the key of the smallest value out of a key:whatever, value:number table
this.keyOfSmallestValue = function(t)
    local picked
    local smallest = math.huge
    for key, value in pairs(t) do
        if value < smallest then
            smallest = value
            picked = key
        end
    end
    return picked
end

return this
