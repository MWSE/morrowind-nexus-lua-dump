local mod = {
    name = "Exploration Tools",
    config = "ExplorationToolsConfig",
    ver = "1.0",
    author = "TribalLu",
            }
local configDefault = {
	enabled = true,
	hotkey = tes3.scanCode.c,
	hotkey2 = tes3.scanCode.y,
	hotkey3 = tes3.scanCode.o,
	hotkey4 = 74,
	RebmessageonOFF = true, 
	RebhelmetonOFF = true,
	icononOFF = false,
	iconslider = 5, 
	iconsliderpercent = 865, 
	iconXwidth = 35, 
	iconXheight = 35, 
	climbsoundoption = true, 
	resolutionHor = 1920, 
	resolutionVer = 1080,
	climbreqtool = true,
	cfoption = true,
	cspoption = true, 
	cfdspeed = 3, 
	csdebuff = 2, 
	Rebequipunderwater = true, 
}

local config = mwse.loadConfig(mod.config, configDefault)

if not config then
    config = { blocked = {} }
end

local ids = {
    RebBlock = tes3ui.registerID("Reb:Block"),
    RebImage = tes3ui.registerID("Reb:Image"),
}

local keybindButton
local keybindButton2
local keybindButton3
local keybindButton4
local enableButton
local RebmessageonoffButton
local RebonoffButton
local ClimbtoolonoffButton
local ClimbsoundonoffButton
local ClimbfonoffButton
local ClimbsponoffButton
local RebequipunderwaterButton

local climbsound = "tribs/climbsound_01.wav"
local airbsound = "tribs/airbsound_01.wav"
local splashsound = "tribs/splashsound_01.wav"

local checkReb = 0
local inicPOS = 0
local getPOSx = 0
local getPOSy = 0
local getPOSz = 0
local getPOSzs = 0
local newPOSx = 0
local newPOSy = 0
local newPOSz = 0
local newPOSzs = 0
local inicEX = 0
local inicEXE = 0
local inicF = 0
local iniAB = 0
local iniABS = 0
local currentZ = 0
local climbani = 0
local currentsp = 0
local cfrate = 0
local csrate = 0
local currentfatigue = 0

local function myClimbCallback(e)
	if ( config.climbreqtool == true ) then 
		local count = tes3.getItemCount({ reference = tes3.mobilePlayer, item = "trib_rope_01" })
		if ( count > 0 ) then
			if tes3.mobilePlayer.isFalling == false then
				tes3.addSpell({ reference = tes3.player, spell = "trib_climb_01" })
			end
			climbextraTimer:reset()
			climbextraTimer:resume()
			climbFatigueTimer:resume()
		else 
			tes3.messageBox("You don't have climbing gear.")
		end
		if ( config.cspoption == true ) then
			currentsp = tes3.mobilePlayer.speed.current
			tes3.mobilePlayer.speed.current = tes3.mobilePlayer.speed.current - csrate
		end 
	else
		if tes3.mobilePlayer.isFalling == false then
			tes3.addSpell({ reference = tes3.player, spell = "trib_climb_01" })
		end 
		if ( config.cspoption == true ) then
			currentsp = tes3.mobilePlayer.speed.current
			tes3.mobilePlayer.speed.current = tes3.mobilePlayer.speed.current - csrate
		end
		climbextraTimer:reset()
		climbextraTimer:resume()
		climbFatigueTimer:resume()
	end
	
	getPOSx = tes3.mobilePlayer.position.x
	getPOSy = tes3.mobilePlayer.position.y
	getPOSz = tes3.mobilePlayer.position.z
	getPOSzs = tes3.mobilePlayer.position.z
	checkPOSTimer:reset()
	checkPOSTimer:resume()
	currentfatigue = tes3.mobilePlayer.fatigue.current

end

local function undoClimbCallback(e)
	climbextraTimer:pause()
	climbextraEndTimer:pause()
	tes3.playAnimation({ reference = tes3.player })
	tes3.playAnimation({ reference = tes3.player1stPerson })
	tes3.removeSpell({ reference = tes3.player, spell = "trib_climb_01" })
	if ( config.cspoption == true ) then
		tes3.mobilePlayer.speed.current = currentsp
	end
	climbFatigueTimer:pause()
	checkPOSTimer:pause()
end

