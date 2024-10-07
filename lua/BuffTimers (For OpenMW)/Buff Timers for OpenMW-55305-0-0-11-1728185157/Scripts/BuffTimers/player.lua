--[[

Mod: Buffs_Timers
Author:Nitro

--]]

--Need to figure out how to save/load the position of the UI element 
--Need to figure out if I need to handle spell overwrites.
--Consider creating update or init functions. 

-- Need to figure out how to handle seperate buffs or not. perhaps wrap eveyrthing in an if statement. 


local aux_util = require("openmw_aux.util")
local core = require("openmw.core")
local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")
local ui = require("openmw.ui")
local ambient = require("openmw.ambient")
local input = require("openmw.input")
local I = require("openmw.interfaces")
local util = require("openmw.util")
local time = require('openmw_aux.time')
local calendar = require('openmw_aux.calendar')
local async = require('openmw.async')
local v2 = util.vector2
local color = util.color
local com = require('Scripts.BuffTimers.common')
local shader = require('Scripts.BuffTimers.radialSwipe')
local auxUi = require('openmw_aux.ui')

local modInfo = require("Scripts.BuffTimers.modInfo")

local playerSettings = storage.playerSection("SettingsPlayer" .. modInfo.name)
local userInterfaceSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "UI")
local controlsSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Controls")
local gameplaySettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Gameplay")
local uiPositions = storage.playerSection("UI_positions") --added late

local xRes = ui.screenSize().x
local yRes = ui.screenSize().y

local debug = true
local timer = nil
local showMessages = userInterfaceSettings:get("showMessages")
local iconSize = userInterfaceSettings:get("iconScaling")
local showBox = userInterfaceSettings:get("showBox")
local buffAlign = userInterfaceSettings:get("buffAlign")
local debuffAlign = userInterfaceSettings:get("debuffAlign")
local splitBuffsDebuffs = userInterfaceSettings:get("splitBuffsDebuffs")
local iconOptions = userInterfaceSettings:get("iconOptions")
local timerColor = userInterfaceSettings:get("timerColor")
local detailTextColor = userInterfaceSettings:get("detailTextColor")
local iconPadding = userInterfaceSettings:get("iconPadding")
local rowLimit = userInterfaceSettings:get("rowLimit")
local buffLimit = userInterfaceSettings:get("buffLimit")

local function initLayer()
    if ui.layers[5] then return end -- Check if this layer already exists. 
    print("Creating Layer.. Effects Layer")
    ui.layers.insertAfter('HUD', 'Effects_Layer', { interactive = true })
end
initLayer()

-- Set the scale of the icons by checking for changes in the UI settings. 
userInterfaceSettings:subscribe(async:callback(function(section, key)
    if key then
        print('Value is changed:', key, '=', userInterfaceSettings:get(key))
        if key == "showMessages" then
            showMessages = userInterfaceSettings:get(key)
        elseif key == "iconScaling" then
            iconSize = userInterfaceSettings:get(key)
        elseif key == "showBox" then
            showBox = userInterfaceSettings:get(key)
        elseif key == "buffAlign" then
            buffAlign = userInterfaceSettings:get(key)
        elseif key == "debuffAlign" then
            debuffAlign = userInterfaceSettings:get(key)
        elseif key == "splitBuffsDebuffs" then
            splitBuffsDebuffs = userInterfaceSettings:get(key)
        elseif key == "iconOptions" then
            iconOptions = userInterfaceSettings:get(key)
        elseif key == "timerColor" then
            timerColor = userInterfaceSettings:get(key)
        elseif key == "detailTextColor" then
            detailTextColor = userInterfaceSettings:get(key)
        elseif key == "iconPadding" then
            iconPadding = userInterfaceSettings:get(key)
        elseif key == "rowLimit" then
            rowLimit = userInterfaceSettings:get(key)
        elseif key == "buffLimit" then
            buffLimit = userInterfaceSettings:get(key)
        end
    else
        print('All values are changed')
    end
end))

local buffPositions = uiPositions:get("BuffPositions")

-- Initialize if it's nil
if not buffPositions then
    uiPositions:set("BuffPositions", {buffPos = v2(0, 0), debuffPos = v2(0, iconSize * 2)})
end

local function traverseTable(tbl, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)  -- Indentation for visualizing depth
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print(prefix .. 'KEY:' .. tostring(key) .. " => Table")
            traverseTable(value, indent + 3)  -- Recursively traverse nested tables
        else
            print(prefix .. 'KEY:' .. tostring(key) .. " Value => " .. tostring(value))
        end
    end
