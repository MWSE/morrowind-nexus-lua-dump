local world = require("openmw.world")
local core = require("openmw.core")
local storage = require("openmw.storage")

local settings = storage.globalSection("SettingsPetTheScribs_settings")
local settingsOther = storage.globalSection("SettingsPetTheScribs_other")
local l10n = core.l10n("PetTheScribs")

local function doTheScribby(actor)
    if settingsOther:get("enableMessages") then
        actor:sendEvent("ShowMessage", { message = l10n("msg_scribPat", {}) })
    end
end

local function normalScrib(actor, scrib, options)
    doTheScribby(actor)

    local jellyCooldown = settings:get("jellyCooldown") * 60 * 60 -- in hours
    local lastJellyTime = options.lastJellyTimeList[scrib.id] or -jellyCooldown
    local currTime = world.getSimulationTime()

    local minJelly = settings:get("minJelly")
    local maxJelly = settings:get("maxJelly")
    local jellyCount = math.random(minJelly, maxJelly)

    if currTime > lastJellyTime + jellyCooldown and jellyCount > 0 then
        local jelly = world.createObject("ingred_scrib_jelly_01", jellyCount)
        local inv = actor.type.inventory(actor)
        ---@diagnostic disable-next-line: discard-returns
        jelly:moveInto(inv)

        options.lastJellyTimeList[scrib.id] = currTime
        actor:sendEvent("ShowMessage", {
            message = l10n("msg_jellyGot", { jellyCount = jellyCount })
        })
    end
end

local function diseasedScrib(actor, scrib, options)
    doTheScribby(actor)

    local proc = math.random() > options.diseaseChance
    local alreadyDiseased = actor.type.activeSpells(actor):isSpellActive(options.diseaseId)
    if proc and not alreadyDiseased then
        actor.type.spells(actor):add(options.diseaseId)
        actor:sendEvent("ShowMessage", {
            message = l10n("msg_caughtDisease", { disease = options.diseaseName })
        })
    end
end

local function iceScrib(actor, scrib, options)
    doTheScribby(actor)

    actor.type.activeSpells(actor):add({
        id = "frostbite",
        effects = { 0 }
    })
end

Scribs = {
    -- vanilla
    ["scrib"]              = normalScrib,
    ["scrib diseased"]     = function(actor, scrib, options)
        options.diseaseChance = settings:get("diseaseChance")
        options.diseaseId = "droops"
        options.diseaseName = "Droops"
        diseasedScrib(actor, scrib, options)
    end,
    ["scrib_vaba-amus"]    = normalScrib,
    ["scrib blighted"]     = function(actor, scrib, options)
        options.diseaseChance = settings:get("blightChance")
        options.diseaseId = "ash-chancre"
        options.diseaseName = "Ash-chancre"
        diseasedScrib(actor, scrib, options)
    end,
    ["scrib_rerlas"]       = normalScrib,

    -- ice scrib
    -- https://www.nexusmods.com/morrowind/mods/51338
    ["icescrib"]           = iceScrib,

    -- Creatures and Critters
    -- https://www.nexusmods.com/morrowind/mods/54518
    ["aa_cr_horned_scrib"] = normalScrib,
}