local function checkPOSActive()
	newPOSx = tes3.mobilePlayer.position.x
	newPOSy = tes3.mobilePlayer.position.y
	newPOSz = tes3.mobilePlayer.position.z
	newPOSzs = tes3.mobilePlayer.position.z

	if newPOSz > math.floor(getPOSz + 60) or newPOSz < math.floor(getPOSz - 60) then
	if newPOSx > math.floor(getPOSx + 30) or newPOSx < math.floor(getPOSx - 30) then
		tes3.playAnimation({ reference = tes3.player })
		tes3.playAnimation({ reference = tes3.player1stPerson })
		tes3.removeSpell({ reference = tes3.player, spell = "trib_climb_01" })
		if ( config.cspoption == true ) then
			tes3.mobilePlayer.speed.current = currentsp
		end
		climbFatigueTimer:pause()
		checkPOSTimer:pause()
		climbextraTimer:pause()
		climbextraEndTimer:pause()
	end
	end
	if newPOSx > math.floor(getPOSx + 45) or newPOSx < math.floor(getPOSx - 45) then
		tes3.playAnimation({ reference = tes3.player })
		tes3.playAnimation({ reference = tes3.player1stPerson })
		tes3.removeSpell({ reference = tes3.player, spell = "trib_climb_01" })
		if ( config.cspoption == true ) then
			tes3.mobilePlayer.speed.current = currentsp
		end
		climbFatigueTimer:pause()
		checkPOSTimer:pause()
		climbextraTimer:pause()
		climbextraEndTimer:pause()
	end
	if newPOSz > math.floor(getPOSz + 60) or newPOSz < math.floor(getPOSz - 60) then
	if newPOSy > math.floor(getPOSy + 30) or newPOSy < math.floor(getPOSy - 30) then
		tes3.playAnimation({ reference = tes3.player })
		tes3.playAnimation({ reference = tes3.player1stPerson })
		tes3.removeSpell({ reference = tes3.player, spell = "trib_climb_01" })
		if ( config.cspoption == true ) then
			tes3.mobilePlayer.speed.current = currentsp
		end
		climbFatigueTimer:pause()
		checkPOSTimer:pause()
		climbextraTimer:pause()
		climbextraEndTimer:pause()
	end
	end
	if newPOSy > math.floor(getPOSy + 45) or newPOSy < math.floor(getPOSy - 45) then
		tes3.playAnimation({ reference = tes3.player })
		tes3.playAnimation({ reference = tes3.player1stPerson })
		tes3.removeSpell({ reference = tes3.player, spell = "trib_climb_01" })
		if ( config.cspoption == true ) then
			tes3.mobilePlayer.speed.current = currentsp
		end
		climbFatigueTimer:pause()
		checkPOSTimer:pause()
		climbextraTimer:pause()
		climbextraEndTimer:pause()
	end
	if newPOSzs > math.floor(getPOSzs + 60) or newPOSzs < math.floor(getPOSzs - 60) then
		if ( config.climbsoundoption == true ) then
			tes3.playSound({ soundPath = climbsound, volume = 0.8 })
			getPOSzs = tes3.mobilePlayer.position.z
		end
	end
	if tes3.mobilePlayer.fatigue.current <= 0 then
		tes3.playAnimation({ reference = tes3.player })
		tes3.playAnimation({ reference = tes3.player1stPerson })
		tes3.removeSpell({ reference = tes3.player, spell = "trib_climb_01" })
		if ( config.cspoption == true ) then
			tes3.mobilePlayer.speed.current = currentsp
		end
		climbFatigueTimer:pause()
		checkPOSTimer:pause()
		climbextraTimer:pause()
		climbextraEndTimer:pause()
	end
	if tes3.mobilePlayer.isMovingForward then
		climbFatigueTimer:resume()
		currentfatigue = tes3.mobilePlayer.fatigue.current
	else
		climbFatigueTimer:pause()
		tes3.mobilePlayer.fatigue.current = currentfatigue
	end
end

local function climbextraActive()
	climbextraTimer:pause()
	climbextraEndTimer:reset()
	climbextraEndTimer:resume()
	if tes3.mobilePlayer.isMovingForward then
		if climbani == 0 then
		tes3.playAnimation({ reference = tes3.player, upper = tes3.animationGroup.idleSpell, shield = tes3.animationGroup.idle1h })
		tes3.playAnimation({ reference = tes3.player1stPerson, upper = tes3.animationGroup.idleSpell, shield = tes3.animationGroup.idle1h })
		climbani = 1
		else
		tes3.playAnimation({ reference = tes3.player, upper = tes3.animationGroup.idle1h, shield = tes3.animationGroup.idleSpell })
		tes3.playAnimation({ reference = tes3.player1stPerson, upper = tes3.animationGroup.idleStorm, shield = tes3.animationGroup.idleSpell })
		climbani = 0
		end
	end
end

local function climbextraEnd()
	climbextraEndTimer:pause()
	climbextraTimer:reset()
	climbextraTimer:resume()
	tes3.playAnimation({ reference = tes3.player })
	tes3.playAnimation({ reference = tes3.player1stPerson })
