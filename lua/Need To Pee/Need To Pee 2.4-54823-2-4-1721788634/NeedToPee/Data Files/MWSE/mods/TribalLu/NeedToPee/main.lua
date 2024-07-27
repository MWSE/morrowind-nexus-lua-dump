local mod = {
    name = "Need to Pee",
    config = "Need to Pee Config",
    ver = "2.4",
    author = "TribalLu",
            }
local configDefault = {
	enabled = true,
	hotkey = tes3.scanCode.p,
	hotkey2 = tes3.scanCode.x,
	hours = 24,
	messageonoff = true,
	hardcoremode = false,
	hardcoretick = 1,
	camerashift = true,
	squatanimation = true,
}

local config = mwse.loadConfig(mod.config, configDefault)

--Natural Pee acumulation
local INTERVAL = 5

--Pee in any of these
local peeObjects = { "waterfall", "bathtub", "ex_vivec_p_water", "forgetful_pool", "pool_01", "terrwater", "waternarsis", "barrelwater", "waterflow", "waterrapid", "watersquare", "barrel01water", "lwbowlwater",
"ko_basin", "ko_rose_basin", "ko_white_basin", "clawtub", "water_bucket-bathsale", "nom_well_", "hlaalu_well", "ex_redoran_well", "ex_t_wellpod", "rp_red_well", "rp_mh_well", "rm_well", "ruined_well_", "ex_nord_well", "furn_well00", "act_bm_well", "_EG_bath", "_EG_tel_bath",
"ab_ex_velwellfountain", "watercircle", "waterrect", "bucketwater", "t_com_furn_basin_01", "t_imp_furnr_basin_01", "t_imp_furnr_basin_02_w", "t_imp_furnr_basin_03_w" }

local peeEffects = { "trib_pee_l1", "trib_pee_l2", "trib_pee_l3", "trib_pee_l4", "trib_pee_l5" }

--Message Notifications
local peeReports = { "You feel a slight discomfort.", "You feel a mild discomfort.", "You feel a moderate discomfort.", "You feel a painful discomfort.", "You feel a severe discomfort.", }

local peeSound = "tribs/peesound_01.wav"

if not config then
    config = { blocked = {} }
end

local keybindButton
local keybind2Button
local enableButton
local messageonoffButton
local hardcoremodeButton
local camerashiftButton
local peeTimer
local squatanimationButton

local alreadyPeeing = false

local hurttick = "tribs/hurt_tick_01.wav"

local iniHC = 0
local iniPT = 0

local function subString(arr, x)
	for _, v in pairs(arr) do
		if string.find(x, v) then
			return true 
		end
	end
	return false
end

local function clearpeeEffects()
	for _, effect in ipairs(peeEffects) do
		tes3.removeSpell({ reference = tes3.player, spell = effect })
	end
end

local function applypeeEffects()
	clearpeeEffects()
	local i = ( tes3.player.data.NeedToPee.currentPeeLevel ) % 6
	local s = peeEffects[i]
	
	tes3.addSpell({ reference = tes3.player, spell = s })

--	if ( tes3.player.data.NeedToPee.trueTotalMax >= 600 ) then 
--		tes3.player.data.NeedToPee.trueTotalMax = 600
--	else
--		tes3.player.data.NeedToPee.trueTotalMax = tes3.player.data.NeedToPee.trueTotalMax + config.hours
--			local truemaxpee
--			truemaxpee = math.floor( config.hours * 5 )
--			if ( tes3.player.data.NeedToPee.trueTotalMax > truemaxpee ) then 
--				tes3.player.data.NeedToPee.trueTotalMax = truemaxpee
--			end
--	end

end

local function cleanpee()
	tes3.player.data.NeedToPee.pee = 0
	tes3.player.data.NeedToPee.currentPeeLevel = 0
	tes3.player.data.NeedToPee.trueTotalMax = config.hours

	clearpeeEffects()
	HardcoreTimer:pause()
end

local function reportPee()
	if ( config.messageonoff ) then
		local s = peeReports[tes3.player.data.NeedToPee.currentPeeLevel]
		tes3.messageBox(s)
	else end
end

