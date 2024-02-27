-- will be done once Skill Editing is available

local ui = require('openmw.ui')
local core = require("openmw.core")
local Player = require('openmw.types').Player
local NPC = require('openmw.types').NPC
local self = require('openmw.self')
local settings = require("scripts.comprehensive_rebalance.lib.settings")
local section = settings.GetSection("char")

-- Vanilla Health Formula is
-- ((lvl 1 Strength + lvl 1 Endurance) / 2) + 10% of END per level, calculated per level
-- We want to make it
-- ((lvl 1 Strength + lvl 1 Endurance) / 2) + (END / 10 * level - 1)


local current_base = 0

local function onSave()
    return {
        current_max = current_max
    }
end

local function onLoad(savedData, initData)
    current_max = savedData.current_max
end

local function GetClassAttributeBonus(attribute)
	local class = NPC.classes.record(NPC.record(self).class)
	
    for _, attr in ipairs(class.attributes) do
        if attr == attribute then
            print (attr)
            return 10
        end
    end

    return 0

end

--These are filthy dirty hacks until we get proper support for Race and Class records
local function GetLevel1Strength()

	local race = NPC.record(self).race
	local isMale = NPC.record(self).isMale

	local total = 40

	-- race
	if race == 'breton' and not isMale then
		total = 30
	elseif race == 'high elf' then
		total = 30
	elseif race == 'khajiit' and not isMale then
		total = 30
	elseif race == 'nord' then
		total = 50
	elseif race == 'orc' then
		total = 45
	elseif race == 'redguard' and isMale then
		total = 50
	elseif race == 'wood elf' then
		total = 30
	end
    
    --add class bonus
    total = total + GetClassAttributeBonus('strength')
	return total

end

--These are filthy dirty hacks until we get proper support for Race and Class records
local function GetLevel1Endurance()
	
	local race = NPC.record(self).race
	local isMale = NPC.record(self).isMale

	local total = 40

	if race == 'argonian' or race == 'breton' or race == 'wood elf' then
		total = 30
	elseif race == 'dark elf' and not isMale then
		total = 30
	elseif race == 'high elf' and not isMale then
		total = 30
	elseif race == 'khajiit' and not isMale then
		total = 30
	elseif race == 'nord' and isMale then
		total = 50
	elseif race == 'orc' or race == 'redguard' then
		total = 50
	end

    --add class bonus
    total = total + GetClassAttributeBonus('endurance')
    return total

end

local function RecalculateHealth()

	local baseEND = Player.stats.attributes["endurance"](self).base
	local baseSTR = Player.stats.attributes["strength"](self).base
	local currentLevel = Player.stats.level(self).current
	local scale = section:get("newHealthFormulaScale")
		
	--calculate level 1 health value
	local lvl1STR = GetLevel1Strength()
	local lvl1END = GetLevel1Endurance()
	local lvl1Health = (lvl1STR + lvl1END) * 0.5
	
	local totalEnd = 0
	
	--ui.showMessage('lvl1End: ' .. lvl1END)
	
	--get base health at lvl 1
	local newBaseHealth = lvl1Health
	
	--now "level up" as if we put the maximum amount into endurance each level up
	local calcLevel = 2
	while calcLevel <= currentLevel do
	
		--get the amount of endurance we will have this level
		local levelEnd = lvl1END + ((calcLevel - 1) * scale)
		
		--clamp it to our max end
		if (levelEnd > baseEND) then
			levelEnd = baseEND
		end
		
		totalEnd = levelEnd
				
		--calculate health for that level and add it to our base health
		--todo: use GMST fLevelUpHealthEndMult instead of 0.1
		newBaseHealth = newBaseHealth + levelEnd * 0.1
		
		--ui.showMessage('At level ' .. calcLevel .. ', endurance will be ' .. levelEnd .. ', resulting in ' .. newBaseHealth .. ' health')
		
		calcLevel = calcLevel + 1
	end
	
	--calculate health for any remaining endurance
	local remaining = baseEND - totalEnd
	--ui.showMessage('remaining endurance: ' .. remaining)
	if remaining > 0 then
		--ui.showMessage('Add any extra Endurance (from books etc): ' .. remaining)
		newBaseHealth = newBaseHealth + remaining * 0.1
	end
	
	return newBaseHealth

end

local function SetPlayerHealth(value)
    local actualHealth = Player.stats.dynamic.health(self).base
    local difference = value - actualHealth

    Player.stats.dynamic.health(self).base = value
    Player.stats.dynamic.health(self).current = Player.stats.dynamic.health(self).current + difference

    current_max = value
end

local function SetHealthFormula(data)
	if data.newMode == "Interface" or data.oldMode == "LevelUp" then
		if section:get("newHealthFormula") then
		
			local health = RecalculateHealth()
            if health ~= current_max then
                --ui.showMessage('recalc health - new formula. Health is ' .. health)
                SetPlayerHealth(health)
            end
		end
	end
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave
    },

    eventHandlers = {
		UiModeChanged = SetHealthFormula
	}
}
