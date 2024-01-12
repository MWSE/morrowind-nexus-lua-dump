local eng = tes3.getLanguage() ~= "rus"
local cf = mwse.loadConfig("Impact Sounds", {newsnd = true, metblood = true,
volimp = 0.7, volarm = 1, voldmg = 0.7, volsw = 0.7, volit = 1, npcfdist = 2000, volfoot = 1, volfootnpc = 1, volfarm = 1, volfarmnpc = 1, volcont = 1})

local function registerModConfig()		local tpl = mwse.mcm.createTemplate("Impact Sounds")	tpl:saveOnClose("Impact Sounds", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local ps = tpl:createPage()
ps:createYesNoButton{label = eng and "Improved sounds" or "Улучшенные звуки", variable = var{id = "newsnd", table = cf}, restartRequired = true}
ps:createDecimalSlider{label = eng and "Weapon impact sound volume" or "Громкость звуков соударений оружия", variable = var{id = "volimp", table = cf}}
ps:createDecimalSlider{label = eng and "The volume of weapon impacts on armor" or "Громкость ударов оружия по броне", variable = var{id = "volarm", table = cf}}
ps:createDecimalSlider{label = eng and "Damage sound volume" or "Громкость звуков урона", variable = var{id = "voldmg", table = cf}}
ps:createDecimalSlider{label = eng and "Weapon swing sound volume" or "Громкость звуков взмахов оружия", variable = var{id = "volsw", table = cf}}
ps:createDecimalSlider{label = eng and "Item sound volume" or "Громкость звуков предметов", variable = var{id = "volit", table = cf}}
ps:createDecimalSlider{label = eng and "Player footstep volume" or "Громкость звуков шагов игрока", variable = var{id = "volfoot", table = cf}}
ps:createDecimalSlider{label = eng and "NPC footstep volume" or "Громкость звуков шагов нпс", variable = var{id = "volfootnpc", table = cf}}
ps:createDecimalSlider{label = eng and "Player armor clanking volume" or "Громкость лязга брони игрока", variable = var{id = "volfarm", table = cf}}
ps:createDecimalSlider{label = eng and "NPC armor clanking volume" or "Громкость лязга брони нпс", variable = var{id = "volfarmnpc", table = cf}}
ps:createSlider{label = eng and "Replacement distance for NPC footstep sounds" or "Дистанция замены звуков шагов нпс", min = 0, max = 3000, step = 100, jump = 500, variable = var{id = "npcfdist", table = cf}}
ps:createDecimalSlider{label = eng and "Volume of sounds of looting bodies" or "Громкость звуков лутания тел", variable = var{id = "volcont", table = cf}}
ps:createYesNoButton{label = eng and "Replace metal blood with sparks" or "Заменить металлическую кровь на искры", variable = var{id = "metblood", table = cf}}
end		event.register("modConfigReady", registerModConfig)


local p, mp, wc		local G = {DmgR = {}}	local V = {down10 = tes3vector3.new(0, 0, -10), down = tes3vector3.new(0,0,-1), up20 = tes3vector3.new(0,0,20)}
local L = {FIL = {}, TCash = {}, TD = require("4NM.tex"), ITNIF = require("4NM.itemnifs"), CRNIF = require("4NM.creanifs"),
MAT = {Dirt = "Dirt", Metal = "Metal", Stone = "Stone", Wood = "Wood", Ice = "Ice", Carpet = "Dirt", Grass = "Dirt", Gravel = "Dirt", Sand = "Dirt", Snow = "Dirt", Mud = "Dirt", Water = "Water"},
MatD = {Dmg = 0.5, DmgDwemer = 1, DmgSkeleton = 0.5, DmgGhost = 0.1, Dirt = 0.3, Metal = 1, Stone = 0.8, Wood = 0.4, Ice = 0.4, Carpet = 0.3, Grass = 0.3, Gravel = 0.5, Sand = 0.3, Snow = 0.2, Mud = 0.2, Water = 0.05},
MatSpark = {Stone = true, Metal = true, DmgDwemer = true},
AD = {[5] = 1, [6] = 1, [7] = 1},
}

local WT = {[-1]={s=26,p1="hand1",p2="hand2",p3="hand3",p4="hand4",p5="hand5",p6="hand6",p8="hand8",pc="hand12",iso=0,sws="SwingFist"},
[0]={s=22,p1="short1",p2="short2",p3="short3",p4="short4",p5="short5",p6="short6",p7="short7",p8="short8",p9="short9",p="short0",pc="short13",h1=true,dw=true,pso=1,iso=1,sws="SwingShort",isnd="Short"},
[1]={s=5,p1="long1a",p2="long2a",p3="long3a",p4="long4a",p5="long5a",p6="long6a",p7="long7a",p8="long8a",p9="long9a",p="long0",pc="long9",h1=true,dw=true,pso=2,iso=2,sws="SwingLong1",isnd="Long"},
[2]={s=5,p1="long1b",p2="long2b",p3="long3b",p4="long4b",p5="long5b",p6="long6b",p7="long7b",p8="long8b",p9="long9b",p="long0",pso=2,iso=2,sws="SwingLong2",isnd="Long"},
[3]={s=4,p1="blu1a",p2="blu2a",p3="blu3a",p4="blu4a",p5="blu5a",p6="blu6a",p7="blu7a",p8="blu8a",p9="blu9a",p="blu0a",h1=true,dw=true,pso=4,iso=4,sws="SwingBlunt1",isnd="Blunt"},
[4]={s=4,p1="blu1b",p2="blu2b",p3="blu3b",p4="blu4b",p5="blu5b",p6="blu6b",p7="blu7b",p8="blu8b",p9="blu9b",p="blu0a",pso=4,iso=4,sws="SwingBlunt2",isnd="Blunt"},
[5]= {s=4,p1="blu1c",p2="blu2c",p3="blu3c",p4="blu4c",p5="blu5c",p6="blu6c",p7="blu7c",p8="blu8c",p9="blu9c",p="blu0c",pc="blu10",pso=4,iso=4,sws="SwingSpear",isnd="Blunt"},
[-3]={s=4,p1="blu1c",p2="blu2c",p3="blu3c",p4="blu4c",p5="blu5c",p6="blu6c",p7="blu7c",p8="blu8c",p9="blu9c",p="blu0c",pc="blu10",h1=true,dw=true,pso=4,iso=4,sws="SwingSpear",isnd="Blunt"},
[6]={s=7,p1="spear1",p2="spear2",p3="spear3",p4="spear4",p5="spear5",p6="spear6",p7="spear7",p8="spear8",p9="spear9",p="spear0",pso=3,iso=2,sws="SwingSpear",isnd="Spear"},
[-2]={s=7,p1="spear1a",p2="spear2a",p3="spear3a",p4="spear4a",p5="spear5a",p6="spear6a",p7="spear7a",p8="spear8a",p9="spear9a",p="spear0",h1=true,dw=true,pso=3,iso=2,sws="SwingSpear",isnd="Spear"},
[7]={s=6,p1="axe1a",p2="axe2a",p3="axe3a",p4="axe4a",p5="axe5a",p6="axe6a",p7="axe7a",p8="axe8a",p9="axe9a",p="axe0",h1=true,dw=true,pso=3,iso=3,sws="SwingAxe1",isnd="Axe"},
[8]={s=6,p1="axe1b",p2="axe2b",p3="axe3b",p4="axe4b",p5="axe5b",p6="axe6b",p7="axe7b",p8="axe8b",p9="axe9b",p="axe0",pso=3,iso=3,sws="SwingAxe2",isnd="Axe"},
[9]={s=23,p1="mark1a",p2="mark2a",p3="mark3a",p4="mark4a",p5="mark5a",p6="mark6a",p="mark0a",iso=5,isnd="Bow"},
[10]={s=23,p1="mark1b",p2="mark2b",p3="mark3b",p4="mark4b",p5="mark5b",p6="mark6b",p="mark0b",iso=5,isnd="Cross"},
[11]={s=23,p1="mark1c",p2="mark2c",p3="mark3c",p4="mark4c",p5="mark5c",p6="mark6c",p="mark0c",h1=true,iso=5,sws="SwingThrow",isnd="Throw"},
[12]={isnd="Ammo"},
[13]={isnd="Ammo"}}

L.RSound = function(d) if not L.FIL[d] then L.FIL[d] = {}	for file in lfs.dir("data files\\sound\\4NM\\" .. d) do if file:endswith("wav") then table.insert(L.FIL[d], file) end end	end	return ("4NM\\%s\\%s"):format(d, table.choice(L.FIL[d])) end
L.GetMat = function(hit)	local tex = hit.object.texturingProperty	tex = tex and tex.maps[1].texture.fileName		
	if tex then		local result = L.TCash[tex]
		if not result then result = tex:lower():gsub("/", "\\")
			if result:find("^textures\\") then result = result:sub(10, -5) elseif result:find("^data files\\textures\\") then result = result:sub(21, -5) else result = result:sub(1, -5) end
			L.TCash[tex] = result
		end
		local Mat = L.TD[result]
		
		if not Mat then local r = hit.reference
			if r then	local meshl = r.object.mesh:lower()
				if meshl:find("flora") then Mat = meshl:find("tree") and "Wood" or "Dirt" 
				else Mat = "Stone" end
			else Mat = "Dirt" end
			L.TD[result] = Mat
		end
		return Mat
	end
end


local function attackHit(e) local a = e.mobile	if a == mp then		local ad = a.actionData		local rw = a.readiedWeapon	local w = rw and rw.object		local wt = w and w.type or -1
	if wt < 9 then
		if not e.targetMobile then
			local hit = tes3.rayTest{position = tes3.getPlayerEyePosition() + V.down10, direction = tes3.getPlayerEyeVector(), maxDistance = 135 * (w and w.reach or tes3.findGMST("fHandToHandReach").value), ignore = {p}}
			if hit then local r = hit.reference	local mob = r and r.mobile		local Mat, dir		local dmg = WT[wt].iso
				if mob then
					if mob.isDead then	local ob = r.object		local at
						if ob.objectType == tes3.objectType.creature then	local mt = L.CRNIF[ob.mesh:lower()]		at = mt and mt.at
							if ob.type == tes3.creatureType.undead then
								if mob.chameleon > 49 then dir = "DmgGhost"		Mat = "DmgGhost"	
								elseif ob.blood == 1 then dir = "DmgSkeleton"	Mat = "DmgSkeleton" end
							elseif ob.blood == 2 then dir = "DmgDwemer"			Mat = "DmgDwemer" end
							if not Mat then Mat = mt and mt.mat or "Dmg" end
						else	Mat = "Dmg"		at = tes3.getEquippedItem{actor = r, objectType = tes3.objectType.armor, slot = 1}		if at then at = at.object.weightClass end	end
						if not dir then dir = (dmg > 0 and Mat or "Dmg") .. dmg end
						if at then tes3.playSound{reference = r, soundPath = L.RSound("DmgArmor" .. at), volume = cf.volarm, pitch = math.random(90,110)/100} end
						tes3.playSound{reference = r, soundPath = L.RSound(dir), volume = cf.voldmg, pitch = math.random(90,110)/100}
					--elseif not ad.hitTarget then ad.hitTarget = mob		t = mob
					end
				else
					Mat = L.MAT[L.GetMat(hit)] or "Stone"
					if Mat == "Water" then dir = Mat elseif wt == -1 then dir = "Dmg0" else dir = Mat .. dmg end
					tes3.playSound{reference = p, soundPath = L.RSound(dir), volume = cf.volimp, pitch = math.random(90,110)/100}
				end
				if w and Mat then rw.variables.condition = math.max(rw.variables.condition - ad.physicalDamage * L.MatD[Mat] * 0.1, 0)
					if L.MatSpark[Mat] then tes3.createVisualEffect{object = G.VFXspark, repeatCount = 1, position = hit.intersection} end
				end		--tes3.messageBox("%s   mat = %s", dir, Mat)
			end
		end
	end
end end		event.register("attackHit", attackHit)



local function CALCARMORPIECEHIT(e)
	G.ArSlot = e.slot
end		if cf.newsnd then event.register("calcArmorPieceHit", CALCARMORPIECEHIT) end


local function DAMAGE(e) local source = e.source	if source == "attack" then		local a = e.attacker	local tr = e.reference		local t = e.mobile
	local rw = a.readiedWeapon		local pr = e.projectile		local w = pr and pr.firingWeapon or (rw and rw.object)		local wt = w and w.type or -1		
	
	if cf.metblood and tr ~= p and tr.object.blood == 2 then
		for _, splash in ipairs(wc.splashController.activeSplashes) do splash.node.appCulled = true end
		tes3.createVisualEffect{object = G.VFXspark, repeatCount = 1, position = (tr.position + tes3vector3.new(0,0,t.height * math.random(50,90)/100) + tr.forwardDirection * 25 + tr.rightDirection * math.random(-30,30))}
	end
	
	if e.damage > 0 and L.AD[a.actionData.physicalAttackType] ~= 1 then G.DmgR[tr] = WT[wt].iso end
elseif source == "fall" then
	if e.damage > 0 then G.DmgR[e.reference] = "Fall" end
end end		event.register("damage", DAMAGE)



L.ARS = {["Light Armor Hit"] = 0, ["Medium Armor Hit"] = 1, ["Heavy Armor Hit"] = 2}
L.SND = {
["Hand To Hand Hit"] = {"Dmg0", "voldmg"},
["Hand to Hand Hit 2"] = {"Dmg0", "voldmg"},
["crossbowPull"] = {"CrossPull", "volsw"},
["crossbowShoot"] = {"CrossShoot", "volsw"},
["bowPull"] = {"BowPull", "volsw"},
["bowShoot"] = {"BowShoot", "volsw"},

["potion success"] = {"PotionSuccess", "volit"},
["Drink"] = {"PotionDrink", "volit"},
["Repair"] = {"RepairSuccess", "volit"},
["repair fail"] = {"RepairFail", "volit"},
["book page"] = {"Scrolls", "volit"},
["book page2"] = {"Scrolls", "volit"},
["scroll"] = {"Scrolls", "volit"},
["Item Ingredient Up"] = {"Ingredient", "volit"},	-- Для график гербализма
["Item Ammo Down"] = {"Ingredient", "volit"},		-- Для график гербализма
["Swallow"] = {"IngredientEat", "volit"},
--["potion fail"] = {"PotionFail", "volit"},
["FootWaterLeft"] = {"WaterL", "volfoot"},
["FootWaterRight"] = {"WaterR", "volfoot"},
["Swim Left"] = {"WaterL", "volfoot"},
["Swim Right"] = {"WaterR", "volfoot"},
["DefaultLandWater"] = {"WaterJ", "volfoot"},
["SwishL"] = 0,
["SwishM"] = 0,
["SwishS"] = 0,
["miss"] = 0}
L.FOOTS = {
["FootBareLeft"] = "L",
["FootBareRight"] = "R",
["FootLightLeft"] = "L",
["FootLightRight"] = "R",
["FootMedLeft"] = "L",
["FootMedRight"] = "R",
["FootHeavyLeft"] = "L",
["FootHeavyRight"] = "R",
["animalLARGEleft"] = "L",
["animalLARGEright"] = "R",
["animalSMALLleft"] = "L",
["animalSMALLright"] = "R",
["DefaultLand"] = "J",
["Body Fall Large"] = "J"}
L.DmgMat = {[1] = true, [2] = true, [3] = true, [4] = true, [5] = true}

local function ADDSOUND(e)		local r = e.reference	if r then	local sid = e.sound.id
	--mwse.log("%s  %s", sid, r)		tes3.messageBox("%s  %s", sid, r)
	if L.FOOTS[sid] then	local m = r.mobile
		if m and (r == p or m.playerDistance < cf.npcfdist) then
			if cf[r == p and "volfarm" or "volfarmnpc"] > 0 then	local ob = r.object		local cui
				if ob.objectType == tes3.objectType.creature then
					local mt = L.CRNIF[ob.mesh:lower()]		cui = mt and mt.at
					if ob.type == tes3.creatureType.undead and ob.blood == 1 then tes3.playSound{reference = r, soundPath = L.RSound("Bones"), volume = cf["volfarmnpc"], pitch = math.random(90,110)/100} end
				else cui = tes3.getEquippedItem{actor = r, objectType = tes3.objectType.armor, slot = 1}	if cui then cui = cui.object.weightClass end end
				if cui then tes3.playSound{reference = r, soundPath = L.RSound("Armor" .. cui), volume = cf[r == p and "volfarm" or "volfarmnpc"], pitch = math.random(90,110)/100} end
			end
			local Mat		local hit = tes3.rayTest{position = r.position + V.up20, direction = V.down, maxDistance = 50, ignore = {r}}
			if hit then	local ref = hit.reference	local mob = ref and ref.mobile		if mob then Mat = ref.object.blood == 2 and "Metal" or "Dirt" else Mat = L.GetMat(hit) or "Dirt" end	end
			if r == p then if Mat then G.LastFloorMat = Mat else Mat = G.LastFloorMat end end
			tes3.playSound{reference = r, soundPath = L.RSound((Mat or "Dirt") .. L.FOOTS[sid]), volume = cf[r == p and "volfoot" or "volfootnpc"], pitch = math.random(90,110)/100}		e.block = true
		end
	elseif L.ARS[sid] then
		local dir = (G.ArSlot and "DmgArmor" or "DmgShield") .. L.ARS[sid]
		tes3.playSound{reference = r, soundPath = L.RSound(dir), volume = G.ArSlot and cf.volarm or cf.volimp, pitch = math.random(90,110)/100}		G.ArSlot = nil		e.block = true
	elseif sid == "Health Damage" then	local m = r.mobile
		if m then	local ob = r.object 	local dir, mat		local dmg = G.DmgR[r] or ""		G.DmgR[r] = nil
			if ob.objectType == tes3.objectType.creature then	local mt = L.CRNIF[ob.mesh:lower()]
				local at = mt and mt.at		if at then tes3.playSound{reference = r, soundPath = L.RSound("DmgArmor" .. at), volume = cf.volarm, pitch = math.random(90,110)/100} end
	
				if ob.type == tes3.creatureType.undead then
					if m.chameleon > 49 then dir = "DmgGhost"
					elseif ob.blood == 1 then dir = "DmgSkeleton" end
				elseif ob.blood == 2 then dir = "DmgDwemer"
				elseif mt then mat = mt.mat end
			end
			if not dir then dir = (L.DmgMat[dmg] and mat or "Dmg") .. dmg end
			tes3.playSound{reference = r, soundPath = L.RSound(dir), volume = cf.voldmg, pitch = math.random(90,110)/100}		e.block = true
		end
	elseif sid == "Weapon Swish" then	local m = r.mobile
		if m then
			local wt = m.readiedWeapon		wt = wt and wt.object.type or -1	
			tes3.playSound{reference = r, soundPath = L.RSound(WT[wt].sws), volume = cf.volsw, pitch = math.random(90,110)/100}		e.block = true
		end
	elseif L.SND[sid] then
		if L.SND[sid] == 0 then e.block = true
		else tes3.playSound{reference = r, soundPath = L.RSound(L.SND[sid][1]), volume = cf[L.SND[sid][2]], pitch = math.random(90,110)/100}	e.block = true end
	--else mwse.log("%s  %s", sid, r)		tes3.messageBox("%s  %s", sid, r)
	end
end end		if cf.newsnd then event.register("addSound", ADDSOUND) end

L.ITYP = {
[tes3.objectType.weapon] = "Weapon",
[tes3.objectType.ammunition] = "Weapon",
[tes3.objectType.armor] = "Armor",
[tes3.objectType.clothing] = "Clothing",
[tes3.objectType.book] = "Book",
[tes3.objectType.ingredient] = "Ingredient",
[tes3.objectType.alchemy] = "Potion",
[tes3.objectType.probe] = "Lockpick",
[tes3.objectType.lockpick] = "Lockpick",
[tes3.objectType.repairItem] = "Repair",
[tes3.objectType.apparatus] = "Misc",
[tes3.objectType.light] = "Misc",
[tes3.objectType.miscItem] = "Misc"}
L.JevSlot = {[8] = "Ring", [9] = "Amulet"}

local function PLAYITEMSOUND(e)	local ob = e.item	local typ = L.ITNIF[ob.mesh:lower()] or L.ITYP[ob.objectType]		local dir
	--tes3.messageBox("%s   ref = %s   state = %s   ot = %s   type = %s", ob.id, e.reference, e.state, ob.objectType, ob.type)
	if typ == "Weapon" then			dir = WT[ob.type].isnd .. (e.state == 0 and "0" or "1")
	elseif typ == "Armor" then		dir = ("Armor%s"):format(ob.weightClass)
	elseif typ == "Clothing" then	dir = L.JevSlot[ob.slot] or "Clothing"
	elseif typ == "Book" then		if ob.type == 1 then dir = "Scrolls" else dir = "Book" .. (e.state == 0 and "0" or "1") end 
	elseif typ then					dir = typ end
	if dir then tes3.playSound{reference = e.reference or p, soundPath = L.RSound(dir), volume = cf.volit, pitch = math.random(90,110)/100}		e.block = true end
end		if cf.newsnd then event.register("playItemSound", PLAYITEMSOUND) end


local function JOURNAL(e)
	tes3.playSound{reference = p, soundPath = L.RSound("Journal" .. (e.new and "New" or "Update")), volume = 1}
end		if cf.newsnd then event.register("journal", JOURNAL) end


local function MENUCONTENTS(e)	-- Если использовать uiActivated то даже через 1 фрейм звук произойдет в меню
	local m = e.menu:getPropertyObject("MenuContents_Actor")
	if m then local ob = m.object
		local dir = ob.blood == 2 and "ContDwemer" or "ContBody"
		tes3.playSound{reference = p, soundPath = L.RSound(dir .. "1"), volume = 1}
		timer.delayOneFrame(function() tes3.playSound{reference = p, soundPath = L.RSound(dir .. "2"), volume = cf.volcont} end)
	end
end		if cf.newsnd then event.register("menuEnter", MENUCONTENTS, {filter = "MenuContents"}) end


local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer
end		event.register("loaded", loaded)

local function initialized(e)	wc = tes3.worldController
G.VFXspark = tes3.createObject{objectType = tes3.objectType.static, id = "VFX_WSparks", mesh = "e\\spark.nif"}
end		event.register("initialized", initialized)