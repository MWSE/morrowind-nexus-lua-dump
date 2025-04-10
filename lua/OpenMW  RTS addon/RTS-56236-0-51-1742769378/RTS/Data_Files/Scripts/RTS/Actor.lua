local self=require('openmw.self')
local AI=require('openmw.interfaces').AI
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local core=require('openmw.core')

local time=require('openmw_aux.time')



local NoAttack=0
local ActivatedObject
local Selected=false
local EnnemyFactions={}
local DistanceToAttack=500
local PatrolPoints={P1=nil,P2=nil,Activated=nil}

local function ActorIA(dt)

	if NoAttack>0 and AI.getActivePackage()==nil then
		NoAttack=0
	elseif NoAttack>0 then
		NoAttack=NoAttack-dt
	end

	if PatrolPoints.Activated then
		if AI.getActivePackage()==nil then
			AI.startPackage({type='Travel',destPosition=PatrolPoints[PatrolPoints.Activated]})
		elseif (PatrolPoints[PatrolPoints.Activated]-self.position):length()<100 then
			if PatrolPoints.Activated=="P1" then
				PatrolPoints.Activated="P2"
				AI.startPackage({type='Travel',destPosition=PatrolPoints[PatrolPoints.Activated]})
			elseif PatrolPoints.Activated=="P2" then
				PatrolPoints.Activated="P1"
				AI.startPackage({type='Travel',destPosition=PatrolPoints[PatrolPoints.Activated]})
			end
		end
	end

	if ActivatedObject then
--		print((ActivatedObject.position-self.position):length())
		if ActivatedObject.type==types.Door and (ActivatedObject.position-self.position):length()<150 then
			if types.Lockable.isLocked(ActivatedObject)==false  then
				core.sound.playSound3d(types.Door.record(ActivatedObject).openSound,self)
				
				if types.Door.destCell(ActivatedObject) then
					core.sendGlobalEvent("Teleport",{object=self,cell=types.Door.destCell(ActivatedObject).name,position=types.Door.destPosition(ActivatedObject)})
				else
					ActivatedObject:activateBy(self)
				end
			else 
				ActivatedObject:activateBy(self)
			end
			ActivatedObject=nil
		elseif ActivatedObject.type.inventory and (ActivatedObject.position-self.position):length()<50 then
			if ActivatedObject.type.inventory(ActivatedObject):getAll()[1] and types.Lockable.isLocked(ActivatedObject)==false then
--				print("take all")
				for i, item in ipairs(ActivatedObject.type.inventory(ActivatedObject):getAll()) do
					core.sendGlobalEvent("MoveInto",{actor=self, Item=item})
				end
			else 
				ActivatedObject:activateBy(self)
			end
			ActivatedObject=nil
		elseif (ActivatedObject.type~=types.Door and (ActivatedObject.position-self.position):length()<30) then
			ActivatedObject:activateBy(self)
			ActivatedObject=nil
		end
	end
end

local function onUpdate(dt)
	
	if AI.getActivePackage() and AI.getActivePackage().destPosition and self.controls.movement==1 and AI.getActivePackage().target==nil then
		self.controls.run=true
	end
--	ActorIA(dt)
end


local function Move(data) 
--	print("move Received")
	print(data.Position)
--	local destination=nearby.findNearestNavMeshPosition(data.Position)
--	print(destination)
	ActivatedObject=nil
	AI.removePackages()
--	AI.startPackage({type='Travel',destPosition=destination})
	
--	core.sendGlobalEvent("MovingSelect",{Position=destination})

	AI.startPackage({type='Travel',destPosition=data.Position})
	
	core.sendGlobalEvent("MovingSelect",{Position=data.Position})
	NoAttack=10
	PatrolPoints.Activated=nil
end


local function Attack(data) 
--	print(self)
--	print("attack")
--	print(data.Target)
	ActivatedObject=nil
	AI.removePackages()
	AI.startPackage({type='Combat',target=data.Target})
	PatrolPoints.Activated=nil
end


local function ActivateObject(data)
	ActivatedObject=data.Object
--	print("received")
	AI.startPackage({type='Travel',destPosition=ActivatedObject.position})
	PatrolPoints.Activated=nil
end




local function DefendStance()
	DistanceToAttack=500
end

local function AttackStance()
	DistanceToAttack=2500
end

local function NothingStance()
	DistanceToAttack=0
end


local function Patrol(data)

	ActivatedObject=nil
	AI.removePackages()

	PatrolPoints.P1=self.position
