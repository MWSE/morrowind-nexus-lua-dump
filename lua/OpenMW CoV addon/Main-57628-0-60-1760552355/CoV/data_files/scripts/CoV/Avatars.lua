local self=require('openmw.self')
local AI=require('openmw.interfaces').AI
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local core = require('openmw.core')
local time=require('openmw_aux.time')
local anim=require('openmw.animation')
local Combat=require('openmw.interfaces').Combat

self.enableAI(self,false)
local ItemTypes={types.Weapon,types.Armor}
local FriendlyCast=false
local FriendFightValue=50

time.runRepeatedly(function() 	
	for _, Type in pairs(ItemTypes) do
		for i, item in pairs(types.Actor.inventory(self):getAll(Type)) do
			local condition=types.Item.itemData(item).condition
			local health=item.type.records[item.recordId].health
			if condition and health and condition<health then
				core.sendGlobalEvent('ModifyItemCondition', {actor = self, item = item, amount= health-condition})
			end
			local Charge=types.Item.itemData(item).enchantmentCharge
			local Enchant=item.type.records[item.recordId].enchant
			if Enchant and Charge and core.magic.enchantments.records[Enchant].charge and Charge<core.magic.enchantments.records[Enchant].charge then
				core.sendGlobalEvent('CoVRestoreEnchantCharge', {Item = item, Value= core.magic.enchantments.records[Enchant].charge-Charge})
			end
		end
	end
end,
3*time.second)


time.runRepeatedly(function() 	
	for i, actor in pairs(nearby.actors) do
		if types.Actor.isDead(actor)==false and (self.position-actor.position):length()<2000 and types.Actor.stats.ai.fight(actor).modified>FriendFightValue then
			if FriendlyCast==true then
				AI.removePackages()
				FriendlyCast=false
			end
			I.AI.startPackage({type="Combat", target=actor})
		end
	end
end,
0.5*time.second)


time.runRepeatedly(function() 	
	if types.Actor.stats.dynamic.health(self).current<types.Actor.stats.dynamic.health(self).base then
		types.Actor.stats.dynamic.health(self).current=types.Actor.stats.dynamic.health(self).current+types.Actor.stats.attributes.endurance(self).base*0.005
	end
	if types.Actor.stats.dynamic.magicka(self).current<types.Actor.stats.dynamic.magicka(self).base then
		types.Actor.stats.dynamic.magicka(self).current=types.Actor.stats.dynamic.magicka(self).current+types.Actor.stats.attributes.intelligence(self).base*0.005
	end
end,
1*time.second)


local function Move(data)
	self.controls.yawChange=data.Value-self.rotation:getYaw()
	if data.NoMove==true then
		I.AnimationController.playBlendedAnimation('runforward',{startkey="loop start", stopkey="loop stop", priority = {	[anim.BONE_GROUP.RightArm] = anim.PRIORITY.Movement,
																															[anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Movement,
																															[anim.BONE_GROUP.Torso] = anim.PRIORITY.Movement,}})
	else
		self.controls.run=true
		self.controls.movement=1
	end
end

local function PlayerHit(data)
	if types.Actor.getStance(self)==types.Actor.STANCE.Weapon then
		self.controls.use=self.ATTACK_TYPE.Any
		if data.FriendlyFire=="Yes" then
			FriendFightValue=25
		else
			if FriendFightValue==25 then
				AI.removePackages()
			end
			FriendFightValue=50
		end
	end
end

local function PlayerCast(data)
--	print("CASTSPELL")
	if types.Actor.stats.dynamic.magicka(self).current>=types.Actor.getSelectedSpell(self).cost and anim.getActiveGroup(self,anim.BONE_GROUP.Torso)~="spellcast" then
		types.Actor.setStance(self,types.Actor.STANCE.Spell)
		self.controls.use=1
		if data.FriendlyFire=="Yes" then
			FriendFightValue=25
		else
			FriendFightValue=50
		end
	end
end

local CoinsTaken={}
local function onUpdate(dt)
	--print( types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight) , types.Actor.getStance(self)==types.Actor.STANCE.Nothing)
	if types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight) and types.Actor.getStance(self)==types.Actor.STANCE.Nothing then
		types.Actor.setStance(self,types.Actor.STANCE.Weapon)
	end
	if not(types.Actor.getSelectedSpell(self)) then
		for i, spell in pairs(types.Actor.spells(self)) do
			if spell.type==core.magic.SPELL_TYPE.Spell then
				types.Actor.setSelectedSpell(self, spell.id)
				break 
			end
		end
	end

	
	for i, item in pairs(nearby.items) do
		if (item.position-self.position):length()<150 and string.find(item.recordId,"gold_") and not(CoinsTaken[item.id]) then
			nearby.players[1]:sendEvent("TakeCoins",{Player=self, Value=item.count})
			core.sendGlobalEvent("CoVMoveInto",{Object=item,Container=self})
			CoinsTaken[item.id]=true
			core.sound.playSoundFile3d("sound/fx/item/gold_up.wav", self)
			break
		end
	end
end


I.AnimationController.addTextKeyHandler("", function(group, key)
--	print(group,key)
	if string.find(key,"max attack") then
		self.controls.use=self.ATTACK_TYPE.NoAttack
	end
	if group=="idlespell" and key=="stop" then
		types.Actor.setStance(self,types.Actor.STANCE.Weapon)
	end
	if group=="spellcast" and types.Actor.getSelectedSpell(self) then
		if core.magic.effects.records[core.magic.spells.records[types.Actor.getSelectedSpell(self).id].effects[1].id].harmful==false then
			if FriendlyCast==false then
				AI.removePackages()
				FriendlyCast=true
			end
			for i, actor in pairs(nearby.actors) do
				if types.Actor.isDead(actor)==false and (self.position-actor.position):length()<2000 and types.Actor.stats.ai.fight(actor).modified<=FriendFightValue then
					I.AI.startPackage({type="Combat", target=actor})
				end
			end
		end
	end
end)


