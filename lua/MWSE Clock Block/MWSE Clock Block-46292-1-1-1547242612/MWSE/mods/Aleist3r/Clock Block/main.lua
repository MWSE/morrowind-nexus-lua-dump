local common = {}

common.version = 1.0

local defaultConfig = {
	version = common.version,
	components = {
		turnOnClock = true,
		twelveHourMode = false,
		clockBottom = false,
		isGameTime = false,
	},
}

local config = table.copy(defaultConfig)

local function loadConfig()
	config = {}

	table.copy(defaultConfig, config)

	local configJson = mwse.loadConfig("Clock Block")
	if (configJson ~= nil) then
		if (configJson.version == nil or common.version > configJson.version) then
			configJson.components = nil
		end
		table.copy(configJson, config)
	end
end
loadConfig()

local modConfig = {}

function modConfig.onCreate(container)
	local pane = container:createThinBorder{}
	pane.widthProportional = 1.0
	pane.heightProportional = 1.0
	pane.paddingAllSides = 12
    pane.flowDirection = "top_to_bottom"
	
	local header = pane:createLabel({ text = "Clock Block by Aleist3r, version 1.0" })
    header.borderAllSides = 6
	header.color = tes3ui.getPalette("header_color")
	
	local horizontalBlock1 = pane:createBlock({})
	horizontalBlock1.flowDirection = "left_to_right"
	horizontalBlock1.widthProportional = 1.0
	horizontalBlock1.height = 32
	horizontalBlock1.borderTop = 6
	horizontalBlock1.borderLeft = 6
	horizontalBlock1.borderRight = 6

	local label1 = horizontalBlock1:createLabel({ text = "Enable clock:" })
	label1.absolutePosAlignX = 0.0
	label1.absolutePosAlignY = 0.5

	local buttonTurnOn = horizontalBlock1:createButton({ text = config.components.turnOnClock and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value })
	buttonTurnOn.absolutePosAlignX = 1.0
	buttonTurnOn.absolutePosAlignY = 0.5
	buttonTurnOn.paddingTop = 3
	buttonTurnOn:register("mouseClick", function(e)
		config.components.turnOnClock = not config.components.turnOnClock
		buttonTurnOn.text = (config.components.turnOnClock and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value)
	end)

	local horizontalBlock2 = pane:createBlock({})
	horizontalBlock2.flowDirection = "left_to_right"
	horizontalBlock2.widthProportional = 1.0
	horizontalBlock2.height = 32
	horizontalBlock2.borderRight = 6
	horizontalBlock2.borderLeft = 6

	local label2 = horizontalBlock2:createLabel({ text = "Clock mode:" })
	label2.absolutePosAlignX = 0.0
	label2.absolutePosAlignY = 0.5

	local buttonClockMode = horizontalBlock2:createButton({ text = config.components.twelveHourMode and "12 hour mode" or "24 hour mode" })
	buttonClockMode.absolutePosAlignX = 1.0
	buttonClockMode.absolutePosAlignY = 0.5
	buttonClockMode.paddingTop = 3
	buttonClockMode:register("mouseClick", function(e)
		config.components.twelveHourMode = not config.components.twelveHourMode
		buttonClockMode.text = (config.components.twelveHourMode and "12 hour mode" or "24 hour mode")
	end)
	
	local horizontalBlock3 = pane:createBlock({})
	horizontalBlock3.flowDirection = "left_to_right"
	horizontalBlock3.widthProportional = 1.0
	horizontalBlock3.height = 32
	horizontalBlock3.borderRight = 6
	horizontalBlock3.borderLeft = 6

	local label3 = horizontalBlock3:createLabel({ text = "Clock position:" })
	label3.absolutePosAlignX = 0.0
	label3.absolutePosAlignY = 0.5

	local buttonClockPos = horizontalBlock3:createButton({ text = config.components.clockBottom and "Bottom" or "Top" })
	buttonClockPos.absolutePosAlignX = 1.0
	buttonClockPos.absolutePosAlignY = 0.5
	buttonClockPos.paddingTop = 3
	buttonClockPos:register("mouseClick", function(e)
		config.components.clockBottom = not config.components.clockBottom
		buttonClockPos.text = (config.components.clockBottom and "Bottom" or "Top")
	end)

	local horizontalBlock4 = pane:createBlock({})
	horizontalBlock4.flowDirection = "left_to_right"
	horizontalBlock4.widthProportional = 1.0
	horizontalBlock4.height = 32
	horizontalBlock4.borderBottom = 6
	horizontalBlock4.borderLeft = 6
	horizontalBlock4.borderRight = 6
	local label4 = horizontalBlock4:createLabel({ text = "Clock type:" })
	label4.absolutePosAlignX = 0.0
	label4.absolutePosAlignY = 0.5

	local buttonClockType = horizontalBlock4:createButton({ text = config.components.isGameTime and "Game time" or "Real time" })
	buttonClockType.absolutePosAlignX = 1.0
	buttonClockType.absolutePosAlignY = 0.5
	buttonClockType.paddingTop = 3
	buttonClockType:register("mouseClick", function(e)
		config.components.isGameTime = not config.components.isGameTime
		buttonClockType.text = (config.components.isGameTime and "Game time" or "Real time")
	end)

	local UI_textInfo = pane:createLabel({ text = "You need to reload your game to apply some changes."})
	UI_textInfo.borderAllSides = 6
	UI_textInfo.color = tes3ui.getPalette("health_color")

	local credits = pane:createLabel({ text = "Credits:" })
	credits.color = tes3ui.getPalette("header_color")
	credits.borderLeft = 6
	credits.borderRight = 6
	credits.borderTop = 6

	local UI_coding = pane:createLabel({ text = "Coding: Aleist3r, Merlord"})
	UI_coding.borderLeft = 6
	UI_coding.borderRight = 6

	local UI_Help = pane:createLabel({ text = "Various help: Morrowind Modding Comunity Discord"})
	UI_Help.borderLeft = 6
	UI_Help.borderRight = 6

	pane:updateLayout()