local function pee(e)
	if ( tes3.menuMode() ) then
		return
	end
	
	if ( alreadyPeeing ) then
		return
	end

	if ( tes3.mobilePlayer.inCombat ) then
		tes3.messageBox("You cannot pee while in combat!")
		return
	end

	local canPeeHere = false
	local currentCells = tes3.getActiveCells()
	local waterLevel
	local playerX = tes3.mobilePlayer.position.z
	local waterAccess

	for _, cell in ipairs(currentCells) do
		waterLevel = cell.waterLevel
	end

	if ( waterLevel and playerX < waterLevel ) then
		canPeeHere = true
		waterAccess = true
	else
		local rayhit = tes3.rayTest {position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), maxDistance = 300, ignore = {tes3.player}};

		if rayhit and rayhit.reference then	
			local id = string.lower(rayhit.reference.object.id)
			if ( subString(peeObjects, id) ) then
				canPeeHere = true
				waterAccess = true
			end
		end
	
	end

	if canPeeHere then
		if waterAccess then
			alreadyPeeing = true
			tes3.messageBox("You relieved yourself.")
			cleanpee()
			if config.squatanimation == true then tes3.loadAnimation({ reference = tes3.player, file = "Squat.nif", }) end
			tes3.playSound({ soundPath = peeSound, volume = 0.8 })
    			timer.start({ duration = 5, iterations = 1, type = timer.real, callback = function()
			if config.squatanimation == true then tes3.loadAnimation({ reference = tes3.player }) end
			tes3.removeSound({ soundPath = peeSound })
			alreadyPeeing = false
    			end})
		end
	else
		tes3.messageBox("You need a water source in order to pee.")
	end
end

local peevar = 0
local function peeTimerActive()
	if peevar == 1 then
	tes3.player.data.NeedToPee.pee = tes3.player.data.NeedToPee.pee - 6
		if tes3.player.data.NeedToPee.pee <= 0 then tes3.player.data.NeedToPee.pee = 0 end
	end
end

local function myPeeFreeCallback(e)
	peevar = 1
	if config.squatanimation == true then tes3.loadAnimation({ reference = tes3.player, file = "Squat.nif", }) end
	if config.camerashift == true then
		if tes3.mobilePlayer.is3rdPerson == false then tes3.mobilePlayer.cameraHeight = 0.5 * tes3.mobilePlayer.cameraHeight end
	end
	tes3.playSound({ soundPath = peeSound, volume = 0.8 })
	peeTimer:reset()
	peeTimer:resume()
end

local function undoPeeFreeCallback(e)
	peevar = 0
	if config.squatanimation == true then tes3.loadAnimation({ reference = tes3.player }) end
	if config.camerashift == true then
		tes3.mobilePlayer.cameraHeight = nil
	end
	tes3.removeSound({ soundPath = peeSound })
	peeTimer:pause()
end


local function updatePee()

	if not config.enabled then
		return
	end

	local currDay = tes3.findGlobal("DaysPassed").value
	local currHour = tes3.findGlobal("GameHour").value
		
	local daysInHours = ( currDay - tes3.player.data.NeedToPee.day ) * 24
	local hours = currHour - tes3.player.data.NeedToPee.hour
	local hoursPassed
	
	local currentPeeLevel
	
	hoursPassed = daysInHours + hours
	
	tes3.player.data.NeedToPee.pee = hoursPassed + tes3.player.data.NeedToPee.pee
	tes3.player.data.NeedToPee.day = currDay
	tes3.player.data.NeedToPee.hour = currHour
	
	currentPeeLevel = math.floor( tes3.player.data.NeedToPee.pee / config.hours )
	if ( currentPeeLevel > 5 ) then
		currentPeeLevel = 5
	end
	
	local maxpee
	maxpee = math.floor( config.hours * 5 )
	if ( tes3.player.data.NeedToPee.pee > maxpee ) then 
		tes3.player.data.NeedToPee.pee = maxpee
	end
	
	tes3.player.data.NeedToPee.trueTotal = tes3.player.data.NeedToPee.pee

	if ( currentPeeLevel > tes3.player.data.NeedToPee.currentPeeLevel ) then 
		tes3.player.data.NeedToPee.currentPeeLevel = currentPeeLevel
		applypeeEffects()
		reportPee()
	end
	
	if ( config.hardcoremode == true ) then
		if tes3.player.data.NeedToPee.currentPeeLevel >= 5 then
			HardcoreTimer:resume()
		else
			HardcoreTimer:pause()
		end
	end
	
end

local function HardcoreActive()
	tes3.mobilePlayer.health.current = tes3.mobilePlayer.health.current - config.hardcoretick
	tes3.playSound({ soundPath = hurttick, volume = 0.5 })
	--tes3.messageBox("Relieve your bladder immediately.")
	if tes3.mobilePlayer.health.current <= 0 then
		HardcoreTimer:pause()
		tes3.removeSound({ soundPath = hurttick })
	end
