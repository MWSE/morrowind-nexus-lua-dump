local types = require("openmw.types")
local core = require("openmw.core")
local storage = require("openmw.storage")
local l10n = core.l10n("pursuit", "en")
---------------------------------------------------------------------------------------------
local thisHandler = {}
---------------------------------------------------------------------------------------------
thisHandler.name = "disableCreaturePursue"
---------------------------------------------------------------------------------------------
function thisHandler:fn(data)
    -- Only handle creatures
    if data.pursuer.type ~= types.Creature then
        return true
    end

    local record = types.Creature.records[data.pursuer.recordId]
    if not record then
        return true
    end

    local settings              = storage.globalSection("Settings!_PursuitExtra_!")
    local disableCreaturePursue = settings:get("disableCreaturePursue")
    local enableSpecialCreature = settings:get("enableSpecialCreature")

    --[[Credit: ShulShagana]]
    --[[https://www.nexusmods.com/morrowind/mods/56333]]
    local isHumanoid = record.type == types.Creature.TYPE.Humanoid
    if (record.isBiped or record.canUseWeapons or isHumanoid) and enableSpecialCreature then
        return true
    end

    if disableCreaturePursue then
        -- world.players[1]:sendEvent('ShowMessage', { message = "Creatures cannot pursue" })
        return false
    end

    return true
end
---------------------------------------------------------------------------------------------
thisHandler.settings = {
    {
        key = "disableCreaturePursue",
        renderer = "checkbox",
        name = l10n("settings_group2_setting1_name"),
        description = l10n("settings_group2_setting1_desc"),
        default = true,
        argument = {
            trueLabel = core.getGMST("sYes"),
            falseLabel = core.getGMST("sNo")
        }
    },
    {
        key = "enableSpecialCreature",
        renderer = "checkbox",
        name = l10n("settings_group2_setting2_name"),
        description = l10n("settings_group2_setting2_desc"),
        default = true,
        argument = {
            trueLabel = core.getGMST("sYes"),
            falseLabel = core.getGMST("sNo")
        }
    },
}
---------------------------------------------------------------------------------------------
return thisHandler