end

function modConfig.onClose(container)
	mwse.saveConfig("Clock Block", config)
end

modConfig.config = config

local function registerModConfig()
	mwse.registerModConfig("Clock Block", modConfig)
end
event.register("modConfigReady", registerModConfig)

local function onMenuClock(e)
	if (config.components.turnOnClock ~= true) then
		return
	end

	if (not e.newlyCreated) then
		return
	end

	UI = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
	local UI_MiniMap = UI:findChild(tes3ui.registerID("MenuMap_panel"))
	local UI_MiniMapBlock = UI_MiniMap.parent

	UI_MiniMapBlock.flowDirection = "top_to_bottom"
	UI_MiniMapBlock.alpha = tes3.worldController.menuAlpha

	UI_ClockBlock = UI_MiniMapBlock:createThinBorder({id = tes3ui.registerID("Aleist3r:ClockBlock")})
	UI_ClockBlock.flowDirection = "left_to_right"
	UI_ClockBlock.width= 65
	UI_ClockBlock.height = 20

	UI_TimeText = UI_ClockBlock:createLabel({ id = tes3ui.registerID("Aleist3r:ClockText") })
	UI_TimeText.absolutePosAlignX = 0.5

	if (config.components.clockBottom == false) then
		UI_MiniMapBlock:reorderChildren(UI_MiniMap, UI_ClockBlock, 1)
	end

	UI:updateLayout()
end

event.register("uiActivated", onMenuClock, { filter = "MenuMulti" })

local function onClockUpdate()
	--[[
	if (config.components.turnOnClock ~= true) then
		if (UI_ClockBlock ~= nil) then
			UI_ClockBlock:destroy()
			UI:updateLayout()
			return
		else
			return
		end
	end--]]
	local realDate = os.date("*t")
	local realTime
	if (config.components.isGameTime == false) then
		if (config.components.twelveHourMode == true) then
			if (realDate.hour > 12) then
				local timeHour
				if (realDate.hour > 13) then
					timeHour = realDate.hour - 12
				else
					timeHour = realDate.hour
				end
				if (realDate.min < 10) then
					realTime = (timeHour .. ":0" .. realDate.min .. "pm")
				else
					realTime = (timeHour .. ":" .. realDate.min .. "pm")
				end
			else
				if (realDate.min < 10) then
					realTime = (realDate.hour .. ":0" .. realDate.min .. "am")
				else
					realTime = (realDate.hour .. ":" .. realDate.min .. "am")
				end
			end
		else
			if (realDate.min < 10) then
				realTime = (realDate.hour .. ":0" .. realDate.min)
			else
				realTime = (realDate.hour .. ":" .. realDate.min)
			end
		end
	else
		local gameTime = tes3.getGlobal("GameHour")
		local hourString

		if (config.components.twelveHourMode == true) then
			local isPM = false
			if (gameTime > 12) then
				isPM = true
				if (gameTime > 13) then
					gameTime = gameTime - 12
				end
			end

			if gameTime < 10 then 
				hourString = string.sub(gameTime, 1, 1)
			else
				hourString  = string.sub(gameTime, 1, 2)
			end

			local minuteTime = ( gameTime - hourString ) * 60
			local minuteString
			if minuteTime < 10 then
				minuteString = "0" .. string.sub( minuteTime, 1, 1 )
			else
				minuteString = string.sub ( minuteTime , 1, 2)
			end
			realTime = (hourString .. ":" .. minuteString .. (isPM and "pm" or "am"))
		else
			if gameTime < 10 then 
				hourString = string.sub(gameTime, 1, 1)
			else
				hourString  = string.sub(gameTime, 1, 2)
			end

			local minuteTime = ( gameTime - hourString ) * 60
			local minuteString
			if minuteTime < 10 then
				minuteString = "0" .. string.sub( minuteTime, 1, 1 )
			else
				minuteString = string.sub ( minuteTime , 1, 2)
			end
			realTime = (hourString .. ":" .. minuteString)
		end
	end
	if (UI_ClockBlock ~= nil) then
		UI_TimeText.text = realTime
	end
end

event.register("enterFrame", onClockUpdate)