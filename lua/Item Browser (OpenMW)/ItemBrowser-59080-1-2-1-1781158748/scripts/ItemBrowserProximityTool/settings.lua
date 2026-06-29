local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')

local l10n = core.l10n('ItemBrowserProximityTool')

local function textBox(text, onClick)
    local box = {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        props = { text = text },
                    },
                },
            },
        },
    }
    if onClick then
        box.events = {
            mouseClick = async:callback(onClick),
        }
    end
    return box
end

I.Settings.registerRenderer('ItemBrowserProximityTool/toggle', function(value, set, argument)
    argument = argument or {}
    local text = l10n(value == true and (argument.on or 'setting_on') or (argument.off or 'setting_off'))
    return textBox(text, function()
        set(value ~= true)
    end)
end)

I.Settings.registerGroup {
    key = 'Settings/ItemBrowserProximityTool/1_Tracking',
    page = 'ItemBrowser',
    l10n = 'ItemBrowserProximityTool',
    name = 'settings_group_proximity_tool',
    permanentStorage = true,
    order = 40,
    settings = {
        {
            key = 'TrackFavorites',
            renderer = 'ItemBrowserProximityTool/toggle',
            name = 'setting_track_favorites',
            description = 'setting_track_favorites_desc',
            default = true,
        },
        {
            key = 'TrackContainers',
            renderer = 'ItemBrowserProximityTool/toggle',
            name = 'setting_track_containers',
            description = 'setting_track_containers_desc',
            default = true,
        },
        {
            key = 'TrackActorInventories',
            renderer = 'ItemBrowserProximityTool/toggle',
            name = 'setting_track_actor_inventories',
            description = 'setting_track_actor_inventories_desc',
            default = false,
        },
        {
            key = 'ResolveUnresolvedContainers',
            renderer = 'ItemBrowserProximityTool/toggle',
            name = 'setting_resolve_unresolved_containers',
            description = 'setting_resolve_unresolved_containers_desc',
            default = false,
        },
    },
}
