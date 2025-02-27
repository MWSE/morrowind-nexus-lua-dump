local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')

local attributes = {
    'strength',
    'intelligence',
    'willpower',
    'agility',
    'speed',
    'endurance',
    'personality',
    'luck',
}

local attributeBonuses = {
    ['strength'] = 0,
    ['intelligence'] = 0,
    ['willpower'] = 0,
    ['agility'] = 0,
    ['speed'] = 0,
    ['endurance'] = 0,
    ['personality'] = 0,
    ['luck'] = 0,
}

local level = 1

local cached_attributes = nil

-- General Functions

local function getCurrentLevel()
    return types.Player.stats.level(self).current
end

local function getAttribute(attr)
    return types.Player.stats.attributes[attr](self).base
end

local function getAttributeBonuses()
	for _, attribute in ipairs(attributes) do
        attributeBonuses[attribute] = types.Player.stats.level(self).skillIncreasesForAttribute[attribute]
    end
end

local function cacheAttributes()
    if cached_attributes == nil then
        cached_attributes = {}
    end
    for _, attribute in ipairs(attributes) do
        cached_attributes[attribute] = getAttribute(attribute)
    end
end

local function setAttributeBonus(attribute, value)
    types.Player.stats.level(self).skillIncreasesForAttribute[attribute] = value
end

-- Engine Handlers
local function onLoad()
    level = getCurrentLevel()
	getAttributeBonuses()
	cacheAttributes()
end

local function onUpdate()
	
    if (getCurrentLevel() > level and getCurrentLevel() > 1) then
        --Update the level var
        level = getCurrentLevel()

        for _, attribute in ipairs(attributes) do
            ui.printToConsole('Raw '.. attribute.. ': '.. tostring(getAttribute(attribute)).. '. Cached: '.. tostring(cached_attributes[attribute]), ui.CONSOLE_COLOR.Error)
            --check which attributes went up then reduce the bonus
            if(getAttribute(attribute) > cached_attributes[attribute]) then
                if attributeBonuses[attribute] > 10 then
                    attributeBonuses[attribute] = attributeBonuses[attribute] - 10
                    setAttributeBonus(attribute, attributeBonuses[attribute])
                else
                    attributeBonuses[attribute] = 0
                end
            else
                --apply all stored bonuses
                setAttributeBonus(attribute, attributeBonuses[attribute])
            end
        end		
    else
        getAttributeBonuses()
        cacheAttributes()
    end

end

return {
    engineHandlers = {
        onLoad = onLoad,
        onUpdate = onUpdate,
    }
}