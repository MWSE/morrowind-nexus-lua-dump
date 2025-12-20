-- chargeBar.lua
local ui      = require("openmw.ui")
local self    = require("openmw.self")
local types   = require("openmw.types")
local util    = require("openmw.util")
local core    = require("openmw.core")
local I       = require("openmw.interfaces")
local modInfo = require("Scripts.HUDweaponCharge.modInfo")
local storage = require("openmw.storage")
local async   = require('openmw.async')
local saveData = {}

-- Load user settings
local userInterfaceSettings = storage.playerSection("SettingsPlayer" .. modInfo.name)
local colorMenu = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Color")
local colorSetting = colorMenu:get("colorSetting")
local enable = userInterfaceSettings:get("modEnable")
local betterBar = userInterfaceSettings:get("betterBarSetting")
local persist = userInterfaceSettings:get("alwaysOn")
local HUD_LOCK = userInterfaceSettings:get("HUD_LOCK")
local xSett = userInterfaceSettings:get("xPos")
local ySett = userInterfaceSettings:get("yPos")
-- Local variables & Defaults
local v2 = util.vector2
local Actor = types.Actor
local Item = types.Item
local SLOT_CARRIED_RIGHT = Actor.EQUIPMENT_SLOT.CarriedRight
local iconSize = 30
local displayAreaY = ui.layers[1].size.y
local defaults = {xPos = 82, yPos = displayAreaY-12}
local DataBarHeight = 7
local UPDATE_INTERVAL = 0.15        -- update every 1 seconds

saveData.x = xSett or (betterBar and 12 or 82)
saveData.y = ySett or (displayAreaY - 12)

local function setCoord(v2)
    userInterfaceSettings:set("xPos",math.floor(v2.x))
    userInterfaceSettings:set("yPos",math.floor(v2.y))
end

local function saveGameData(vector2)
    saveData.x = vector2.x
    saveData.y = vector2.y
end
-- Getter for current right slot
local function getCurrentWeapon() return Actor.equipment(self)[SLOT_CARRIED_RIGHT] end
-- Small Progress Bar Creator
local function createSmallProgressBar(width, height, color, percent, opacity)
    local p = percent and math.max(0, math.min(1, percent)) or 1
    return {
        template = I.MWUI.templates.boxSolid,
        type     = ui.TYPE.Container,
        props    = { inheritAlpha = false, color = util.color.rgba(0, 0, 0, 0), alpha = opacity or 1.0 },
        content  = ui.content({
            {
                type  = ui.TYPE.Image,
                props = {
                    inheritAlpha = false,
                    alpha  = 0,
                    color  = util.color.rgb(color.r, color.g, color.b),
                    size   = util.vector2(width - 4, height - 4),
                    resource = ui.texture{
                        path   = 'textures/menu_bar_gray.dds',
                        size   = util.vector2(1, 8),
                        offset = util.vector2(0, 0)
                    }
                },
                content = ui.content({
                    {
                        type  = ui.TYPE.Image,
                        props = {
                            inheritAlpha = false,
                            alpha  = opacity or 1.0,
                            color  = util.color.rgb(color.r, color.g, color.b),
                            size   = util.vector2((width - 4) * p, height - 4),
                            resource = ui.texture{
                                path   = 'textures/menu_bar_gray.dds',
                                size   = util.vector2(1, 8),
                                offset = util.vector2(0, 0)
                            }
                        }
                    }
                })
            }
        })
    }
end

local function setupMouseEvents(element)
    element.layout.events = {
        mousePress = async:callback(function(coord, layout)
            if HUD_LOCK then return end
            layout.userData.doDrag = true
            layout.userData.lastMousePos = coord.position
        end),
        mouseRelease = async:callback(function(_, layout)
            if HUD_LOCK then return end
            local props = layout.props
            layout.userData.doDrag = false
            setCoord(props.position) --Setter for UI storage sections
            saveGameData(props.position) --Save func for data.
        end),
        mouseMove = async:callback(function(coord, layout)
            if HUD_LOCK then return end
            if not layout.userData.doDrag then return end
            local props = layout.props
            props.position = props.position - (layout.userData.lastMousePos - coord.position)
            element:update()
            layout.userData.lastMousePos = coord.position
        end),
    }
end

-- ROOT UI ELEMENT
local barRoot = ui.create {
    layer = HUD_LOCK and "HUD" or "Modal",
    name  = "ChargeBarHUD",
    props = {
        anchor = v2(0, 0),
        position = v2(saveData.x or defaults.xPos, saveData.y or defaults.yPos),
        size = v2(iconSize*1.2, DataBarHeight),
    },
    content = ui.content {},
    events = {},
    userData = {doDrag = false, lastMousePos = nil},
}
setupMouseEvents(barRoot)
-- UPDATE TIMER
local accumulator = 0

