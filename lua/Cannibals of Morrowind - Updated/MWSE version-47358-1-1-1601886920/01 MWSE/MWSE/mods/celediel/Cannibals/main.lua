local data = require("celediel.Cannibals.data")

local modName = "Cannibals"
-- LuaFormatter off
local modInfo = "Based on Updated Cannibals of Morrowind by Danae " ..
    "which is in turn based on Cannibals of Morrowind by Morandir Nailo\n\n" ..
    "Adds body part ingredients (brains, hearts, flesh, etc.) to " ..
    "all NPC's in the game, on death, which restore fatigue and have further " ..
    "properties which reflect the race (for instance, Dunmer Flesh can be eaten, " ..
    "or used in a potion, to gain fire resistance).\n\n" ..
    "In addition, each NPC has a skull, which can be kept as a trophy, or used as " ..
    "a Mortar & Pestle. Most skulls are generic (dunmer skull, nord skull, etc.) " ..
    "but certain important NPCs have unique skulls bearing their name, for those " ..
    "important kills. More powerful NPC skulls will act as better quality Mortar & " ..
    "Pestles. Beasts and vampires have new skull meshes, courtesy of Barabus."
-- LuaFormatter on
local codeAuthor = "Celediel"
local version = "1.0.0"
local esp = "Cannibals of Morrowind MWSE.esp"

-- mimic the esp version
local defaultConfig = {addSkulls = true, bodyPartChance = 50, debug = false}
local config = mwse.loadConfig(modName, defaultConfig)

-- send nonsense to the logs
local function log(...) if config.debug then mwse.log("[%s] %s", modName, string.format(...)) end end

-- skull/body part picking functions
local function pickSkull(actor)
    -- only NPCs get skulls
    if actor.actorType ~= tes3.actorType.npc then return end

    -- shortcuts
    local race = actor.object.race.id:lower()
    -- some references have ref.baseObject, some have ref.object.baseObject
    -- I really don't know which is the "right one"
    -- just try them all or something
    local obj = actor.baseObject and actor.baseObject or
                    (actor.object.baseObject and actor.object.baseObject or actor.object)
    local id = obj.id:lower()
    local isVampire = obj.head.vampiric

    local skull
    -- log("Picking skull for %s%s (id:%s race:%s)", obj.name, isVampire and ", a vampire" or "", id, race)

    if isVampire then
        skull = data.skulls["vampire"]
        log("Picked %s because vampire", skull)
    elseif data.skulls[id] then
        skull = data.skulls[id]
        log("Picked %s by id:%s", skull, id)
    elseif data.skulls[race] then
        skull = data.skulls[race]
        log("Picked %s by race:%s", skull, race)
    else
        -- generic skull for mod added races
        -- todo: better support for mod added races
        skull = data.skulls.fallback
        log("Picked generic %s", skull)
    end

    return skull
end

local function pickBodyPart(actor)
    -- log("Picking parts for %s (id:%s race:%s mesh:%s)", actor.object.name, actor.object.id,
    --     actor.object.race.id:lower(), actor.object.mesh:lower())

    -- list of parts relevant to the actor
    local parts = {}

    if actor.actorType == tes3.actorType.npc then
        local race = actor.object.race.id:lower()
        log("Picking parts based on race:%s", race)
        parts = data.randomParts[race] or data.randomParts.fallback
    elseif actor.actorType == tes3.actorType.creature then
        -- todo: probably put this in pickSkull because these are skulls
        -- todo: but the original mod had them spawn at the same rate as body parts so I put it here
        local mesh = actor.object.mesh:lower()

        -- works with SpaceDevo's Divine Dagoths because those meshes follow similar naming convention
        -- but other mesh replacing esps could causes issues
        if mesh:match("ashghoul") then
            parts = data.randomParts.ashGhoul
        elseif mesh:match("sleeper") then
            parts = data.randomParts.sleeper
        elseif mesh:match("ashvampire") then
            parts = data.randomParts.ashVampire
        end

        if #parts > 0 then log("Picked parts based on mesh:%s", mesh) end
    end

    -- pick one of the parts
    return table.choice(parts)
end

local function addParts(ref, skull, bodyPart)
    local parts = ""

    if skull and config.addSkulls then
        parts = parts .. skull
        tes3.addItem({reference = ref, item = skull, count = 1, playSound = false})
    end

    -- all in the name of debug log formatting
    if skull and config.addSkulls and bodyPart and config.bodyPartChance > 0 then parts = parts .. " " end

    if bodyPart then
        local roll = math.random(1, 100)
        local addPart = config.bodyPartChance >= roll
        -- log("Adding %sparts because %s %s %s", addPart and "" or "no ", config.bodyPartChance, addPart and ">" or "<", roll)

        if addPart then
            parts = parts .. bodyPart
            tes3.addItem({reference = ref, item = bodyPart, count = 1, playSound = false})
        end
    end

    if parts ~= "" then log("Added parts:%s to %s", parts, ref) end
end

-- event function(s)
local eventFunctions = {}
eventFunctions.onDeath = function(e) addParts(e.reference, pickSkull(e.mobile), pickBodyPart(e.mobile)) end

local function onInitialized()
    -- check if our esp is active
    if not tes3.isModActive(esp) then
        local msg = string.format("%s must be activated for %s to work!", esp, modName)
        mwse.log("[%s] %s", modName, msg)
        tes3.messageBox(msg)
        return
    end

    -- now that that's out of the way
    for name, func in pairs(eventFunctions) do
        log("Registering functions for event: %s", name)
        event.register(name:gsub("^on(%u)", string.lower), func)
    end
    mwse.log("[%s] Initialized with config:%s", modName, json.encode(config))
end

-- MCM
local function doConfigMenu()
    local template = mwse.mcm.createTemplate(modName)
    template:saveOnClose(modName, config)

    local page = template:createSideBarPage({
        label = "Sidebar Page???",
        description = string.format("%s v%s Lua code by %s\n\n%s", modName, version, codeAuthor, modInfo)
    })

    local category = page:createCategory(modName)

    category:createYesNoButton({
        label = "Add skulls to NPCs?",
        description = "On death, NPCs will have a skull added to their " ..
            "inventory. The type of skull is dependent on the NPC's race. " ..
            "Vampires and some unique NPCs have special skulls.",
        variable = mwse.mcm.createTableVariable({id = "addSkulls", table = config})
    })

    category:createSlider({
        label = "Chance to add other body parts to NPCs and skulls to ash creatures",
        description = "Percent chance to add an additional random body part to NPCs, and skulls to Sleepers, Ash Ghouls and Ash Vampires.",
        variable = mwse.mcm.createTableVariable({id = "bodyPartChance", table = config})
    })

    category:createYesNoButton({
        label = "Debug logging",
        description = "Enable this if you want a bunch of nonsense in your MWSE.log",
        variable = mwse.mcm.createTableVariable({id = "debug", table = config})
    })

    return template
end

event.register("initialized", onInitialized)
event.register("modConfigReady", function() mwse.mcm.register(doConfigMenu()) end)
