local cf = mwse.loadConfig("DragonDoor!", {m = false, fix1 = true, fix2 = false, fixd = 200, fixd2 = 100, help = true, vamp = true, nosav = true, hdist = 2000, skey = {keyCode = 56}})

local function registerModConfig()		local tpl = mwse.mcm.createTemplate("DragonDoor!")	tpl:saveOnClose("DragonDoor!", cf)	tpl:register()	local page = tpl:createPage()	local var = mwse.mcm.createTableVariable
page:createYesNoButton{label = "Show messages", variable = var{id = "m", table = cf}}
page:createYesNoButton{label = "Allow vampires to chase", variable = var{id = "vamp", table = cf}}
--page:createYesNoButton{label = "NPCs will call for help in battle", variable = var{id = "help", table = cf}}
--page:createSlider{label = "The distance from which the enemies hear a call for help", min = 500, max = 5000, step = 100, jump = 500, variable = var{id = "hdist", table = cf}}
page:createYesNoButton{label = "Fix for stuck NPCs in doors - new method - works automatically (enabled by default, use only 1 of 2)", variable = var{id = "fix1", table = cf}}
page:createYesNoButton{label = "Fix for stuck NPCs in doors - old method - works only when the door is activated (disabled by default, use only 1 of 2)", variable = var{id = "fix2", table = cf}}
page:createSlider{label = "Teleportation distance for stuck NPCs (200 by default)", min = 50, max = 500, step = 50, jump = 100, variable = var{id = "fixd", table = cf}}
page:createSlider{label = "Teleportation distance for stuck NPCs in open doors (100 by default, set 0 to disable)", min = 0, max = 500, step = 10, jump = 50, variable = var{id = "fixd2", table = cf}}
page:createYesNoButton{label = "Prevent save when pursuing - recommended to enable", variable = var{id = "nosav", table = cf}, restartRequired = true}
page:createKeyBinder{label = "Emergency save button. Hold this button while saving to remove the ban on saving when pursuing.", variable = var{id = "skey", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local G = {}		local H = {}	local TH = {}		local TS = {}	local p, mp, TIM, Dtim, AC, wc		local Matr = tes3matrix33.new()		--local Up = tes3vector3.new(0,0,0.3)
local BD = {["dn\\door_dwrv_inner00_dn.nif"] = true,
["d\\ex_t_door_slavepod_01.nif"] = true}


local BList = {["atronach_flame_summon"] = true,["atronach_frost_summon"] = true,["atronach_storm_summon"] = true,["golden saint_summon"] = true,["daedroth_summon"] = true,["dremora_summon"] = true,["scamp_summon"] = true,
["winged twilight_summon"] = true,["clannfear_summon"] = true,["hunger_summon"] = true,["Bonewalker_Greater_summ"] = true,["ancestor_ghost_summon"] = true,["skeleton_summon"] = true,["bonelord_summon"] = true,
["daedraspider_s"] = true,["dremora_mage_s"] = true,["skaafin_archer_s"] = true,["xivkyn_s"] = true,["xivilai_s"] = true,["mazken_s"] = true,["skeleton_mage_s"] = true,["skeleton_archer_s"] = true,
["BM_bear_black_summon"] = true,["BM_wolf_grey_summon"] = true,["BM_wolf_bone_summon"] = true,["bonewalker_summon"] = true,["centurion_sphere_summon"] = true,["fabricant_summon"] = true,
["NM_Dremora_unique"] = true}

local HandyCr = {["atronach_flame"] = 1, ["atronach_frost"] = 1, ["atronach_storm"] = 1, ["atronach_frost_BM"] = 1, ["atronach_flame_lord"] = 1, ["atronach_frost_lord"] = 1, ["atronach_storm_lord"] = 1,
["scamp"] = 1, ["clannfear"] = 1, ["clannfear_lesser"] = 1, ["vermai"] = 1, ["hunger"] = 1, ["daedroth"] = 1, ["winged twilight"] = 1, ["daedraspider"] = 1, ["xivilai"] = 1,
["bonewalker"] = 1, ["bonewalker_weak"] = 1, ["Bonewalker_Greater"] = 1, ["bonelord"] = 1, ["BM_draugr01"] = 1, ["draugr"] = 1,
["ancestor_ghost"] = 1, ["ancestor_ghost_greater"] = 1, ["dwarven ghost"] = 1,
["corprus_stalker"] = 1, ["corprus_lame"] = 1, ["goblin_bruiser"] = 1,
["centurion_sphere"] = 1, ["centurion_steam"] = 1, ["centurion_projectile"] = 1, ["centurion_steam_advance"] = 1, ["centurion_sword"] = 1,  ["centurion_tank"] = 1}

local function combatStarted(e) if e.target == mp then	local m = e.actor	local r = m.reference	local bid = r.baseObject.id		local ob = m.object
if not H[r] and not BList[bid] and not r.data.SumM and (m.actorType == 1 and m.flee < 70 and (cf.vamp or not r.baseObject.head.vampiric) or (ob.biped or ob.type ~= 0 or ob.usesEquipment))
and m.health.normalized > 0.5 and tes3.getCurrentAIPackageId(m) ~= 3 then
	H[r] = {m = m, spos = m.position:copy(), scell = r.cell, status = 1, safe = tes3.makeSafeObjectHandle(r)}		if cf.m then tes3.messageBox("%s joined the battle! Enemies = %s", m.object.name, table.size(H)) end
end

--[[
if cf.help and r.cell.isInterior and not TH[r] and not BList[bid] and not r.data.SumM then
	TH[r] = timer.start{duration = 3, iterations = 10, callback = function() if not m.isDead and m.inCombat and m.fatigue.current > 0 and m.paralyze < 1 and m.silence < 1 then			--[C]: in function '__index'
		TH[r]:cancel()		if cf.m then tes3.messageBox("%s calls for help!", m.object.name) end
		for _, mob in pairs(tes3.findActorsInProximity{reference = r, range = cf.hdist}) do if mob ~= mp and mob ~= m and mob.fight >= 90 and not mob.inCombat then
			mob:startCombat(mp)		if cf.m then tes3.messageBox("%s heard and runs into battle!", mob.object.name) end
		end end
	end end}
end
--]]

end end		event.register("combatStarted", combatStarted)

-- Статусы: 1 = видит игрока и в бою, 2 = ранен или вырублен, 3 = потерял из виду, 0 = идёт к двери куда последний раз зашёл игрок
local function activate(e) local door = e.target		if door.object.objectType == tes3.objectType.door then	local actp = e.activator == p
if actp and door.destination then
	local list = "You are haunted by: "		local count = 0		G.LastDoor = door
	for r, t in pairs(H) do
		if t.safe:valid() then
			if t.status == 1 then
				if AC[r.cell] and t.m.inCombat then
					if t.m.health.normalized <= 0.5 or t.m.fatigue.current < 0 then t.status = 2		if cf.m then tes3.messageBox("%s no longer wants to chase you", r.object.name) end
					elseif p.position:distance(r.position) > 5000 then t.status = 3		if cf.m then tes3.messageBox("%s lost sight of you. Distance = %d", r.object.name, p.position:distance(r.position)) end end
				else t.status = 3		if cf.m then tes3.messageBox("%s lost sight of you!", r.object.name) end end
			elseif t.status == 3 then if AC[r.cell] and t.m.inCombat then t.status = 1		if cf.m then tes3.messageBox("%s see you again", r.object.name) end end end
			if t.status < 2 then list = ("%s %s,"):format(list, r.object.name)	count = count + 1
				if t.status == 1 then t.tim = 1 + math.floor(p.position:distance(r.position)/(200 + t.m.speed.current*3))
					local alt = t.m.actorType == 1 and t.m:getSkillValue(11) or 0		t.unl = alt > 50 and alt/2 or t.m.strength.current/10
				end
			end
		else H[r] = nil		tes3.messageBox("ref not valid (activate)") end
	end
	
	if cf.m and count ~= 0 then tes3.messageBox("%s  Total = %s/%s", list, count, table.size(H)) end
	if Dtim then Dtim:cancel() end		Dtim = timer.start{duration = 0.3, callback = function() Dtim = nil end}

else	local StartZ = door.startingOrientation.z
	if cf.fix2 and not BD[door.object.mesh:lower()] then		local bb = door.object.boundingBox		local DX = (bb.max.x - bb.min.x) > (bb.max.y - bb.min.y)	local ang		Matr:toRotationZ(StartZ)
		for _, m in pairs(tes3.findActorsInProximity{position = door.position, range = 200}) do if m ~= mp then
			if not actp or not (m.actorType == 1 or m.object.biped) then	ang = m:getViewToPointWithFacing(StartZ, door.position)
				if cf.m then tes3.messageBox("%s nostack  dist = %d   TypeX = %s   ang = %d", m.reference, cf.fixd, DX, ang) end
				m.position = m.position + (DX and Matr:getForwardVector() * (math.abs(ang) > 90 and cf.fixd or -cf.fixd) or Matr:getRightVector() * (ang > 0 and -cf.fixd or cf.fixd) )
				--m:doJump{velocity = (vec + Up) * cf.jacs, applyFatigueCost = false}
			end
		end end
	end
	
	if not actp then if (math.abs(door.facing - StartZ) * 180 / math.pi > 88) or door:testActionFlag(256) or door:testActionFlag(1024) then return false end end
end
end end		event.register("activate", activate)


local function collision(e) if cf.fix1 then		local door = e.target
if door and door.object.objectType == tes3.objectType.door and not door.destination and not tes3.getLocked{reference = door} and not BD[door.object.mesh:lower()] then
	local r = e.reference		local m = e.mobile
	if m.actorType and r ~= p then	local ts = tes3.getSimulationTimestamp()
		if TS[r] ~= ts then TS[r] = ts			local StartZ = door.startingOrientation.z		local dist		--local Open = math.abs(door.facing - StartZ) * 180 / math.pi > 88
			if math.abs(door.facing - StartZ) * 180 / math.pi < 88 then		dist = cf.fixd
				if not (door:testActionFlag(256) or door:testActionFlag(1024)) then	local ob = r.object
					if m.actorType == 1 or (ob.biped or ob.type ~= 0 or ob.usesEquipment) then r:activate(door) end			--[C]: in function 'activate'
				end
			else dist = cf.fixd2 end
			if dist > 0 then
				--	local vec = r.position - door.position		vec.z = 0		vec = vec:normalized()		r.position = r.position + r.forwardDirection * -80 + vec * 80
				local bb = door.object.boundingBox		local DX = (bb.max.x - bb.min.x) > (bb.max.y - bb.min.y)	local ang = m:getViewToPointWithFacing(StartZ, door.position)
				if cf.m then tes3.messageBox("%s nostack   dist = %d   TypeX = %s   ang = %d", r, dist, DX, ang) end
				Matr:toRotationZ(StartZ)		r.position = r.position + (DX and Matr:getForwardVector() * (math.abs(ang) > 90 and dist or -dist) or Matr:getRightVector() * (ang > 0 and -dist or dist) )
			end
		end
	end
end
end end		event.register("collision", collision)


local function cellChanged(e)	AC = {}		for _, cell in pairs(tes3.getActiveCells()) do AC[cell] = true end		if e.previousCell and table.size(H) > 0 then
if Dtim and (e.cell.isInterior or e.previousCell.isInterior) then	local door
	if table.size(H) ~= 0 then	local mind = 1000	local dist
		for dref in p.cell:iterateReferences(tes3.objectType.door) do if dref.destination then dist = p.position:distance(dref.position)		if mind > dist then mind = dist		door = dref end end end
	end
	
	for r, t in pairs(H) do
		if t.safe:valid() then
			if t.status == 1 then
				if r.cell ~= p.cell and (r.cell.isInterior or p.cell.isInterior) then t.tcell = p.cell	t.tpos = p.position:copy()	t.status = 0	t.door = door
				elseif AC[r.cell] then	if cf.m then tes3.messageBox("%s see you!", r.object.name) end end
			elseif t.status == 2 then
				if not AC[r.cell] and not AC[t.scell] then tes3.positionCell{cell = t.scell, position = t.spos, reference = r}	H[r] = nil	if cf.m then tes3.messageBox("%s is beaten and returned to his place", r.object.name) end end
			elseif t.status == 3 then
				if AC[r.cell] then	t.status = 1	if cf.m then tes3.messageBox("%s see you again!", r.object.name) end
				elseif not AC[t.scell] then tes3.positionCell{cell = t.scell, position = t.spos, reference = r}		H[r] = nil	mp:exerciseSkill(19, r.object.level/10)			--[C]: in function 'positionCell'
					if cf.m then tes3.messageBox("%s returned to his place", r.object.name) end
				end
			elseif t.status == 0 and AC[r.cell] then t.status = 1	if cf.m then tes3.messageBox("%s see you again!!", r.object.name) end end
		else H[r] = nil		tes3.messageBox("ref not valid") end
	end
	
	if table.size(H) ~= 0 then 
		if TIM == nil then TIM = timer.start{duration = 1, iterations = -1, callback = function() local fin = true	local DOORS = {}
			for r, t in pairs(H) do		if t.status == 0 then fin = nil		t.tim = t.tim - 1
				if t.tim <= 0 then
					local lock = t.door and t.door.lockNode
					if lock and lock.locked then DOORS[t.door] = math.max(t.unl, DOORS[t.door] or 0)
					else
						tes3.positionCell{cell = t.tcell, position = t.tpos, reference = r}
						if AC[t.tcell] then	t.status = 1	r.mobile:startCombat(mp)		r.mobile.actionData.aiBehaviorState = 3
							if cf.m then tes3.messageBox("%s opened the door and found you! Distance = %d", r.object.name, p.position:distance(t.tpos)) end
						else t.status = 3	if cf.m then tes3.messageBox("%s opened the door and lost sight of you!", r.object.name) end end
					end
				end
			end end
			for d, unl in pairs(DOORS) do d.lockNode.level = math.max(d.lockNode.level - unl)		if d.lockNode.level < 1 then tes3.unlock{reference = d} end end	
			if fin then TIM:cancel()	TIM = nil	if cf.m then tes3.messageBox("The chase is over") end end
		end} end
	end
elseif not (e.cell.isInterior or e.previousCell.isInterior) then
	for r, t in pairs(H) do
		if t.safe:valid() then
			if not r.cell.isInterior and p.position:distance(r.position) > 13000 then
				if cf.m then tes3.messageBox("%s returned to his place (ext) dist = %d", r.object.name, p.position:distance(r.position)) end
				tes3.positionCell{cell = t.scell, position = t.spos, reference = r}		mp:exerciseSkill(19, r.object.level/10)		H[r] = nil
			end
		else H[r] = nil		tes3.messageBox("ref not valid (ext)") end
	end
else
	for r, t in pairs(H) do
		if t.safe:valid() then
			if not AC[t.scell] then
				tes3.positionCell{cell = t.scell, position = t.spos, reference = r}
				if cf.m then tes3.messageBox("%s returned to his place (TELEPORT)", r.object.name) end		H[r] = nil	--[C]: in function 'positionCell'
			end
		else H[r] = nil		tes3.messageBox("ref not valid (Teleport)") end
	end
end
end	end		event.register("cellChanged", cellChanged)


local function save(e) if table.size(H) > 0 and not wc.inputController:isKeyDown(cf.skey.keyCode) then	local ms = ""
	for r, t in pairs(H) do ms = ("%s %s (%d),"):format(ms, r.object.name, p.position:distance(r.position)) end
	tes3.messageBox("You cannot save the game when %s enemies hunt you: %s", table.size(H), ms) return false
end end		if cf.nosav then event.register("save", save) end

local function death(e) H[e.reference] = nil end		event.register("death", death)
local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer		wc = tes3.worldController	H = {}		TH = {}		TS = {}		TIM = nil		Dtim = nil	end		event.register("loaded", loaded)
--can get the door reference from the door ui element with door_marker:getPropertyObject("MenuMap_object", "tes3reference")