end

local function assignHotkey(e)
	event.unregister(tes3.event.keyDown, pee, { filter = config.hotkey } )
	config.hotkey = e.keyCode
	
	if ( config.enabled ) then
		event.register(tes3.event.keyDown, pee, { filter = config.hotkey } )
	end
	local buttonName = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value
	tes3.messageBox('Pee hotkey is now "%s"', buttonName);
	keybindButton.buttonText = buttonName
	event.unregister(tes3.event.keyDown, assignHotkey)
	keybindButton:setText(buttonName)
end

local function assignHotkey2(e)
	event.unregister(tes3.event.keyDown, myPeeFreeCallback, { filter = config.hotkey2 } )
	event.unregister(tes3.event.keyUp, undoPeeFreeCallback, { filter = config.hotkey2 } )
	config.hotkey2 = e.keyCode
	
	if ( config.enabled ) then
		event.register(tes3.event.keyDown, myPeeFreeCallback, { filter = config.hotkey2 } )
		event.register(tes3.event.keyUp, undoPeeFreeCallback, { filter = config.hotkey2 } )
	end
	local buttonName = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey2).value
	tes3.messageBox('PeeFree hotkey is now "%s"', buttonName);
	keybind2Button.buttonText = buttonName
	event.unregister(tes3.event.keyDown, assignHotkey2)
	keybind2Button:setText(buttonName)
end

local function startPeeTimer()
	tes3.player.data.NeedToPee = tes3.player.data.NeedToPee or {}
	tes3.player.data.NeedToPee.pee = tes3.player.data.NeedToPee.pee or 0 -- number of hours since peeed
	tes3.player.data.NeedToPee.currentPeeLevel = tes3.player.data.NeedToPee.currentPeeLevel or 0 -- 5 tiers of debuff
	tes3.player.data.NeedToPee.trueTotal = tes3.player.data.NeedToPee.trueTotal or 0
	tes3.player.data.NeedToPee.trueTotalMax = config.hours
	
	tes3.player.data.NeedToPee.hour = tes3.player.data.NeedToPee.hour or tes3.findGlobal("GameHour").value
	tes3.player.data.NeedToPee.day = tes3.player.data.NeedToPee.day or tes3.findGlobal("DaysPassed").value
	
	timer.start({ duration = INTERVAL, callback = updatePee, type = timer.simulate, iterations = -1 })
end

local function startHardcoreTimer()
	HardcoreTimer = timer.start({ duration = 10, iterations = -1, type = timer.real, callback = HardcoreActive})
	if iniHC == 0 then HardcoreTimer:pause() end
end

local function startPeeFreeTimer()
	peeTimer = timer.start({ duration = 5, iterations = 1, type = timer.real, callback = peeTimerActive})
	if iniPT == 0 then peeTimer:pause() end
end

local function initialized()
	if tes3.isModActive("NeedToPee.esp") then
		if ( config.enabled) then
			event.register(tes3.event.keyDown, pee, { filter = config.hotkey } )
			event.register(tes3.event.keyDown, myPeeFreeCallback, { filter = config.hotkey2 } )
			event.register(tes3.event.keyUp, undoPeeFreeCallback, { filter = config.hotkey2 } )
			event.register(tes3.event.loaded, startPeeTimer)
			event.register(tes3.event.loaded, startHardcoreTimer)
			event.register(tes3.event.loaded, startPeeFreeTimer)
		end
	else
		tes3.messageBox("Enable NeedToPee.esp to enable pee mechanics.")
	end
	
	print("[NeedToPee] NeedToPee Initialized")
end

event.register(tes3.event.initialized, initialized)