I.AnimationController.addPlayBlendedAnimationHandler(function (groupname, options)
	if groupname=="idlespell" then
    	options.speed=8
	elseif groupname=="spellcast" then
    	options.speed=2
	end
end)


local function Block()
	if string.find(anim.getActiveGroup(self,anim.BONE_GROUP.Torso),"idle") then
		local WeaponType=types.Weapon.records[types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight).recordId].type
		if types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedLeft) and not(WeaponType==types.Weapon.TYPE.AxeTwoHand or WeaponType==types.Weapon.TYPE.BluntTwoClose or WeaponType==types.Weapon.TYPE.BluntTwoWide or WeaponType==types.Weapon.TYPE.LongBladeTwoHand or WeaponType==types.Weapon.TYPE.SpearTwoWide) then
			I.AnimationController.playBlendedAnimation('shield',{startPoint=0.8, speed=0.1,startKey="block start", stopKey="block hit",priority=anim.PRIORITY.WeaponLowerBody})
		else
			I.AnimationController.playBlendedAnimation('handtohand',{startPoint=0.5, speed=0.5,startKey="equip start", stopKey="equip stop",priority=anim.PRIORITY.WeaponLowerBody})
		end
	end
end


local function EquipSpell(data)
	types.Actor.setSelectedSpell(self, data.spell)
end

local function PlayerUse(data)
--	print("USE")
	local Activated=false
	local ActivateDistance=150
	if Activated==false then
		for i, item in pairs(nearby.items) do
			if types.Item.isCarriable(item) and (item.position-self.position):length()<ActivateDistance and not(string.find(item.recordId,"gold_")) then
--				print("ITEM",item)
				Activated=true
				core.sendGlobalEvent("CoVMoveInto",{Object=item,Container=self})
				core.sound.playSoundFile3d("sound/fx/item/generic_up.wav",self)
				--item:activateBy(self)
				break
			end
		end
	end
	if Activated==false then
		for i, container in pairs(nearby.containers) do
			if (types.Container.inventory(container):isResolved()==false or types.Container.inventory(container):getAll()[1]) and (container.position-self.position):length()<ActivateDistance then
--				print(container)
				Activated=true
				container:activateBy(self)
				break
			end
		end
	end
	if Activated==false then
		for i, activator in pairs(nearby.activators) do
			if (activator.position-self.position):length()<ActivateDistance then
--				print(activator)
				Activated=true
				activator:activateBy(self)
				if activator.recordId=="save point" then
					types.Player.sendMenuEvent(nearby.players[1], 'CoVSaveGame')
				end
				break
			end
		end
	end
	if Activated==false then
		for i, actor in pairs(nearby.actors) do
			if types.Actor.isDead(actor)==false and types.Actor.stats.ai.fight(actor).modified<30 and actor.id~=self.id and (actor.position-self.position):length()<ActivateDistance then
--				print(actor)
				Activated=true
				actor:activateBy(nearby.players[1])
				break
			end
		end
	end
	if Activated==false then
		for i, door in pairs(nearby.doors) do
			if (door.position-self.position):length()<ActivateDistance then
--				print(door)
				if types.Door.destCell(door) then
					Activated=true
					for j, player in pairs(data.Players) do
						core.sendGlobalEvent("CoVTeleport",{Object=player, Cell=types.Door.destCell(door).name, Position=types.Door.destPosition(door)})
					end
					door:activateBy(nearby.players[1])
					break
				else
					door:activateBy(nearby.players[1])
				end
			end
		end
	end
end

local function StepBack()
--	print("StepBack")
	I.AnimationController.playBlendedAnimation('runback',{ startKey="start", stopKey="loop stop", priority = anim.PRIORITY.Movement})
end


local function CoVSetEquipment(data)
	local Equipment={}
	for slot, item in pairs(data.Equipment) do
		Equipment[slot]=item.recordId
	end
	types.Actor.setEquipment(self,Equipment)
end

local function onInit()
	local Equipment=types.Actor.getEquipment(self)
	if types.Actor.inventory(self):getAll(types.Weapon)[1] then
		Equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]=types.Actor.inventory(self):getAll(types.Weapon)[1].recordId
		types.Actor.setEquipment(self,Equipment)    
	end
	for i, spell in pairs(types.Actor.spells(self)) do
		if spell.type==core.magic.SPELL_TYPE.Spell and spell.id~=string.lower(core.magic.spells.records[spell.id].name).."_0" then
			types.Actor.setSelectedSpell(self, spell)
		end
	end
end

local function CoVUpSpell(data)
	types.Actor.spells(self):remove(data.OldSpell)
	types.Actor.spells(self):add(data.NewSpell)
end

return {
	eventHandlers = {	
						Move=Move,
						PlayerHit=PlayerHit,
						Block=Block,
						PlayerCast=PlayerCast,
						PlayerUse=PlayerUse,
						EquipSpell=EquipSpell,
						StepBack=StepBack,
						CoVSetEquipment=CoVSetEquipment,
						CoVUpSpell=CoVUpSpell,



					},
	engineHandlers = {
						onUpdate=onUpdate,
						onInit=onInit

	}

}