local mod = {
    name = "Need to Pee",
    config = "Need to Pee Config",
    ver = "2.0",
    author = "TribalLu",
            }
local configDefault = {
	enabled = true,
	hotkey = tes3.scanCode.p,
	hotkey2 = tes3.scanCode.x,
	hours = 24,
	messageonoff = true,
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

local alreadyPeeing = false

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

	if ( tes3.player.data.NeedToPee.trueTotalMax >= 600 ) then 
		tes3.player.data.NeedToPee.trueTotalMax = 600
	else
		tes3.player.data.NeedToPee.trueTotalMax = tes3.player.data.NeedToPee.trueTotalMax + config.hours
			local truemaxpee
			truemaxpee = math.floor( config.hours * 5 )
			if ( tes3.player.data.NeedToPee.trueTotalMax > truemaxpee ) then 
				tes3.player.data.NeedToPee.trueTotalMax = truemaxpee
			end
	end
end

local function cleanpee()
	tes3.player.data.NeedToPee.pee = 0
	tes3.player.data.NeedToPee.currentPeeLevel = 0
	tes3.player.data.NeedToPee.trueTotalMax = config.hours

	clearpeeEffects()
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
			tes3.loadAnimation({ reference = tes3.player, file = "Squat.nif", })
			tes3.playSound({ soundPath = peeSound, volume = 0.8 })
    			timer.start({ duration = 5, iterations = 1, type = timer.real, callback = function()
			tes3.loadAnimation({ reference = tes3.player })
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
	tes3.loadAnimation({ reference = tes3.player, file = "Squat.nif", })
	tes3.playSound({ soundPath = peeSound, volume = 0.8 })
    	local peeTimer = timer.start({ duration = 5, iterations = 1, type = timer.real, callback = peeTimerActive})
end

local function undoPeeFreeCallback(e)
	peevar = 0
	tes3.loadAnimation({ reference = tes3.player })
	tes3.removeSound({ soundPath = peeSound })
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

local function initialized()

	if tes3.isModActive("NeedToPee.esp") then
		if ( config.enabled) then
			event.register(tes3.event.keyDown, pee, { filter = config.hotkey } )
			event.register(tes3.event.keyDown, myPeeFreeCallback, { filter = config.hotkey2 } )
			event.register(tes3.event.keyUp, undoPeeFreeCallback, { filter = config.hotkey2 } )
			event.register(tes3.event.loaded, startPeeTimer)
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

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n Need To Pee brings in the need to relieve your character every so often or you will accumulate higher levels of pain with increasing consequences. \n \n The consequences are in the form of a Speed decrease. \n Level 1 Need To Pee = 0 Speed decrease. \n Level 2 Need To Pee = 5 Speed decrease. \n Level 3 Need To Pee = 10 Speed decrease. \n Level 4 Need To Pee = 25 Speed decrease. \n Level 5 Need To Pee = 50 Speed decrease. \n \n \n \n A mod by "..mod.author.."."}
    page.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }
	
    local category0 = page:createCategory("Need To Pee Config")

    enableButton = category0:createButton({
	
        buttonText = getButtonText("Mod", config.enabled),
        description = "Toggle the mod On/Off.",
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
	
	category0:createSlider {
		label = "Hours between Pain Levels",
		description = "Amount of time in hours between pain levels. Default: 24",
		max = 120,
		min = 1,
		step = 1,
		jump = 1,
		variable = mcm:createTableVariable {
			id = "hours",
			table = config
		}
	}
	
	local category1 = page:createCategory("Keybinds for peeing")
	
	keybindButton = category1:createButton({
	
	label = "Full Release Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value;
        description = "Choose pee hotkey.",
        callback = function(self)
			tes3.messageBox("Press a key.")
            event.register(tes3.event.keyDown, assignHotkey)
        end
    })
	keybind2Button = category1:createButton({
	
	label = "Pee Free Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey2).value;
        description = "Choose peefree hotkey.",
        callback = function(self)
			tes3.messageBox("Press a free key.")
            event.register(tes3.event.keyDown, assignHotkey2)
        end
    })

	local category2 = page:createCategory("Display Message Notifications? True/False")
	
	messageonoffButton = category2:createButton({
	
	buttonText = config.messageonoff;
        description = "Turn Message Notification On/True or Off/False.",
		callback = function(self)
			config.messageonoff = not config.messageonoff
			if ( config.messageonoff == true ) then
				tes3.messageBox("Messages enabled.")
				messageonoffButton.buttonText = (config.messageonoff)
				messageonoffButton:setText(config.messageonoff)
			else
				tes3.messageBox("Messages disabled.")
				messageonoffButton.buttonText = (config.messageonoff)
				messageonoffButton:setText(config.messageonoff)
			end
		end
    })

    mcm.register(template)
end

event.register("modConfigReady", registerModConfig)