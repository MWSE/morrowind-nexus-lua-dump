
local cf = mwse.loadConfig("Nwah Randomizer", {en = true, spawnch = 5, live = 6, AI = 4, noact = true, heads = true})

local function registerModConfig()	local template = mwse.mcm.createTemplate("Nwah Randomizer")	template:saveOnClose("Nwah Randomizer", cf)	template:register()	local var = mwse.mcm.createTableVariable	local page = template:createPage()
page:createYesNoButton{label = "English language", variable = var{id = "en", table = cf}}
page:createSlider{label = cf.en and "Spawn chance" or "Шанс спавна", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "spawnch", table = cf}}
page:createSlider{label = cf.en and "Lifetime of new NPCs (game hours)" or "Время жизни новых неписей в игровых часах", min = 1, max = 24, step = 1, jump = 6, variable = var{id = "live", table = cf}}
page:createSlider{label = cf.en and "Period of the new AI timer. Select 0 to disable new AI. Requires loading a save." or
"Периодичность таймера нового ИИ. Выберите 0 чтобы отключить новый ИИ. Требует загрузки сейва.", min = 0, max = 10, step = 1, jump = 1, variable = var{id = "AI", table = cf}}
page:createYesNoButton{label = cf.en and "New NPCs don't speak" or "Новые нпс не разговаривают", variable = var{id = "noact", table = cf}, restartRequired = true}
page:createYesNoButton{label = cf.en and "Allow to use heads from TR" or "Разрешить использовать головы из ТР", variable = var{id = "heads", table = cf}, restartRequired = true}
end		event.register("modConfigReady", registerModConfig)

local p, D, AC, T, hour		local B = {[0] = {}, [1] = {}}		--local BU = {[0] = {}, [1] = {}}
local R = {}	local PG = {}	local SC = {}		local up = tes3vector3.new(0,0,50)


local N = {
cit = {"NM_npc_cit_1", "NM_npc_cit_2"},
pil = {"NM_npc_pil_1", "NM_npc_pil_2"},
red = {"NM_npc_redoran"},
slv = {"NM_npc_slv_1", "NM_npc_slv_2", "NM_npc_slv_3", "NM_npc_slv_4"},
citA = {"NM_npc_cit_A1", "NM_npc_cit_A2"},
tel = {"NM_npc_tel_1", "NM_npc_tel_2"},
miner = {"NM_npc_miner"},
fish = {"NM_npc_fisherman"},
TMora = {"NM_npc_tel_2", "NM_npc_cit_1"},
adv = {"NM_npc_adv"},
}


