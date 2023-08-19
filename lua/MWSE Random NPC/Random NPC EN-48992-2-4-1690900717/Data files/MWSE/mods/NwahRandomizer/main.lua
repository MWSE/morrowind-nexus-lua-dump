local cf = mwse.loadConfig("Nwah Randomizer", {spawnch = 5, live = 6, AI = 4, noact = true, heads = true, tr = true, trib = true})		local eng = tes3.getLanguage() ~= "rus"
local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Nwah Randomizer")	tpl:saveOnClose("Nwah Randomizer", cf)	tpl:register()	local var = mwse.mcm.createTableVariable	local page = tpl:createPage()
page:createSlider{label = eng and "Spawn chance" or "Шанс спавна", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "spawnch", table = cf}}
page:createSlider{label = eng and "Lifetime of new NPCs (game hours)" or "Время жизни новых неписей в игровых часах", min = 1, max = 24, step = 1, jump = 6, variable = var{id = "live", table = cf}}
page:createSlider{label = eng and "Period of the new AI timer. Select 0 to disable new AI. Requires loading a save." or
"Периодичность таймера нового ИИ. Выберите 0 чтобы отключить новый ИИ. Требует загрузки сейва.", min = 0, max = 10, step = 1, jump = 1, variable = var{id = "AI", table = cf}}
page:createYesNoButton{label = eng and "Allow spawning on the continent" or "Разрешить спавн на континенте", variable = var{id = "tr", table = cf}}
page:createYesNoButton{label = eng and "Allow spawning in Mournhold" or "Разрешить спавн в Морнхолде", variable = var{id = "trib", table = cf}}
page:createYesNoButton{label = eng and "New NPCs don't speak" or "Новые нпс не разговаривают", variable = var{id = "noact", table = cf}, restartRequired = true}
page:createYesNoButton{label = eng and "Allow to use heads from TR" or "Разрешить использовать головы из ТР", variable = var{id = "heads", table = cf}, restartRequired = true}
end		event.register("modConfigReady", registerModConfig)

local p, D, AC, T, hour		local B = {[0] = {}, [1] = {}}
local R = {}	local PG = {} 	 local PGC = {}		local NP = {}		local up = tes3vector3.new(0,0,50)
local function Pos(pos) return math.ceil(pos.x + pos.y) end

local cit = {"NM_npc_cit_1", "NM_npc_cit_2"}
local pil = {"NM_npc_pil_1", "NM_npc_pil_2"}
local red = {"NM_npc_redoran"}
local slv = {"NM_npc_slv_1", "NM_npc_slv_2", "NM_npc_slv_3", "NM_npc_slv_4"}
local citA = {"NM_npc_cit_A1", "NM_npc_cit_A2"}
local tel = {"NM_npc_tel_1", "NM_npc_tel_2"}
local miner = {"NM_npc_miner"}
local fish = {"NM_npc_fisherman"}
local TMora = {"NM_npc_tel_2", "NM_npc_cit_1"}
local adv = {"NM_npc_adv"}



