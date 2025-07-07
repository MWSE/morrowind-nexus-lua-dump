local I = require('openmw.interfaces')
local util  = require('openmw.util')
local types = require('openmw.types')
local async = require("openmw.async")
local self  = require('openmw.self')
local input = require('openmw.input')
local ui    = require('openmw.ui')

input.registerAction {
    key = 'Light',
    type = input.ACTION_TYPE.Boolean,
    l10n = 'TorchHotkey',
    defaultValue = false
}

--======================================================================================================================

-- SETTINGS ----------------------------------------------------------------------------------------------------------

--======================================================================================================================
I.Settings.registerPage {
    key = 'TorchHotkeyPage',
    l10n = 'TorchHotkey',
    name = 'Torch Hotkey',
    description = 'Adds a hotkey for torches and other light source items.',
}
I.Settings.registerGroup {
    key = 'TorchHotkeySettings',
    page = 'TorchHotkeyPage',
    l10n = 'TorchHotkeyPage',
    name = 'Settings',
    permanentStorage = true,
    settings = {
        {
            key = "ToggleLight",
            renderer = "inputBinding",
            default = "ToggleLightButtonKey",
            name = "Toggle Light",
            description = 'Tap to get out/put away light, hold to select specific light.',
            argument = {
                type = "action",
                key = "Light"
            }
        }
    }
}

--======================================================================================================================

-- LOGIC -------------------------------------------------------------------------------------------------------------

--======================================================================================================================
local torchUIWaitTime = 0.25
local iconSize = 30

local white = ui.texture { path = 'white' }

local lastEquippedLeft = nil
local lastEquippedRight = nil
local lastStance = types.Actor.STANCE.Nothing
local lastTorch = nil
local isTorchKeyHeld = false
local torchUITimer = 0.0
local torchUIMenu = nil
local torchMenuInfo = {
    index = -1,
    size = -1
}


local function getBestLight(inv)
    local bestLight = nil
    local lights = inv:getAll(types.Light)

    for _, light in pairs(lights) do
        if types.Light.record(light).isCarriable and not types.Light.record(light).isNegative
        and (not bestLight or types.Item.itemData(light).condition > types.Item.itemData(bestLight).condition) then
            bestLight = light
        end
    end
    return bestLight
end

local function isWeaponTypeOneHanded(weaponType)
    if weaponType == types.Weapon.TYPE.Arrow
    or weaponType == types.Weapon.TYPE.AxeOneHand
    or weaponType == types.Weapon.TYPE.BluntOneHand
    or weaponType == types.Weapon.TYPE.Bolt
    or weaponType == types.Weapon.TYPE.LongBladeOneHand
    or weaponType == types.Weapon.TYPE.MarksmanThrown
    or weaponType == types.Weapon.TYPE.ShortBladeOneHand
    then
        return true
    end
    return false
end

local function canUseTorch(stance, equippedRight)
    if stance == types.Actor.STANCE.Spell
    or (stance == types.Actor.STANCE.Weapon and (
            not equippedRight
         or not isWeaponTypeOneHanded(types.Weapon.record(equippedRight).type)
        ))
    then
        return false
    end
    return true
end

input.registerActionHandler('Light', async:callback(function(val)
    local forceTorch = false
    isTorchKeyHeld = val
    if val == false then
        torchUITimer = 0.0
        if torchUIMenu then
            I.Camera.enableZoom("THK")
            local lights = types.Actor.inventory(self):getAll(types.Light)
            lastTorch = lights[torchMenuInfo.index + 1]
            torchUIMenu:destroy()
            torchUIMenu = nil
            torchMenuInfo = {
                index = -1,
                size = -1
            }
            forceTorch = true
        end
    else
        torchUITimer = 0
        return
    end

    local equipped = types.Actor.equipment(self)
    local equippedLeft = equipped[types.Actor.EQUIPMENT_SLOT.CarriedLeft]
    local equippedRight = equipped[types.Actor.EQUIPMENT_SLOT.CarriedRight]

    -- TODO add case for stance transitions to avoid permanent stance change when mashing light button
    if forceTorch == false and equippedLeft and equippedLeft.type == types.Light and canUseTorch(types.Actor.stance(self), equippedRight) then
        lastTorch = equippedLeft
        -- putting away torch
        -- add case for stacking when condition is the same (change in item id)
        if not canUseTorch(lastStance, lastEquippedRight) then
            equipped[types.Actor.EQUIPMENT_SLOT.CarriedRight] = lastEquippedRight
            types.Actor.setStance(self, lastStance)
        end
        equipped[types.Actor.EQUIPMENT_SLOT.CarriedLeft] = lastEquippedLeft
        types.Actor.setEquipment(self, equipped)
    else
        -- getting out torch
        if forceTorch == false and equippedLeft and equippedLeft.type == types.Light then
            lastTorch = equippedLeft
        end
        local light = lastTorch
        if not light then
            light = getBestLight(types.Actor.inventory(self))
        end

        if not light then
            ui.showMessage('You have no lights')
            return
        end

        if forceTorch == false then
            lastEquippedLeft = equippedLeft
            lastStance = types.Actor.stance(self)
        end
        lastEquippedRight = equippedRight
        if not canUseTorch(types.Actor.stance(self), equippedRight) then
            types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        end
        equipped[types.Actor.EQUIPMENT_SLOT.CarriedLeft] = light
        types.Actor.setEquipment(self, equipped)
    end
end))

