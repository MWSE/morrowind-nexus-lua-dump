local cf = mwse.loadConfig("HeartStrings", {extlvl = 0, extmlvl = 15, extatk = 50, intlvl = 0, intmlvl = 10, intatk = 30, stop = false, msg = false})

local function registerModConfig()		local tpl = mwse.mcm.createTemplate("HeartStrings")	tpl:saveOnClose("HeartStrings", cf)	tpl:register()	local p0 = tpl:createPage()	local var = mwse.mcm.createTableVariable
p0:createSlider{label = "Level of armed enemies to start combat music in exteriors", min = 0, max = 100, step = 5, jump = 10, variable = var{id = "extlvl", table = cf}}
p0:createSlider{label = "Level of monster enemies to start combat music in exteriors", min = 0, max = 100, step = 5, jump = 10, variable = var{id = "extmlvl", table = cf}}
p0:createSlider{label = "Attack power of monster enemies to start combat music in exteriors", min = 0, max = 200, step = 5, jump = 10, variable = var{id = "extatk", table = cf}}
p0:createSlider{label = "Level of armed enemies to start combat music in interiors", min = 0, max = 100, step = 5, jump = 10, variable = var{id = "intlvl", table = cf}}
p0:createSlider{label = "Level of monster enemies to start combat music in interiors", min = 0, max = 100, step = 5, jump = 10, variable = var{id = "intmlvl", table = cf}}
p0:createSlider{label = "Attack power of monster enemies to start combat music in interiors", min = 0, max = 200, step = 5, jump = 10, variable = var{id = "intatk", table = cf}}
p0:createYesNoButton{label = "Start a new track immediately when changing homogeneous locations", variable = var{id = "stop", table = cf}}
p0:createYesNoButton{label = "Print track names", variable = var{id = "msg", table = cf}}
end		event.register("modConfigReady", registerModConfig)


local re = require("re")	local C = require("HeartStrings.music")		local R = require("HeartStrings.regions")		local p, mp, D, COM		local Cach = {["Explore"] = {}}		--local CT = timer
local Ptomb = re.compile[[ "tomb" / "barrow" / "crypt" / "catacomb" / "burial" ]]

local function RandomMP3(dir)	local Tab = Cach[dir]
	if not Tab then Tab = {}	for file in lfs.dir(("data files\\music\\%s"):format(dir)) do if file:endswith("mp3") then table.insert(Tab, file) end end
		Cach[dir] = Tab
	end
	
	local num = #Tab
	if num == 0 then return ("Explore\\%s"):format(Cach.Explore[math.random(#Cach.Explore)])
	else return ("%s\\%s"):format(dir, Tab[math.random(num)]) end
end


local DUN = {
["Dunge"] = 1,
["Dwemer"] = 1,
["Daedric"] = 1,
["Dagoth"] = 1,
["Tomb"] = 1,
["Sewers"] = 1,
["Cave"] = 1,
["Mine"] = 1,
["Stronghold"] = 1,
}

local NOC = {
["Dagoth"] = 1,
["Red Mountain"] = 1,
["Dagoth Ur"] = 1,
["Boss"] = 1,
}

local NOSTOP = {
["Town"] = 1,
["Explore"] = 1,
["Skyrim"] = 1,
["Ashland"] = 1,
["Temple"] = 1,
["Fort"] = 1,
}

local ST = {
["in_pycave"] = "Dunge",
["in_moldcave"] = "Dunge",
["in_mudcave"] = "Dunge",
["in_lavacave"] = "Dunge",
["in_bonecave"] = "Dunge",
["in_BM_cave"] = "Dunge",
["BM_IC"] = "Dunge",
["T_Sky_Cave"] = "Dunge",
["T_Cnq_Cave"] = "Dunge",
["T_Mw_Cave"] = "Dunge",
["AB_In_Cave"] = "Dunge",
["AB_In_MVCave"] = "Dunge",
["T_Ayl_DngRuin"] = "Dunge", -- Айлейдские руины
["T_Imp_Dng"] = "Dunge", -- Киродиильские крипты
["T_Cyr_Cave"] = "Dunge", -- Киродиильские пещеры
}


local function combatStarted(e) if e.target == mp and not COM and not NOC[D.MusL] then		local m = e.actor	local ob = m.object		local int = p.cell.isInterior		local Start 	--local r = m.reference
	if m.actorType == 1 or ob.biped or ob.usesEquipment then					-- ob.type ~= 0
		if ob.level >= (int and cf.intlvl or cf.extlvl) then Start = true end
	elseif (ob.level >= (int and cf.intmlvl or cf.extmlvl)) or (ob.attacks[1].max >= (int and cf.intatk or cf.extatk)) then Start = true end

	if Start then	COM = true
		local file = RandomMP3("Battle")
		tes3.streamMusic{path = file, situation = 1, crossfade = 1}
		if cf.msg then tes3.messageBox("Start - %s", file) end
	end
end end		event.register("combatStarted", combatStarted)


local function musicSelectTrack(e)		--tes3.messageBox("Sit = %s   D = %s    com = %s", e.situation, D.MusL, COM)	
if COM and e.situation == 1 and not NOC[D.MusL] then
	local file = RandomMP3("Battle")
	e.music = file
	if cf.msg then tes3.messageBox("Select - %s", file) end
else
	timer.delayOneFrame(function()	-- Без таймера боевая музыка всегда будет прерывать мирную
		local file = RandomMP3(D.MusL)
		tes3.streamMusic{path = file, situation = 2, crossfade = 1}
		if cf.msg then tes3.messageBox("Select - %s", file) end
	end, timer.real)
	COM = false		e.music = nil	return false
end end		event.register("musicSelectTrack", musicSelectTrack)



local function musicChangeTrack(e)
	tes3.messageBox("Music changed: %s -> %s    sit = %s    fade = %d", e.context, e.music, e.situation, e.crossfade)
end		--event.register("musicChangeTrack", musicChangeTrack)


local function cellChanged(e)	local c = e.cell	local ext = c.isOrBehavesAsExterior		local cid = c.id	local low = cid:lower()		local split = string.split(cid, ",")	split = string.split(split[1], ":")[1]
	local Prev = D.MusL			local Mus = C[cid] or C[split]
	
	if ext then	local reg = tes3.getRegion()	reg = reg and reg.id
		if not Mus or DUN[Mus] then Mus = R[reg] end
	else
		if not Mus then
			if re.find(low, Ptomb) then Mus = "Tomb"		--if string.find(low, "sewers") then Mus = "Sewers" end
			else
				local stid
				for sta in c:iterateReferences(tes3.objectType.static) do stid = sta.id
					for pat, _ in pairs(ST) do if string.startswith(stid, pat) then Mus = "Dunge" break end end
					if Mus then break end
				end
			end
		end
	end
	if not Mus then Mus = "Explore" end

	if D.MusL ~= Mus then D.MusL = Mus
		if not COM and (cf.stop or not (NOSTOP[Prev] and NOSTOP[Mus])) then
			local file = RandomMP3(Mus)
			tes3.streamMusic{path = file, situation = 2, crossfade = 1}
			if cf.msg then tes3.messageBox("Cell - %s", file) end
		end
	end
	--	tes3.messageBox("%s    %s  reg = %s   Mus = %s", cid, split, reg, Mus)
end		event.register("cellChanged", cellChanged)


local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer		D = p.data		D.MusL = D.MusL or "Explore"		COM = nil
end		event.register("loaded", loaded)


local function initialized(e)
	for file in lfs.dir("data files\\music\\Explore") do if file:endswith("mp3") then table.insert(Cach.Explore, file) end end
end		event.register("initialized", initialized)