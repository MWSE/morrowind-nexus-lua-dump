local ui = require('openmw.ui')
local input = require('openmw.input')
local util = require('openmw.util')
local self = require('openmw.self')
local types = require('openmw.types')
local aux_util = require('openmw_aux.util')

local MOUSE_WHEEL = 2
local HIGHLIGHT_COLOR = util.color.rgb(0, 1, 0,1)
local WHEEL_SIZE = 0.35
local WHEEL_INNER_DIAMETER = 0.7

local function invertList(list)
    local result = {}
    for i, v in ipairs(list) do
        result[v] = i
    end
    return result
end

local WEAPON_ORDER = invertList {
    'rw_bomb_throw',
    'rw_gun_01_auto',
    'rw_light_sword',
    'rw_rifle_01_auto',
    'rw_rifle_02_auto',
    'rw_rocketlauncher_01',
    'rw_sniper_01',
    'rw_spear'
}

local AMMO_TYPES = invertList { types.Weapon.TYPE.Arrow, types.Weapon.TYPE.Bolt }

local function collectWeapons()
    local inventory = types.Actor.inventory(self)
    local weapons = inventory:getAll(types.Weapon)
    return aux_util.mapFilterSort(weapons, function(w)
        if AMMO_TYPES[types.Weapon.record(w).type] then return nil end
        return WEAPON_ORDER[w] or math.huge
    end)
end

local function equipWeapon(weapon)
    local equipment = types.Actor.getEquipment(self)
    equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight] = weapon
    types.Actor.setEquipment(self, equipment)
end

local function renderWheel(weaponList, selected)
    local root = {
        layer = 'HUD',
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
            size = util.vector2(1, 1) * math.min(ui.screenSize().x, ui.screenSize().y) * WHEEL_SIZE,
        },
        content = ui.content {},
    }
    local background = {
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = 'Textures/ui/weapon_wheel.dds' },
            color = util.color.rgba(22, 154, 168, 1),
            relativeSize = util.vector2(1, 1),
        },
    }
    root.content:add(background)
    local itemSize = math.min(WHEEL_INNER_DIAMETER * math.pi / #weaponList / math.sqrt(2),
        0.5 * (1 - WHEEL_INNER_DIAMETER))
    for i, weapon in ipairs(weaponList) do
        local angle = 2 * math.pi * (i - 1) / #weaponList + math.pi * 1.5
        local record = types.Weapon.record(weapon)
        local itemLayout = {
            type = ui.TYPE.Image,
            props = {
                relativeSize = util.vector2(1, 1) * itemSize,
                relativePosition = util.vector2(0.5, 0.5) +
                    util.vector2(math.cos(angle), math.sin(angle)) * WHEEL_INNER_DIAMETER * 0.5,
                anchor = util.vector2(0.5, 0.5),
                resource = ui.texture { path = record.icon },
                color = selected == weapon and HIGHLIGHT_COLOR or util.color.rgb(1, 1, 1)
            },
        }
        root.content:add(itemLayout)
    end
    return root
end

local weaponList = {}
local element = nil
local selected = nil
local mouseAnchor = util.vector2(0, 0)

return {
    engineHandlers = {
        onUpdate = function()
            local active = input.isMouseButtonPressed(MOUSE_WHEEL)
            if not element and active then
                weaponList = collectWeapons()
                mouseAnchor = util.vector2(0, 0)
                selected = nil
                element = ui.create(renderWheel(weaponList, selected))
            elseif element and not active then
                if selected then equipWeapon(selected) end
                element:destroy()
                element = nil
            elseif element and active then
                mouseAnchor = mouseAnchor +
                    util.vector2(input.getMouseMoveX(), input.getMouseMoveY()):ediv(ui.screenSize())
                weaponList = collectWeapons()
                local mouseAngle = math.fmod((math.atan2(mouseAnchor.y, mouseAnchor.x) + math.pi * 2.5), 2 * math.pi)
                local selectedIndex = math.floor(mouseAngle / 2 / math.pi * #weaponList) + 1
                if mouseAnchor:length() > 0.1 then
                    selected = weaponList[selectedIndex]
                end
                element.layout = renderWheel(weaponList, selected)
                element:update()
            end
        end,
        onFrame = function()
            if element then
                self.controls.pitchChange = 0
                self.controls.yawChange = 0
            end
        end,
    }
}
