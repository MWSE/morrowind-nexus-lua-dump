local self = require('openmw.self')
local nearby = require('openmw.nearby')
local input = require('openmw.input')
local ui = require('openmw.ui')
local util = require('openmw.util')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local core = require('openmw.core')
local camera = require('openmw.camera')
local async = require('openmw.async')
local ambient = require('openmw.ambient')
local aux_util = require('openmw_aux.util')
local storage = require('openmw.storage')
local PathPointsTriggers  = require('scripts.railshooter.pathpointstriggers')
local WeaponsDatas  = require('scripts.railshooter.weapons')
local auxUi = require('openmw_aux.ui')

---------- override  normal controls
I.Controls.overrideMovementControls(true)
I.Controls.overrideCombatControls(true)
I.Controls.overrideUiControls(true)
types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Looking, false)
types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.ViewMode, false)

types.Actor.stats.dynamic.health(self).current=10000
types.Actor.stats.dynamic.fatigue(self).current=500
--types.Actor.activeEffects(self):modify(100,"feather")


I.UI.setHudVisibility(false)



local Weapons={auxUi.deepLayoutCopy(WeaponsDatas),auxUi.deepLayoutCopy(WeaponsDatas)}

local Weapon={"handgun","handgun"}

local TextRatio=1050/ui.screenSize().y

if not(types.Actor.inventory(self):find("invisiblecloth")) then
	core.sendGlobalEvent("RSCreateObject",{CellName=nil, RecordId="invisiblecloth", Position=nil,Rotation=nil,DestContainer=self})
end


local InvincibleTime={0,0}

local Bullets={Weapons[1].BaseBullets[Weapon[1]],Weapons[2].BaseBullets[Weapon[2]]}
local BulletsUI={{},{}}



CurrentPathPoint=1
local PathPoints={}	



