local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')

AmmunitionTypes={}



if core.magic.enchantments.records[types.Weapon.record(self).enchant]~=nil and types.Weapon.record(self).type==10 then

    local munitions =tostring(core.magic.enchantments.records[types.Weapon.record(self).enchant].id)
    local startingmunitions
    local word=""

    --print(types.Weapon.record(self).id)

    for c in munitions:gmatch"." do
        if not(c=="_") then
            word=word..c
        elseif c=="_" then
            if startingmunitions==nil and word~="" then
                startingmunitions=word
            else
                for a, ammo in ipairs(types.Weapon.records) do
                    if ammo.id==word then
                          table.insert(AmmunitionTypes, ammo.id)
                          --print(word)
                    end
                end
            end
            word=""
        end   

    end	

    if types.Item.getEnchantmentCharge(self)==nil then
        core.sendGlobalEvent('setCharge', {Item=self, value=tonumber(startingmunitions)})
        types.Item.itemData(self).condition=10001
    end

end	

local function setCondition(data)
    --print(self)
    --SelfConditon=data.value
    types.Item.itemData(self).condition=data.value
    --print("weapon side : "..tostring(types.Item.itemData(self).condition))
end

local function GiveWeaponInfos(data)
    if data.Equipped==true then
        data.player:sendEvent('ReturnEquippedWeaponInfos',{AmmunitionTypes=AmmunitionTypes})
    elseif data.Equipped==false then
        data.player:sendEvent('ReturnInventoryWeaponInfos',{AmmunitionTypes=AmmunitionTypes})
    end
    print("received")
end

return {
	eventHandlers = {setCondition=setCondition,GiveWeaponInfos=GiveWeaponInfos },
	engineHandlers = {
        onUpdate = function()

            
            
	end
    ,
	}
}