local function getButtonText(featureString, bool)
	local s
	
	if ( bool ) then
		s = featureString .. " Enabled"
	else
		s = featureString .. " Disabled"
	end
	
	return s
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
			event.unregister(tes3.event.keyDown, pee, { filter = config.hotkey } )
			event.unregister(tes3.event.keyDown, myPeeFreeCallback, { filter = config.hotkey2 } )
			event.unregister(tes3.event.keyUp, undoPeeFreeCallback, { filter = config.hotkey2 } )
			if ( config.enabled ) then
				event.register(tes3.event.keyDown, pee, { filter = config.hotkey } )
				event.register(tes3.event.keyDown, myPeeFreeCallback, { filter = config.hotkey2 } )
				event.register(tes3.event.keyUp, undoPeeFreeCallback, { filter = config.hotkey2 } )
				cleanpee()
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
			else
				cleanpee()
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
			end
        end
    })

	local subcat = page:createCategory("Need To Pee brings in the need to relieve your character every so often or you will accumulate higher levels of pain with increasing consequences. \n \n The consequences are in the form of a Speed decrease. \n Pain Level 1 = 0 Speed decrease. \n Pain Level 2 = 5 Speed decrease. \n Pain Level 3 = 10 Speed decrease. \n Pain Level 4 = 25 Speed decrease. \n Pain Level 5 = 50 Speed decrease.")

	local subcat = page:createCategory("Choose how large your bladder is, how often you accumulate a Pain Level.")
	
	local category1 = page:createCategory("Hours between Pain Levels.")
	
	category1:createSlider {
		label = "Amount of time in hours between pain levels. [Default: 24]",
		max = 120,
		min = 1,
		step = 1,
		jump = 1,
		variable = mcm:createTableVariable {
			id = "hours",
			table = config
		}
	}
	
	local subcat = page:createCategory("Hardcore Mode Available. \n \n In Hardcore Mode you will lose health every 10 seconds once you hit Pain Level 5. You can toggle Hardcore Mode and customize the tick value on the next page.")
	
--Page2
	local page0 = template:createSideBarPage({label="Settings"})
	
	local category1 = page0:createCategory("Keybinds for peeing")
	
	keybindButton = category1:createButton({
	
	label = "Full Release Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value;
        callback = function(self)
			tes3.messageBox("Press a key.")
            event.register(tes3.event.keyDown, assignHotkey)
        end
    })
	keybind2Button = category1:createButton({
	
	label = "Pee Free Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey2).value;
        callback = function(self)
			tes3.messageBox("Press a free key.")
            event.register(tes3.event.keyDown, assignHotkey2)
        end
    })

	local category2 = page0:createCategory("Display Message Notifications")
	
	messageonoffButton = category2:createOnOffButton({
	
        label = "Turn Message Notifications On/Off.",
		variable = mcm:createTableVariable{id = "messageonoff", table = config},
		callback = function(self)
			if ( config.messageonoff == true ) then
				tes3.messageBox("Messages enabled.")
			else
				tes3.messageBox("Messages disabled.")
			end
		end
    })
	
	local category3 = page0:createCategory("Hardcore Mode")
	
	hardcoremodeButton = category3:createOnOffButton({
	
        label = "Turn Hardcore Mode On/Off.",
		variable = mcm:createTableVariable{id = "hardcoremode", table = config},
		callback = function(self)
			if ( config.hardcoremode == true ) then
				tes3.messageBox("Hardcore Mode enabled.")
			else
				tes3.messageBox("Hardcore Mode disabled.")
			end
		end
    })
	
	local category4 = page0:createCategory("Hardcore Tick Value")
	
	category4:createSlider {
		label = "Amount of Health lost per tick while Pain Level 5. [Default: 1]",
		max = 50,
		min = 0,
		step = 1,
		jump = 1,
		variable = mcm:createTableVariable {
			id = "hardcoretick",
			table = config
		}
	}
	
	local category4 = page0:createCategory("Camera Shift")
	
	camerashiftButton = category4:createYesNoButton({
	
        label = "Do you want the camera to shift down when you are peeing in 1st Person?",
		variable = mcm:createTableVariable{id = "camerashift", table = config},
		callback = function(self)
			if ( config.camerashift == true ) then
				tes3.messageBox("Camera Shift enabled.")
			else
				tes3.messageBox("Camera Shift disabled.")
			end
		end
    })
	
	local category5 = page0:createCategory("Squat Animation")
	
	squatanimationButton = category5:createYesNoButton({
	
        label = "Do you want the squat animation when peeing in 3rd Person?",
		variable = mcm:createTableVariable{id = "squatanimation", table = config},
		callback = function(self)
			if ( config.squatanimation == true ) then
				tes3.messageBox("Squat Animation enabled.")
			else
				tes3.messageBox("Squat Animation disabled.")
			end
		end
    })
	
--Page2Sidebar
	page0.sidebar.noScroll = false
	local subcat = page0:createCategory("")
	page0.sidebar:createInfo{ text = "Thank you for using "..mod.name..". \n A mod by "..mod.author.."."}
	page0.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }

    mcm.register(template)
end

event.register("modConfigReady", registerModConfig)