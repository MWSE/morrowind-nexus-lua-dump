
local exp = 0

local creation_complete = false
local enable_magicka_gain = false
local level_cap_unlocked = false
local attribute_cap_unocked = false

--Luck per level
local luck_pts = 1
--Attribute gain
local attr_pts = 1
--How many skills gains for an Attribute increase
local pts2lvl = 2
--How many skill gains for an Attribute increase after lvl 100
local pts2lvl100 = 4
--exp required to level
local exp2lvl = 10


local pt = {
    ['mysticism'] = 0,
    ['destruction'] = 0,
    ['lightarmor'] = 0,
    ['restoration'] = 0,
    ['alteration'] = 0,
    ['longblade'] = 0,
    ['conjuration'] = 0,
    ['illusion'] = 0,
    ['mercantile'] = 0,
    ['enchant'] = 0,
    ['block'] = 0,
    ['armorer'] = 0,
    ['mediumarmor'] = 0,
    ['heavyarmor'] = 0,
    ['unarmored'] = 0,
    ['bluntweapon'] = 0,
    ['axe'] = 0,
    ['spear'] = 0,
    ['athletics'] = 0,
    ['alchemy'] = 0,
    ['security'] = 0,
    ['sneak'] = 0,
    ['acrobatics'] = 0,
    ['shortblade'] = 0,
    ['marksman'] = 0,
    ['speechcraft'] = 0,
    ['handtohand'] = 0
}

local function getCurrentLevel()
    return types.Player.stats.level(self).current
end

local function setLevel(amt)
    types.Player.stats.level(self).current = types.Player.stats.level(self).current + amt
end

local function setHealth(amt)
    types.Player.stats.dynamic.health(self).base = types.Player.stats.dynamic.health(self).base + amt
end

local function setMagicka(amt)
    types.Player.stats.dynamic.magicka(self).base = types.Player.stats.dynamic.magicka(self).base + amt
end

local function getSkillLevel(skill)
    return types.Player.stats.skills[skill](self).base
end


local function modAttribute(attr, amnt)
    types.Player.stats.attributes[attr](self).base = types.Player.stats.attributes[attr](self).base + amnt
end

local function getAttribute(attr)
    return types.Player.stats.attributes[attr](self).base
end

local skillPrev =  {
    ['mysticism'] = getSkillLevel('mysticism'),
    ['destruction'] = getSkillLevel('destruction'),
    ['lightarmor'] = getSkillLevel('lightarmor'),
    ['restoration'] = getSkillLevel('restoration'),
    ['alteration'] = getSkillLevel('alteration'),
    ['longblade'] = getSkillLevel('longblade'),
    ['conjuration'] = getSkillLevel('conjuration'),
    ['illusion'] = getSkillLevel('illusion'),
    ['mercantile'] = getSkillLevel('mercantile'),
    ['enchant'] = getSkillLevel('enchant'),
    ['block'] = getSkillLevel('block'),
    ['armorer'] = getSkillLevel('armorer'),
    ['mediumarmor'] = getSkillLevel('mediumarmor'),
    ['heavyarmor'] = getSkillLevel('heavyarmor'),
    ['unarmored'] = getSkillLevel('unarmored'),
    ['bluntweapon'] = getSkillLevel('bluntweapon'),
    ['axe'] = getSkillLevel('axe'),
    ['spear'] = getSkillLevel('spear'),
    ['athletics'] = getSkillLevel('athletics'),
    ['alchemy'] = getSkillLevel('alchemy'),
    ['security'] = getSkillLevel('security'),
    ['sneak'] = getSkillLevel('sneak'),
    ['acrobatics'] = getSkillLevel('acrobatics'),
    ['shortblade'] = getSkillLevel('shortblade'),
    ['marksman'] = getSkillLevel('marksman'),
    ['speechcraft'] = getSkillLevel('speechcraft'),
    ['handtohand'] = getSkillLevel('handtohand')
}

local attrPrev = {
    ['strength'] = getAttribute('strength'),
    ['intelligence'] = getAttribute('intelligence'),
    ['willpower'] = getAttribute('willpower'),
    ['agility'] = getAttribute('agility'),
    ['speed'] = getAttribute('speed'),
    ['endurance'] = getAttribute('endurance'),
    ['personality'] = getAttribute('personality'),
    ['luck'] = getAttribute('luck')
}

