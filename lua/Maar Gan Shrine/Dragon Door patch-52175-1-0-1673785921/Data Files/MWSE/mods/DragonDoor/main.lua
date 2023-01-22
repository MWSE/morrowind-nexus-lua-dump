local cf = mwse.loadConfig("DragonDoor!", {m = false, nost = true, nor = 200, acs = 800, help = true, vamp = true, nosav = true, hdist = 2000, skey = {keyCode = 56}})
local G = {}		local H = {}	local TH = {}		local p, mp, TIM, Dtim, AC, wc

local BList = {["NM_Dremora_unique"] = true}
local Summon = {["atronach_flame_summon"] = true,["atronach_frost_summon"] = true,["atronach_storm_summon"] = true,["golden saint_summon"] = true,["daedroth_summon"] = true,["dremora_summon"] = true,["scamp_summon"] = true,
["winged twilight_summon"] = true,["clannfear_summon"] = true,["hunger_summon"] = true,["Bonewalker_Greater_summ"] = true,["ancestor_ghost_summon"] = true,["skeleton_summon"] = true,["bonelord_summon"] = true,
["daedraspider_s"] = true,["dremora_mage_s"] = true,["skaafin_archer_s"] = true,["xivkyn_s"] = true,["xivilai_s"] = true,["mazken_s"] = true,["skeleton_mage_s"] = true,["skeleton_archer_s"] = true,
["BM_bear_black_summon"] = true,["BM_wolf_grey_summon"] = true,["BM_wolf_bone_summon"] = true,["bonewalker_summon"] = true,["centurion_sphere_summon"] = true,["fabricant_summon"] = true}
local HandyCr = {["atronach_flame"] = 1, ["atronach_frost"] = 1, ["atronach_storm"] = 1, ["atronach_frost_BM"] = 1, ["atronach_flame_lord"] = 1, ["atronach_frost_lord"] = 1, ["atronach_storm_lord"] = 1,
["scamp"] = 1, ["clannfear"] = 1, ["clannfear_lesser"] = 1, ["vermai"] = 1, ["hunger"] = 1, ["daedroth"] = 1, ["winged twilight"] = 1, ["daedraspider"] = 1, ["xivilai"] = 1,
["bonewalker"] = 1, ["bonewalker_weak"] = 1, ["Bonewalker_Greater"] = 1, ["bonelord"] = 1, ["BM_draugr01"] = 1, ["draugr"] = 1,
["ancestor_ghost"] = 1, ["ancestor_ghost_greater"] = 1, ["dwarven ghost"] = 1,
["corprus_stalker"] = 1, ["corprus_lame"] = 1, ["goblin_bruiser"] = 1,
["centurion_sphere"] = 1, ["centurion_steam"] = 1, ["centurion_projectile"] = 1, ["centurion_steam_advance"] = 1, ["centurion_sword"] = 1,  ["centurion_tank"] = 1}

local function combatStarted(e) if e.target == mp then	local m = e.actor	local r = m.reference	local bid = r.baseObject.id
if not H[r] and not BList[bid] and (m.actorType == 1 and m.flee < 70 and (cf.vamp or not r.baseObject.head.vampiric) or ((m.object.biped or m.object.usesEquipment or HandyCr[bid]) and not Summon[bid]))
and m.health.normalized > 0.5 and tes3.getCurrentAIPackageId(m) ~= 3 then
	H[r] = {m = m, spos = m.position:copy(), scell = r.cell, status = 1}		if cf.m then tes3.messageBox("%s joined the battle! Enemies = %s", m.object.name, table.size(H)) end
end
if cf.help and r.cell.isInterior and not TH[r] and not Summon[bid] then
	TH[r] = timer.start{duration = 3, iterations = 10, callback = function() if not m.isDead and m.inCombat and m.fatigue.current > 0 and m.paralyze < 1 and m.silence < 1 then
		TH[r]:cancel()		if cf.m then tes3.messageBox("%s calls for help!", m.object.name) end
		for _, mob in pairs(tes3.findActorsInProximity{reference = r, range = cf.hdist}) do if mob ~= mp and mob ~= m and mob.fight >= 90 and not mob.inCombat then
			mob:startCombat(mp)		if cf.m then tes3.messageBox("%s heard and runs into battle!", mob.object.name) end
		end end
	end end}
end
end end		event.register("combatStarted", combatStarted)


local DAR = {}
local function DoorKick(e)	local r = e.reference	if DAR[r] then e.mobile.impulseVelocity = DAR[r].v * (1/wc.deltaTime)	DAR[r].f = DAR[r].f - 1		e.speed = 0
	--tes3.messageBox("%s  vec = %s", r, e.mobile.impulseVelocity:length())
	if DAR[r].f <= 0 then DAR[r] = nil	if table.size(DAR) == 0 then event.unregister("calcMoveSpeed", DoorKick) end end
end end

-- Статусы: 1 = видит игрока и в бою, 2 = ранен или вырублен, 3 = потерял из виду, 0 = идёт к двери куда последний раз зашёл игрок
local function activate(e) if e.target.object.objectType == tes3.objectType.door then
if e.activator == p then
	if e.target.destination then	local list = "You are haunted by: "		local count = 0		G.LastDoor = e.target
		for r, t in pairs(H) do
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
		end
		
		if cf.m and count ~= 0 then tes3.messageBox("%s  Total = %s/%s", list, count, table.size(H)) end
		if Dtim then Dtim:cancel() end		Dtim = timer.start{duration = 0.3, callback = function() Dtim = nil end}
	end