end

local function climbfatigue()
	if ( config.cfoption == true ) then 
		if tes3.mobilePlayer.isMovingForward then
			tes3.mobilePlayer.fatigue.current = tes3.mobilePlayer.fatigue.current - cfrate
		end
	else end	
end

local function myPathmCallback(e)
	local replaceMarker = tes3.getItemCount({ reference = tes3.mobilePlayer, item = "trib_pathmarker_02" })
	if ( replaceMarker > 0 ) then 
		tes3.removeItem({ reference = tes3.player, item = "trib_pathmarker_02", count = replaceMarker })
		tes3.addItem({ reference = tes3.player, item = "trib_pathmarker_01", count = replaceMarker })
	end
	local count = tes3.getItemCount({ reference = tes3.mobilePlayer, item = "trib_pathmarker_01" })
	local count2 = tes3.getItemCount({ reference = tes3.mobilePlayer, item = "trib_flint_01" })
	local count3 = tes3.getItemCount({ reference = tes3.mobilePlayer, item = "AB_Misc_FlintAndSteel" })
	local count4 = tes3.getItemCount({ reference = tes3.mobilePlayer, item = "T_Com_FlintAndSteel_01" })
	if ( count > 0 ) then
		tes3.playAnimation({ reference = tes3.player, group = tes3.animationGroup.pickProbe, })
		tes3.playAnimation({ reference = tes3.player1stPerson, upper = tes3.animationState.pickingProbing, shield = tes3.animationGroup.pickProbe, })
		if tes3.mobilePlayer.underwater == false then
			if ( count2 > 0 or count3 > 0 or count4 > 0 ) then
				tes3.removeItem({ reference = tes3.player, item = "trib_pathmarker_01" })
				tes3.addItem({ reference = tes3.player, item = "trib_pathmarker_02" })
				tes3.dropItem({ reference = tes3.player, item = "trib_pathmarker_02" })
			else
				tes3.dropItem({ reference = tes3.player, item = "trib_pathmarker_01" })
			end
		else
			tes3.dropItem({ reference = tes3.player, item = "trib_pathmarker_01" })
		end
	else
		tes3.messageBox("You need path markers.")
	end
end

local function undoPathmCallback(e)
	tes3.playAnimation({ reference = tes3.player })
	tes3.playAnimation({ reference = tes3.player1stPerson })
end

local function myRebreCallback(e)
	local count = tes3.getItemCount({ reference = tes3.mobilePlayer, item = "trib_rebreather_01" })
	local checkActiveSpell = tes3.isAffectedBy({ reference = tes3.mobilePlayer, effect = tes3.effect.waterBreathing })
	if ( count > 0 ) then
		if config.Rebequipunderwater == true then
			if tes3.mobilePlayer.underwater == false then
				if ( checkReb == 0 ) then 
					if checkActiveSpell == true then
						tes3.messageBox("Wait till current Spell wears off.")
					else
						tes3.mobilePlayer.waterBreathing = 1
						if ( config.RebmessageonOFF ) then
							tes3.messageBox("You equip your Rebreather.")
						else end
						if ( config.RebhelmetonOFF ) then
							local rebcount = tes3.getItemCount({ reference = tes3.mobilePlayer, item = "trib_rebhelmet_01" })
							if rebcount > 0 then
								tes3.mobilePlayer:equip({ item = "trib_rebhelmet_01" })
							else
								tes3.mobilePlayer:equip({ item = "trib_rebhelmet_01", addItem = true })
							end
						else end 
						checkReb = 1
						config.icononOFF = true
						local block = menuMultiRebFillbarsBlock:findChild(ids.RebBlock)
						if block then	
							block.visible = config.icononOFF
							menuMultiRebFillbarsBlock:updateLayout()
						end
					end
				else
					if checkActiveSpell == true then
						tes3.messageBox("Wait till current Spell wears off.")
					else
						tes3.mobilePlayer.waterBreathing = 0
						if ( config.RebmessageonOFF ) then
							tes3.messageBox("You unequip your Rebreather.")
						else end
						if ( config.RebhelmetonOFF ) then
							tes3.removeItem({ reference = tes3.player, item = "trib_rebhelmet_01", count = 99 })
						else end 
						checkReb = 0
						config.icononOFF = false
						local block = menuMultiRebFillbarsBlock:findChild(ids.RebBlock)
						if block then	
							block.visible = config.icononOFF
							menuMultiRebFillbarsBlock:updateLayout()
						end
					end
				end
			else
				tes3.messageBox("You can't equip the Rebreather underwater.")
			end
		else
			if ( checkReb == 0 ) then 
				if checkActiveSpell == true then
					tes3.messageBox("Wait till current Spell wears off.")
				else
					tes3.mobilePlayer.waterBreathing = 1
					if ( config.RebmessageonOFF ) then
						tes3.messageBox("You equip your Rebreather.")
					else end
					if ( config.RebhelmetonOFF ) then
						local rebcount = tes3.getItemCount({ reference = tes3.mobilePlayer, item = "trib_rebhelmet_01" })
						if rebcount > 0 then
							tes3.mobilePlayer:equip({ item = "trib_rebhelmet_01" })
						else
							tes3.mobilePlayer:equip({ item = "trib_rebhelmet_01", addItem = true })
						end
					else end 
					checkReb = 1
					config.icononOFF = true
					local block = menuMultiRebFillbarsBlock:findChild(ids.RebBlock)
					if block then	
						block.visible = config.icononOFF
						menuMultiRebFillbarsBlock:updateLayout()
					end
				end
			else
				if checkActiveSpell == true then
					tes3.messageBox("Wait till current Spell wears off.")
				else
					tes3.mobilePlayer.waterBreathing = 0
					if ( config.RebmessageonOFF ) then
						tes3.messageBox("You unequip your Rebreather.")
					else end
					if ( config.RebhelmetonOFF ) then
						tes3.removeItem({ reference = tes3.player, item = "trib_rebhelmet_01", count = 99 })
					else end 
					checkReb = 0
					config.icononOFF = false
					local block = menuMultiRebFillbarsBlock:findChild(ids.RebBlock)
					if block then	
						block.visible = config.icononOFF
						menuMultiRebFillbarsBlock:updateLayout()
					end
				end
			end
		end
	else
		tes3.messageBox("You don't have a Rebreather.")
	end
