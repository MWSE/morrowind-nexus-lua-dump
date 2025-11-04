local types = require("openmw.types")

require("scripts.CanonicalGear.globalValues")
require("scripts.CanonicalGear.equipment.wizardStaff")
require("scripts.CanonicalGear.equipment.mouthStaff")
require("scripts.CanonicalGear.equipment.kingsOath")
require("scripts.CanonicalGear.equipment.dorisasBooks")

local function onActorActive(actor)
    if not types.NPC.objectIsInstance(actor) then return end
    if Toggles:get("wizardStaffEnabled") then   AddWizardStaff(actor) end
    if Toggles:get("mouthStaffEnabled") then    AddMouthStaff(actor) end
    if Toggles:get("kingsOathEnabled") then     AddKingsOath(actor) end
    if Toggles:get("dorisasBooksEnabled") then  DorisaDarvelAddBooks(actor) end
    print(Debug:get("printToConsole"))
end

local function onLoad(data)
    GearedNPCs = data.gearedNPCs
end

local function onSave()
    return { gearedNPCs = GearedNPCs }
end

return {
    engineHandlers = {
        onActorActive = onActorActive,
        onLoad = onLoad,
        onSave = onSave
    },
}
