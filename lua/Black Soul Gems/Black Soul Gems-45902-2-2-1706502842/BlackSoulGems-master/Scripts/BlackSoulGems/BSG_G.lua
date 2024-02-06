local world = require("openmw.world")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local actorlist = require("scripts.blacksoulgems.bsg_actorlist")
local anim = require('openmw.animation')
local fixedCell = false

local alterObject = nil
if core.API_REVISION < 42 then
    local errorM =
    "Your OpenMW version is too old to use this mod! Please update to 0.49, or the latest development build."
    error(errorM)
end

local function startsWith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end
local gemId = "a_bsg_emptyblackgem"
local gemIdfallBack = "a_bsg_emptyblackgem"
local function checkGemID()
    if core.contentFiles.has("oaab_data.esm") then
        gemId = "AB_Misc_SoulGemBlack"
    end
end
local function formatNumberToFourDigits(number)
    return string.format("%04d", number)
end
local function getSoulId(id)
    for index, str in ipairs(actorlist) do
        if str == id then
            return "soul_" .. formatNumberToFourDigits(index)
        end
    end
    return "soul_generic"
end
local function createSoundObject()
    local ob = world.createObject("zhac_bsg_soundob")
    ob:teleport(world.players[1].cell, world.players[1].position)
end

local function NPCTrapped(NPC, fgemId)
    local NPCId = NPC.recordId
    local soulObLs = types.Actor.inventory(world.players[1]):findAll(fgemId)
    for index, soulOb in ipairs(soulObLs) do
        if not soulOb.type.getSoul(soulOb) then
            local nsoulOb = soulOb:split(1)
            nsoulOb.type.setSoul(nsoulOb, getSoulId(NPCId))
            nsoulOb:moveInto(types.Actor.inventory(world.players[1]))
            world.players[1]:sendEvent("BSG_ShowMessage", core.getGMST("sSoultrapSuccess"))
            world.players[1]:sendEvent("BSG_playSoundEvent", "conjuration hit")
            anim.addVfx(NPC, "VFX_Soul_Trap")
            return true
        end
    end
    return false
end
local function NPCTrappedEvent(NPCId)
    if NPCTrapped(NPCId, gemId) then
        return
    else
        NPCTrapped(NPCId, gemIdfallBack)
    end
end
local function fixCell()
    world.getCellByName("Mawia"):getAll()
    if fixedCell then return end
    local greefOb = world.getObjectByFormId(core.getFormId("morrowind.esm", 72974))
    local tableOb = world.getObjectByFormId(core.getFormId("morrowind.esm", 72952))
    if greefOb:isValid() then
        greefOb:remove()
        fixedCell = true
    end
    if tableOb:isValid() then
        tableOb:remove()
        fixedCell = true
    end
end
local function onObjectActive(obj)
    if obj.recordId == "aa_blackalter" then
        alterObject = obj
    end
end
local function onUpdate(dt)
    if alterObject and alterObject:isValid() and alterObject.cell == world.players[1].cell then
        local mwsc = world.mwscript.getLocalScript(alterObject)
        if mwsc then
            if mwsc.variables.itemswap == 1 then
                mwsc.variables.itemswap = 0
                local obj = types.Container.content(alterObject):find("misc_soulgem_grand")
                if obj then
                    obj:remove(1)
                    local newObj = world.createObject(gemId)
                    newObj:moveInto(types.Container.content(alterObject))
                end
            end
        end
    end
end
local function onSave()
    return { fixedCell = fixedCell }
end
local function onPlayerAdded(plr)
    if plr then
        fixCell()
        checkGemID()
    end
end
local function onInit()
    fixCell()
    checkGemID()
end
local function onLoad(data)
    if not data or not data.fixedCell then
        fixCell()
    end
    checkGemID()
    alterObject = world.getObjectByFormId(core.getFormId("black soul gems.esp", 2))
end
return {
    interfaceName = "BSG",
    interface = {
        version = 1,
        getSoulId = getSoulId,
    },
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onInit = onInit,
        onPlayerAdded = onPlayerAdded,
        onUpdate = onUpdate,
    },
    eventHandlers = { NPCTrapped = NPCTrappedEvent, }
}