for i=1,8 do
	local BulletUI=ui.create({ layer = 'Windows', type = ui.TYPE.Image, props = {color=util.color.rgb(1,1,1),visible=false, relativeSize = util.vector2(1/60, 1/18), relativePosition = util.vector2(0.05+i*0.022, 0.9), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/'..Weapon[1]..'bullet.png' , }, },})
	BulletsUI[1][i]=BulletUI
end
BulletsUI[1][9]=ui.create({ layer = 'Windows', type = ui.TYPE.Text, template=I.MWUI.templates.textHeader, props = {textSize=40*TextRatio, autoSize=true, text="+..", visible=false, relativePosition = util.vector2(0.05+9*0.022, 0.9), anchor = util.vector2(0, 0.5),}})



for i=1,8 do
	local BulletUI=ui.create({ layer = 'Windows', type = ui.TYPE.Image, props = {color=util.color.rgb(1,1,1),visible=false, relativeSize = util.vector2(1/60, 1/18), relativePosition = util.vector2(0.95-i*0.022, 0.9), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/'..Weapon[1]..'bullet.png' , }, },})
	BulletsUI[2][i]=BulletUI
end
BulletsUI[2][9]=ui.create({ layer = 'Windows', type = ui.TYPE.Text, template=I.MWUI.templates.textHeader, props = {textSize=40*TextRatio, autoSize=true, text="..+", visible=false, relativePosition = util.vector2(0.95-9*0.022, 0.9), anchor = util.vector2(0, 0.5),}})


local function Reload(Player)
	Bullets[Player]=Weapons[Player].BaseBullets[Weapon[Player]]
	for i=1,8 do
		local Visible=true
		if i>Bullets[Player] then Visible=false end 
		BulletsUI[Player][i].layout.props.resource=ui.texture { path = 'textures/'..Weapon[Player]..'bullet.png' , }
		BulletsUI[Player][i].layout.props.visible=Visible
		BulletsUI[Player][i]:update()
	end
	
	if Bullets[Player]>8 then
		local AmmoText="+"..Bullets[Player]-8
		if Player==2 then
			AmmoText=(Bullets[Player]-8).."+"
		end
		BulletsUI[Player][9].layout.props.text=AmmoText
		BulletsUI[Player][9].layout.props.visible=true
	else
		BulletsUI[Player][9].layout.props.visible=false
	end
	BulletsUI[Player][9]:update()
	ambient.playSound(Weapon[Player].."reload")
end


local function onLoad(data)
	if data then
		if data.SavePathPoints then
			PathPoints=data.SavePathPoints
		end
		if data.SaveCurrentPathPoint then 
			CurrentPathPoint=data.SaveCurrentPathPoint
		end
		if data.SaveWeapons then 
			Weapons=data.SaveWeapons
		end
		if data.SaveWeapon then 
			Weapon=data.SaveWeapon
			Reload(1)
		end
		if data.SavedHealth then 
			Health=data.SavedHealth
		end
	end
end

Reload(1)


local HealthUIs={{},{}}
local Health={tonumber(storage.playerSection('RailShootercontrols'):get('Lifes')),tonumber(storage.playerSection('RailShootercontrols'):get('Lifes'))}
local Credit=tonumber(storage.playerSection('RailShootercontrols'):get('Credits'))


local CreditUI=ui.create({ layer = 'Windows', type = ui.TYPE.Text, template=I.MWUI.templates.textHeader, props = {Tempo=2, textSize=50*TextRatio, visible=true, autoSize=true, text="CREDIT(S)  "..Credit, relativePosition = util.vector2(0.5,0.95), anchor = util.vector2(0.5, 0.5),}})
local Player2RequestUI=ui.create({ layer = 'Windows', type = ui.TYPE.Text, template=I.MWUI.templates.textHeader, props = {Tempo=2, textSize=50*TextRatio, visible=true, autoSize=true, text="PRESS START BUTTON", relativePosition = util.vector2(0.85,0.95), anchor = util.vector2(0.5, 0.5),}})
local Player1RequestUI=ui.create({ layer = 'Windows', type = ui.TYPE.Text, template=I.MWUI.templates.textHeader, props = {Tempo=2, textSize=50*TextRatio, visible=false, autoSize=true, text="PRESS START BUTTON", relativePosition = util.vector2(0.15,0.95), anchor = util.vector2(0.5, 0.5),}})

local ContinueUI=ui.create({ layer = 'Windows', type = ui.TYPE.Flex, props = {visible=false, tempo=1, number=9, horizontal=true,  relativeSize = util.vector2(0.5, 0.5), relativePosition = util.vector2(0.5,0.5), anchor = util.vector2(0.5, 0.5),},
								content=ui.content({{ type = ui.TYPE.Image, props = { size =util.vector2(ui.screenSize().x/3,ui.screenSize().y/5), resource = ui.texture {	path = 'textures/continue.png' ,
																																											offset = util.vector2(150,90),
																																											size = util.vector2(750, 130), }, },},
													{ type = ui.TYPE.Image, props = { size = util.vector2(ui.screenSize().x/8,ui.screenSize().y/2.5), resource = ui.texture {	path = 'textures/continue.png' ,
																																												offset = util.vector2(9*100,280),
																																												size = util.vector2(100, 230), }, },}
												})})


for j=1,2 do
	for i=1,6 do
		local Visible =true
		local relativePosition=util.vector2(0.02+i*0.05, 0.97)
		if j==2 then
			relativePosition=util.vector2(0.98-i*0.05, 0.97)
		end
		if i>Health[j] or j==2 then
			Visible=false
		end
		local HealthUI=ui.create({ layer = 'Windows', type = ui.TYPE.Image, props = {way=1,color=util.color.rgb(1,1,1),visible=Visible, alpha=1, relativeSize = util.vector2(1/25, 1/20), relativePosition = relativePosition, anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/healthj'..j..'.png' , }, },})
		HealthUIs[j][i]=HealthUI
	end
	local visible=false
	if j==1 and Health[j]>6 then
		visible=true
	end
	local relativePosition=util.vector2(0.02+7*0.05, 0.97)
	local HealthText="+"..Health[j]-6
	if j==2 then
		relativePosition=util.vector2(0.98-7*0.05, 0.97)
		HealthText=(Health[j]-6).."+"
	end
	HealthUIs[j][7]=ui.create({ layer = 'Windows', type = ui.TYPE.Text, template=I.MWUI.templates.textHeader, props = {textSize=40*TextRatio, autoSize=true, text=HealthText, visible=visible, relativePosition = relativePosition, anchor = util.vector2(0.5, 0.5),}})
end






local BulletEffects={}

local Cursor={	ui.create({ layer = 'Windows', type = ui.TYPE.Image, props = {color=util.color.rgb(1,1,1),visible=true, relativeSize = util.vector2(1/25, 1/20), relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/crosshair.png' , }, },}),
				ui.create({ layer = 'Windows', type = ui.TYPE.Image, props = {color=util.color.rgb(1,1,1),visible=false, relativeSize = util.vector2(1/25, 1/20), relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/crosshairj2.png' , }, },}),}


local ReloadUI={ui.create({ layer = 'Windows', type = ui.TYPE.Image, props = {color=util.color.rgb(0.9,0,0),visible=false, alpha=1, relativeSize = util.vector2(1/6, 1/8), relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/reload.png' , }, },}),
				ui.create({ layer = 'Windows', type = ui.TYPE.Image, props = {color=util.color.rgb(0,0,0.9),visible=false, alpha=1, relativeSize = util.vector2(1/12, 1/16), relativePosition = util.vector2(0.75, 0.5), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/reload.png' , }, },})}


local BloodSpatter={ui.create({ layer = 'Windows', type = ui.TYPE.Image, props = {color=util.color.rgb(1,1,1),visible=false, alpha=1, relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), resource = ui.texture {	path = 'textures/blood spatter.png' ,
																																																																				offset = util.vector2(100+math.random(0,2)*450, 470),
																																																																				size = util.vector2(450, 450), }, },}),
					ui.create({ layer = 'Windows', type = ui.TYPE.Image, props = {color=util.color.rgb(1,1,1),visible=false, alpha=1, relativeSize = util.vector2(0.5, 0.5), relativePosition = util.vector2(0.75, 0.5), anchor = util.vector2(0.5, 0.5), resource = ui.texture {	path = 'textures/blood spatter.png' ,
																																																																				offset = util.vector2(100+math.random(0,2)*450, 470),
																																																																				size = util.vector2(450, 450), }, },})}																																																																	





local BossBarSize=util.vector2(ui.screenSize().x*7/8,ui.screenSize().y/20)
local BossBar=ui.create({ layer = 'Windows', type = ui.TYPE.Widget,props = {actor=self,visible=false, alpha=1, relativeSize = util.vector2(0.7, 0.1), relativePosition = util.vector2(0.5, 0.1), anchor = util.vector2(0.5, 0.5),},
							content=ui.content({{name="BossName", type = ui.TYPE.Text, template=I.MWUI.templates.textHeader, props = {textSize=50*TextRatio, autoSize=true, text="BossName", relativePosition = util.vector2(0.5, 0.1), anchor = util.vector2(0.5, 0.5)}},
												{name="Bars", type = ui.TYPE.Container, template=I.MWUI.templates.bordersThick, props = {relativeSize= util.vector2(0.5, 0.9), relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5)},
													content=ui.content({	{name="Red", type = ui.TYPE.Image, props = {color=util.color.rgb(1,0,0),size= BossBarSize, anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'white' },},},
																			{name="Yellow", type = ui.TYPE.Image, props = {color=util.color.rgb(0.7, 0.7, 0), size= BossBarSize, anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'white' }}},
																			{name="Blue", type = ui.TYPE.Image, props = {color=util.color.rgb(0,0,1), size= BossBarSize, anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'white' }},},

																		})}
												})})





local function NewBoss(data)
	BossBar.layout.content["BossName"].props.text=data.Actor.type.records[data.Actor.recordId].name
	BossBar.layout.props.visible=true
	BossBar.layout.props.alpha=1
	BossBar.layout.props.actor=data.Actor
	BossBar.layout.content["Bars"].content["Yellow"].props.size=BossBarSize
	BossBar.layout.props.relativeSize=util.vector2(0,0.1)
	BossBar:update()
end



local function FoeKilled()
	if FoesToKill>0 then
		FoesToKill=FoesToKill-1
		if FoesToKill<=0 then
			CurrentPathPoint=CurrentPathPoint+1
		end
	end
end

FoesToKill=0																													


local ReloadTimer={0,0}



local J2Play=false
local function StartJ2()
	BloodSpatter[1].layout.props.relativeSize=util.vector2(0.5,0.5)
	BloodSpatter[1].layout.props.relativePosition=util.vector2(0.25,0.5)
	Cursor[2].layout.props.visible=true
	Player2RequestUI.layout.props.visible=false
	Player2RequestUI:update()

	Reload(2)

	ReloadUI[1].layout.props.relativeSize = util.vector2(1/12, 1/16)
	ReloadUI[1].layout.props.relativePosition = util.vector2(0.25, 0.5)
	Credit=Credit-1
	CreditUI.layout.props.text="CREDIT(S)  "..Credit
	CreditUI:update()
	Cursor[2]:update()
	Health[2]=tonumber(storage.playerSection('RailShootercontrols'):get('Lifes'))
	for i=1, Health[2] do
		HealthUIs[2][i].layout.props.visible=true
		HealthUIs[2][i]:update()
		if i==7 then break end
	end
	ambient.playSound("newplayer")
end
local function StopJ2()
	J2Play=false
	Cursor[2].layout.props.visible=false
	Cursor[2]:update()
	for i=1,7 do
		BulletsUI[2][i].layout.props.visible=false
		BulletsUI[2][i]:update()
	end
end

input.registerTriggerHandler("Start", async:callback(function ()
	if ContinueUI.layout.props.visible==true then
		Player1RequestUI.layout.props.visible=false
		Player1RequestUI:update()
		ContinueUI.layout.props.visible=false
		ContinueUI:update()
		Health[1]=tonumber(storage.playerSection('RailShootercontrols'):get('Lifes'))
		Cursor[1].layout.props.visible=true
		Cursor[1]:update()
		InvincibleTime[1]=0.5
		Credit=Credit-1
		CreditUI.layout.props.text="CREDIT(S)  "..Credit
		CreditUI:update()
		for i=1, Health[1] do
			HealthUIs[1][i].layout.props.visible=true
			HealthUIs[1][i]:update()
			if i==7 then break end
		end
		Player1RequestUI.layout.props.visible=false
		ambient.playSound("newplayer")
	end
end))
input.registerTriggerHandler("StartJ2", async:callback(function ()
	if J2Play==false then
		J2Play=true
		StartJ2()
	end
end))


local function Shoot(Player)

	if Bullets[Player]>0 then
		local BulletEffect=ui.create({ layer = 'Windows', type = ui.TYPE.Image, props = {Tempo=0,2,color=util.color.rgb(1,1,1),visible=true, relativeSize = util.vector2(1/5, 1/4), relativePosition = Cursor[Player].layout.props.relativePosition, anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/'..Weapon[Player]..' effects.png' ,
																																																																								offset = util.vector2((math.random(5)-1)*65,0),																																																																					
																																																																								size = util.vector2(70, 70), }, },})
		table.insert(BulletEffects,BulletEffect)
		ambient.playSound(Weapon[Player].."Shoot")
		local AmmoText="+"..Bullets[Player]-9
		if Player==2 then
			AmmoText=(Bullets[Player]-9).."+"
		end
		if Bullets[Player]>9 then
			BulletsUI[Player][9].layout.props.text=AmmoText
			BulletsUI[Player][9].layout.props.visible=true
			BulletsUI[Player][9]:update()
		else
			BulletsUI[Player][9].layout.props.visible=false
			BulletsUI[Player][9]:update()
			BulletsUI[Player][Bullets[Player]].layout.props.visible=false
			BulletsUI[Player][Bullets[Player]]:update()
		end
		Bullets[Player]=Bullets[Player]-1


		local Ray
		local IgnoreObjects={self,PathFollower}

		
		for j=1,Weapons[Player].Pellets[Weapon[Player]] do
			local AimPos=util.vector2(0,0)
			if j>1 then
				AimPos=util.vector2(math.random(-10,10)/100,math.random(-10,10)/100)
			end
			for i=1,10 do
				Ray=nearby.castRay(camera.getPosition()+camera.viewportToWorldVector(Cursor[Player].layout.props.relativePosition),camera.getPosition()+camera.viewportToWorldVector(Cursor[Player].layout.props.relativePosition+AimPos)*camera.getBaseViewDistance(),{ignore=IgnoreObjects})
				if Ray.hitObject and not((Ray.hitObject.type==types.NPC or Ray.hitObject.type==types.Creature) and types.Actor.isDead(Ray.hitObject)==true) then
					if Ray.hitObject.type==types.NPC or Ray.hitObject.type==types.Creature then
						local attack = {
							attacker = self,
							weapon = nil,
							sourceType = I.Combat.ATTACK_SOURCE_TYPES.Melee,
							strength = 1,
							type = self.ATTACK_TYPE.Chop,
							hitPos=Ray.hitPos,
							damage = {
								health = Weapons[Player].Damage[Weapon[Player]],
							},
							successful = true,
							spellOnHitRecord=Weapons[Player].spellOnHitRecord[Weapon[Player]],
							spellOnHitRecordEffect=nil,
							RSPlayer=Player,
						}
						Ray.hitObject:sendEvent('Hit', attack)
					elseif Ray.hitPos then
						if Weapons[Player].spellOnHitRecord[Weapon[Player]] then
							local NearbyActors={}
							for i, effect in pairs(core.magic.spells.records[Weapons[Player].spellOnHitRecord[Weapon[Player]]].effects) do
								if effect.area>1 then
									core.sendGlobalEvent("SpawnVfx",{model=types.Static.records[effect.effect.areaStatic].model, position=Ray.hitPos, options={scale=effect.area}})
									if not(NearbyActors[Player]) then
										for j, actor in pairs(nearby.actors) do
											if actor.type~=types.Player and types.Actor.isDead(actor)==false then
												table.insert(NearbyActors,actor)
											end
										end							
										for j, actor in pairs(NearbyActors) do
											if (Ray.hitPos-actor.position):length()<effect.area*80 then
												local attack = {
													attacker = self,
													weapon = nil,
													sourceType = I.Combat.ATTACK_SOURCE_TYPES.Melee,
													strength = 1,
													type = self.ATTACK_TYPE.Chop,
													hitPos=actor.position,
													damage = {
														health = 0,
													},
													successful = true,
													spellOnHitRecord=Weapons[Player].spellOnHitRecord[Weapon[Player]],
													spellOnHitRecordEffect=i,
													RSPlayer=Player,
												}
												actor:sendEvent('Hit', attack)
											end
										end

									end
								end
								core.sound.playSound3d(effect.effect.school.." hit",self)
							end
						else
							core.sendGlobalEvent("SpawnVfx",{model=types.Static.records[core.magic.effects.records["firedamage"].areaStatic].model, position=Ray.hitPos, options={scale=0.05,useAmbientLight=false}})
						end
					end
					if Weapons[Player].Piercing[Weapon[Player]]==false then 
						break
					else 
						table.insert(IgnoreObjects,Ray.hitObject)
					end
				else
					table.insert(IgnoreObjects,Ray.hitObject)
				end
			end
		end
	else
		ambient.playSound("RSReloadVoice")
		ambient.playSound(Weapon[Player].."EmptyClip")
		ReloadUI[Player].layout.props.visible=true
		ReloadUI[Player].layout.props.alpha=1
		ReloadUI[Player]:update()
	end
end



--local PlayerHeadHeight=self:getBoundingBox().halfSize.z*3/2
local PlayerHeadHeight=130
local SendCurrentPathPointOnce=true
local function Move(Target,dt)
	local TargetAngle={x=camera.worldToViewportVector(Target.position).x/ui.screenSize().x,y=camera.worldToViewportVector(Target.position+util.vector3(0,0,PlayerHeadHeight)).y/ui.screenSize().y}
	local WrongDirection=(((util.vector3(math.sin(self.rotation:getYaw())*10, math.cos(self.rotation:getYaw())*10,0) + self.position)-Target.position):length() > (self.position-Target.position):length())
	if WrongDirection==true or TargetAngle.x>1 then
		self.controls.yawChange = dt/0.4
	elseif TargetAngle.x<0 then
		self.controls.yawChange = -dt/0.4
	elseif TargetAngle.x<0.49 then
		self.controls.yawChange = -dt/2
	elseif TargetAngle.x>0.51 then
		self.controls.yawChange = dt/2
	end

--	print(TargetAngle.y)	
--	if TargetAngle.y>1 then
--		self.controls.pitchChange = -dt/2
--	elseif TargetAngle.y<0 then
--		self.controls.pitchChange = dt/2
--	elseif TargetAngle.y<0.49 then
--		print("Down")
--		self.controls.pitchChange = -dt/5
--	elseif TargetAngle.y>0.51 then
--		print("UP")
--		self.controls.pitchChange = dt/5
--	end

--	if (self.position-Target.position):length()<100 then
	if (util.vector2(self.position.x,self.position.y)-util.vector2(Target.position.x,Target.position.y)):length()<100 then
		if SendCurrentPathPointOnce==true then
			core.sendGlobalEvent("RSWriteMWSGlobal",{Player=self, Variable="CurrentPathPoint",Value=CurrentPathPoint+1})
			SendCurrentPathPointOnce=false
		end
		if FoesToKill==0 and PathPointsTriggers[CurrentPathPoint] then
			PathPointsTriggers[CurrentPathPoint]()
		end
		self.controls.movement=0
	else
		SendCurrentPathPointOnce=true
		self.controls.movement=1
		self.controls.run=true
	end

end


local ShootButton={false,false}
local ShootButtonTrigger={false,false}
local AutomaticFireTempo={Weapons[1].Automatic[Weapon[1]],Weapons[2].Automatic[Weapon[1]]}
local Cell

local function onUpdate(dt)
	if dt>0 then
		if ContinueUI.layout.props.visible==true then
			ContinueUI.layout.props.tempo=ContinueUI.layout.props.tempo-dt
			if ContinueUI.layout.props.tempo<0 then
				if ContinueUI.layout.props.number==0 then
					types.Actor.stats.dynamic.health(self).current=0
				else
					ContinueUI.layout.props.tempo=1
					ContinueUI.layout.props.number=ContinueUI.layout.props.number-1
					ContinueUI.layout.content[2].props.resource = ui.texture {	path = 'textures/continue.png' ,
																				offset = util.vector2(ContinueUI.layout.props.number*100,280),
																				size = util.vector2(100, 230), }
					ContinueUI:update()
				end
			end
		end

		if J2Play==false and Credit>0 then
			Player2RequestUI.layout.props.Tempo=Player2RequestUI.layout.props.Tempo-dt
			if Player2RequestUI.layout.props.visible==true then
				if Player2RequestUI.layout.props.Tempo<0 then
					Player2RequestUI.layout.props.Tempo=0.5
					Player2RequestUI.layout.props.visible=false
					Player2RequestUI:update()
				end
			else  
				if Player2RequestUI.layout.props.Tempo<0 then
					Player2RequestUI.layout.props.Tempo=1.5
					Player2RequestUI.layout.props.visible=true
					Player2RequestUI:update()
				end
			end
		end
		if HealthUIs[1][1].layout.props.visible==false and Credit>0 then
			Player1RequestUI.layout.props.Tempo=Player1RequestUI.layout.props.Tempo-dt
			if Player1RequestUI.layout.props.visible==true then
				if Player1RequestUI.layout.props.Tempo<0 then
					Player1RequestUI.layout.props.Tempo=0.5
					Player1RequestUI.layout.props.visible=false
					Player1RequestUI:update()
				end
			else  
				if Player1RequestUI.layout.props.Tempo<0 then
					Player1RequestUI.layout.props.Tempo=1.5
					Player1RequestUI.layout.props.visible=true
					Player1RequestUI:update()
				end
			end
		end

		CreditUI.layout.props.Tempo=CreditUI.layout.props.Tempo-dt
		if CreditUI.layout.props.visible==true then
			if CreditUI.layout.props.Tempo<0 then
				CreditUI.layout.props.Tempo=0.5
				CreditUI.layout.props.visible=false
				CreditUI:update()
			end
		else  
			if CreditUI.layout.props.Tempo<0 then
				CreditUI.layout.props.Tempo=1.5
				CreditUI.layout.props.visible=true
				CreditUI:update()
			end
		end

		if BossBar.layout.props.visible==true then
			local Layout=BossBar.layout
			local Boss=Layout.props.actor
			if Layout.props.relativeSize.x<0.7 then
				Layout.props.relativeSize=BossBar.layout.props.relativeSize+util.vector2(dt,0)
			end
			Layout.content["Bars"].content["Blue"].props.size=util.vector2(BossBarSize.x*types.Actor.stats.dynamic.health(Boss).current/types.Actor.stats.dynamic.health(Boss).base,BossBarSize.y)
			if Layout.content["Bars"].content["Yellow"].props.size.x>Layout.content["Bars"].content["Blue"].props.size.x then
				Layout.content["Bars"].content["Yellow"].props.size=util.vector2(Layout.content["Bars"].content["Yellow"].props.size.x-dt*1500,Layout.content["Bars"].content["Yellow"].props.size.y)
			end

			if types.Actor.isDead(Boss) then
				Layout.props.alpha=Layout.props.alpha-dt
				if Layout.props.alpha<0.2 then
					Layout.props.visible=false
				end
			end
			BossBar:update()
		end

		if Cell~=self.cell or not(PathPoints[1]) then
			ambient.streamMusic("Music/Battle/MW battle 4.mp3")
			Cell=self.cell
			PathPoints={}
			for i,activator in pairs(nearby.activators) do
				if string.find(activator.recordId,"pathpoint") then
					PathPoints[tonumber(string.sub(activator.recordId,10))]=activator
				end
			end
		end
		if PathPoints[CurrentPathPoint] then
			Move(PathPoints[CurrentPathPoint],dt)
		end

		if (not(types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.Pants)) or types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.Pants).recordId~="InvisibleCloth") and types.Actor.inventory(self):find("InvisibleCloth") then
			local Equipment={}
			Equipment[types.Actor.EQUIPMENT_SLOT.Pants]="InvisibleCloth"
			types.Actor.setEquipment(self,Equipment)
		end
		--self.controls.yawChange=0
		self.controls.pitchChange=0


		local DT=math.floor(dt*10000)/10000
		--print(DT)
		if Cursor[1].layout.props.relativePosition.x+input.getMouseMoveX()*DT/10<1.1 and Cursor[1].layout.props.relativePosition.x+input.getMouseMoveX()*DT/10>-0.1 and Cursor[1].layout.props.relativePosition.y+input.getMouseMoveY()*DT/10<1.1 and Cursor[1].layout.props.relativePosition.y+input.getMouseMoveY()*DT/10>-0.1 then
            Cursor[1].layout.props.relativePosition=Cursor[1].layout.props.relativePosition+util.vector2(input.getMouseMoveX()/800,input.getMouseMoveY()/800) 
			--print(Cursor.layout.props.relativePosition)
        end
		if input.getMouseMoveY()>(100) and ReloadTimer[1]<=0 then
			ReloadTimer[1]=1
		elseif input.getMouseMoveY()<-100 and ReloadTimer[1]>0 then
			if HealthUIs[1][1].layout.props.visible==true then
				Reload(1)
			end
			ReloadTimer[1]=0
		elseif ReloadTimer[1]>0 then
			ReloadTimer[1]=ReloadTimer[1]-DT
		end

		Cursor[1]:update()


		for i, effect in pairs(BulletEffects) do
			if effect.layout then
				if effect.layout.props.Tempo>0 then
					effect.layout.props.Tempo=effect.layout.props.Tempo-dt
				else
					effect:destroy()
					effect=nil 
				end
			end
		end

		


		if Cursor[1].layout.props.visible==true then
			ShootButton[1] = input.getBooleanActionValue('Shoot')
		end
		if J2Play==true then
			if input.getAxisValue(input.CONTROLLER_AXIS.LeftY)<-0.8 and ReloadTimer[2]<=0 then
				ReloadTimer[2]=1
			elseif input.getAxisValue(input.CONTROLLER_AXIS.LeftY)>0.8 and ReloadTimer[2]>0 then
				Reload(2)
				ReloadTimer[2]=0
			elseif ReloadTimer[2]>0 then
				ReloadTimer[2]=ReloadTimer[2]-DT
			end

			ShootButton[2] = input.getBooleanActionValue('ShootJ2')
			Cursor[2].layout.props.relativePosition=util.vector2(input.getAxisValue(input.CONTROLLER_AXIS.LeftX)+0.5,input.getAxisValue(input.CONTROLLER_AXIS.LeftY)+0.5)
			Cursor[2]:update()
		end


		for i=1,2 do
			if InvincibleTime[i]>0 then 
				InvincibleTime[i]=InvincibleTime[i]-dt 
				BloodSpatter[i].layout.props.alpha=BloodSpatter[i].layout.props.alpha-dt
				if BloodSpatter[i].layout.props.alpha<0.2 then
					BloodSpatter[i].layout.props.visible=false
				end
				BloodSpatter[i]:update()
			end

			for j, healthUI in pairs(HealthUIs[i]) do
				if healthUI.layout.props.alpha then
					if healthUI.layout.props.alpha>0.9 then
						healthUI.layout.props.way=1
					elseif healthUI.layout.props.alpha<0.6 then
						healthUI.layout.props.way=-1
					end
					healthUI.layout.props.alpha=healthUI.layout.props.alpha-DT*healthUI.layout.props.way
					healthUI:update()
				end
			end

			if ReloadUI[i].layout.props.visible==true then
				ReloadUI[i].layout.props.alpha=ReloadUI[i].layout.props.alpha-DT/0.4
				if ReloadUI[i].layout.props.alpha<0.2 then
					ReloadUI[i].layout.props.visible=false
				end
				ReloadUI[i]:update()
			end


			if AutomaticFireTempo[i]==false and Weapons[i].Automatic[Weapon[i]]~=false then 
				AutomaticFireTempo[i]=Weapons[i].Automatic[Weapon[i]] 
			elseif  AutomaticFireTempo[i]~=false and Weapons[i].Automatic[Weapon[i]]==false then
				AutomaticFireTempo[i]=false
			end

			if ShootButton[i]==true then
				if Weapons[i].Automatic[Weapon[i]] and Bullets[i]>=1 then
					if AutomaticFireTempo[i]<=0 then
						Shoot(i)
						AutomaticFireTempo[i]=Weapons[i].Automatic[Weapon[i]]
					else
						AutomaticFireTempo[i]=AutomaticFireTempo[i]-dt 
					end
				elseif ShootButtonTrigger[i]==false then
					Shoot(i)
					ShootButtonTrigger[i]=true
				end
			elseif ShootButton[i]==false and ShootButtonTrigger[i]==true then
				ShootButtonTrigger[i]=false

			end
		end



	end
end


I.Combat.addOnHitHandler(function(attack)
	local Player=1
	if J2Play==true then
		if HealthUIs[1][1].layout.props.visible==false then
			Player=2
		elseif camera.worldToViewportVector(attack.attacker.position).x/ui.screenSize().x>0.5 then
			Player=2
		end
	end
	if InvincibleTime[Player]>0 then return(false) end
   	if attack.successful==true then
		if attack.attacker.type.records[attack.attacker.recordId].name=="RSMagicBolt" then
			core.sendGlobalEvent("RSRemove",{object=attack.attacker})
		end
		InvincibleTime[Player]=4
		BloodSpatter[Player].layout.props.visible=true
		BloodSpatter[Player].layout.props.alpha=1
		BloodSpatter[Player].layout.props.resource = ui.texture {	path = 'textures/blood spatter.png' ,
																	offset = util.vector2(100+math.random(0,2)*450, 470),																																																																					
																	size = util.vector2(450, 450), }
		BloodSpatter[Player]:update()
		if Health[Player]>7 then
			local HealthText="+"..Health[Player]-7
			if Player==2 then
				HealthText=(Health[Player]-7).."+"
			end
			HealthUIs[Player][7].layout.props.text="+"..Health[Player]-7
			HealthUIs[Player][7]:update()
		elseif  Health[Player]>0 then
			HealthUIs[Player][Health[Player]].layout.props.visible=false
			HealthUIs[Player][Health[Player]]:update()
		end

		Health[Player]=Health[Player]-1

		if Player==1 and Health[1]<=0 then
			if Credit>0 then
				Player1RequestUI.layout.props.visible=true
				Player1RequestUI:update()
				Cursor[1].layout.props.visible=false
				Cursor[1]:update()
				InvincibleTime[1]=100
				ContinueUI.layout.props.visible=true
				ContinueUI.layout.props.tempo=1
				ContinueUI.layout.props.number=9
				ContinueUI.layout.content[2].props.resource = ui.texture {	path = 'textures/continue.png' ,
																			offset = util.vector2(ContinueUI.layout.props.number*100,280),
																			size = util.vector2(100, 230), }
				ContinueUI:update()
			elseif J2Play==false then
				types.Actor.stats.dynamic.health(self).current=0
			else
				Cursor[1].layout.props.visible=false
				Cursor[1]:update()
			end
		elseif Player==2 and Health[2]<=0 then
			if credit==0 and HealthUIs[1][1].layout.pros.visible==false then
				types.Actor.stats.dynamic.health(self).current=0
			else
				StopJ2()
			end
		end
   	end
end)




local function onSave()
    return{SavePathPoints=PathPoints,SaveCurrentPathPoint=CurrentPathPoint,SaveWeapons=Weapons,SaveWeapon=Weapon,SavedCredit=Credit,savedHealth=Health}
end


local function AmbientSound(data)
	ambient.playSound(data.Sound)
end


local function Heal(data)
	local Player=1
	if data.RSPlayer then
		Player=data.RSPlayer
	end
	Health[Player]=Health[Player]+1
	if Health[Player]>6 then
		HealthUIs[Player][7].layout.props.visible=true
		
		local HealthText="+"..Health[Player]-6
		if Player==2 then
			relativePosition=util.vector2(0.98-7*0.05, 0.97)
			HealthText=(Health[Player]-6).."+"
		end
		HealthUIs[Player][7].layout.props.text=HealthText
		HealthUIs[Player][7]:update()
	else
		HealthUIs[Player][Health[Player]].layout.props.visible=true
		HealthUIs[Player][Health[Player]]:update()
	end
	ambient.playSound(core.magic.effects.records["restorehealth"].hitSound)
end

local function DamageBonus(data)
	local Player=1
	if data.RSPlayer then
		Player=data.RSPlayer
	end
	Weapons[Player].Damage[Weapon[Player]]=Weapons[Player].Damage[Weapon[Player]]*1.1
	ambient.playSound(core.magic.effects.records["feather"].hitSound)
end

local function BonusBullets(data)
	local Player=1
	if data.RSPlayer then
		Player=data.RSPlayer
	end
	Weapons[Player].BaseBullets[Weapon[Player]]=Weapons[Player].BaseBullets[Weapon[Player]]+data.Number
	ambient.playSound(core.magic.effects.records["feather"].hitSound)
end

local function ChangeWeapons(data)
	local Weapon=Weapon[data.RSPlayer]
	if data.Weapon then
		Weapon=data.Weapon
	end
	Weapons[data.RSPlayer][data.Property][Weapon]=data.Value
end


local function ChangeCurrentPathPoint(data)
	CurrentPathPoint=data.Value
end


local function EquipWeapon(data)
	local Player=1
	if data.RSPlayer then
		Player=data.RSPlayer
	end
	Weapon[Player]=data.Weapon
	Bullets[Player]=Weapons[Player].BaseBullets[Weapon[Player]]
	Reload(Player)
end



return {
    interfaceName = "RailShooter",
    interface = {
        version = 1,
        Weapons=Weapons,
		Weapon=Weapon,
		FoesToKill=FoesToKill,
		CurrentPathPoint=CurrentPathPoint,
		EquipWeapon=EquipWeapon,
		ChangeWeapons=ChangeWeapons,
		ChangeCurrentPathPoint=ChangeCurrentPathPoint,
	},

	eventHandlers ={DeclarePathFollower=DeclarePathFollower,
					FoeKilled=FoeKilled,
					Heal=Heal,
					AmbientSound=AmbientSound,
					EquipWeapon=EquipWeapon,
					BonusBullets=BonusBullets,
					DamageBonus=DamageBonus,
					NewBoss=NewBoss,
					ChangeWeapons=ChangeWeapons,
					ChangeCurrentPathPoint=ChangeCurrentPathPoint,
					
					},
	engineHandlers = {
		onSave=onSave,
		onLoad=onLoad,
		onUpdate=onUpdate

	}
}