-- UPDATE FUNCTION
local function updateChargeBar()
    if not I.UI.isHudVisible() then
        barRoot.layout.content = ui.content({})
        barRoot:update()
        return
    end
    local weapon = getCurrentWeapon()

    local rec, itemData = nil, nil
    if weapon then
        rec      = weapon.type.records[weapon.recordId]
        itemData = Item.itemData(weapon)
    end

    if not weapon and not persist then
        barRoot.layout.content = ui.content({})
        barRoot:update()
        return
    end
    local ench = rec and rec.enchant and core.magic.enchantments.records[rec.enchant]
    local pct, bar -- initialized as nil, if applies is false, then content in bar(content) is nil
    if not ench and persist then
		bar = createSmallProgressBar(iconSize*1.2, DataBarHeight, colorSetting, 0, 1.0)
	elseif ench and persist then
		pct = (itemData and math.floor(itemData.enchantmentCharge) or 0) / ench.charge
		bar = createSmallProgressBar(iconSize*1.2, DataBarHeight, colorSetting, pct, 1.0)
    elseif ench and not persist then
        local applies = (ench.type == core.magic.ENCHANTMENT_TYPE.CastOnStrike) or (ench.type == core.magic.ENCHANTMENT_TYPE.CastOnUse)
        if applies then
            pct = (itemData and math.floor(itemData.enchantmentCharge) or 0) / ench.charge
            bar = createSmallProgressBar(iconSize*1.2, DataBarHeight, colorSetting, pct, 1.0)
        end
    end

    barRoot.layout.content = ui.content{bar}
    barRoot:update()
end

colorMenu:subscribe(async:callback(function(section, key)
    if key then
        if key == "colorSetting" then
            print("color setting changed..")
            colorSetting = colorMenu:get(key)
            print(colorSetting)
            updateChargeBar()
        end
    end
end))

-- Subscribe to color setting
userInterfaceSettings:subscribe(async:callback(function(section, key)
    if key then
        if key == "betterBarSetting" then
            betterBar = userInterfaceSettings:get(key)
            if betterBar then
                defaults.xPos = 12
            else
                defaults.xPos = 82
            end
            local vec = v2(defaults.xPos,defaults.yPos)
            barRoot.layout.props.position = vec
            saveGameData(vec)
            self:sendEvent("settingMenuUpdate", vec) --send event to update the UI position boxes
            updateChargeBar()
        elseif key == "alwaysOn" then
            persist = userInterfaceSettings:get(key)
            updateChargeBar()
        elseif key == "HUD_LOCK" then
            HUD_LOCK = userInterfaceSettings:get(key)
            if HUD_LOCK then
                barRoot.layout.layer = "HUD"
                saveData.layer = "HUD"
            else
                barRoot.layout.layer = "Modal"
                saveData.layer = "Modal"
            end
            updateChargeBar()
        elseif key == "R_FLAG" then
            --print('RESETTING INSIDE THE PLAYER SCRIPT>>>>>') --for Debugging
            local defaultVec = v2(defaults.xPos, defaults.yPos)
            barRoot.layout.props.position = defaultVec
            saveGameData(defaultVec)
            updateChargeBar()
        elseif key == "modEnable" then
            enable = userInterfaceSettings:get(key)
        end
    end
end))

-- oneShot flag for immediate update when HUD becomes visible
local oneShot = true

local function onUpdate(dt)
    if not enable then return end
    if I.UI.isHudVisible() then
        -- 1st update immediately when HUD becomes visible
        if oneShot then
            updateChargeBar()
            oneShot = false
        end
        accumulator = accumulator + dt
        if accumulator >= UPDATE_INTERVAL then
            accumulator = 0
            updateChargeBar()
        end
    else
        accumulator = 0
        oneShot = true -- reset oneShot for when HUD becomes visible again
        barRoot.layout.content = ui.content({})
        barRoot:update()
    end
end

local function onSave()
    -- returns saved data..
    if not enable then return end
    return saveData
end

local function settingMenuUpdate(data)
    setCoord(data)
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onLoad = function(data)
            if not enable then return end
            -- saveData = data or nil
            if saveData then
                saveData.xPos = data and data.xPos
                saveData.xPos = data and data.yPos
            end
            updateChargeBar()
        end,
        onSave = onSave,
    },
    eventHandlers = {
        settingMenuUpdate = settingMenuUpdate,
    },
}