local C = {--Cell"] = "Nwahs",--CommentsComments2Comments 3
["-11 15"] = {cit, fish},--VillageАльд Велоти
["-2 6"] = {citA, pil, red, citA, pil, red, adv},--RedoranАльдрун
["-3 6"] = {citA, citA, red, citA, citA, red, adv},--RedoranАльдрун
["-2 -2"] = {cit},--HlaaluБалмора
["-3 -2"] = {cit, cit, pil, cit, cit, pil, adv},--HlaaluБалмора
["-3 -3"] = {cit, cit, pil, cit, cit, pil, adv},--HlaaluБалмора
["-4 -2"] = {cit, cit, slv},--HlaaluБалмора
["4 -11"] = {cit, cit, slv, adv, adv},--Indoril VivecВивек, Арена
["3 -12"] = {cit},--Indoril VivecВивек, Делин
["3 -10"] = {cit, cit, adv, pil},--Indoril VivecВивек, Квартал Чужеземцев
["4 -10"] = {cit},--Indoril VivecВивек, Квартал Чужеземцев
["4 -12"] = {cit},--Indoril VivecВивек, Олмс
["3 -11"] = {cit, cit, red},--Indoril VivecВивек, Редоран
["5 -11"] = {cit, tel, tel, slv},--Indoril VivecВивек, Телванни
["2 -10"] = {cit},--Indoril VivecВивек, территория рядом
["3 -9"] = {cit, pil},--Indoril VivecВивек, территория рядом
["5 -10"] = {cit},--Indoril VivecВивек, территория рядом
["2 -11"] = {cit, cit, cit, slv},--Indoril VivecВивек, Хлаалу
["3 -13"] = {cit, pil, pil},--Indoril VivecВивек, Храм
["4 -13"] = {pil},--Indoril VivecВивек, Храм
["11 14"] = {cit},--TelvanniВос
["12 13"] = {cit, fish},--TelvanniВос
["-8 3"] = {cit, fish, fish},--VillageГнаар Мок
["-10 11"] = {cit, miner},--RedoranГнисис
["-11 11"] = {pil, miner},--RedoranГнисис
["7 22"] = {cit, fish},--VillageДагон Фел
["-2 2"] = {cit, miner, cit},--ImperialКальдера
["-3 1"] = {miner},--ImperialКальдера, шахты
["-3 12"] = {pil, red, citA},--RedoranМаар Ган
["12 -8"] = {pil},--RedoranМолаг Мар
["13 -8"] = {pil, pil, citA},--RedoranМолаг Мар
["0 -7"] = {cit},--ImperialПелагиад
["0 -8"] = {cit},--ImperialПелагиад
["2 4"] = {pil, red, adv},--Indoril TempleПризрачные Врата
["17 4"] = {tel, tel, slv, cit, fish},--TelvanniСадрит Мора
["17 5"] = {tel, tel, cit},--TelvanniСадрит Мора
["18 4"] = {tel, tel, slv, cit, cit, adv},--TelvanniСадрит Мора
["-2 -9"] = {cit, fish},--VillageСейда Нин
["6 -6"] = {cit, cit, cit, pil, slv},--HlaaluСуран
["6 -7"] = {cit},--HlaaluСуран
["15 5"] = {tel, tel, slv, cit},--TelvanniТель Арун
["14 -13"] = {tel, cit, fish},--TelvanniТель Бранора
["15 -13"] = {tel, tel, slv, cit},--TelvanniТель Бранора
["10 14"] = {tel, tel, slv},--TelvanniТель Вос
["3 14"] = {cit, TMora, TMora, TMora, slv},--TelvanniТель Мора
["-6 -5"] = {cit, fish, fish},--VillageХла Оуд
["-9 17"] = {cit, fish, fish},--VillageХуул
["1 -13"] = {cit, cit, cit, cit, cit, adv},--ImperialЭбенгард
["2 -13"] = {cit, cit, cit, cit, cit, adv},--ImperialЭбенгард
["Adonathran"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Andothren"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Armun Pass Outpost"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Arvud"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Balmora"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Hlan Oek"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Hlarud"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Idathen"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Ilaanam"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Indal-Ruhn"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Kragen Mar"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Menaan"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Narsis"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Narun"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Nav Andaram"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Omaynis"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Othmura"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Sadrathim"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Shipal Sharai"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Suran"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Ud Hleryn"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Uneyn"] = {cit, cit, cit, cit, cit, pil, pil, adv},--Hlaalu
["Bal Oyra"] = {cit, cit, cit, cit, cit, adv},--Imperial
["Caldera"] = {cit, cit, cit, cit, cit, adv},--Imperial
["Cormar"] = {cit, cit, cit, cit, cit, adv},--Imperial
["Ebonheart"] = {cit, cit, cit, cit, cit, adv},--Imperial
["Firewatch"] = {cit, cit, cit, cit, cit, adv},--Imperial
["Helnim"] = {cit, cit, cit, cit, cit, adv},--Imperial
["Nivalis"] = {cit, cit, cit, cit, cit, adv},--Imperial
["Old Ebonheart"] = {cit, cit, cit, cit, cit, adv},--Imperial
["Pelagiad"] = {cit, cit, cit, cit, cit, adv},--Imperial
--["Raven Rock"] = {cit, cit, cit, cit, cit, adv},--Imperial
["Teyn"] = {cit, cit, cit, cit, cit, adv},--Imperial
["Aimrah"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Akamora"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Almalexia"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Ammar"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Bosmora"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Dreynim Spa"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Enamor Dayn"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Gorne"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Meralag"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Molag Mar"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Othrenis"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Roa Dyr"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Sailen"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Vhul"] = {cit, cit, cit, cit, pil, pil, adv},--Indoril
["Almas Thirr"] = {cit, cit, cit, pil, pil, pil, adv},--Indoril Temple
["Ghostgate"] = {pil, pil, adv},--Indoril Temple
["Necrom"] = {cit, pil, pil},--Indoril Temple
["Mournhold, Godsreach"] = {cit, cit, cit, cit, pil, adv},--Mournhold
["Mournhold, Great Bazaar"] = {cit, cit, cit, cit, pil, adv},--Mournhold
["Mournhold, Plaza Brindisi Dorom"] = {cit, cit, cit, cit, pil, pil, adv},--Mournhold
["Mournhold, Temple Courtyard"] = {cit, pil, pil},--Mournhold
["Ald-ruhn"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Baan Malur"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Bodrem"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Bodrum"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Gnisis"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Kartur"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Kogomar"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Kogotel"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Maar Gan"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Rhanim"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Rhun Huk"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Soluthis"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Uman"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Verachen"] = {cit, cit, citA, citA, red, red, pil, adv},--Redoran
["Alt Bosara"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Gah Sadrith"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Llothanis"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Marog"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Port Telvannis"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Ranyon-ruhn"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Sadrith Mora"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Tel Aranyon"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Tel Aruhn"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Tel Branora"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Tel Drevis"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Tel Gilan"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Tel Mora"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Tel Mothrivra"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Tel Muthada"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Tel Oren"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Tel Ouada"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Tel Rivus"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
--["Uvirith's Grave"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Verulas Pass"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Vos"] = {cit, cit, cit, slv, tel, tel, pil, adv},--Telvanni
["Ald Velothi"] = {cit, cit, cit, fish, pil},--Village
["Bahrammu"] = {cit, cit, cit, fish, pil},--Village
["Baldrahn"] = {cit, cit, cit, fish, pil},--Village
["Dondril"] = {cit, cit, cit, fish, pil},--Village
["Eravan"] = {cit, cit, cit, fish, pil},--Village
["Fair Helas"] = {cit, cit, cit, fish, pil},--Village
["Felms Ithul"] = {cit, cit, cit, fish, pil},--Village
["Gnaar Mok"] = {cit, cit, cit, fish, pil},--Village
["Hla Bulor"] = {cit, cit, cit, fish, pil},--Village
["Hla Oad"] = {cit, cit, cit, fish, pil},--Village
["Khuul"] = {cit, cit, cit, fish, pil},--Village
["Saveri"] = {cit, cit, cit, fish, pil},--Village
["Selyn"] = {cit, cit, cit, fish, pil},--Village
["Seyda Neen"] = {cit, cit, cit, fish, pil},--Village
["Tahvel"] = {cit, cit, cit, fish, pil},--Village
["Velonith"] = {cit, cit, cit, fish, pil},--Village
["Andar Mok"] = {cit, cit, cit, cit, fish, pil, adv},--Village Port
["Darvonis"] = {cit, cit, cit, cit, fish, pil, adv},--Village Port
["Dreynim"] = {cit, cit, cit, cit, fish, pil, adv},--Village Port
["Gol Mok"] = {cit, cit, cit, cit, fish, pil, adv},--Village Port
["Rilsoan"] = {cit, cit, cit, cit, fish, pil, adv},--Village Port
["Seitur"] = {cit, cit, cit, cit, fish, pil, adv},--Village Port
["Windbreaker Keep"] = {cit, cit, cit, cit, fish, pil, adv},--Village Port
}




local function mobileActivated(e)	local r = e.reference	local d = r.data		if d and d.born then
	if tes3.getSimulationTimestamp() > d.born then r:disable()	mwscript.setDelete{reference = r}
	else local m = e.mobile		R[r] = {m = m, d = d, ad = m.actionData, ai = m.aiPlanner} end
end end		event.register("mobileActivated", mobileActivated)

local function mobileDeactivated(e) R[e.reference] = nil end		event.register("mobileDeactivated", mobileDeactivated)


local function cellChanged(e)	if p.cell.isOrBehavesAsExterior then	local mob, r, pos, np, num		local st = tes3.getSimulationTimestamp()	local deathhour = st + math.min(cf.live, 20 - hour.value)
	local Day = hour.value > 8 and hour.value < 20		PG = {}		--PGC = {}		local eye = tes3.getPlayerEyePosition()	
	for _, cell in pairs(tes3.getActiveCells()) do	local c, tab
		if cell.isInterior then		if cf.trib then c = cell.id 	tab = C[c] end
		else c = cell.gridX .. " " .. cell.gridY		tab = C[c]		if not tab and cf.tr then tab = C[cell.id] end
		end
	
		if tab and cell.pathGrid then
			local SpawnTime = Day and st > (D[c] or 0)		if SpawnTime then D[c] = deathhour end	
			for i, nod in pairs(cell.pathGrid.nodes) do np = nod.position	num = Pos(np)	PG[num] = nod		--NP[num] = np		PGC[num] = nod.connectedNodes
				if SpawnTime and cf.spawnch >= math.random(100) then	pos = np + up
				--	if eye:distance(pos) > 1000 or not tes3.testLineOfSight{position1 = eye, position2 = pos} then
						r = tes3.createReference{object = table.choice(table.choice(tab)), cell = cell, position = pos}		mob = r.mobile		r.data.born = deathhour		r.data.curX = num
						R[r] = {m = mob, d = r.data, ad = mob.actionData, ai = mob.aiPlanner, curnod = nod, lastnod = nod}
				--	end
				end
			end
		end
	end
end end		event.register("cellChanged", cellChanged)

--	for r in tes3.iterate(cell.actors) do if r.data.born then if st - r.data.born > cf.live then r:disable()	mwscript.setDelete{reference = r} else cur = cur + 1 end end end
--	if cell.pathGrid then tes3.messageBox("%s  max = %s   cur = %s", cell.editorName, math.ceil(cell.pathGrid.nodeCount * cf.spawnch/100), cur) end



local function loaded(e)	p = tes3.player		if not p.data.NRAND then p.data.NRAND = {} end	D = p.data.NRAND		hour = tes3.worldController.hour
if cf.AI > 0 then T = timer.start{duration = cf.AI, iterations = -1, callback = function()
	for r, t in pairs(R) do if not t.m.inCombat then
		if not t.curnod then t.curnod = PG[t.d.curX]	t.lastnod = t.curnod end
		if t.curnod then
			local CON = t.curnod.connectedNodes		local Cnum = #CON 	if Cnum > 0 then		--	local cur = t.ai:getActivePackage()		[C]: in function '__index'
				if Cnum > 1 then table.removevalue(CON, t.lastnod) end		--local delind = Cnum > 1 and table.find(CON, t.lastnod)		if delind then CON[delind] = nil end
				t.lastnod = t.curnod
				t.curnod = table.choice(CON)
				t.d.curX = Pos(t.curnod.position)
				tes3.setAITravel{reference = r, destination = t.curnod.position, reset = false}
				--	tes3.messageBox("%s  ind = %s  ai = %s  done = %s   pos = %s", r, t.ai.currentPackageIndex, cur.type, cur.isDone, cur.targetPosition)
			end
		else 	--tes3.messageBox("No curnode! %s   Dest exist = %s", r, PG[Pos(t.ad.walkDestination)])
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


local function initialized(e)		--for c, t in pairs(C) do C[c].m = #t.p end
	for race in tes3.iterate(tes3.getDataHandler().nonDynamicData.races) do B[0][race.id] = {m={}, f={}}	 B[1][race.id] = {m={}, f={}} end
	for bp in tes3.iterateObjects(1497648962) do if bp.partType == 0 and B[bp.part] and bp.playable then 
		if cf.heads or bp.sourceMod == "Morrowind.esm" then table.insert(B[bp.part][bp.raceName][bp.female and "f" or "m"], bp) end		--attempt to index a nil value
	end end
end		event.register("initialized", initialized)