end

local function myAirBCallback(e)
	local count = tes3.getItemCount({ reference = tes3.mobilePlayer, item = "trib_airbladder_01" })
	if ( count > 0 ) then
		if tes3.mobilePlayer.underwater == true then
			if tes3.mobilePlayer.cell.isInterior == false then
				tes3.playAnimation({ reference = tes3.player, upper = tes3.animationGroup.idleStorm, shield = tes3.animationGroup.idle1h })
				tes3.playAnimation({ reference = tes3.player1stPerson, upper = tes3.animationGroup.idleStorm, shield = tes3.animationGroup.idle1h })
				airBladderTimer:resume()
				tes3.playSound({ soundPath = airbsound, volume = 0.8, loop = true })
			else
				tes3.messageBox("It is unsafe to use here.")
			end
		end
	else
		tes3.messageBox("You don't have an Air Bladder.")
	end
end

local function undoAirBCallback(e)
	tes3.playAnimation({ reference = tes3.player })
	tes3.playAnimation({ reference = tes3.player1stPerson })
	airBladderTimer:pause()
	if tes3.mobilePlayer.underwater == true then
		tes3.removeSound({ soundPath = airbsound })
	end
end

local function airbladderUse()
	tes3.mobilePlayer.position.z = tes3.mobilePlayer.position.z + 1
	if tes3.mobilePlayer.underwater == false then
		currentZ = tes3.mobilePlayer.position.z
		tes3.playAnimation({ reference = tes3.player })
		tes3.playAnimation({ reference = tes3.player1stPerson })
		airBladderTimer:pause()
		airBladderSplashTimer:reset()
		airBladderSplashTimer:resume()
		tes3.removeSound({ soundPath = airbsound })
	end
end

local function airbladderSplash()
	tes3.mobilePlayer.position.z = math.floor(currentZ + 25)
	tes3.playSound({ soundPath = splashsound, volume = 0.8 })
end

local function assignHotkey(e)
	event.unregister(tes3.event.keyDown, myClimbCallback, { filter = config.hotkey } )
	event.unregister(tes3.event.keyUp, undoClimbCallback, { filter = config.hotkey } )
	config.hotkey = e.keyCode
	
	if ( config.enabled ) then
		event.register(tes3.event.keyDown, myClimbCallback, { filter = config.hotkey } )
		event.register(tes3.event.keyUp, undoClimbCallback, { filter = config.hotkey } )
	end
	local buttonName = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value
	tes3.messageBox('Climb hotkey is now "%s"', buttonName);
	keybindButton.buttonText = buttonName
	event.unregister(tes3.event.keyDown, assignHotkey)
	keybindButton:setText(buttonName)
end

