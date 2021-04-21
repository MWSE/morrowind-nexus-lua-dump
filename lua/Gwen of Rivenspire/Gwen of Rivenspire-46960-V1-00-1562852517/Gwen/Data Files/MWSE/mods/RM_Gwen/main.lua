--[[
    Gwen Companion
    by Rubberman
--]]

mwse.log("[Gwen Companion] Initialized Version 0.0")
local passiveResponses = require("RM_Gwen.passiveResponses")
local deathResponses = require("RM_Gwen.deathResponses")
local bathcheck = require("RM_Gwen.bathcheck")
local gwen





-----------------------
-- UTILITY FUNCTIONS --
-----------------------
local journalHelper = setmetatable({}, {
    __index = function(t, id)
        return tes3.getJournalIndex{id=id}
    end,
    __newindex = function(t, id)
        return tes3.setJournalIndex{id=id}
    end,
})
------------------------
-- RESPONSE FUNCTIONS --
------------------------
local function triggerResponse(ref, responsesTable)
    -- get the reference's base object if applicable
    local obj = ref.object.baseObject or ref.object

    -- do nothing if no response function for this id
    local getResponse = responsesTable[obj.id:lower()]
    if getResponse == nil then
        return
    end

    local distance = gwen.position:distance(ref.position)
    local results = getResponse(ref, distance, gwen.context, journalHelper)

    if type(results) == "string" then
        tes3.messageBox(results)
    elseif type(results) == "table" then
        tes3.messageBox(table.choice(results))
    end

    return results
end
---------------------------------------------------------
local function scanNearbyObjects()
    if tes3.getGlobal("RM_Gwen_Global") < 3 then
        return
    end
    if gwen.mobile.inCombat then
        return
    end
    for ref in gwen.cell:iterateReferences() do
        if triggerResponse(ref, passiveResponses) then
            break
        end
    end
end
---------------------------------------------------------
local function scanNearbyNodes()
    if tes3.getGlobal("RM_Gwen_Global") < 3 then
        return
    end
    if gwen.mobile.inCombat then
        return
    end
    for ref in gwen.cell:iterateReferences() do
    ---	tes3.messageBox("scanNearbyNodes: %s", ref)
        if triggerResponse(ref, bathcheck) then
            break
        end
    end
end
------------
-- EVENTS --
------------
local function onDeath(e)
    triggerResponse(e.reference, deathResponses)
end
event.register("death", onDeath)
local function onDamaged(e)
    if tes3.getGlobal("RM_Gwen_Global") < 3 then
        return
    elseif tes3.getGlobal("RM_GotHeal") ~= 5 then
         return
    end

    local ref, mob = e.reference, e.mobile

    -- don't do anything if out of magicka
    if mob.magicka.current < 25 then return end

    -- get the damaged actors health ratio
    local healthRatio = (mob.health.current / mob.health.base)

    -- if health too low, cast heal spells
    if healthRatio < 0.4 then
        if ref == tes3.player then
            tes3.cast{reference=gwen, target=ref, spell="Heal Companion"}
        elseif ref == gwen then
            tes3.cast{reference=gwen, target=ref, spell="Hearth Heal"}
        end
    end
end
event.register("damaged", onDamaged)
local function onLoaded(e)
    -- Cache a handle to the Gwen reference.
    gwen = tes3.getReference("RM_Gwen")
    -- Every 15 seconds, scan for nearby objects to interact with.
    timer.start{type=timer.simulate, duration=15, iterations=-1, callback=scanNearbyObjects}
    -- Every 3 seconds, scan for nearby objects to interact with.
    timer.start{type=timer.simulate, duration=3, iterations=-1, callback=scanNearbyNodes}
end
event.register("loaded", onLoaded)
----------------------
-- Reload Responses --
----------------------
local function onKeyDownX(e)
    if e.isAltDown then
        local path = debug.getinfo(1).source:sub(2):match("(.-)([^\\]+)$")
        tes3.messageBox("Reloading: %s", path)
        passiveResponses = dofile(path .. "\\passiveResponses.lua")
        bathcheck = dofile(path .. "\\bathcheck.lua")
    end
end
event.register("keyDown", onKeyDownX, {filter=tes3.scanCode.x})


----------------------
-- Script Overrides --
----------------------

event.register("initialized", function()

  mwse.overrideScript("RM_share", function(e)
      local pcGold = mwscript.getItemCount{reference="player", item="gold_001"}
      mwscript.removeItem{reference="player", item="gold_001", count=pcGold}

      local gwGold = mwscript.getItemCount{reference="RM_Gwen", item="gold_001"}
      mwscript.removeItem{reference="RM_Gwen", item="gold_001", count=gwGold}

      local total = math.floor((pcGold + gwGold) / 2)
      mwscript.addItem{reference="player", item="gold_001", count=total}
      mwscript.addItem{reference="RM_Gwen", item="gold_001", count=total}

      mwscript.stopScript{script="RM_share"}
  end)
  
end)





