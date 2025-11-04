local types = require('openmw.types')
local core=require('openmw.core')
local world=require('openmw.world')
local I=require('openmw.interfaces')
local util=require('openmw.util')
local vfs=require('openmw.vfs')
local async=require('openmw.async')


local PlayerNumber=2
local Players={}
local CoV=false
local SelectionCharacters={}
--local Starting={Cell="Seyda Neen, Terurise Girvayne's House",Position=util.vector3(-100, 50, -123)}
local Starting={Cell="Marvani Ancestral Tomb",Position=util.vector3(-657, 4776, -1023)}
--local Starting={Cell="",Position=util.vector3(-0, 0, -0)}

local function CoVTeleport(data)
    if data.Object.count then
--        print(data.Object,data.Position)
        data.Object:teleport(data.Cell,data.Position)
    end
end


local function CoVMoveInto(data)
    if data.Object.count then
        if data.Number and data.Object.count>data.Number then
            data.Object:split(data.Number):moveInto(data.Container.type.inventory(data.Container))
        else
            data.Object:moveInto(data.Container.type.inventory(data.Container))
        end
    end
end

local function onSave()
	return{Players=Players}
end

local function onLoad(data)
    if data.Players then
        Players=data.Players
    end
end

local function StartCoV(data)
	data.Player:setScale(0.0001)
	CoV=true
end

local function StopCoV(data)
	data.Player:setScale(1)
	data.Player:teleport(data.Player.cell,data.Position)
	CoV=false
end

local ActivatorsAvatarsList={}
local function onUpdate(dt)

    if not(SelectionCharacters[1]) and not(Players[1]) and world.players[1].cell.name~="CharacterSelectionCell" then
    world.players[1]:teleport("CharacterSelectionCell",util.vector3(0,0,0))
    elseif not(SelectionCharacters[1]) and world.players[1].cell.name=="CharacterSelectionCell" then

        for i, activator in pairs(world.players[1].cell:getAll(types.Activator)) do
            for j, activator2 in pairs(world.players[1].cell:getAll(types.Activator)) do
                if activator2.recordId=="characterselection"..i then
                    SelectionCharacters[i]=world.createObject(world.createRecord(types.NPC.createRecordDraft({name=types.NPC.records["PlayerChoice"..i].class:gsub("^%l", string.upper), template=types.NPC.records["PlayerChoice"..i]})).id,1)
                    SelectionCharacters[i]:teleport("CharacterSelectionCell",activator2.position)
                    table.insert(ActivatorsAvatarsList,activator2)
                end
            end
        end
        world.players[1]:sendEvent("ActivatorsForAvatarSelection",{ActivatorsAvatarsList=ActivatorsAvatarsList})
    end

--   if not(Players[1]) and 1==0 then
--       for i=1,PlayerNumber do
--        --    Players[i]=world.createObject(world.createRecord(types.NPC.createRecordDraft({name="Player"..i, template=types.NPC.records[world.players[1].recordId]})).id,1)
--            Players[i]=world.createObject(world.createRecord(types.NPC.createRecordDraft({name="Player"..i, template=types.NPC.records["PlayerChoice"..math.random(10)]})).id,1)
--            Players[i]:teleport(world.players[1].cell,world.players[1].position)
--            Players[i]:addScript("scripts/covengineavatars.lua")
--            Players[i]:sendEvent("AddVfx",{model="meshes/player"..i..".nif",options={loop=true}})
--        end
--        world.players[1]:sendEvent("DeclarePlayers",{Players=Players})
--    end
end

local function CoVStartGlobal(data)
    for i, avatar in pairs (data.Avatars) do
        Players[i]=world.createObject(world.createRecord(types.NPC.createRecordDraft({name="Player"..i, template=types.NPC.records[avatar]})).id,1)
        Players[i]:teleport(Starting.Cell, Starting.Position,{onGround=true})
        Players[i]:addScript("scripts/cov/avatars.lua")
        Players[i]:sendEvent("AddVfx",{model="meshes/player"..i..".nif",options={loop=true}})
    end
    world.players[1]:teleport(Starting.Cell, Starting.Position)
    world.players[1]:sendEvent("DeclarePlayers",{Players=Players})
end

local function CoVReturnMWGlobal(data)
    world.mwscript.getGlobalVariables(data.Player)[data.Variable]=data.Value
end

local function CoVEmptyInventory(data)
--    print("EMPTY ",data.Object)
	data.Object.type.inventory(data.Object):resolve()--------GLOBAL
	for i,item in pairs(data.Object.type.inventory(data.Object):getAll()) do
        if data.Object.type==types.Container or item.recordId=="gold_001" or (item.type.records[item.recordId].enchant and (core.magic.enchantments.records[item.type.records[item.recordId].enchant].type==core.magic.ENCHANTMENT_TYPE.CastOnStrike  or core.magic.enchantments.records[weapon.type.records[weapon.recordId].enchant].type==core.magic.ENCHANTMENT_TYPE.ConstantEffect)) or ((item.type==types.Armor or item.type==types.Weapon or  item.type==types.Potion) and math.random(100)<20)  then
--            print(item.recordId)
		    item:teleport(data.Object.cell, data.Object.position)
            item:addScript("scripts/cov/droppeditem.lua")
        end
	end
end

local function CoVStopLuaScript(data)
--    print("RemoveScript", data.Object)
    data.Object:removeScript(data.Script)