--local function skillPrev(skill)
    --if skill == 'mysticism' then
        --return getSkillLevel('mysticism')
    --end
--end

local function expHandle()
    --Handles the exp and main level of the player. As well as adding health and Magicka per level.

    --Add health using morrowinds original way by dividing the endurance by 10 and rounded down..
    local tempH = math.floor(getAttribute('endurance') / 10)
    --Add Magicka by taking intelligence and adding it to willpower that has been devided by 2 then the sum of those is devided by 15 and rounded down
    local tempM = math.floor((getAttribute('intelligence') + (getAttribute('willpower')/2)) / 15)

    --checks to see if exp is greater or equal to 10 and if so sets the level by 1 and adds the tempH and tempM to health and magicka respectively. Also adds 1 luck and shows a message to the player.
    if exp >= exp2lvl then
		if level_cap_unlocked = true then
			setLevel(1)
        setHealth(tempH)
		if enable_magicka_gain = true
			setMagicka(tempM)
        modAttribute('luck', luck_pts)
        ui.showMessage('You are now level ' .. getCurrentLevel() .."!")
        exp = 0
    end
end

local function skillHandle(skill, attr)
    local skillCur = getSkillLevel(skill)
    local attrCur = getAttribute(attr)

    if types.Actor.inventory(self):countOf("chargen statssheet") > 0 and creation_complete == true then
        skillPrev[skill] = skillCur
        attrPrev[attr] = attrCur
        exp = 0
        types.Player.stats.level(self).current = 1
        pt[skill] = 0
    else
        if skillCur > skillPrev[skill] then
            pt[skill] = pt[skill] + 1
            exp = exp + 1
        end

        if getAttribute(attr) >= 100 && attribute_cap_unocked = true then
            if pt[skill] >= pts2lvl100 then
                modAttribute(attr, attr_pts)
                ui.showMessage('Your ' .. attr .. ' has increased to ' ..  getAttribute(attr) .. "!")
                pt[skill] = 0
            end
        else
            if pt[skill] >= pts2lvl then
                modAttribute(attr, attr_pts)
                ui.showMessage('Your ' .. attr .. ' has increased to ' ..  getAttribute(attr) .. "!")
                pt[skill] = 0
            end
        end
    end
    attrPrev[attr] = attrCur
    skillPrev[skill] = skillCur

end

local function onSave()
    return{
        exp = exp,
        pt = pt,
        creation_complete = creation_complete
    }
end

local function onLoad(data)
    exp = data.exp
    pt = data.pt
    creation_complete = data.creation_complete
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onKeyPress = function(key)
            if key.symbol == 'x' then
                ui.showMessage('Progress to next level is ' .. exp .. '/10')
            end
        end,
        onUpdate = function()
            if types.Actor.inventory(self):countOf("chargen statssheet") > 0 and creation_complete == false then
                creation_complete = true
            end
            if creation_complete == true then
                expHandle()
                skillHandle('mysticism', 'willpower')
                skillHandle('destruction', 'willpower')
                skillHandle('alteration', 'willpower')
                skillHandle('conjuration', 'intelligence')
                skillHandle('illusion', 'personality')
                skillHandle('restoration', 'willpower')
                skillHandle('alchemy', 'intelligence')
                skillHandle('enchant', 'intelligence')
                skillHandle('security', 'intelligence')
                skillHandle('sneak', 'agility')
                skillHandle('heavyarmor', 'endurance')
                skillHandle('mediumarmor', 'endurance')
                skillHandle('spear', 'endurance')
                skillHandle('acrobatics', 'strength')
                skillHandle('armorer', 'strength')
                skillHandle('axe', 'strength')
                skillHandle('bluntweapon', 'strength')
                skillHandle('longblade', 'strength')
                skillHandle('block', 'agility')
                skillHandle('lightarmor', 'agility')
                skillHandle('marksman', 'agility')
                skillHandle('athletics', 'speed')
                skillHandle('shortblade', 'speed')
                skillHandle('unarmored', 'speed')
                skillHandle('handtohand', 'speed')
                skillHandle('mercantile', 'personality')
                skillHandle('speechcraft', 'personality')
            end
        end,
    },
}