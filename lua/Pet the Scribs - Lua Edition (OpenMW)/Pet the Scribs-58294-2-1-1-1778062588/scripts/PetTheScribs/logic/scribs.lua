local world = require("openmw.world")
local core = require("openmw.core")
local storage = require("openmw.storage")

local settings = storage.globalSection("SettingsPetTheScribs_settings")
local l10n = core.l10n("PetTheScribs")

local function normalScrib(actor, scrib, options)
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
    local activeEffects = actor.type.activeEffects(actor)
    local diseaseResist = options.resistEffect
        and activeEffects:getEffect(options.resistEffect).magnitude / 100
        or 0
    local proc = math.random() < options.diseaseChance - diseaseResist

    local alreadyDiseased = actor.type.activeSpells(actor):isSpellActive(options.disease.id)

    local telekinesisActive = activeEffects:getEffect(core.magic.EFFECT_TYPE.Telekinesis).magnitude > 0

    if proc and not alreadyDiseased and not telekinesisActive then
        actor.type.spells(actor):add(options.disease.id)
        actor:sendEvent("ShowMessage", {
            message = l10n("msg_caughtDisease", { disease = options.disease.name })
        })
    end
end

local function iceScrib(actor, scrib, options)
    local telekinesisActive = actor.type.activeEffects(actor):getEffect("telekinesis").magnitude > 0
    if not telekinesisActive then
        actor.type.activeSpells(actor):add({
            id = "frostbite",
            effects = { 0 }
        })
    end
end

Scribs = {
    -- vanilla
    ["scrib"] = normalScrib,
    ["scrib diseased"] = function(actor, scrib, options)
        options.diseaseChance = settings:get("diseaseChance")
        options.disease = core.magic.spells.records["droops"]
        options.resistEffect = core.magic.EFFECT_TYPE.ResistCommonDisease
        diseasedScrib(actor, scrib, options)
    end,
    ["scrib_vaba-amus"] = normalScrib,
    ["scrib blighted"] = function(actor, scrib, options)
        options.diseaseChance = settings:get("blightChance")
        options.disease = core.magic.spells.records["droops"]
        options.resistEffect = core.magic.EFFECT_TYPE.ResistBlightDisease
        diseasedScrib(actor, scrib, options)
    end,
    ["scrib_rerlas"] = normalScrib,

    -- ice scrib
    -- https://www.nexusmods.com/morrowind/mods/51338
    ["icescrib"] = iceScrib,

    -- Creatures and Critters
    -- https://www.nexusmods.com/morrowind/mods/54518
    ["aa_cr_horned_scrib"] = normalScrib,

    -- Diverse Scribs
    -- https://www.nexusmods.com/morrowind/mods/56176
    ["scrib_2"] = normalScrib,
    ["scrib diseased_2"] = function(actor, scrib, options)
        options.diseaseChance = settings:get("diseaseChance")
        options.disease = core.magic.spells.records["droops"]
        options.resistEffect = core.magic.EFFECT_TYPE.ResistCommonDisease
        diseasedScrib(actor, scrib, options)
    end,
    ["ttooth_scrib_2"] = normalScrib,

    -- TriangleTooth's Ecology Mod
    -- https://www.nexusmods.com/morrowind/mods/47061
    ["ttooth_scrib"] = normalScrib,

    -- Utility Spells
    -- https://www.nexusmods.com/morrowind/mods/58288
    ["scrib_summon"] = normalScrib,
}
