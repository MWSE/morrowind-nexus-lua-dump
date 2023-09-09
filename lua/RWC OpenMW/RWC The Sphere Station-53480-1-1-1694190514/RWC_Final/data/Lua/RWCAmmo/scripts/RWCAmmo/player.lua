local self = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')
local types = require('openmw.types')

local A = types.Actor
local W = types.Weapon

local displayed = {
    count = nil,
    icon = nil,
}

local function getCurrentAmmo(actor)
    local currentAmmo = {
        count = nil,
        icon = nil,
    }
    local ammo = A.getEquipment(actor, A.EQUIPMENT_SLOT.Ammunition)
    if ammo then
        currentAmmo.count = ammo.count
        local record = W.record(ammo)
        currentAmmo.icon = record.icon
    end

    return currentAmmo
end

local function formatAmmoCount(count)
    count = math.min(count, 9999)
    return tostring(count)
end

local backgroundIcon = ui.texture { path = 'icons/RWCAmmo/compass_ring.dds' }

local element = nil

local function renderUi(icon, count)
    if icon == nil then
        if element then element:destroy() end
        element = nil
        return
    end

    local layout = {
        layer = 'HUD',
        props = {
            size = util.vector2(80, 80),
            relativePosition = util.vector2(0.07, 0.35),
        },
        content = ui.content {}
    }
    layout.content:add {
        type = ui.TYPE.Image,
        props = {
            relativeSize = util.vector2(1, 1),
            resource = backgroundIcon,
        },
    }
    layout.content:add {
        type = ui.TYPE.Image,
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
            relativeSize = util.vector2(1, 1) * 0.73,
            resource = ui.texture { path = icon },
        },
    }
    layout.content:add {
        type = ui.TYPE.Text,
        props = {
            relativePosition = util.vector2(0, 0.65),
            text = formatAmmoCount(count),
            textColor = util.color.rgb(1, 0.467, 0.149),
            textSize = 24,
        }
    }

    if not element then
        element = ui.create(layout)
    else
        element.layout = layout
        element:update()
    end
end

local function update()
    local currentAmmo = getCurrentAmmo(self)
    if currentAmmo.icon == displayed.icon and currentAmmo.count == displayed.count then return end
    print(currentAmmo.count, currentAmmo.icon, displayed.count, displayed.icon)
    displayed = currentAmmo
    renderUi(displayed.icon, displayed.count)
end

return {
    engineHandlers = {
        onUpdate = update,
    },
}