local C = {
["-3 -3"] = {N.cit, N.cit, N.pil}, -- Балмора
["-3 -2"] = {N.cit, N.cit, N.pil}, -- Балмора
["-2 -2"] = {N.cit}, -- Балмора
["-4 -2"] = {N.cit, N.cit, N.slv}, -- Балмора

["-2 -9"] = {N.cit, N.fish}, -- Сейда Нин

["-3 6"] = {N.citA, N.citA, N.red}, -- Альдрун
["-2 6"] = {N.citA, N.pal, N.red}, -- Альдрун

["3 -9"] = {N.cit, N.pil}, -- территория рядом с Вивеком		в ванили pathGrid отсутствует!
["2 -10"] = {N.cit}, -- территория рядом с Вивеком
["5 -10"] = {N.cit}, -- территория рядом с Вивеком
["4 -11"] = {N.cit, N.cit, N.slv, N.adv, N.adv}, -- Вивек, Арена
["3 -10"] = {N.cit, N.cit, N.adv, N.pil}, -- Вивек, Квартал Чужеземцев
["4 -10"] = {N.cit}, -- Вивек, Квартал Чужеземцев
["2 -11"] = {N.cit, N.cit, N.slv}, -- Вивек, Хлаалу
["3 -11"] = {N.cit, N.cit, N.red}, -- Вивек, Редоран
["3 -12"] = {N.cit}, -- Вивек, Делин
["4 -12"] = {N.cit}, -- Вивек, Олмс
["5 -11"] = {N.cit, N.tel, N.tel, N.slv}, -- Вивек, Телванни
["3 -13"] = {N.cit, N.pil, N.pil}, -- Вивек, Храм
["4 -13"] = {N.pil}, -- Вивек, Храм

["1 -13"] = {N.cit}, -- Эбенгард
["2 -13"] = {N.cit}, -- Эбенгард

["6 -6"] = {N.cit, N.cit, N.slv}, -- Суран
["6 -7"] = {N.cit}, -- Суран

["-10 11"] = {N.cit, N.miner}, -- Гнисис
["-11 11"] = {N.pil, N.miner}, -- Гнисис

["-9 17"] = {N.cit, N.fish, N.fish}, -- Хуул

["-8 3"] = {N.cit, N.fish, N.fish}, -- Гнаар Мок

["-6 -5"] = {N.cit, N.fish, N.fish}, -- Хла Оуд

["7 22"] = {N.cit, N.fish}, -- Дагон Фел

["3 14"] = {N.cit, N.TMora, N.TMora, N.TMora, N.slv}, -- Тель Мора

["12 13"] = {N.cit, N.fish}, -- Вос
["11 14"] = {N.cit}, -- Вос

["10 14"] = {N.tel, N.tel, N.slv}, -- Тель Вос

["15 5"] = {N.tel, N.tel, N.slv, N.cit}, -- Тель Арун

["17 4"] = {N.tel, N.tel, N.slv, N.cit, N.fish}, -- Садрит Мора
["17 5"] = {N.tel}, -- Садрит Мора
["18 4"] = {N.tel, N.tel, N.slv, N.cit}, -- Садрит Мора

["14 -13"] = {N.tel, N.cit, N.fish}, -- Тель Бранора
["15 -13"] = {N.tel, N.tel, N.slv, N.cit}, -- Тель Бранора

["12 -8"] = {N.pil}, -- Молаг Мар
["13 -8"] = {N.pil, N.pil, N.citA}, -- Молаг Мар

["-3 12"] = {N.pil, N.red, N.citA}, -- Маар Ган

["-11 15"] = {N.cit, N.fish}, -- Альд Велоти

["2 4"] = {N.pil, N.red}, -- Призрачные Врата

["-2 2"] = {N.cit, N.miner, N.cit}, -- Кальдера
["-3 1"] = {N.miner}, -- Кальдера, шахты

["0 -8"] = {N.cit}, -- Пелагиад
["0 -7"] = {N.cit}, -- Пелагиад

}



local function mobileActivated(e)	local r = e.reference	local d = r.data		if d and d.born then
	if tes3.getSimulationTimestamp() > d.born then r:disable()	mwscript.setDelete{reference = r}
	else local m = e.mobile		R[r] = {m = m, d = d, ad = m.actionData, ai = m.aiPlanner} end
end end		event.register("mobileActivated", mobileActivated)

local function mobileDeactivated(e) R[e.reference] = nil end		event.register("mobileDeactivated", mobileDeactivated)


local function cellChanged(e)	if not p.cell.isInterior then	local mob, c, r, pos	local st = tes3.getSimulationTimestamp()	local deathhour = st + math.min(cf.live, 20 - hour.value)
	local eye = tes3.getPlayerEyePosition()		local Day = hour.value > 8 and hour.value < 20			PG = {}
	
	for _, cell in pairs(tes3.getActiveCells()) do c = cell.gridX .. " " .. cell.gridY		if C[c] and cell.pathGrid then
	--	if not SC[c] then
			
			for i, nod in pairs(cell.pathGrid.nodes) do PG[math.ceil(nod.position.x)] = nod end		-- attempt to index field 'pathGrid' (a nil value)
	--		SC[c] = true
	--	end
		
		if Day and st > (D[c] or 0) then
			for i, nod in pairs(cell.pathGrid.nodes) do if cf.spawnch >= math.random(100) then pos = nod.position + up
			--	if eye:distance(pos) > 1000 or not tes3.testLineOfSight{position1 = eye, position2 = pos} then
					r = tes3.createReference{object = table.choice(table.choice(C[c])), cell = cell, position = pos}	mob = r.mobile		r.data.born = deathhour
					r.data.curX = math.ceil(nod.position.x)
					R[r] = {m = mob, d = r.data, ad = mob.actionData, ai = mob.aiPlanner, curnod = nod, lastnod = nod}
			--	end
			end end
			D[c] = deathhour
		end
	end end
