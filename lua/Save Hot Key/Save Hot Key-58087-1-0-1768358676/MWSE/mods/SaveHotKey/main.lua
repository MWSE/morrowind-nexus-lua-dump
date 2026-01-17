local this = {} 
local modConfigPackage = {}

local confPath = "SaveHotKey_config"
config = mwse.loadConfig(confPath)
if not config  then
	config = { 
		SHK_saveKeyCfg = {
			keyCode = tes3.scanCode.F11, 
				
		},
		SHK_loadKeyCfg = {
			keyCode = tes3.scanCode.F10, 
		}
	}
	mwse.saveConfig(confPath, config)
end

local function registerModConfig()
	EasyMCM = require("easyMCM.EasyMCM")
	local template = EasyMCM.createTemplate("Save Hot Key")
	template:saveOnClose(confPath, config)
	local page = template:createPage()
	local category = page:createCategory("Save Hot Key Settings")
	
	
	category:createKeyBinder{
		label = "Set Save Hot Key",
		allowCombincations = false,
		variable = EasyMCM.createTableVariable{
			id = "SHK_saveKeyCfg",
			table = config,
			defaultSetting = {
				keyCode = tes3.scanCode.F11,
			}
		}
	}
	
	category:createKeyBinder{
		label = "Set Load Hot Key",
		allowCombincations = false,
		variable = EasyMCM.createTableVariable{
			id = "SHK_loadKeyCfg",
			table = config,
			defaultSetting = {
				keyCode = tes3.scanCode.F10,
			}
		}
	}
	
	EasyMCM.register(template)
	event.register("keyDown", this.SHK_keyDown)
end

function this.SHK_keyDown(e)
	if(e.keyCode == config.SHK_saveKeyCfg.keyCode) then
		gameHour = tes3.findGlobal("GameHour").value
		saveName = tes3.player.object.name .. tes3.findGlobal("Year").value .. 
		"-" .. tes3.findGlobal("Month").value ..
		"-" .. tes3.findGlobal("Day").value ..
		"-"
		
		tes3.saveGame({file = saveName .. gameHour, name = saveName .. math.floor(gameHour)})
	elseif(e.keyCode == config.SHK_loadKeyCfg.keyCode) then
		tes3.loadGame(saveName .. gameHour .. ".ess")
	end
 end

event.register("modConfigReady", registerModConfig)