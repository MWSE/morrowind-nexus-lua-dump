--[[
	Mod Initialization: Battle Royale
	Author: mort / TNC
]]--

if (mwse.buildDate == nil or mwse.buildDate < 20181015 ) then
	mwse.log("[Battle Rite of Mephala] Build date of %s does not meet minimum build date of 201810015.", mwse.buildDate)
	return
end


--this is pointless now
local nc_itemlist = { nc_frostgore = true, nc_slavebracer = true, nc_chitin_greaves = true, nc_transport_rune = true, nc_slowfall_potion = true, NC_Ebony_Blade = true, nc_FryingPan = true, nc_Glass_Dagger_chip = true, nc_Glass_Dagger_improv = true, nc_PathSpear_1h = true, nc_PathSpear_2h = true, NC_PathSpear_cr1h = true, nc_PathSpear_cr2h = true, nc_Pitchfork_rust = true, nc_Shovel_Rust = true, nc_Shovel_Rust_broke = true, nc_TableLeg_Broke = true, NC_Shield_Barstool_shield = true }


--this is still useful
local nc_pacifistnpcs = { nc_combatant_19 = true, nc_combatant_7 = true }

local ncTimer
local combatantNumber = 20

local function checkTable(set, key)
	return set[key] ~= nil
end

local function addToTable(set, key)
	set[key] = true
end

local function equipBlocker(e)
	if ( string.sub(e.item.id, 1, 3) == "NC_" or string.sub(e.item.id, 1, 3) == "Nc_" or string.sub(e.item.id, 1, 3) == "nc_" ) then
		--do nothing
	elseif ( string.sub(e.item.id, 1, 5) == "expen" or string.sub(e.item.id, 1, 5) == "commo" or string.sub(e.item.id, 1, 5) == "exqui" or string.sub(e.item.id, 1, 5) == "extra" ) then
		---do nothing
	else
		tes3.messageBox({message = "The island's magic prevents foreign materials from being worn."})
		return false
	end
end

local function displayDestroy()
	local menu = tes3ui.findMenu(battleroyaleUI)
	if (menu) then
		menu:destroy()
	end
end

local function recentKillUIDestroy()
	local menu = tes3ui.findMenu(recentKillUI)
	if (menu) then
		menu:destroy()
	end
end

local function makeAIFight(fighttime)
	local activeCells = tes3.getActiveCells()
	local targetRange = 3000
	if fighttime % 5 == 0 then
		targetRange = 8000
	end
	if fighttime >= 24 then
		targetRange = 80000
	end
	for i, cell in pairs(activeCells) do
		for ref in cell:iterateReferences(tes3.objectType.npc) do
			if ( combatantNumber < 4 ) then
				mwscript.startCombat({reference = ref, target = tes3.getPlayerRef()})
				--print("BE AGGRESSIVE")
				break
			end
			if ( ref.mobile.fight >= 40 and ref.mobile.inCombat == false ) then
				local targetPlayer = math.random(4)
				if ( mwscript.getDistance({reference = ref, target = tes3.getPlayerRef()}) < targetRange and targetPlayer == 2 ) then
					mwscript.startCombat({reference = ref, target = tes3.getPlayerRef()})
					break
				else
					for ref2 in cell:iterateReferences(tes3.objectType.npc) do
						if ( mwscript.getDistance({reference = ref, target = ref2}) < targetRange and ref ~= ref2 ) then
							mwscript.startCombat({reference = ref, target = ref2})
							break
						end
					end
				end
			end
		end
	end
end

--the main function to create the menu
local function battleRoyaleUIDisplay(e)
	displayDestroy()
	recentKillUIDestroy()
	
	local battleroyaleUI = tes3ui.createMenu{id = battleroyaleUI, fixedFrame = true}
	battleroyaleUI.alpha = 1.0
	battleroyaleUI.layoutOriginFractionX = 1
	battleroyaleUI.layoutOriginFractionY = 0
	
	combatantNumber = combatantNumber - 1

	local remainingText = combatantNumber .. " players remaining"
	local remainingLabel = battleroyaleUI:createLabel{text = remainingText}
	
	
	local recentKillUI = tes3ui.createMenu{id = recentKillUI, fixedFrame = true}
	recentKillUI.alpha = 1.0
	recentKillUI.layoutOriginFractionX = 1
	recentKillUI.layoutOriginFractionY = 0.035
	
	local recentkillUItext = e.reference.object.name .. " was killed."
	local recentKillLabel = recentKillUI:createLabel{text = recentkillUItext}

end

local function endRoyale()
	event.unregister("equip", equipBlocker)
	event.unregister("death", battleRoyaleUIDisplay)
	displayDestroy()
	recentKillUIDestroy()
	ncTimer:cancel()
	--tes3.messageBox({message = "endroyale"})

	--event.unregister("menuEnter", menuOpened)
	--event.unregister("menuExit", menuClosed)
	tes3.setGlobal("nc_g_inroyale", 0)
	mwscript.stopScript({script = "nc_end_royale_scr"})
end

local function createRoyaleUI()
	local battleroyaleUI = tes3ui.createMenu{id = battleroyaleUI, fixedFrame = true}
	battleroyaleUI.alpha = 1.0
	battleroyaleUI.layoutOriginFractionX = 1
	battleroyaleUI.layoutOriginFractionY = 0

	local remainingText = combatantNumber .. " players remaining"
	local remainingLabel = battleroyaleUI:createLabel{text = remainingText}
	
	local recentKillUI = tes3ui.createMenu{id = recentKillUI, fixedFrame = true}
	recentKillUI.alpha = 1.0
	recentKillUI.layoutOriginFractionX = 1
	recentKillUI.layoutOriginFractionY = 0.035
	
	local recentkillUItext = "Become my Champion"
	local recentKillLabel = recentKillUI:createLabel{text = recentkillUItext}
	
