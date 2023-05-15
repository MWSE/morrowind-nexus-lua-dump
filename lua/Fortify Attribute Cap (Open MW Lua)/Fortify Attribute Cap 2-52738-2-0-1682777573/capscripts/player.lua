local types = require('openmw.types')
local ui = require('openmw.ui')
local self = require('openmw.self')
local storage = require('openmw.storage')
local Att = types.Actor.stats.attributes
local AttArray = {Att.strength, Att.agility, Att.intelligence, Att.endurance, Att.luck, Att.willpower, Att.personality, Att.speed}
local fortBuffArray = {0, 0, 0, 0, 0, 0, 0, 0}
local settings = storage.playerSection('SettingsAttributeCapOption')


local function calcAtt()
    for i = 1,8 do
        attribute = AttArray[i](self)
        
        curCap = settings:get('attCap')
        if i == 8 then curCap = settings:get('speedAttCap') end

        if settings:get('isLiteralCap') then curCap = curCap - attribute.base end

        if attribute.modifier > curCap and curCap >= 0 then
            fortBuffArray[i] = fortBuffArray[i] + attribute.modifier - curCap
            attribute.modifier = curCap
        end

        if attribute.modifier < curCap then
            if attribute.modified < attribute.base then
                if attribute.damage < fortBuffArray[i] then
                    fortBuffArray[i] = fortBuffArray[i] - attribute.damage
                    attribute.damage = 0
                else
                    attribute.damage = attribute.damage - fortBuffArray[i]
                    fortBuffArray[i] = 0
                end
            elseif curCap - attribute.modifier < fortBuffArray[i] then
                fortBuffArray[i] = fortBuffArray[i] - (curCap - attribute.modifier)
                attribute.modifier = curCap
            else
                attribute.modifier = attribute.modifier + fortBuffArray[i]
                fortBuffArray[i] = 0
            end
        end
    end
end



return {
    engineHandlers = {
        
        onFrame = function(dt)
            calcAtt()
        end,

        onSave = function()
            return{savedBuffArray = fortBuffArray}
        end,

        onLoad = function(data)
            selfDamageArray = data.savedBuffArray
        end

    }
}