elseif cf.nost then	local num1 = table.size(DAR)
	for _, mob in pairs(tes3.findActorsInProximity{position = e.target.position, range = cf.nor}) do if mob ~= mp then
		DAR[mob.reference] = {v = mob.reference.sceneNode.rotation:transpose().y * (-cf.acs/30), f = 30}
	end end
	if num1 == 0 then event.register("calcMoveSpeed", DoorKick) end
	if cf.m then tes3.messageBox("%s open the door %s  Total = %d", e.activator.object.name, e.target.object.id, table.size(DAR)) end
end
end end		event.register("activate", activate)



local function cellChanged(e)	AC = {}		for _, cell in pairs(tes3.getActiveCells()) do AC[cell] = true end		if e.previousCell and table.size(H) > 0 then
if Dtim and (e.cell.isInterior or e.previousCell.isInterior) then	local door
	if table.size(H) ~= 0 then	local mind = 1000	local dist
		for dref in p.cell:iterateReferences(tes3.objectType.door) do if dref.destination then dist = p.position:distance(dref.position)		if mind > dist then mind = dist		door = dref end end end
	end
	
	for r, t in pairs(H) do
		if t.status == 1 then
			if r.cell ~= p.cell and (r.cell.isInterior or p.cell.isInterior) then t.tcell = p.cell	t.tpos = p.position:copy()	t.status = 0	t.door = door
			elseif AC[r.cell] then	if cf.m then tes3.messageBox("%s see you!", r.object.name) end end
		elseif t.status == 2 then
			if not AC[r.cell] and not AC[t.scell] then tes3.positionCell{cell = t.scell, position = t.spos, reference = r}	H[r] = nil	if cf.m then tes3.messageBox("%s is beaten and returned to his place", r.object.name) end end
		elseif t.status == 3 then
			if AC[r.cell] then	t.status = 1	if cf.m then tes3.messageBox("%s see you again!", r.object.name) end
			elseif not AC[t.scell] then tes3.positionCell{cell = t.scell, position = t.spos, reference = r}		H[r] = nil	mp:exerciseSkill(19, 1 + r.object.level/10)		if cf.m then tes3.messageBox("%s returned to his place", r.object.name) end end
		elseif t.status == 0 and AC[r.cell] then t.status = 1	if cf.m then tes3.messageBox("%s see you again!!", r.object.name) end end
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
	for r, t in pairs(H) do if not r.cell.isInterior and p.position:distance(r.position) > 13000 then
		if cf.m then tes3.messageBox("%s returned to his place (ext) dist = %d", r.object.name, p.position:distance(r.position)) end
		tes3.positionCell{cell = t.scell, position = t.spos, reference = r}		mp:exerciseSkill(19, 1 + r.object.level/10)		H[r] = nil
	end end
else
	for r, t in pairs(H) do if not AC[t.scell] then
		tes3.positionCell{cell = t.scell, position = t.spos, reference = r}		if cf.m then tes3.messageBox("%s returned to his place (TELEPORT)", r.object.name) end		H[r] = nil
	end end
end
end	end		event.register("cellChanged", cellChanged)


local function save(e) if table.size(H) > 0 and not wc.inputController:isKeyDown(cf.skey.keyCode) then	local ms = ""
for r, t in pairs(H) do ms = ("%s %s (%d),"):format(ms, r.object.name, p.position:distance(r.position)) end
tes3.messageBox("You cannot save the game when %s enemies hunt you: %s", table.size(H), ms) return false	end end		if cf.nosav then event.register("save", save) end

local function death(e) H[e.reference] = nil end		event.register("death", death)
local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer		wc = tes3.worldController	H = {}	TH = {}		TIM = nil		Dtim = nil	end		event.register("loaded", loaded)

local function registerModConfig()		local template = mwse.mcm.createTemplate("DragonDoor!")	template:saveOnClose("DragonDoor!", cf)	template:register()		local page = template:createPage()
page:createYesNoButton{label = "Show messages", variable = mwse.mcm.createTableVariable{id = "m", table = cf}}
page:createYesNoButton{label = "Fix for stuck NPCs in doors", variable = mwse.mcm.createTableVariable{id = "nost", table = cf}}
page:createSlider{label = "Radius for stuck NPCs", min = 50, max = 500, step = 10, jump = 50, variable = mwse.mcm.createTableVariable{id = "nor", table = cf}}
page:createSlider{label = "Backward speed for stuck NPCs", min = 500, max = 2000, step = 50, jump = 100, variable = mwse.mcm.createTableVariable{id = "acs", table = cf}}
page:createYesNoButton{label = "Allow vampires to chase", variable = mwse.mcm.createTableVariable{id = "vamp", table = cf}}
page:createYesNoButton{label = "NPCs will call for help in battle", variable = mwse.mcm.createTableVariable{id = "help", table = cf}}
page:createSlider{label = "The distance from which the enemies hear a call for help", min = 1000, max = 5000, step = 10, jump = 500, variable = mwse.mcm.createTableVariable{id = "hdist", table = cf}}
page:createYesNoButton{label = "Prevent save when pursuing - recommended to enable (requires game restart)", variable = mwse.mcm.createTableVariable{id = "nosav", table = cf}}
page:createKeyBinder{allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "skey", table = cf}, label = "Emergency save button. Hold this button while saving to remove the ban on saving when pursuing."}
end		event.register("modConfigReady", registerModConfig)