return {
    engineHandlers = {
        onUpdate = function(dt)
            if isTorchKeyHeld == true then
                torchUITimer = torchUITimer + dt
                if torchUITimer >= torchUIWaitTime and torchMenuInfo.size ~= 0 then
                    if not torchUIMenu then
                        I.Camera.disableZoom("THK")
                        local lights = types.Actor.inventory(self):getAll(types.Light)
                        torchMenuInfo.size = #lights
                        if torchMenuInfo.size == 0 then return end
                        local layout = {
                            template = I.MWUI.templates.boxTransparent,
                            type = ui.TYPE.Container,
                            layer = 'HUD',
                            props = {
                                size = util.vector2(iconSize * 5, iconSize * torchMenuInfo.size),
                                relativePosition = util.vector2(0.25, 0.5),
                                anchor = util.vector2(0.5, 0.5),
                                alpha = 0.5
                            },
                            content = ui.content{}
                        }
                        torchMenuInfo.index = 0
                        layout.content:add{
                            type = ui.TYPE.Image,
                            name = 'highlight',
                            props = {
                                resource = white,
                                size = util.vector2(iconSize * 5, iconSize),
                                color = util.color.rgb(0.63, 0.52, 0.30),
                                position = util.vector2(0.0, torchMenuInfo.index * iconSize)
                            }
                        }
                        for index, light in pairs(lights) do
                            -- remembering last selected torch index
                            if lastTorch == light then
                                torchMenuInfo.index = index - 1
                                layout.content.highlight.props.position = util.vector2(0.0, torchMenuInfo.index * iconSize)
                            end
                            -- item image
                            layout.content:add{
                                type = ui.TYPE.Image,
                                props = {
                                    size = util.vector2(iconSize, iconSize),
                                    resource = ui.texture{path = light.type.records[light.recordId].icon},
                                    inheritAlpha = false,
                                    position = util.vector2(0.0, (index - 1) * iconSize)
                                }
                            }
                            -- total condition bar
                            layout.content:add{
                                type = ui.TYPE.Image,
                                props = {
                                    size = util.vector2(iconSize * 5 - 60, 10),
                                    resource = white,
                                    color = util.color.rgb(0.0, 0.0, 0.0),
                                    position = util.vector2(40, (index - 1) * iconSize + 15),
                                    anchor = util.vector2(0.0, 0.5)
                                }
                            }
                            -- condition bar
                            layout.content:add{
                                type = ui.TYPE.Image,
                                props = {
                                    size = util.vector2((iconSize * 5 - 60) * (types.Item.itemData(light).condition / types.Light.record(light).duration), 10),
                                    resource = white,
                                    inheritAlpha = false,
                                    color = util.color.rgb(0.35, 0.03, 0.01),
                                    position = util.vector2(40, (index - 1) * iconSize + 15),
                                    anchor = util.vector2(0.0, 0.5)
                                }
                            }
                        end
                        torchUIMenu = ui.create(layout)
                        torchUIMenu:update()
                    end
                end
            end
        end,
        onMouseWheel = function(vert)
            if torchUIMenu then
                torchMenuInfo.index = torchMenuInfo.index - math.floor(vert)
                torchMenuInfo.index = torchMenuInfo.index % torchMenuInfo.size
                torchUIMenu.layout.content.highlight.props.position = util.vector2(0.0, torchMenuInfo.index * iconSize)
                torchUIMenu:update()
            end
        end
    },
    interfaceName = 'TorchHotkey',
    interface = {
        version = 1.0,
    }
}