local function assignHotkey2(e)
	event.unregister(tes3.event.keyDown, myPathmCallback, { filter = config.hotkey2 } )
	event.unregister(tes3.event.keyUp, undoPathmCallback, { filter = config.hotkey2 } )
	config.hotkey2 = e.keyCode
	
	if ( config.enabled ) then
		event.register(tes3.event.keyDown, myPathmCallback, { filter = config.hotkey2 } )
		event.register(tes3.event.keyUp, undoPathmCallback, { filter = config.hotkey2 } )
	end
	local buttonName = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey2).value
	tes3.messageBox('Pathfinder hotkey is now "%s"', buttonName);
	keybindButton2.buttonText = buttonName
	event.unregister(tes3.event.keyDown, assignHotkey2)
	keybindButton2:setText(buttonName)
end

local function assignHotkey3(e)
	event.unregister(tes3.event.keyDown, myRebreCallback, { filter = config.hotkey3 } )
	config.hotkey3 = e.keyCode
	
	if ( config.enabled ) then
		event.register(tes3.event.keyDown, myRebreCallback, { filter = config.hotkey3 } )
	end
	local buttonName = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey3).value
	tes3.messageBox('Rebreather hotkey is now "%s"', buttonName);
	keybindButton3.buttonText = buttonName
	event.unregister(tes3.event.keyDown, assignHotkey3)
	keybindButton3:setText(buttonName)
end

local function assignHotkey4(e)
	event.unregister(tes3.event.keyDown, myAirBCallback, { filter = config.hotkey4 } )
	event.unregister(tes3.event.keyUp, undoAirBCallback, { filter = config.hotkey4 } )
	config.hotkey4 = e.keyCode
	
	if ( config.enabled ) then
		event.register(tes3.event.keyDown, myAirBCallback, { filter = config.hotkey4 } )
		event.register(tes3.event.keyUp, undoAirBCallback, { filter = config.hotkey4 } )
	end
	local buttonName = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey4).value
	tes3.messageBox('Air Bladder hotkey is now "%s"', buttonName);
	keybindButton4.buttonText = buttonName
	event.unregister(tes3.event.keyDown, assignHotkey4)
	keybindButton4:setText(buttonName)
end

local function startcheckPOSTimer()
	checkPOSTimer = timer.start({ duration = 0.01, iterations = -1, type = timer.real, callback = checkPOSActive})
	if inicPOS == 0 then checkPOSTimer:pause() end
end

local function startclimbextraTimer()
	climbextraTimer = timer.start({ duration = 0.25, iterations = -1, type = timer.real, callback = climbextraActive})
	if inicEX == 0 then climbextraTimer:pause() end
end

local function startclimbextraEndTimer()
	climbextraEndTimer = timer.start({ duration = 0.35, iterations = -1, type = timer.real, callback = climbextraEnd})
	if inicEXE == 0 then climbextraEndTimer:pause() end
end

local function startclimbFatigueTimer()
	climbFatigueTimer = timer.start({ duration = 0.08, iterations = -1, type = timer.real, callback = climbfatigue})
	if inicF == 0 then climbFatigueTimer:pause() end
end

local function startairBladderTimer()
	airBladderTimer = timer.start({ duration = 0.005, iterations = -1, type = timer.real, callback = airbladderUse})
	if iniAB == 0 then airBladderTimer:pause() end
end

local function startairBladderSplashTimer()
	airBladderSplashTimer = timer.start({ duration = 0.005, iterations = 1, type = timer.real, callback = airbladderSplash})
	if iniABS == 0 then airBladderSplashTimer:pause() end
end

local function initialized()

		if ( config.enabled) then
			event.register(tes3.event.keyDown, myClimbCallback, { filter = config.hotkey } )
			event.register(tes3.event.keyUp, undoClimbCallback, { filter = config.hotkey } )
			event.register(tes3.event.keyDown, myPathmCallback, { filter = config.hotkey2 } )
			event.register(tes3.event.keyUp, undoPathmCallback, { filter = config.hotkey2 } )
			event.register(tes3.event.keyDown, myRebreCallback, { filter = config.hotkey3 } )
			event.register(tes3.event.keyDown, myAirBCallback, { filter = config.hotkey4 } )
			event.register(tes3.event.keyUp, undoAirBCallback, { filter = config.hotkey4 } )
			event.register(tes3.event.loaded, startcheckPOSTimer)
			event.register(tes3.event.loaded, startclimbextraTimer)
			event.register(tes3.event.loaded, startclimbextraEndTimer)
			event.register(tes3.event.loaded, startclimbFatigueTimer)
			event.register(tes3.event.loaded, startairBladderTimer)
			event.register(tes3.event.loaded, startairBladderSplashTimer)
		end
		
		config.icononOFF = false
		local block = menuMultiRebFillbarsBlock:findChild(ids.RebBlock)
		if block then	
		block.visible = config.icononOFF
		menuMultiRebFillbarsBlock:updateLayout()
		end
	
	print("[Exploration Tools] Exploration Tools Initialized")
