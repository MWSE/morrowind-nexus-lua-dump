local types = require('openmw.types')
local self  = require('openmw.self')
local I     = require('openmw.interfaces')

local function OnMiss(data)
    --print('Player missed with weapon type: ' .. tostring(data.weaponType))
    -- XP logic goes here
    if data.weaponType == 0
    then
         --print('this ought to be a short blade!')
         I.SkillProgression.skillUsed('shortblade', {useType = 0, scale = 0.25})

    elseif data.weaponType == 1 or data.weaponType == 2
    then
         --print ('this ought to be a long blade!')
         I.SkillProgression.skillUsed('longblade', {useType = 0, scale = 0.25})

    elseif data.weaponType == 3 or data.weaponType == 4 or data.weaponType == 5
    then
         --print ('this ought to be a blunt weapon!')
         I.SkillProgression.skillUsed('bluntweapon', {useType = 0, scale = 0.25})

    elseif data.weaponType == 6
    then
         --print ('this ought to be a spear!')
         I.SkillProgression.skillUsed('spear', {useType = 0, scale = 0.25})

    elseif data.weaponType == 7 or data.weaponType == 8
    then
         --print('this ought to be an axe!')
         I.SkillProgression.skillUsed('axe', {useType = 0, scale = 0.25})

    elseif data.weaponType == 9 or data.weaponType == 10
    then
        --print('this is strange! you must be using your bow or crossbow for melee! how unusual!')

    elseif data.weaponType == 11 or data.weaponType == 12 or data.weaponType == 13
    then
         --print('this ought to be a marksman weapon!')
         I.SkillProgression.skillUsed('marksman', {useType = 0, scale = 0.25})

    elseif data.weaponType == 'unarmed'
    then
        --print('you must be using your fists!')
        I.SkillProgression.skillUsed('handtohand', {useType = 0, scale = 0.25})

    end

end

return {
    eventHandlers = {
       OnMiss = OnMiss
            }
}