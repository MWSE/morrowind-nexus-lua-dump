local tooltipsComplete = include("Tooltips Complete.interop")
local tooltipData = {
    { id = "mdBC_CratePulley", description = "A heavy wooden crate which contains a heavy duty pulley system. Some assembly required.", itemType = "miscItem" },
    { id = "mdBC_CrateTelescope", description = "A heavy wooden crate which contains a telescope. Some assembly required.", itemType = "miscItem" },
    { id = "mdBC_CrateWood", description = "A heavy wooden crate filled with neatly stacked planks of wood.", itemType = "miscItem" },
    { id = "mdBC_CrateRope", description = "A heavy wooden crate filled with thick coils of rope.", itemType = "miscItem" },
    { id = "mdBC_bk_Planbook", description = "Tsanara's plans to improve the Grahtwood Roost.", itemType = "book" },
    { id = "mdBC_bk_OdeToVerticality", description = "A book written by someone enchanted by the glorious heights of verticality.", itemType = "book" },
    { id = "mdBC_StaffCoprinus", description = "The staff, which calls itself 'Agabix', whispers of how it longs to send its children home.", itemType = "weapon" }
}
local function initialized()
    if tooltipsComplete then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end
event.register("initialized", initialized)