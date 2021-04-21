--[[Let There Be Darkness
	mod changes lighting values of interior cells
	and nukes lights without a visible mesh

	authors = {
	["Greatness7"] = {scripting, troubleshooting},
	["Merlord"] = {troubleshooting},
	["OperatorJack"] = {scripting, troubleshooting},
	["Petethegoat"] = {troubleshooting, testing},
	["RedFurryDemon"] = {scripting}}

	in case of bugs, please ping RFD on discord
]]--

local config = require("RFD.LetThereBeDarkness.config")
local overrides = require("RFD.LetThereBeDarkness.overrides")

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\RFD\\LetThereBeDarkness\\mcm.lua")
end)

local cell
local changedCells = {  }

local function lightsOff(cell)
	--saving vanilla values
	if (changedCells[cell] == nil) then
		changedCells[cell] = {
    		ambientColor = tes3vector3.new(cell.ambientColor.r,cell.ambientColor.g,cell.ambientColor.b),
    		fogColor = tes3vector3.new(cell.fogColor.r,cell.fogColor.g,cell.fogColor.b),
    		sunColor = tes3vector3.new(cell.sunColor.r,cell.sunColor.g,cell.sunColor.b),
		}
	end
	local cellName = cell.id:lower()
	local oT = nil
	if (config.useOverrides == "TLaD") then
		oT = overrides.overrideTableTLaD
	elseif (config.useOverrides == "DL") then
		oT = overrides.overrideTableDL
	end
	if (config.useOverrides) and (oT[cellName]) then
		if (config.debugMode == true) then
			tes3.messageBox("[Let There Be Darkness] Light settings retrieved from override table")
			mwse.log("[Let There Be Darkness] Light settings retrieved from override table")
		end
		--[[for colorType in pairs({"ambientColor", "fogColor", "sunColor"}) do
			cell[colorType].r = oT[cellName][colorType].r
			cell[colorType].g = oT[cellName][colorType].g
			cell[colorType].b = oT[cellName][colorType].b
		end]]
		cell.ambientColor.r = (oT[cellName].ambientColor.r)
		cell.ambientColor.g = (oT[cellName].ambientColor.g)
		cell.ambientColor.b = (oT[cellName].ambientColor.b)
		cell.fogColor.r = (oT[cellName].fogColor.r)
		cell.fogColor.g = (oT[cellName].fogColor.g)
		cell.fogColor.b = (oT[cellName].fogColor.b)
		cell.sunColor.r = (oT[cellName].sunColor.r)
		cell.sunColor.g = (oT[cellName].sunColor.g)
		cell.sunColor.b = (oT[cellName].sunColor.b)
	else
		--[[for colorType in pairs({"ambientColor", "fogColor", "sunColor"}) do
			cell[colorType].r = changedCells[cell][colorType].r * config[colorType] * 0.1
			cell[colorType].g = changedCells[cell][colorType].g * config[colorType] * 0.1
			cell[colorType].b = changedCells[cell][colorType].b * config[colorType] * 0.1
		end]]
		cell.ambientColor.r = (changedCells[cell].ambientColor.r * config.ambientColorR * 0.01)
		cell.ambientColor.g = (changedCells[cell].ambientColor.g * config.ambientColorG * 0.01)
		cell.ambientColor.b = (changedCells[cell].ambientColor.b * config.ambientColorB * 0.01)
		cell.fogColor.r = (changedCells[cell].fogColor.r * config.fogColorR * 0.01)
		cell.fogColor.g = (changedCells[cell].fogColor.g * config.fogColorG * 0.01)
		cell.fogColor.b = (changedCells[cell].fogColor.b * config.fogColorB * 0.01)
		cell.sunColor.r = (changedCells[cell].sunColor.r * config.sunColorR * 0.01)
		cell.sunColor.g = (changedCells[cell].sunColor.g * config.sunColorG * 0.01)
		cell.sunColor.b = (changedCells[cell].sunColor.b * config.sunColorB * 0.01)
	end
	if (config.debugMode == true) then
		mwse.log("[Let There Be Darkness] Cell %s base:\n--- [AMB] %.0f %.0f %.0f\n--- [FOG] %.0f %.0f %.0f\n--- [SUN] %.0f %.0f %.0f", cell, changedCells[cell].ambientColor.r, changedCells[cell].ambientColor.g, changedCells[cell].ambientColor.b, changedCells[cell].fogColor.r, changedCells[cell].fogColor.g, changedCells[cell].fogColor.b, changedCells[cell].sunColor.r, changedCells[cell].sunColor.g, changedCells[cell].sunColor.b)
		mwse.log("[Let There Be Darkness] Cell %s edited:\n--- [AMB] %.0f %.0f %.0f\n--- [FOG] %.0f %.0f %.0f\n--- [SUN] %.0f %.0f %.0f", cell, cell.ambientColor.r, cell.ambientColor.g, cell.ambientColor.b, cell.fogColor.r, cell.fogColor.g, cell.fogColor.b, cell.sunColor.r, cell.sunColor.g, cell.sunColor.b)
		tes3.messageBox("[Let There Be Darkness] Cell %s edited:\n[AMB] %.0f %.0f %.0f\n[FOG] %.0f %.0f %.0f\n[SUN] %.0f %.0f %.0f", cell, cell.ambientColor.r, cell.ambientColor.g, cell.ambientColor.b, cell.fogColor.r, cell.fogColor.g, cell.fogColor.b, cell.sunColor.r, cell.sunColor.g, cell.sunColor.b)
		tes3.messageBox("[Let There Be Darkness] Cell %s base:\n[AMB] %.0f %.0f %.0f\n[FOG] %.0f %.0f %.0f\n[SUN] %.0f %.0f %.0f", cell, changedCells[cell].ambientColor.r, changedCells[cell].ambientColor.g, changedCells[cell].ambientColor.b, changedCells[cell].fogColor.r, changedCells[cell].fogColor.g, changedCells[cell].fogColor.b, changedCells[cell].sunColor.r, changedCells[cell].sunColor.g, changedCells[cell].sunColor.b)
	end