end


local function d_message(msg)
	if not debug then return end

	ui.showMessage(tostring(msg))
end

local fadingOut = true
local alpha = 0.5 -- initial alpha 50%
--d_message("Initial Alpha: " .. alpha)


local function d_print(fname, msg)
	if not debug then return end

	if fname == nil then
		fname = "\x1b[35mnil"
	end

	if msg == nil then
		msg = "\x1b[35mnil"
	end

	print("\n\t\x1b[33;3m" .. tostring(fname) .. "\n\t\t\x1b[33;3m" .. tostring(msg) .. "\n\x1b[39m")
end

local function reverseTable(t)
    local reversed = {}
    for i = #t, 1, -1 do
        table.insert(reversed, t[i])
    end
    return reversed
end

local function updateAlpha()
    --local alpha = alpha
    if fadingOut and alpha >= 0.5 then
        alpha = alpha - 0.1
        if alpha <= 0.5 then
            fadingOut = false
        end
    else
        alpha = alpha + 0.1
        if alpha >= 1 then
            if alpha > 1 then alpha = 1 end
            fadingOut = true
        end
    end
end

-- Function to calculate size based on iconSize without children content
local function calculateDynamicSize(iconSize, pad)
    local padding = pad and 6 or 0
    
    -- Use iconSize directly for width
    local width = (iconSize+padding) or 30  -- Default to 30 if iconSize is nil
  
    -- Calculate total height using the logic from previous elements
    local fx_textSize = iconSize and (iconSize * 0.3+1)*2 or 10
    local fx_timeRemainSize = iconSize and iconSize * 0.3 + 1 or 10

    -- Total height is the sum of the text size, icon size, and timer size
    local totalHeight = fx_textSize + width + fx_timeRemainSize

    return v2(width, totalHeight)  -- Return as a vector
end

local function getContentKeys(contentLayer, debugF)
    local contentNames = {}
    local printLog = debugF or false
    for i = 1, #contentLayer do
        contentNames[i] = contentLayer[i].name
        if printLog then
            print('widget_name:',contentLayer[i].name,'at Index: ',i)
            --traverseTable(contentNames)
            if contentLayer[i].content then
                print('  `--ChildWidget_name: ', contentLayer[i].content[1].name )
            end
        end
    end
    return contentNames
end

local dummyLayout = ui.content {
    {
        name = 'someString',
        type = ui.TYPE.Image,
        props = {
            position = v2(0,0),
            size = v2(24, 24),
            relativePosition = v2(0,0),
            relativeSize = v2(0,0),
            anchor = v2(0,0),
            visible = true,
            alpha = 1,
            inheritAlpha = false,
            resource = ui.texture({path = 'white'})
        },
        userdata = {
        --some userdata
            --Duration = fx.duration,
        },
        events = {
        -- Some events perhaps mouseover Tooltip
        },
    },
}


local function getAlignment(alignment)
    return alignment and ui.ALIGNMENT.Start or ui.ALIGNMENT.End
end

local function nilCheck(tbl, ...)
    local value = tbl
    for _, key in ipairs({...}) do
        value = value and value[key]  -- Only proceed if the current level isn't nil
        if value == nil then
            return nil  -- Return nil if any key level does not exist
        end
    end
    return value  -- Return the final value if all keys were valid
end

-- Function to set up mouse events for a given flexWrapElement
local function setupMouseEvents(flexWrapElement)
    flexWrapElement.layout.events = {
        mousePress = async:callback(function(coord, layout)
            layout.userData.doDrag = true
            layout.userData.lastMousePos = coord.position
            print("mouseclicked!", coord.position, layout.name)
        end),
        mouseRelease = async:callback(function(_, layout)
            layout.userData.doDrag = false
            print("mousereleased!")
        end),
        mouseMove = async:callback(function(coord, layout)
            if not layout.userData.doDrag then return end
            local props = layout.props
            props.position = props.position - (layout.userData.lastMousePos - coord.position)
            flexWrapElement:update()
            layout.userData.lastMousePos = coord.position
        end),
    }
end

-- Function to update flexWrap properties
local function updateFlexWrapProps(flexWrap, rowsOfIcons)
    if nilCheck(flexWrap, "props", "size") and nilCheck(flexWrap, "props", "arrange") then
        flexWrap.props.size = com.calculateRootFlexSize(rowsOfIcons)
        flexWrap.props.arrange = ui.ALIGNMENT.Center
    end