end

local function CoVAvatarChoiceSex(data)
    local NewHead
    if data.isMale==false then
        for head in vfs.pathsWithPrefix("meshes/b") do
            if string.find(head,"01") and string.find(head,"head") and string.find(head,"_f_") and string.find(head, types.NPC.records[SelectionCharacters[data.Choice].recordId].race) then
                NewHead=string.gsub(string.gsub(head,".nif",""),"meshes/b/","")
                break
            end
        end
    else
        for head in vfs.pathsWithPrefix("meshes/b") do
            if string.find(head,"01") and string.find(head,"head") and string.find(head,"_m_") and string.find(head, types.NPC.records[SelectionCharacters[data.Choice].recordId].race) then
                NewHead=string.gsub(string.gsub(head,".nif",""),"meshes/b/","")
                break
            end
        end
    end
    local NewHair
    if data.isMale==false then
        for hair in vfs.pathsWithPrefix("meshes/b") do
            if string.find(hair,"01") and string.find(hair,"hair") and string.find(hair,"_f_") and string.find(hair, types.NPC.records[SelectionCharacters[data.Choice].recordId].race) then
                NewHair=string.gsub(string.gsub(hair,".nif",""),"meshes/b/","")
                break
            end
        end
    else
        for hair in vfs.pathsWithPrefix("meshes/b") do
            if string.find(hair,"01") and string.find(hair,"hair") and string.find(hair,"_m_") and string.find(hair, types.NPC.records[SelectionCharacters[data.Choice].recordId].race) then
                NewHair=string.gsub(string.gsub(hair,".nif",""),"meshes/b/","")
                break
            end
        end
    end
    local NPCRecord=world.createRecord(types.NPC.createRecordDraft({hair=NewHair, head=NewHead, name=types.NPC.records["PlayerChoice"..data.Choice].class, isMale=data.isMale, template=types.NPC.records[SelectionCharacters[data.Choice].recordId]}))
    SelectionCharacters[data.Choice]:remove()
    SelectionCharacters[data.Choice]=world.createObject(NPCRecord.id,1)
    SelectionCharacters[data.Choice]:teleport("CharacterSelectionCell",ActivatorsAvatarsList[data.Choice].position)

end


local function CoVReanimateAvatar(data)
--    print(Players[data.AvatarNbr],Players[data.AvatarNbr].count)
    if types.Actor.isDead(Players[data.AvatarNbr])==true and Players[data.AvatarNbr].count>0 then
        local NewAvatar=world.createObject(Players[data.AvatarNbr].recordId,1)
        for i, item in pairs(types.Actor.inventory(NewAvatar):getAll()) do
            item:remove()
        end

        for i, item in pairs(types.Actor.inventory(Players[data.AvatarNbr]):getAll()) do
            local NewItem=world.createObject(item.recordId,item.count)
            NewItem:moveInto(types.Actor.inventory(NewAvatar))
        end
        local DeadEquipment=types.Actor.getEquipment(Players[data.AvatarNbr])
        NewAvatar:sendEvent("CoVSetEquipment",{Equipment=DeadEquipment})
                                    
        for i, attribute in pairs(core.stats.Attribute.records) do 
            NewAvatar:sendEvent("SetAttribute",{Attribute=attribute.id, Value=types.Actor.stats.attributes[attribute.id](Players[data.AvatarNbr]).base})
        end

        types.Actor.spells(NewAvatar):clear()
        for i, spell in pairs(types.Actor.spells(Players[data.AvatarNbr])) do
            types.Actor.spells(NewAvatar):add(spell)
        end
        NewAvatar:addScript("scripts/cov/avatars.lua")

        NewAvatar:teleport(data.Survivor.cell,data.Survivor.position)

	    core.sound.playSoundFile3d(core.magic.effects.records[core.magic.EFFECT_TYPE.RestoreHealth].hitSound, NewAvatar)
        
        NewAvatar:sendEvent("AddVfx",{model=types.Static.records[core.magic.effects.records[core.magic.EFFECT_TYPE.RestoreHealth].hitStatic].model,options={loop=false}})
        
        Players[data.AvatarNbr]:remove()
        Players[data.AvatarNbr]=NewAvatar
        
        NewAvatar:sendEvent("AddVfx",{model="meshes/player"..data.AvatarNbr..".nif",options={loop=true}})

        world.players[1]:sendEvent("CoVReanimate",{Avatar=NewAvatar,AvatarNbr=data.AvatarNbr})

    end
end

local function CoVRestoreEnchantCharge(data)
    types.Item.itemData(data.Item).enchantmentCharge=data.Value
end

return {
	eventHandlers = {CoVReturnMWGlobal=CoVReturnMWGlobal,
                    CoVTeleport=CoVTeleport,
                    CoVEmptyInventory=CoVEmptyInventory,
                    CoVAvatarChoiceSex=CoVAvatarChoiceSex,
                    CoVStartGlobal=CoVStartGlobal,
                    CoVStopLuaScript=CoVStopLuaScript,
                    CoVMoveInto=CoVMoveInto,
                    CoVReanimateAvatar=CoVReanimateAvatar,
                    CoVRestoreEnchantCharge=CoVRestoreEnchantCharge
					},
	engineHandlers = {
        onUpdate = onUpdate,
        onSave=onSave,
        onLoad=onLoad,
	}

}