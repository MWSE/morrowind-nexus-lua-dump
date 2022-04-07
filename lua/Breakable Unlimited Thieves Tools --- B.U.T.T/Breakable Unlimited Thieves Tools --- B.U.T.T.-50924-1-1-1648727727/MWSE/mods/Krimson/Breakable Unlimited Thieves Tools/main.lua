local config

event.register("modConfigReady", function()
    require("Krimson.Breakable Unlimited Thieves Tools.mcm")
	config  = require("Krimson.Breakable Unlimited Thieves Tools.config")
end)

local function onTrapDisarm(e)

	local bentProbe = tes3.getObject("probe_bent")
	local appProbe = tes3.getObject("probe_apprentice_01")
	local jourProbe = tes3.getObject("probe_journeyman_01")
	local masterProbe = tes3.getObject("probe_master")
	local grandProbe = tes3.getObject("probe_grandmaster")
	local secretProbe = tes3.getObject("probe_secretmaster")
	local currentTool = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.probe })

	if e.tool == bentProbe then
		if config.breakEnabled then
			local intel = tes3.mobilePlayer.intelligence.base
			local luckyNum = tes3.mobilePlayer.luck.base / 2
			local lucky = math.random(1,luckyNum)
			local secur = tes3.mobilePlayer.security.base
			local qual = e.tool.quality
			local breakMod = ( intel + secur ) / 4 * qual + lucky
			local randomNum = math.random(100)
			local basePick = config.baseProbe
			basePick = basePick - breakMod
			if basePick <= 0 then
				basePick = 1
			end
			if randomNum <= basePick then
				currentTool.itemData.condition = 0
			elseif config.modEnabled then
				currentTool.itemData.condition = 25
			end
		elseif config.modEnabled then
			currentTool.itemData.condition = 25
		end
	end
	if e.tool == appProbe then
		if config.breakEnabled then
			local intel = tes3.mobilePlayer.intelligence.base
			local luckyNum = tes3.mobilePlayer.luck.base / 2
			local lucky = math.random(1,luckyNum)
			local secur = tes3.mobilePlayer.security.base
			local qual = e.tool.quality
			local breakMod = ( intel + secur ) / 4 * qual + lucky
			local randomNum = math.random(100)
			local basePick = config.baseProbe
			basePick = basePick - breakMod
			if basePick <= 0 then
				basePick = 1
			end
			if randomNum <= basePick then
				currentTool.itemData.condition = 0
			elseif config.modEnabled then
				currentTool.itemData.condition = 25
			end
		elseif config.modEnabled then
			currentTool.itemData.condition = 25
		end
	end
	if e.tool == jourProbe then
		if config.breakEnabled then
			local intel = tes3.mobilePlayer.intelligence.base
			local luckyNum = tes3.mobilePlayer.luck.base / 2
			local lucky = math.random(1,luckyNum)
			local secur = tes3.mobilePlayer.security.base
			local qual = e.tool.quality
			local breakMod = ( intel + secur ) / 4 * qual + lucky
			local randomNum = math.random(100)
			local basePick = config.baseProbe
			basePick = basePick - breakMod
			if basePick <= 0 then
				basePick = 1
			end
			if randomNum <= basePick then
				currentTool.itemData.condition = 0
			elseif config.modEnabled then
				currentTool.itemData.condition = 25
			end
		elseif config.modEnabled then
			currentTool.itemData.condition = 25
		end
	end
	if e.tool == masterProbe then
		if config.breakEnabled then
			local intel = tes3.mobilePlayer.intelligence.base
			local luckyNum = tes3.mobilePlayer.luck.base / 2
			local lucky = math.random(1,luckyNum)
			local secur = tes3.mobilePlayer.security.base
			local qual = e.tool.quality
			local breakMod = ( intel + secur ) / 4 * qual + lucky
			local randomNum = math.random(100)
			local basePick = config.baseProbe
			basePick = basePick - breakMod
			if basePick <= 0 then
				basePick = 1
			end
			if randomNum <= basePick then
				currentTool.itemData.condition = 0
			elseif config.modEnabled then
				currentTool.itemData.condition = 25
			end
		elseif config.modEnabled then
			currentTool.itemData.condition = 25
		end
	end
	if e.tool == grandProbe then
		if config.breakEnabled then
			local intel = tes3.mobilePlayer.intelligence.base
			local luckyNum = tes3.mobilePlayer.luck.base / 2
			local lucky = math.random(1,luckyNum)
			local secur = tes3.mobilePlayer.security.base
			local qual = e.tool.quality
			local breakMod = ( intel + secur ) / 4 * qual + lucky
			local randomNum = math.random(100)
			local basePick = config.baseProbe
			basePick = basePick - breakMod
			if basePick <= 0 then
				basePick = 1
			end
			if randomNum <= basePick then
				currentTool.itemData.condition = 0
			elseif config.modEnabled then
				currentTool.itemData.condition = 25
			end
		elseif config.modEnabled then
			currentTool.itemData.condition = 25
		end
	end
	if config.modEnabled then
		if e.tool == secretProbe then
			currentTool.itemData.condition = 25
		end
	end
end

