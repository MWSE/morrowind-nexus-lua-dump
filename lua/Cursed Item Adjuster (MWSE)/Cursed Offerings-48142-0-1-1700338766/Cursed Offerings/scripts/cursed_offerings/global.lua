local world = require "openmw.world"
local types = require "openmw.types"
local util = require "openmw.util"
local core = require "openmw.core"
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local advSetting = require("scripts.cursed_offerings.advancedSettings")
local globalSection = storage.globalSection("Settings_cursed_offerings_Options_Key_KINDI")
local summonPosition = require("scripts.cursed_offerings.constants").summonPosition
local daedricCreatures = require("scripts.cursed_offerings.constants").daedricCreatures
local daedricPrinceStatue = require("scripts.cursed_offerings.constants").daedricPrinceStatue

local trans = util.transform

local function pickRandom(t)
    return t and t[math.random(#t)] or nil
end

local function spawnDaedra(daedricPrince, objectValue)
    local daedra = nil
    local summonType = globalSection:get("Summon Type")

    if not globalSection:get("Mod Status") then
        summonType = nil
    end

    if summonType == "settings_name_matching" then
        daedra = pickRandom(daedricCreatures[daedricPrince]) or
            "dremora_lord" -- //unknown daedric prince use the default
    elseif summonType == "settings_name_randomised" then
        daedra = pickRandom(daedricCreatures["Random"])
    elseif summonType == "settings_name_default" then
        daedra = "dremora_lord"
    elseif summonType == "settings_name_itemvalue" then
        if objectValue < 100 then
            daedra = pickRandom(daedricCreatures["GR1"])
        elseif objectValue >= 100 and objectValue < 250 then
            daedra = pickRandom(daedricCreatures["GR2"])
        elseif objectValue >= 250 then
            daedra = pickRandom(daedricCreatures["GR3"])
        end
    elseif summonType == "settings_name_nothing" then
        return nil
    else
        -- // fallback summon
        daedra = "dremora_lord"
    end


    local spawned_daedra
    local success, err = pcall(function() spawned_daedra = world.createObject(daedra) end)

    return spawned_daedra, success, err
end

local function determineDaedricPrince(cell)
    for _, object in pairs(cell:getAll()) do
        local daedricPrince = daedricPrinceStatue[object.recordId]
        if daedricPrince then
            return daedricPrince
        end
    end
end

local function callback(target, activator)
    local script = target.type.record(target).mwscript
    local hasScript = advSetting.mwscript[script]
    local variablename
    local variablevalue
    if hasScript then
        variablename, variablevalue = next(hasScript)
    else
        return
    end

    local object, success, err = spawnDaedra(determineDaedricPrince(target.cell), target.type.record(target).value)
    local mwscript = world.mwscript.getLocalScript(target, activator)
    if mwscript and mwscript.variables then
        mwscript.variables[variablename] = variablevalue
    end
    if object == nil then
        -- will still spawn dremora if item was taken with mouse cursor from inventory menu (API 50), fix engine side
        return
    end

    if success then
        local fromActorSpace = trans.move(activator.position) * trans.rotateZ(activator.rotation:getYaw())
        local posBehindActor = fromActorSpace * summonPosition.back

        object:teleport(activator.cell.name, posBehindActor)
        object:sendEvent("StartAIPackage", { type = "Combat", target = activator, cancelOther = false })
    elseif success == false then
        print(string.format('[Cursed Offerings] %s. Fallback to default', err))
    end
end

for T in pairs(advSetting.types) do
    I.Activation.addHandlerForType(T, callback)
end
