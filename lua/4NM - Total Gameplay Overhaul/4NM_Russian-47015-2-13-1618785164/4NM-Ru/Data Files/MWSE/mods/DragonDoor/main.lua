local cf = mwse.loadConfig("DragonDoor!", {m = false, nost = true, nor = 300, acs = 1000, help = true, vamp = true, nosav = true, hdist = 3000, skey = {keyCode = 56}})
local H = {}	local TH = {}		local p, mp, TIM, Dtim, AC, wc
local summon = {["atronach_flame_summon"] = true,["atronach_frost_summon"] = true,["atronach_storm_summon"] = true,["golden saint_summon"] = true,["daedroth_summon"] = true,["dremora_summon"] = true,["scamp_summon"] = true,
["winged twilight_summon"] = true,["clannfear_summon"] = true,["hunger_summon"] = true,["Bonewalker_Greater_summ"] = true,["ancestor_ghost_summon"] = true,["skeleton_summon"] = true,["bonelord_summon"] = true,
["4nm_daedraspider_s"] = true,["4nm_dremora_mage_s"] = true,["4nm_skaafin_s"] = true,["4nm_xivkyn_s"] = true,["4nm_xivilai_s"] = true,["4nm_mazken_s"] = true,["4nm_ogrim_s"] = true,["4nm_skeleton_mage_s"] = true,["4nm_lich_elder_s"] = true,
["BM_bear_black_summon"] = true,["BM_wolf_grey_summon"] = true,["BM_wolf_bone_summon"] = true,["bonewalker_summon"] = true,["centurion_sphere_summon"] = true,["fabricant_summon"] = true}

local function combatStarted(e) if e.target == mp then	local m = e.actor	local r = m.reference
if not H[r] and (m.actorType == 1 and m.flee < 70 and (cf.vamp or not r.baseObject.head.vampiric) or (m.object.biped and not summon[r.baseObject.id])) and m.health.normalized > 0.5 and tes3.getCurrentAIPackageId(m) ~= 3 then
	H[r] = {spos = m.position:copy(), scell = r.cell, status = 1}		if cf.m then tes3.messageBox("%s joined the battle! Enemies = %s", m.object.name, table.size(H)) end
end
if cf.help and r.cell.isInterior and not TH[r] and not summon[r.baseObject.id] then
	TH[r] = timer.start{duration = 3, iterations = 10, callback = function() if not m.isDead and m.inCombat and m.fatigue.current > 0 and m.paralyze < 1 and m.silence < 1 then
		TH[r]:cancel()		if cf.m then tes3.messageBox("%s calls for help!", m.object.name) end
		for ref in tes3.iterate(r.cell.actors) do if not H[ref] and r ~= ref and r.position:distance(ref.position) < cf.hdist and ref.mobile and not ref.mobile.isDead and ref.mobile.fight >= 90 and not ref.mobile.inCombat then
			ref.mobile:startCombat(mp)		if cf.m then tes3.messageBox("%s heard and runs into battle!", ref.object.name) end
		end end
	end end}
end
end end		event.register("combatStarted", combatStarted)


local DAR = {}
local function DoorKick(e)	local r = e.reference	if DAR[r] then e.mobile.impulseVelocity = DAR[r].v * (1/30/wc.deltaTime)	DAR[r].f = DAR[r].f - 1		e.speed = 0
	if DAR[r].f <= 0 then DAR[r] = nil	if table.size(DAR) == 0 then event.unregister("calcMoveSpeed", DoorKick) end end
end end