end

local function grabIndexes(tbl, x)
    local result = {}
    -- Ensure x doesn't exceed the table size
    local limit = math.min(x, #tbl)
    
    -- Loop through the first x elements and insert them into result
    for i = 1, limit do
        result[i] = tbl[i]
    end
    
    return result
end


-- Initialize Buff and Debuff Layouts
local rootLayoutDebuffs, wrapFxIconsDebuffs = com.createRootFlexLayouts(iconPadding and 'pad', iconSize, com.fltDebuffTimers)
rootLayoutDebuffs = grabIndexes(rootLayoutDebuffs,buffLimit)
wrapFxIconsDebuffs = grabIndexes(wrapFxIconsDebuffs,buffLimit)
local rowsOfDebuffIcons = com.flexWrapper(rootLayoutDebuffs, { iconsPerRow = rowLimit, Alignment = getAlignment(debuffAlign) })
local debuff_FlexWrap = com.ui.createFlex(rowsOfDebuffIcons, false)
updateFlexWrapProps(debuff_FlexWrap, rowsOfDebuffIcons)
local debuff_FlexWrapElement = com.ui.createElementContainer(debuff_FlexWrap)

-- Handle nil on initialization
local debuffPosition = buffPositions and buffPositions.debuffPos or v2(0, 2 * iconSize)

debuff_FlexWrapElement.layout.props.position = debuffPosition
setupMouseEvents(debuff_FlexWrapElement)

local rootLayoutBuffs, wrapFxIconsBuffs = com.createRootFlexLayouts(iconPadding and 'pad', iconSize, com.fltBuffTimers)
rootLayoutDebuffs = grabIndexes(rootLayoutBuffs,buffLimit)
wrapFxIconsDebuffs = grabIndexes(wrapFxIconsDebuffs,buffLimit)
local rowsOfBuffIcons = com.flexWrapper(rootLayoutBuffs, { iconsPerRow = rowLimit, Alignment = getAlignment(buffAlign) })
local buff_FlexWrap = com.ui.createFlex(rowsOfBuffIcons, false)
updateFlexWrapProps(buff_FlexWrap, rowsOfBuffIcons)
local Buff_FlexWrapElement = com.ui.createElementContainer(buff_FlexWrap)

-- Handle nil on initialization
local buffPosition = buffPositions and buffPositions.buffPos or v2(0, 2 * iconSize)

Buff_FlexWrapElement.layout.props.position = buffPosition
setupMouseEvents(Buff_FlexWrapElement)

--Funtion whether to display box around icons. 
local function getBoxSetting()
    if not showBox then
        Buff_FlexWrapElement.layout.props.alpha = 0
		debuff_FlexWrapElement.layout.props.alpha = 0
    else 
        Buff_FlexWrapElement.layout.props.alpha = 0.2
		debuff_FlexWrapElement.layout.props.alpha = 0.2
    end
end

getBoxSetting()


-- Function that updates both Buffs and Debuffs in UI
local function updateUI_Element()
    -- Destroy previous tooltips
    com.destroyTooltip(true)
	getBoxSetting()

    -- Update debuffs
    rootLayoutDebuffs, wrapFxIconsDebuffs = com.createRootFlexLayouts(iconPadding and 'pad', iconSize, com.fltDebuffTimers)
    rootLayoutDebuffs = grabIndexes(rootLayoutDebuffs,buffLimit)
    wrapFxIconsDebuffs = grabIndexes(wrapFxIconsDebuffs,buffLimit)
    rowsOfDebuffIcons = com.flexWrapper(rootLayoutDebuffs, { iconsPerRow = rowLimit, Alignment = getAlignment(debuffAlign) })
    debuff_FlexWrap = com.ui.createFlex(rowsOfDebuffIcons, false)
    updateFlexWrapProps(debuff_FlexWrap, rowsOfDebuffIcons)

    -- Update buffs
    rootLayoutBuffs, wrapFxIconsBuffs = com.createRootFlexLayouts(iconPadding and 'pad', iconSize, com.fltBuffTimers)
    rootLayoutBuffs = grabIndexes(rootLayoutBuffs,buffLimit)
    wrapFxIconsBuffs = grabIndexes(wrapFxIconsBuffs,buffLimit)
    rowsOfBuffIcons = com.flexWrapper(rootLayoutBuffs, { iconsPerRow = rowLimit, Alignment = getAlignment(buffAlign) })
    buff_FlexWrap = com.ui.createFlex(rowsOfBuffIcons, false)
    updateFlexWrapProps(buff_FlexWrap, rowsOfBuffIcons)

    -- Get current layouts for buffs and debuffs
    local curDebuff_FlexWrapElement = debuff_FlexWrapElement.layout  -- Debuffs layout
    local curBuff_FlexWrapElement = Buff_FlexWrapElement.layout    -- Buffs layout (may need a separate flexWrapElement)

    -- Update debuff content
    local actualIconSz = calculateDynamicSize(iconSize,iconPadding)
    local buffBoxSize = v2(actualIconSz.x*rowLimit, actualIconSz.y*(util.round(buffLimit/rowLimit)))
    curDebuff_FlexWrapElement.content = ui.content{
        debuff_FlexWrap or showBox and {props = {size = buffBoxSize}} or {}
    }
    
    -- Update buff content
    curBuff_FlexWrapElement.content = ui.content{
        buff_FlexWrap or showBox and {props = {size = buffBoxSize}} or {}
    }

    -- Update the alpha value (flashing effect)
    updateAlpha()

    -- Update alpha for debuff icons
    for i, layout in ipairs(rootLayoutDebuffs) do
        if layout.userdata.Duration and layout.userdata.fx.durationLeft < 10 then
            wrapFxIconsDebuffs[i].props.alpha = alpha
        end
    end

    -- Update alpha for buff icons
    for i, layout in ipairs(rootLayoutBuffs) do
        if layout.userdata.Duration and layout.userdata.fx.durationLeft < 10 then
            wrapFxIconsBuffs[i].props.alpha = alpha
        end
    end

    -- Update both debuff and buff flexWrap elements
    debuff_FlexWrapElement:update()
	Buff_FlexWrapElement:update()
end

local buffElement = {}


local function startUpdating()
    --timer = time.runRepeatedly(updateUI_Element, 5 * time.second, { type = time.GameTime }) --5 is a slow pulse, 2 is a quick pulse. Perhaps increase speed to 2, under 5s duration remaining. 
    timer = time.runRepeatedly(updateUI_Element, 4 * time.second, { type = time.GameTime })
end

local function stopUpdating()
    if timer then
        timer() -- Makes the timer stop
        timer = nil
        alpha = 1 -- Reset alpha to zero opacity when stopping
		--imageTest = imageContent()
    end
end

local function onKeyPress(key)
	local tempKeyBind = input.KEY.G -- Perhaps use this key to toggle the UI on/off

--[[ 	if (not playerSettings:get("modEnable")) or (key.code ~= tempKeyBind) or core.isWorldPaused()  then return end
	if tempKeyBind == input.KEY.G then
		if buffElement then
			buffElement:destroy()
			buffElement = nil
			stopUpdating()
		else
			--buffElement = ui.create(newFlexRow)
			startUpdating()
		end
	end ]]

    local SavePositions = input.KEY.Equals
    local resetPositions = input.KEY.Minus
    if (not playerSettings:get("modEnable")) or (key.code ~= SavePositions) and (key.code ~= resetPositions)  or core.isWorldPaused()  then return end

    local buffPos = Buff_FlexWrapElement.layout.props.position
    local debuffPos = debuff_FlexWrapElement.layout.props.position

    if key.code == SavePositions then
        uiPositions:set("BuffPositions",{buffPos = buffPos, debuffPos = debuffPos})
        print(uiPositions:get("BuffPositions").debuffPos)

    end

    if key.code == resetPositions then
        uiPositions:set("BuffPositions",{buffPos = v2(0,0), debuffPos = v2(0,iconSize*2)}) --Consider getting relative position
        if debuff_FlexWrapElement then debuff_FlexWrapElement.layout.props.position = uiPositions:get("BuffPositions").debuffPos; debuff_FlexWrapElement:update() end
        if Buff_FlexWrapElement then Buff_FlexWrapElement.layout.props.position = uiPositions:get("BuffPositions").buffPos; Buff_FlexWrapElement:update() end
        --print(xRes)
        print(uiPositions:get("BuffPositions").debuffPos)
    end

end

local function onKeyRelease(key)

end

local function onUpdate(dt)

end

local function onSave()
end

local function onLoad()

end

startUpdating()

return {
	engineHandlers = {
		onKeyPress = onKeyPress,
		onKeyRelease = onKeyRelease,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
	}
}