end

local function nukeLights()
	for i, cells in ipairs(tes3.getActiveCells()) do
		for ref in cells:iterateReferences() do
			if ((ref.object.objectType == tes3.objectType.light) and (ref.object.mesh == (""))) then
				if (config.blacklistLights == true) then
					if (config.lightBlacklist[ref.object.id]) then
						ref:deleteDynamicLightAttachment()
					end
				else
					ref:deleteDynamicLightAttachment()
				end
			end
		end
	end
end

local function disableStuff(cell)
	if (config.disableLights == true) then
		nukeLights()
	end
	if cell.isInterior then
		lightsOff(cell)
	end
end

local function checkPlayerCell(e)
	cell = e.cell
	if (config.useWhitelisted == true) then
		local cellName = cell.id:lower()
		if (config.affectedCells[cellName]) then
			if (config.debugMode == true) then
				mwse.log("[Let There Be Darkness] Cell %s is on the whitelist, editing.", cellName)
			end
			disableStuff(e.cell)
		end
	else
		disableStuff(e.cell)
	end
end

local menuId = tes3ui.registerID("LTBD_EditCellUI")
local function openLiveLightEditing()
	if tes3.menuMode() then
		return
	end
	if (tes3.player == nil) then
		tes3.messageBox("[Let There Be Darkness] Game must be loaded to edit lighting values")
		return
	elseif (tes3.getPlayerCell().isInterior == false) then
		tes3.messageBox("[Let There Be Darkness] You must be in an interior cell to edit lighting values")
		return
	end
    local menu = tes3ui.createMenu{ id = menuId, fixedFrame = true }
    tes3ui.enterMenuMode(menuId)
    local sliderBlock = menu:createBlock()
    sliderBlock.width = 500
    sliderBlock.autoHeight = true
    mwse.mcm.createSlider(
        menu,
        {
            label = "Ambient color (RED)",
            min = 0,
            max = 255,
            jump = 5,
            variable = mwse.mcm.createTableVariable{
				id = "temp_a_r",
				get = function()
					return cell.ambientColor.r
				end,
				set = function(_, newColor)
					cell.ambientColor.r = newColor
				end
				},
        }
    )
    mwse.mcm.createSlider(
        menu,
        {
            label = "Ambient color (GREEN)",
            min = 0,
            max = 255,
            jump = 5,
            variable = mwse.mcm.createTableVariable{
				id = "temp_a_g",
				get = function()
					return cell.ambientColor.g
				end,
				set = function(_, newColor)
					cell.ambientColor.g = newColor
				end
				},
        }
    )
    mwse.mcm.createSlider(
        menu,
        {
            label = "Ambient color (BLUE)",
            min = 0,
            max = 255,
            jump = 5,
            variable = mwse.mcm.createTableVariable{
				id = "temp_a_b",
				get = function()
					return cell.ambientColor.b
				end,
				set = function(_, newColor)
					cell.ambientColor.b = newColor
				end
				},
        }
    )
    mwse.mcm.createSlider(
        menu,
        {
            label = "Fog color (RED)",
            min = 0,
            max = 255,
            jump = 5,
            variable = mwse.mcm.createTableVariable{
				id = "temp_f_r",
				get = function()
					return cell.fogColor.r
				end,
				set = function(_, newColor)
					cell.fogColor.r = newColor
				end
				},
        }
    )
    mwse.mcm.createSlider(
        menu,
        {
            label = "Fog color (GREEN)",
            min = 0,
            max = 255,
            jump = 5,
            variable = mwse.mcm.createTableVariable{
				id = "temp_f_g",
				get = function()
					return cell.fogColor.g
				end,
				set = function(_, newColor)
					cell.fogColor.g = newColor
				end
				},
        }
    )
    mwse.mcm.createSlider(
        menu,
        {
            label = "Fog color (BLUE)",
            min = 0,
            max = 255,
            jump = 5,
            variable = mwse.mcm.createTableVariable{
				id = "temp_f_b",
				get = function()
					return cell.fogColor.b
				end,
				set = function(_, newColor)
					cell.fogColor.b = newColor
				end
				},
        }
    )
    mwse.mcm.createSlider(
        menu,
        {
            label = "Sun color (RED)",
            min = 0,
            max = 255,
            jump = 5,
            variable = mwse.mcm.createTableVariable{
				id = "temp_s_r",
				get = function()
					return cell.sunColor.r
				end,
				set = function(_, newColor)
					cell.sunColor.r = newColor
				end
				},
        }
    )
    mwse.mcm.createSlider(
        menu,
        {
            label = "Sun color (GREEN)",
            min = 0,
            max = 255,
            jump = 5,
            variable = mwse.mcm.createTableVariable{
				id = "temp_s_g",
				get = function()
					return cell.sunColor.g
				end,
				set = function(_, newColor)
					cell.sunColor.g = newColor
				end
				},
        }
    )
    mwse.mcm.createSlider(
        menu,
        {
            label = "Sun color (BLUE)",
            min = 0,
            max = 255,
            jump = 5,
            variable = mwse.mcm.createTableVariable{
				id = "temp_s_b",
				get = function()
					return cell.sunColor.b
				end,
				set = function(_, newColor)
					cell.sunColor.b = newColor
				end
				},
        }
    )
    local buttonBlock = menu:createBlock()
    buttonBlock.autoHeight = true
    buttonBlock.widthProportional = 1.0
    buttonBlock.childAlignX = 0.5
    --Okay
    local okayButton = buttonBlock:createButton{
        text = "Apply lighting values"
    }
    okayButton:register("mouseClick",
        function()
            menu:destroy()
            tes3ui.leaveMenuMode(menuId)
			mwse.log("[Let There Be Darkness] Cell %s previewed with settings:\n--- [AMB] %.0f %.0f %.0f\n--- [FOG] %.0f %.0f %.0f\n--- [SUN] %.0f %.0f %.0f", cell, cell.ambientColor.r, cell.ambientColor.g, cell.ambientColor.b, cell.fogColor.r, cell.fogColor.g, cell.fogColor.b, cell.sunColor.r, cell.sunColor.g, cell.sunColor.b)
			mwse.log("To save these settings in overrides.lua, replace the entry for this cell with this:")
			local printthis = cell.id:lower()
			mwse.log("		[\"%s\"] = {", printthis)
			mwse.log("			ambientColor = tes3vector3.new(%.0f,%.0f,%.0f),", cell.ambientColor.r, cell.ambientColor.g, cell.ambientColor.b)
			mwse.log("			fogColor = tes3vector3.new(%.0f,%.0f,%.0f),", cell.fogColor.r, cell.fogColor.g, cell.fogColor.b)
			mwse.log("			sunColor = tes3vector3.new(%.0f,%.0f,%.0f),", cell.sunColor.r, cell.sunColor.g, cell.sunColor.b)
			mwse.log("		},")
			tes3.messageBox("[Let There Be Darkness] Cell %s previewed with settings:\n[AMB] %.0f %.0f %.0f\n[FOG] %.0f %.0f %.0f\n[SUN] %.0f %.0f %.0f\nSettings exported to mwse.log", cell, cell.ambientColor.r, cell.ambientColor.g, cell.ambientColor.b, cell.fogColor.r, cell.fogColor.g, cell.fogColor.b, cell.sunColor.r, cell.sunColor.g, cell.sunColor.b)
        end
    )
    --Cancel
    local resetButton = buttonBlock:createButton{
        text = "Reset"
    }
    resetButton:register("mouseClick",
        function()
            menu:destroy()
            tes3ui.leaveMenuMode(menuId)
			lightsOff(cell)
        end
    )
    menu:getTopLevelMenu():updateLayout()