end

event.register(tes3.event.initialized, initialized)

local function createRebFillbar(element)
    local block = element:createRect({ id = ids.RebBlock, color = {0.0, 0.0, 0.0} })
    block.ignoreLayoutX = true
    block.ignoreLayoutY = true
    block.width = config.iconXwidth
    block.height = config.iconXheight
    block.borderAllSides = 2
    block.alpha = 0.8
    block.positionX = config.iconslider
    block.positionY = -config.iconsliderpercent
    block.visible = config.icononOFF
	
		local RebImagePath = "icons\\tribm\\rebreather."
		local path = lfs.fileexists(RebImagePath .. "dds") and RebImagePath .. "dds" or RebImagePath .. "tga"
        local Rebimage = block:createImage({id = ids.RebImage, path = path })
        Rebimage.width = config.iconXwidth
        Rebimage.height = config.iconXheight

    element:updateLayout()

    return
end

local function createMenuMultiRebFillbar(e)
	if not e.newlyCreated then return end

	menuMultiRebFillbarsBlock = e.element:findChild(tes3ui.registerID("MenuMulti_icons_layout"))
	menuRebBar = createRebFillbar(menuMultiRebFillbarsBlock)
end
event.register("uiActivated", createMenuMultiRebFillbar, { filter = "MenuMulti" })

local function refreshRebFillbarCustomization()
        local block = menuMultiRebFillbarsBlock:findChild(ids.RebBlock)
        if block then
			block:destroy()
			menuMultiRebFillbarsBlock:updateLayout()
        end
	createRebFillbar(menuMultiRebFillbarsBlock)
end

local function updateRebFillbarCustomization()
        local block = menuMultiRebFillbarsBlock:findChild(ids.RebBlock)
        if block then	
		block.width = config.iconXwidth
		block.height = config.iconXheight
		block.positionX = config.iconslider
		block.positionY = -config.iconsliderpercent
		block.visible = config.icononOFF
		local Rebimage = menuMultiFillbarsBlock:findChild(ids.RebImage)
		if Rebimage then
		Rebimage.width = config.iconXwidth
		Rebimage.height = config.iconXheight
		end
	    menuMultiRebFillbarsBlock:updateLayout()
        end
end

local function updateClimbFatigueDrainSpeed()
	if config.cfdspeed == 1 then 
		cfrate = 1
	end
	if config.cfdspeed == 2 then 
		cfrate = 0.8
	end
	if config.cfdspeed == 3 then 
		cfrate = 0.6
	end
	if config.cfdspeed == 4 then 
		cfrate = 0.4
	end
	if config.cfdspeed == 5 then 
		cfrate = 0.2
	end
end
event.register(tes3.event.loaded, updateClimbFatigueDrainSpeed)

local function updateClimbSpeedDebuff()
	if config.csdebuff == 1 then 
		csrate = 15
	end
	if config.csdebuff == 2 then 
		csrate = 30
	end
	if config.csdebuff == 3 then 
		csrate = 45
	end
end
event.register(tes3.event.loaded, updateClimbSpeedDebuff)

local function getButtonText(featureString, bool)
	local s
	
	if ( bool ) then
		s = featureString .. " Enabled"
	else
		s = featureString .. " Disabled"
	end
	
	return s
end

local function changeResolutionHor()
	if config.resolutionHor == 3840 then
		tes3.messageBox("Horizontal set to 4k. Restart Required.")
	elseif config.resolutionHor == 1920 then
		tes3.messageBox("Horizontal set to 1080p. Restart Required.")
	end
end

local function changeResolutionVer()
	if config.resolutionVer == 2160 then
		tes3.messageBox("Vertical set to 4k. Restart Required.")
	elseif config.resolutionVer == 1080 then
		tes3.messageBox("Vertical set to 1080p. Restart Required.")
	end
end

local function registerModConfig()
    local mcm = mwse.mcm
    local template = mcm.createTemplate(mod.name)
    template:saveOnClose(mod.config, config)

