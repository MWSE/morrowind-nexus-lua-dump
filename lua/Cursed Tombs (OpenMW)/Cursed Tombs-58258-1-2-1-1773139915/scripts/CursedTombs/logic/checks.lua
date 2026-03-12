local storage = require("openmw.storage")

local sectionChecks = storage.globalSection("SettingsCursedTombs_checks")

function IgnoredContainer(trggeredConts, activatedConts, obj)
    return trggeredConts[obj.id]
        or (activatedConts[obj.cell.id] and activatedConts[obj.cell.id][obj.id])
        or obj.mwscript
end

function GotLucky(actor)
    local baseChance = math.random(
        sectionChecks:get("minBaseSafeChance"),
        sectionChecks:get("maxBaseSafeChance")
    )
    local attrs = actor.type.stats.attributes
    local safeChance = baseChance +
        attrs.luck(actor).modified * sectionChecks:get("luckModifier") +
        attrs.agility(actor).modified * sectionChecks:get("agilityModifier")

    return math.random(100) <= safeChance
end

function HasKey(obj, actor)
    local keyRecord = obj.type.getKeyRecord(obj)
    if not keyRecord then return false end

    local inv = actor.type.inventory(actor)
    return inv:find(keyRecord.id) ~= nil
end

function IsCity(obj)
    return obj.cell:hasTag("NoSleep")
end