--	PatrolPoints.P2=nearby.findNearestNavMeshPosition(data.Position)
	PatrolPoints.P2=data.Position
	PatrolPoints.Activated="P2"
	
	AI.startPackage({type='Travel',destPosition=PatrolPoints.P2})
	
	core.sendGlobalEvent("MovingSelect",{Position=PatrolPoints.P2})
end



time.runRepeatedly(function() 	
    if Selected then
		local String="Waiting"
		if AI.getActivePackage() then
			if AI.getActivePackage().target then
				if AI.getActivePackage().target.type==types.Creature then
					String="Attacking "..types.Creature.record(AI.getActivePackage().target).name
				elseif AI.getActivePackage().target.type==types.NPC then
					if types.NPC.record(AI.getActivePackage().target).class then
						String="Attacking "..types.NPC.record(AI.getActivePackage().target).class
					else
						String="Attacking"
					end
				end
			elseif  AI.getActivePackage().destPosition  then
				String="Moving"
			end
		end
        Selected:sendEvent("SelectedStatut",{String=String})
    end



	local FightingFaction=false
	for i,faction in ipairs(core.factions.records) do
		if EnnemyFactions[faction.id] then
			FightingFaction=true
			break
		end
	end



	if FightingFaction==true and NoAttack<=0 and ActivatedObject==nil and types.Actor.stats.ai.fight(self).base >0 then
		if AI.getActivePackage()==nil or (AI.getActivePackage() and AI.getActivePackage().target==nil) or  (AI.getActivePackage() and AI.getActivePackage().target and types.Actor.isDead(AI.getActivePackage().target)==true) then 
--			print(self)
--			print("NEWATTack")
			local AttackDistance=DistanceToAttack
			for i, faction in pairs(EnnemyFactions) do
				for j,actor in ipairs(nearby.actors)do
					if types.Actor.isDead(actor)==false and
						((actor.type==types.NPC and types.NPC.getFactions(actor) and types.NPC.getFactions(actor)[1]==faction)
						or(actor.type==types.Creature and types.Actor.spells(actor)[faction.." spellflag"])) 
						and (self.position-actor.position):length()<DistanceToAttack then
							AttackDistance=(self.position-actor.position):length()+1
					end
				end
	
				if AttackDistance<DistanceToAttack then
					for j,actor in ipairs(nearby.actors)do
						if types.Actor.isDead(actor)==false and
							((actor.type==types.NPC and types.NPC.getFactions(actor) and types.NPC.getFactions(actor)[1]==faction)
							or(actor.type==types.Creature and types.Actor.spells(actor)[faction.." spellflag"])) 
							and (self.position-actor.position):length()<AttackDistance then
								AI.startPackage({type='Combat',target=actor})
--							print("ATTACK")
--							print(self)
--							print(actor)
							break
						end
					end
				end
			end
		end
	end		
	ActorIA(0.5)
end,
0.5*time.second)


local function DeclareFactions(data)
--	print(self)
--	print("faction declared")
	if (self.type==types.NPC and types.NPC.getFactions(self) and types.NPC.getFactions(self)[1]==data.PlayerFaction) or (self.type==types.Creature and types.Actor.spells(self)[data.PlayerFaction.." spellflag"]) then
		EnnemyFactions=data.EnnemyFactions
	else
		for i, faction in pairs(data.EnnemyFactions) do
			if (self.type==types.NPC and types.NPC.getFactions(self) and types.NPC.getFactions(self)[1]==faction) or (self.type==types.Creature and types.Actor.spells(self)[faction.." spellflag"]) then
				EnnemyFactions[data.PlayerFaction]=data.PlayerFaction
				DistanceToAttack=4000
				break
			end
		end
	end
--	for i, faction in pairs(EnnemyFactions) do
--		print(faction)
--	end
end

local function IsSelected(data)
	Selected=data.Player
	
	local String="Waiting"
	if AI.getActivePackage() then
		if AI.getActivePackage().target then
			String="Attacking "..AI.getActivePackage().target.recordId
		elseif  AI.getActivePackage().destPosition  then
			String="Moving"
		end
	end
	if Selected then
		Selected:sendEvent("SelectedStatut",{String=String})
	end
end

return {
	eventHandlers = {	Move=Move,
						Attack=Attack, 
						ActivateObject=ActivateObject,
						IsSelected=IsSelected,
						DeclareFactions=DeclareFactions,
						DefendStance=DefendStance,
						AttackStance=AttackStance,
						NothingStance=NothingStance,
						Patrol=Patrol,
					},
	engineHandlers = {
        onUpdate = onUpdate,
	}

}