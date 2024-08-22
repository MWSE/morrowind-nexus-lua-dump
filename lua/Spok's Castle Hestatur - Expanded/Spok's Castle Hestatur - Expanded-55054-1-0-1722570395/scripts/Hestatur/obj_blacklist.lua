local blacklistItems = {["spok_le_rack"] = "spok_le_rack",
["spok_acme_daedric_bow_box"] ="spok_acme_daedric_bow_box"}
local world = require("openmw.world")
local types = require("openmw.types")
local blockManniq = true
local function isHestatur(id)
    if id:find("hestatur" ) then
        return true
    end
    return false
end

local function onObjectActive(obj)
    if not isHestatur(obj.cell.id) then
        return
    end
   if blacklistItems[obj.recordId] then
    obj.enabled = false
   end
end
local function onActorActive(obj)
    if blockManniq and (obj.recordId == "spok_mannequin_s" or obj.recordId == "spok_mannequin_w" )then
      --  obj.enabled = false
    end
end
return {
    engineHandlers = {
        onObjectActive = onObjectActive,
        onActorActive = onActorActive,
    }
}