local function onLockPick(e)

	local appPick = tes3.getObject("pick_apprentice_01")
	local jourPick = tes3.getObject("pick_journeyman_01")
	local masterPick = tes3.getObject("pick_master")
	local grandPick = tes3.getObject("pick_grandmaster")
	local secretPick = tes3.getObject("pick_secretmaster")
	local skelKey = tes3.getObject("skeleton_key")
	local currentTool = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.lockpick })

	if e.tool == appPick then
		if config.breakEnabled then
			local intel = tes3.mobilePlayer.intelligence.base
			local luckyNum = tes3.mobilePlayer.luck.base / 2
			local lucky = math.random(1,luckyNum)
			local secur = tes3.mobilePlayer.security.base
			local qual = e.tool.quality
			local breakMod = ( intel + secur ) / 4 * qual + lucky
			local randomNum = math.random(100)
			local basePick = config.basePick
			basePick = basePick - breakMod
			if basePick <= 0 then
				basePick = 1
			end
			if randomNum <= basePick then
				currentTool.itemData.condition = 0
			elseif config.modEnabled then
				currentTool.itemData.condition = 25
			end
		elseif config.modEnabled then
			currentTool.itemData.condition = 25
		end
	end
	if e.tool == jourPick then
		if config.breakEnabled then
			local intel = tes3.mobilePlayer.intelligence.base
			local luckyNum = tes3.mobilePlayer.luck.base / 2
			local lucky = math.random(1,luckyNum)
			local secur = tes3.mobilePlayer.security.base
			local qual = e.tool.quality
			local breakMod = ( intel + secur ) / 4 * qual + lucky
			local randomNum = math.random(100)
			local basePick = config.basePick
			basePick = basePick - breakMod
			if basePick <= 0 then
				basePick = 1
			end
			if randomNum <= basePick then
				currentTool.itemData.condition = 0
			elseif config.modEnabled then
				currentTool.itemData.condition = 25
			end
		elseif config.modEnabled then
			currentTool.itemData.condition = 25
		end
	end
	if e.tool == masterPick then
		if config.breakEnabled then
			local intel = tes3.mobilePlayer.intelligence.base
			local luckyNum = tes3.mobilePlayer.luck.base / 2
			local lucky = math.random(1,luckyNum)
			local secur = tes3.mobilePlayer.security.base
			local qual = e.tool.quality
			local breakMod = ( intel + secur ) / 4 * qual + lucky
			local randomNum = math.random(100)
			local basePick = config.basePick
			basePick = basePick - breakMod
			if basePick <= 0 then
				basePick = 1
			end
			if randomNum <= basePick then
				currentTool.itemData.condition = 0
			elseif config.modEnabled then
				currentTool.itemData.condition = 25
			end
		elseif config.modEnabled then
			currentTool.itemData.condition = 25
		end
	end
	if e.tool == grandPick then
		if config.breakEnabled then
			local intel = tes3.mobilePlayer.intelligence.base
			local luckyNum = tes3.mobilePlayer.luck.base / 2
			local lucky = math.random(1,luckyNum)
			local secur = tes3.mobilePlayer.security.base
			local qual = e.tool.quality
			local breakMod = ( intel + secur ) / 4 * qual + lucky
			local randomNum = math.random(100)
			local basePick = config.basePick
			basePick = basePick - breakMod
			if basePick <= 0 then
				basePick = 1
			end
			if randomNum <= basePick then
				currentTool.itemData.condition = 0
			elseif config.modEnabled then
				currentTool.itemData.condition = 25
			end
		elseif config.modEnabled then
			currentTool.itemData.condition = 25
		end
	end
	if config.modEnabled then
		if e.tool == secretPick then
			currentTool.itemData.condition = 25
		end
		if e.tool == skelKey then
			currentTool.itemData.condition = 50
		end
	end
end

local function onUiObjectTooltip(e)

	local bentProbe = tes3.getObject("probe_bent")
	local appProbe = tes3.getObject("probe_apprentice_01")
	local jourProbe = tes3.getObject("probe_journeyman_01")
	local masterProbe = tes3.getObject("probe_master")
	local grandProbe = tes3.getObject("probe_grandmaster")
	local secretProbe = tes3.getObject("probe_secretmaster")
	local appPick = tes3.getObject("pick_apprentice_01")
	local jourPick = tes3.getObject("pick_journeyman_01")
	local masterPick = tes3.getObject("pick_master")
	local grandPick = tes3.getObject("pick_grandmaster")
	local secretPick = tes3.getObject("pick_secretmaster")
	local skelKey = tes3.getObject("skeleton_key")

	if e.object == bentProbe then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	elseif e.object == appProbe then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	elseif e.object == jourProbe then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	elseif e.object == masterProbe then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	elseif e.object == grandProbe then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	elseif e.object == secretProbe then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	elseif e.object == appPick then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	elseif e.object == jourPick then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	elseif e.object == masterPick then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	elseif e.object == grandPick then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	elseif e.object == secretPick then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	elseif e.object == skelKey then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	else
		return
	end
end

local function initialized(e)
	event.register("trapDisarm", onTrapDisarm)
	event.register("lockPick", onLockPick)
	if config.modEnabled then
		event.register("uiObjectTooltip", onUiObjectTooltip)
	end
	print("Breakable Unlimited Thieves Tools-[B.U.T.T.]-registered")
end

event.register("initialized", initialized)