end end		event.register("cellChanged", cellChanged)

--	for r in tes3.iterate(cell.actors) do if r.data.born then if st - r.data.born > cf.live then r:disable()	mwscript.setDelete{reference = r} else cur = cur + 1 end end end
--	if cell.pathGrid then tes3.messageBox("%s  max = %s   cur = %s", cell.editorName, math.ceil(cell.pathGrid.nodeCount * cf.spawnch/100), cur) end



local function loaded(e)	p = tes3.player		if not p.data.NRAND then p.data.NRAND = {} end	D = p.data.NRAND		hour = tes3.worldController.hour
if cf.AI > 0 then T = timer.start{duration = cf.AI, iterations = -1, callback = function()
	for r, t in pairs(R) do if not t.m.inCombat then
		if not t.curnod then t.curnod = PG[t.d.curX]	t.lastnod = t.curnod end
		
		local CON = t.curnod.connectedNodes		local Cnum = #CON 	if Cnum > 0 then		--	local cur = t.ai:getActivePackage()		[C]: in function '__index'
			local delind = Cnum > 1 and table.find(CON, t.lastnod)		if delind then CON[delind] = nil end
		--	if Cnum > 1 then CON[table.find(CON, t.lastnod)] = nil end		-- table index is nil
			t.lastnod = t.curnod
			t.curnod = table.choice(CON)
			t.d.curX = math.ceil(t.curnod.position.x)
			tes3.setAITravel{reference = r, destination = t.curnod.position, reset = false}
			--	tes3.messageBox("%s  ind = %s  ai = %s  done = %s   pos = %s", r, t.ai.currentPackageIndex, cur.type, cur.isDone, cur.targetPosition)
		end
	end end
	--tes3.messageBox("size = %s", table.size(R))
end} end
end		event.register("loaded", loaded)		--	tes3.getCurrentAIPackageId(r.mobile) ~= 1


local function bodyPartAssigned(e) local r = e.reference	local ind = e.index		if B[ind] and r.baseObject.id:find("NM_npc") and not e.object then
--	tes3.messageBox("r = %s  ind = %s", r, ind)
	if r.data["BP"..ind] then e.bodyPart = tes3.getObject(r.data["BP"..ind])
	else local bp = table.choice(B[ind][r.object.race.id][r.object.female and "f" or "m"])	e.bodyPart = bp		r.data["BP"..ind] = bp.id end
end end		event.register("bodyPartAssigned", bodyPartAssigned)

local function activate(e) local t = e.target
	if e.activator == p and t.object.objectType == tes3.objectType.npc and t.data.born and not t.mobile.isDead and not tes3.mobilePlayer.isSneaking and t.baseObject.barterGold == 0 then return false end
end		if cf.noact then event.register("activate", activate) end


--local function onKey()	tes3.messageBox([=[ %s ["%s"] {%d,%d,%d}]=], p.cell.id, p.cell.gridX .. p.cell.gridY, p.position.x, p.position.y, p.position.z+100)
--mwse.log([=[ %s ["%s"] {%d,%d,%d}]=], p.cell.id, p.cell.gridX .. p.cell.gridY, p.position.x, p.position.y, p.position.z+100) end		event.register("keyDown", onKey, {filter = 42})


local function initialized(e)		--for c, t in pairs(C) do C[c].m = #t.p end
	for race in tes3.iterate(tes3.getDataHandler().nonDynamicData.races) do B[0][race.id] = {m={}, f={}}	 B[1][race.id] = {m={}, f={}} end
	for bp in tes3.iterateObjects(1497648962) do if bp.partType == 0 and B[bp.part] and not bp.playable then 
		if cf.heads or bp.sourceMod == "Morrowind.esm" then table.insert(B[bp.part][bp.raceName][bp.female and "f" or "m"], bp) end		--attempt to index a nil value
	end end
end		event.register("initialized", initialized)