--Page1
    local page = template:createPage({label=mod.name})

	local category0 = page:createCategory("Welcome to \""..mod.name.."\" Configuration Menu.")

    enableButton = category0:createButton({
	
        buttonText = getButtonText("Mod", config.enabled),
        callback = function(self)
            config.enabled = not config.enabled
			event.unregister(tes3.event.keyDown, myClimbCallback, { filter = config.hotkey } )
			event.unregister(tes3.event.keyUp, undoClimbCallback, { filter = config.hotkey } )
			event.unregister(tes3.event.keyDown, myPathmCallback, { filter = config.hotkey2 } )
			event.unregister(tes3.event.keyUp, undoPathmCallback, { filter = config.hotkey2 } )
			event.unregister(tes3.event.keyDown, myRebreCallback, { filter = config.hotkey3 } )
			event.unregister(tes3.event.keyDown, myAirBCallback, { filter = config.hotkey4 } )
			event.unregister(tes3.event.keyUp, undoAirBCallback, { filter = config.hotkey4 } )
			if ( config.enabled ) then
				event.register(tes3.event.keyDown, myClimbCallback, { filter = config.hotkey } )
				event.register(tes3.event.keyUp, undoClimbCallback, { filter = config.hotkey } )
				event.register(tes3.event.keyDown, myPathmCallback, { filter = config.hotkey2 } )
				event.register(tes3.event.keyUp, undoPathmCallback, { filter = config.hotkey2 } )
				event.register(tes3.event.keyDown, myRebreCallback, { filter = config.hotkey3 } )
				event.register(tes3.event.keyDown, myAirBCallback, { filter = config.hotkey4 } )
				event.register(tes3.event.keyUp, undoAirBCallback, { filter = config.hotkey4 } )
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
			else
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
			end
        end
    })
	
	local subcat = page:createCategory("This mod adds in five new tools that allow you to enhance your exploring experience. \n ")

	local subcat = page:createCategory("Climbing Gear: Ability to Climb \n Hold the keybind button and move in the direction you want to climb. \n  Note: You will fall if you run out of stamina or let go of the keybind. \n ")
	
	local subcat = page:createCategory("Pathmarkers: Places physical marker \n Press the keybind, it will drop a marker if available. Pick them back up to use them again later. \n  Note: If you have Flint and Steel then the marker will be lit. \n ")
	
	local subcat = page:createCategory("Rebreather: Ability to Breathe Underwater \n Press the keybind to equip it and again to unequip it. \n ")
	
	local subcat = page:createCategory("Airbladder: Rise to surface of water quickly \n Press the keybind, you will shoot up in the water until you let go. \n ")

	local subcat = page:createCategory("See more settings on the next Page. \n ")
	
	local subcat = page:createCategory("On the next page you can change the Location of the Rebreather HUD Icon. \n Note: If your changes didn't take affect, Press the Refresh button.")

	local subcat = page:createCategory(" Refresh")
    subcat:createButton{label = "Click to Refresh", callback = refreshRebFillbarCustomization, buttonText = "Refresh"}