local list, count
local function activate(e) if e.target.object.objectType == tes3.objectType.door then
if e.activator == p then	list = "You are haunted by: "	count = 0
	for r, t in pairs(H) do if t.status == 1 then
		if AC[r.cell] and r.mobile.inCombat then
			if r.mobile.health.normalized <= 0.5 or r.mobile.fatigue.current < 0 then t.status = 2		if cf.m then tes3.messageBox("%s no longer wants to chase you", r.object.name) end
			elseif p.position:distance(r.position) > 5000 then t.status = 3		if cf.m then tes3.messageBox("%s lost sight of you. Distance = %d", r.object.name, p.position:distance(r.position)) end
			else t.tim = 1 + math.floor(p.position:distance(r.position)/(200 + r.mobile.speed.current*3))	list = list .. r.object.name .. ", "	count = count + 1 end
		else t.status = 3		if cf.m then tes3.messageBox("%s lost sight of you!", r.object.name) end
		end
	elseif t.status == 3 then if AC[r.cell] and r.mobile.inCombat then t.status = 1		t.tim = 1 + math.floor(p.position:distance(r.position)/(200 + r.mobile.speed.current*3))
		if cf.m then tes3.messageBox("%s see you again", r.object.name) end		list = list .. r.object.name .. ", "	count = count + 1 end
	elseif t.status == 4 then list = list .. r.object.name .. ", "	count = count + 1 end end
	if cf.m and count ~= 0 then tes3.messageBox("%s Total = %s/%s", list, count, table.size(H)) end
	if Dtim then Dtim:cancel() end		Dtim = timer.start{duration = 0.3, callback = function() Dtim = nil end}
elseif cf.nost then
	for ref in tes3.iterate(e.target.cell.actors) do if ref.mobile and not ref.mobile.isDead and e.target.position:distance(ref.position) < cf.nor then
		if table.size(DAR) == 0 then event.register("calcMoveSpeed", DoorKick) end		DAR[ref] = {v = ref.sceneNode.rotation:transpose().y * -cf.acs, f = 30}
	end end
	if cf.m then tes3.messageBox("%s open the door %s  Total = %d", e.activator.object.name, e.target.object.id, table.size(DAR)) end
end
end end		event.register("activate", activate)


-- Статусы: 1 = видит игрока и в бою, 2 = ранен или вырублен, 3 = потерял из виду, 4 = идёт к двери куда последний раз зашёл игрок
local function cellChanged(e)	AC = {}		for _, cell in pairs(tes3.getActiveCells()) do AC[cell] = true end	if e.previousCell and table.size(H) > 0 then
if Dtim and (e.cell.isInterior or e.previousCell.isInterior) then
	for r, t in pairs(H) do
		if t.status == 1 then
			if r.cell ~= p.cell and (r.cell.isInterior or p.cell.isInterior) then t.tcell = p.cell	t.tpos = p.position:copy()	t.status = 4
			elseif AC[r.cell] then	if cf.m then tes3.messageBox("%s see you!", r.object.name) end end
		elseif t.status == 2 then
			if not AC[r.cell] and not AC[t.scell] then tes3.positionCell{cell = t.scell, position = t.spos, reference = r}	H[r] = nil	if cf.m then tes3.messageBox("%s is beaten and returned to his place", r.object.name) end end
		elseif t.status == 3 then
			if AC[r.cell] then	t.status = 1	if cf.m then tes3.messageBox("%s see you again!", r.object.name) end
			elseif not AC[t.scell] then tes3.positionCell{cell = t.scell, position = t.spos, reference = r}		H[r] = nil	mp:exerciseSkill(19, 1 + r.object.level/10)		if cf.m then tes3.messageBox("%s returned to his place", r.object.name) end end
		elseif t.status == 4 and AC[r.cell] then t.status = 1	if cf.m then tes3.messageBox("%s see you again!!", r.object.name) end end
	end
	
	if table.size(H) ~= 0 and TIM == nil then TIM = timer.start{duration = 1, iterations = -1, callback = function() local fin = true
		for r, t in pairs(H) do
			if t.status == 4 then fin = nil		t.tim = t.tim - 1
				if t.tim <= 0 then	tes3.positionCell{cell = t.tcell, position = t.tpos, reference = r}
					if AC[t.tcell] then	t.status = 1	r.mobile:startCombat(mp)		r.mobile.actionData.aiBehaviorState = 3
						if cf.m then tes3.messageBox("%s opened the door and found you! Distance = %d", r.object.name, p.position:distance(t.tpos)) end
					else t.status = 3	if cf.m then tes3.messageBox("%s opened the door and lost sight of you!", r.object.name) end end
				end
			end
		end
		if fin then TIM:cancel()	TIM = nil	if cf.m then tes3.messageBox("The chase is over") end end
	end} end
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
end end		event.register("cellChanged", cellChanged)


local function save(e) if table.size(H) > 0 and not wc.inputController:isKeyDown(cf.skey.keyCode) then	local ms = ""	--p.position:distance(r.position)	r.mobile.boundSize.z
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