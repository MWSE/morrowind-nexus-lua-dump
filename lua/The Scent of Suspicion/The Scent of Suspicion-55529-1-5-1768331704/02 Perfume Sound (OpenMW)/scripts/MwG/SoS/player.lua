local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local ambient = require('openmw.ambient')
local async = require('openmw.async')

local potion_up
local potion_down

local function potion_pick(event) --potion is picked
    potion_up = event.potion
end

local function potion_drop(event) --potions appears to world
    potion_down = event.potion
end

local function onUpdate() -- check every frame   
    if ambient.isSoundPlaying("item potion up") and potion_up then
        ambient.stopSound("item potion up")
	core.sound.playSound3d("item misc up",self)
        potion_up = nil  -- theory: prevent for other potions
    end
    if ambient.isSoundPlaying("item potion down") and potion_down then
        ambient.stopSound("item potion down")
	core.sound.playSound3d("item misc down",self)
        --print("down") -- console print
        potion_down = nil -- theory: prevent for other potions
    end
end

local function onConsume(item)
                                        -- find partial match
    if string.find(item.recordId,string.lower("MwG_Apo_EoS")) then

        --print("consume", item.recordId)  
                                        -- consumed potions effects
        local pot_effe = types.Potion.record(item.recordId).effects

        for i=1, #pot_effe do --loop over           -- syntax detail
        --print( "pot", core.magic.effects.records[pot_effe[i].id].id )
                      -- specific effect
            if core.magic.effects.records[pot_effe[i].id].id == core.magic.EFFECT_TYPE.FortifySkill then
            --print("ok")

                if core.sound.isSoundPlaying("drink",self) == true then --drink sound Id
                    core.sound.stopSound3d("drink",self)
                    core.sound.playSound3d("MwG_Apo_Spray",self) -- custom spray sound Id
                end
            end
        end
    end
end

return {
    engineHandlers = { onConsume = onConsume, onUpdate = onUpdate },
    eventHandlers = { potion_pick = potion_pick, potion_drop = potion_drop } }