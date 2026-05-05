local types = require('openmw.types')
local world = require('openmw.world')

local SCRIPT_NAME = 'scripts/detd_npc_sheatheweapon.lua'
local hookedObjects = {}

local function onObjectActive(obj)
    if not obj or not obj:isValid() then return end
    if obj.type ~= types.NPC then return end
    if types.Actor.isDead(obj) then return end

    local id = obj.id
    if hookedObjects[id] then return end

    hookedObjects[id] = obj
    obj:addScript(SCRIPT_NAME)

    local currentValue = world.mwscript.getGlobalVariables()["detd_PcHasWeaponDrawn"] or 0
    obj:sendEvent("detd_pcWeaponState", currentValue)

    --print("GLOBAL | attached script to:", obj.recordId, "| initial sync =", currentValue)
end

local function unhookObject(data)
    local obj = data.object
    if not obj or not obj:isValid() then return end

    if obj.id then
        hookedObjects[obj.id] = nil
    end
end

local function pcWeaponDrawn(value)
    local globals = world.mwscript.getGlobalVariables()
    globals["detd_PcHasWeaponDrawn"] = value

    if value == 0 then
        globals["detd_Pc_Weapon_Warning"] = 0
    end

   -- print("GLOBAL | pcWeaponDrawn received:", value)
   -- print("GLOBAL | detd_PcHasWeaponDrawn =", globals["detd_PcHasWeaponDrawn"])
   -- print("GLOBAL | detd_Pc_Weapon_Warning =", globals["detd_Pc_Weapon_Warning"])


    local sentCount = 0

    for id, obj in pairs(hookedObjects) do
        if obj and obj:isValid() and not types.Actor.isDead(obj) then
            obj:sendEvent("detd_pcWeaponState", value)
            sentCount = sentCount + 1
           -- print("GLOBAL | sending detd_pcWeaponState to:", obj.recordId, "| value:", value)
        else
            hookedObjects[id] = nil
        end
    end

   -- print("GLOBAL | total hooked NPCs sent to:", sentCount)
end

return {
    engineHandlers = {
        onObjectActive = onObjectActive,
    },
    eventHandlers = {
        detd_npc_sheatheweapon_Unhook = unhookObject,
        pcWeaponDrawn = pcWeaponDrawn,
    },
}