--Page2
	local page0 = template:createSideBarPage({label="Settings"})

	local category0 = page0:createCategory("Keybind Options")
	
	keybindButton = category0:createButton({
	
	label = "Climbing Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value;
        callback = function(self)
			tes3.messageBox("Press a free key.")
            event.register(tes3.event.keyDown, assignHotkey)
        end
    })
	
	keybindButton2 = category0:createButton({
	
	label = "Pathmarker Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey2).value;
        callback = function(self)
			tes3.messageBox("Press a free key.")
            event.register(tes3.event.keyDown, assignHotkey2)
        end
    })
	
	keybindButton3 = category0:createButton({
	
	label = "Rebreather Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey3).value;
        callback = function(self)
			tes3.messageBox("Press a free key.")
            event.register(tes3.event.keyDown, assignHotkey3)
        end
    })

	keybindButton4 = category0:createButton({
	
	label = "Air Bladder Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey4).value;
        callback = function(self)
			tes3.messageBox("Press a free key.")
            event.register(tes3.event.keyDown, assignHotkey4)
        end
    })
	
	local category1 = page0:createCategory("Rebreather Options")
	
	RebmessageonoffButton = category1:createOnOffButton({
	
		label = "Rebreather Messages On/Off",
		variable = mcm:createTableVariable{id = "RebmessageonOFF", table = config},
		callback = function(self)
			if ( config.RebmessageonOFF == true ) then
				tes3.messageBox("Messages enabled.")
			else
				tes3.messageBox("Messages disabled.")
			end
		end
    })
	
	RebonoffButton = category1:createOnOffButton({
	
		label = "Show Rebreather Helmet On/Off",
		variable = mcm:createTableVariable{id = "RebhelmetonOFF", table = config},
		callback = function(self)
			if ( config.RebhelmetonOFF == true ) then
				tes3.messageBox("Helmet enabled.")
			else
				tes3.messageBox("Helmet disabled.")
			end
		end
    })
	
	RebequipunderwaterButton = category1:createOnOffButton({
	
		label = "Can't Equip Rebreather Underwater On/Off",
		variable = mcm:createTableVariable{id = "Rebequipunderwater", table = config},
		callback = function(self)
			if ( config.Rebequipunderwater == true ) then
				tes3.messageBox("Can't equip underwater enabled.")
			else
				tes3.messageBox("Can't equip underwater disabled.")
			end
		end
    })
	
	local category2 = page0:createCategory("Climbing Options")
	
	ClimbtoolonoffButton = category2:createOnOffButton({
	
		label = "Climbing Requires Tool On/Off",
        variable = mcm:createTableVariable{id = "climbreqtool", table = config},
		callback = function(self)
			if ( config.climbreqtool == true ) then
				tes3.messageBox("Climb Require Tool enabled.")
			else
				tes3.messageBox("Climb Require Tool disabled.")
			end
		end
    })
	
	ClimbsoundonoffButton = category2:createOnOffButton({
	
		label = "Climbing Sounds On/Off",
        variable = mcm:createTableVariable{id = "climbsoundoption", table = config},
		callback = function(self)
			if ( config.climbsoundoption == true ) then
				tes3.messageBox("Sound enabled.")
			else
				tes3.messageBox("Sound disabled.")
			end
		end
    })
	
	ClimbfonoffButton = category2:createOnOffButton({
	
		label = "Climbing Drains Fatigue On/Off",
        variable = mcm:createTableVariable{id = "cfoption", table = config},
		callback = function(self)
			if ( config.cfoption == true ) then
				tes3.messageBox("Climbing Fatigue enabled.")
			else
				tes3.messageBox("Climbing Fatigue disabled.")
			end
		end
    })
	
	ClimbsponoffButton = category2:createOnOffButton({
	
		label = "Climbing Speed Debuff On/Off",
        variable = mcm:createTableVariable{id = "cspoption", table = config},
		callback = function(self)
			if ( config.cspoption == true ) then
				tes3.messageBox("Climbing Speed Debuff enabled.")
			else
				tes3.messageBox("Climbing Speed Debuff disabled.")
			end
		end
    })

--Page2Sidebar
	page0.sidebar.noScroll = false
	local subcat = page0.sidebar:createCategory("Rebreather Icon Position")
	page0.sidebar:createSlider {label = "Horizontal (Min:0 to Max:"..config.resolutionHor..")", max = config.resolutionHor, min = 0, step = 1, jump = 10, variable = mcm:createTableVariable {id = "iconslider", table = config}, callback = updateRebFillbarCustomization}
	page0.sidebar:createSlider {label = "Vertical (Min:0 to Max:"..config.resolutionVer..")", max = config.resolutionVer, min = 0, step = 1, jump = 10, variable = mcm:createTableVariable {id = "iconsliderpercent", table = config}, callback = updateRebFillbarCustomization}
	
	local subcat = page0.sidebar:createCategory("Climbing Fatigue Drain")
	page0.sidebar:createSlider {label = "Rate", max = 5, min = 1, step = 1, jump = 1, variable = mcm:createTableVariable {id = "cfdspeed", table = config}, callback = updateClimbFatigueDrainSpeed}	
	local subcat = page0.sidebar:createCategory(" Definitions: \n  1 = Very Fast \n  2 = Fast \n  3 = Average \n  4 = Slow \n  5 = Very Slow")
	
	local subcat = page0.sidebar:createCategory("Climbing Speed Debuff")
	page0.sidebar:createSlider {label = "Scale", max = 3, min = 1, step = 1, jump = 1, variable = mcm:createTableVariable {id = "csdebuff", table = config}, callback = updateClimbSpeedDebuff}	
	local subcat = page0.sidebar:createCategory(" Definitions: \n  1 = Minimum \n  2 = Medium \n  3 = Maximum")
	
--Page3	
	local page1 = template:createSideBarPage({label="Other Options"})
	
	local subcat = page1:createCategory(" Screen Resolution     <- 1080p --- 4k ->")
    subcat:createSlider{label = "Horizontal", min = 1920, max = 3840, step = 1920, jump = 1920, variable = mcm.createTableVariable{id = "resolutionHor", table = config}, callback = changeResolutionHor}
    subcat:createSlider{label = "Vertical", min = 1080, max = 2160, step = 1080, jump = 1080, variable = mcm.createTableVariable{id = "resolutionVer", table = config}, callback = changeResolutionVer}

	local subcat = page1:createCategory("")
	page1.sidebar:createInfo{ text = "Thank you for using "..mod.name..". \n A mod by "..mod.author.."."}
	page1.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }
	
    mcm.register(template)
end

event.register("modConfigReady", registerModConfig)