end

local function menuOpened()
	displayDestroy()
	recentKillUIDestroy()
end

local function menuClosed()
	if tes3.getGlobal("nc_g_inroyale") == 1 then
		createRoyaleUI()
	end
end

local function onTimerComplete()
	local fighttime = 1
	makeAIFight(fighttime)
	fighttime = fighttime + 1
end

local function battleStart()
	local doOnce = 0
	if (doOnce == 0) then
		tes3.setGlobal("nc_g_inroyale", 1)
		tes3.mobilePlayer:unequip{type = tes3.objectType.armor}
		tes3.mobilePlayer:unequip{type = tes3.objectType.clothing}
		tes3.mobilePlayer:unequip{type = tes3.objectType.weapon}
		
		
		mwscript.addItem({ reference = tes3.getPlayerRef(), item = "nc_slavebracer", count = 1 })
		mwscript.addItem({ reference = tes3.getPlayerRef(), item = "nc_common_pants_02", count = 1 })
		mwscript.addItem({ reference = tes3.getPlayerRef(), item = "nc_common_shirt_01", count = 1 })
		
		mwscript.equip({reference = tes3.getPlayerRef(), item = "nc_slavebracer" })
		mwscript.equip({reference = tes3.getPlayerRef(), item = "nc_common_pants_02" })
		mwscript.equip({reference = tes3.getPlayerRef(), item = "nc_common_shirt_01" })
		tes3.messageBox({message = "Your retinas sear as text materializes inside your eyes."})
		tes3.messageBox({message = "You notice a note at your feet."})
		
		ncTimer = timer.start({ duration = 5, callback = onTimerComplete, iterations = -1 })
		
		event.register("death", battleRoyaleUIDisplay)
		battleroyaleUI = tes3ui.registerID("mort:battleroyaleUI")
		recentKillUI = tes3ui.registerID("mort:recentKillUI")
		event.register("menuEnter", menuOpened)
		event.register("menuExit", menuClosed)
		event.register("equip", equipBlocker)
		createRoyaleUI()
		
		doOnce = 1
	end
	mwscript.stopScript({script = "nc_battle_start_scr"})
end

local function loadedBattleStart()
	local doOnce = 0
	if (doOnce == 0) then
		
		ncTimer = timer.start({ duration = 5, callback = onTimerComplete, iterations = -1 })
		
		event.register("death", battleRoyaleUIDisplay)
		battleroyaleUI = tes3ui.registerID("mort:battleroyaleUI")
		recentKillUI = tes3ui.registerID("mort:recentKillUI")
		event.register("menuEnter", menuOpened)
		event.register("menuExit", menuClosed)
		event.register("equip", equipBlocker)
		createRoyaleUI()
		
		doOnce = 1
	end
	mwscript.stopScript({script = "nc_battle_start_scr"})
end

local function ebonyBladeScr()
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.npc) do
    if mwscript.onMurder({reference = ref}) then
		if tes3.mobilePlayer.readiedWeapon.object.id == "NC_Ebony_Blade" then
			if tes3.mobilePlayer.readiedWeapon.object.slashMax < 200 then
				--print(tes3.mobilePlayer.readiedWeapon.object.slashMax)
				tes3.mobilePlayer.readiedWeapon.object.slashMax = tes3.mobilePlayer.readiedWeapon.object.slashMax + 1
				tes3.mobilePlayer.readiedWeapon.object.slashMin = tes3.mobilePlayer.readiedWeapon.object.slashMin + 1
				tes3.mobilePlayer.readiedWeapon.object.chopMax = tes3.mobilePlayer.readiedWeapon.object.chopMax + 1
				tes3.mobilePlayer.readiedWeapon.object.chopMin = tes3.mobilePlayer.readiedWeapon.object.chopMin + 1
				tes3.mobilePlayer.readiedWeapon.object.thrustMax = tes3.mobilePlayer.readiedWeapon.object.thrustMax + 1
				tes3.mobilePlayer.readiedWeapon.object.thrustMin = tes3.mobilePlayer.readiedWeapon.object.thrustMin + 1
				--print(tes3.mobilePlayer.readiedWeapon.object.slashMax)
				tes3.messageBox("The Ebony Blade accepts your sacrifice.")
			end
		end
    end
end

end

local function nc_loaded()

	if tes3.getGlobal("nc_g_inroyale") == 1 then
		combatantNumber = tes3.getGlobal("nc_g_combatants_remaining")
		loadedBattleStart()
	end
end

local function initialize()
	if (mwse.buildDate == nil or mwse.buildDate < 20181015) then
		tes3.messageBox("Battle Rite of Mephala requires a newer version of MWSE. Please run MWSE-Update.exe.", mwse.buildDate)
		return
	end

	event.register("loaded", nc_loaded)
	
	mwse.overrideScript("nc_ebony_blade_scr", ebonyBladeScr)
	mwse.overrideScript("nc_battle_start_scr", battleStart)
	mwse.overrideScript("nc_end_royale_scr", endRoyale)

end

event.register("initialized", initialize)
