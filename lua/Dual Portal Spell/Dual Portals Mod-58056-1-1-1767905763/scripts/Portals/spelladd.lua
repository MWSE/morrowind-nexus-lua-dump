local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local constants = require("scripts.Portals.constants")



local actors = {
    "Ranis Athrys",
    "Ethasi Rilvayn",
    "Ervona Barys",
    "Lalatia Varian",
    "Uvele Berendas",
    "Galero Andaram",
    "Llaalam Madalas",
    "Galero Andaram",
    "Malven Romori",
    "Salver Lleran",
    "Dileno Lloran"
}
local actorKeys = {}
for i,x in ipairs(actors) do
actorKeys[x:lower()] = true
end

local function onActorActive(actor)
    if actorKeys[actor.recordId] then
        types.Actor.spells(actor):add("zhac_portal_alpha")
    end
end
return {engineHandlers = {
    onActorActive = onActorActive,
}}