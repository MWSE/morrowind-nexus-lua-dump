local types = require('openmw.types')
local core=require('openmw.core')
local world=require('openmw.world')
local I=require('openmw.interfaces')

local PoisonedWeapons={}
local PoisonKeys={}

local function ApplyPoisonKey(data)
	PoisonKeys[data.Actor.id]=data.Bolean
end

local function onUpdate(dt)
    
end


local function ApplyPoison(data)
    if PoisonedWeapons[data.Weapon.id] then
--        print("HIT with",data.Weapon.id,PoisonedWeapons[data.Weapon.id])
--        local Poison=world.createObject(PoisonedWeapons[data.Weapon.id],1)
--        data.Actor:sendEvent("TakePoison",{Poison=Poison})
--        core.sendGlobalEvent('UseItem', {object = data.Poison, actor = data.Actor, force = true})
        local PoisonRecord
        if types.Potion.records[PoisonedWeapons[data.Weapon.id]] then
            PoisonRecord=types.Potion.records[PoisonedWeapons[data.Weapon.id]]
        else
            PoisonRecord=types.Ingredient.records[PoisonedWeapons[data.Weapon.id]]
        end
        for i, effect in ipairs(PoisonRecord.effects) do
            local duration=effect.duration
            if duration==0 then
                duration=10
            end
            data.Actor:sendEvent("APtWApplyEffect",{PoisonId=PoisonRecord.id, Attacker=data.Attacker})
        end
        PoisonedWeapons[data.Weapon.id]=nil
        for i, player in ipairs(world.players) do
            player:sendEvent("APtWDeclarePoisonedWeapons",{List=PoisonedWeapons})
        end
    end
    
end


I.ItemUsage.addHandlerForType(types.Potion, function(potion, actor)
    if PoisonKeys[actor.id]==true then
        local CarriedRight=types.Actor.getEquipment(actor,types.Actor.EQUIPMENT_SLOT.CarriedRight)
        if CarriedRight then
            if CarriedRight.type==types.Weapon then
                PoisonedWeapons[CarriedRight.id]=potion.recordId
                actor:sendEvent("APtWShowMessage",{text="You have applied "..potion.type.records[potion.recordId].name.." to your "..CarriedRight.type.records[CarriedRight.recordId].name.."."})
                potion:remove(1)
                for i, player in ipairs(world.players) do
                    actor:sendEvent("APtWDeclarePoisonedWeapons",{List=PoisonedWeapons})
                end
            else
                actor:sendEvent("APtWShowMessage",{text="You can't apply poison on that."})

            end
        else 
            actor:sendEvent("APtWShowMessage",{text="No weapon equiped, you can't apply poison."})
        end

        return false
    end
end)


I.ItemUsage.addHandlerForType(types.Ingredient, function(ingredient, actor)
    if PoisonKeys[actor.id]==true then
        local CarriedRight=types.Actor.getEquipment(actor,types.Actor.EQUIPMENT_SLOT.CarriedRight)
        if CarriedRight then
            if CarriedRight.type==types.Weapon then
                PoisonedWeapons[CarriedRight.id]=ingredient.recordId
                actor:sendEvent("APtWShowMessage",{text="You have applied "..ingredient.type.records[ingredient.recordId].name.." to your "..CarriedRight.type.records[CarriedRight.recordId].name.."."})
                ingredient:remove(1)
                for i, player in ipairs(world.players) do
                    actor:sendEvent("APtWDeclarePoisonedWeapons",{List=PoisonedWeapons})
                end
            else
                actor:sendEvent("APtWShowMessage",{text="You can't apply poison on that."})

            end
        else 
            actor:sendEvent("APtWShowMessage",{text="No weapon equiped, you can't apply poison."})
        end

        return false
    end
end)



local function onSave()
    return{SavePoisonedWeapons=PoisonedWeapons}
end


local function onLoad(data)
    if data and data.SavePoisonedWeapons then
        PoisonedWeapons=data.SavePoisonedWeapons
        for i, player in ipairs(world.players) do
            player:sendEvent("APtWDeclarePoisonedWeapons",{List=PoisonedWeapons})
        end
    end
end

return {
	eventHandlers = {APtWApplyPoison=ApplyPoison,APtWApplyPoisonKey=ApplyPoisonKey,
					},
	engineHandlers = {
        onUpdate = onUpdate,
        onSave=onSave,
        onLoad=onLoad,
	}

}