end

local function editLights()
    	for light in tes3.iterateObjects(tes3.objectType.light) do
		--flicker removal
			if (config.noFlicker == true) then
				if (light.isFire == false or (config.noFireFlicker == true and light.isFire == true)) then
				light.flickers = false
				light.flickersSlowly = false
				light.pulses = false
				light.pulsesSlowly = false
				if (config.debugMode == true) then
					mwse.log("[Let There Be Darkness] Light %s flicker removed", light.id)
				end
				else
				if (config.debugMode == true) then
					mwse.log("[Let There Be Darkness] Light %s is fire, skipping", light.id)
				end
				end
			end
		local lightName = light.id:lower()
		--TLaD override
			if (config.lightOverride == true) then
				local oT = overrides.overrideLightTLaD
				if (oT[lightName]) then
					light.color[1] = (oT[lightName].color.r)
					light.color[2] = (oT[lightName].color.g)
					light.color[3] = (oT[lightName].color.b)
					light.radius = (oT[lightName].radius)
					light.time = (oT[lightName].time)
				end
			end
		--TST override
			if (config.torchOverride == true) then
				local oT = overrides.overrideLightTST
				if (oT[lightName]) then
					light.radius = (oT[lightName].radius)
					light.time = (oT[lightName].time)
					light.value = (oT[lightName].value)
					light.weight = (oT[lightName].weight)
				end
			end
		--radius scaling
			if (config.scaleLightRadius ~= 100) then
				if (light.radius <= config.scaleCutoff) then
					if (config.debugMode == true) then
						mwse.log("[Let There Be Darkness] Light %s base radius: %.0f", light.id, light.radius)
					end
					light.radius = (light.radius * config.scaleLightRadius * 0.01)
					if (config.debugMode == true) then
						mwse.log("[Let There Be Darkness] Light %s edited radius: %.0f", light.id, light.radius)
					end
				else
					if (config.debugMode == true) then
						mwse.log("[Let There Be Darkness] Light %s radius above cutoff, skipping", light.id)
					end
				end
			end
		--nuking negative lights
			if (config.nukeDarkLights == true) then
				if(light.isNegative == true) then
					light.color[1] = 0
					light.color[2] = 0
					light.color[3] = 0
					light.isNegative = false
					mwse.log("[Let There Be Darkness] Light %s is negative, nuking", light.id)
				end
			end
        end
	if (config.debugMode == true) then
		tes3.messageBox("[Let There Be Darkness] Lights edited")
	end
end

local function initialized()
	event.register("cellChanged", checkPlayerCell)
	event.register("keyDown", openLiveLightEditing, {filter = tes3.scanCode.l})
	editLights()
	mwse.log("[Let There Be Darkness] initialized")
	if (config.debugMode == true) then
		tes3.messageBox("[Let There Be Darkness] initialized")
	end
end

event.register("initialized", initialized)