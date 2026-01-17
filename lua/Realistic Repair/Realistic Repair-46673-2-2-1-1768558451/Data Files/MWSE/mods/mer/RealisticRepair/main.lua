local config = require("mer.RealisticRepair.config")
local logger = mwse.Logger.new{
    modName = "Realistic Repair",
    logLevel = config.mcm.logLevel,
}
---Load configuration and MCM
require("mer.RealisticRepair.mcm")

---Load data
require("mer.RealisticRepair.data.stations")

---Load UI components
require("mer.RealisticRepair.ui.ConditionBarRenderer")
require("mer.RealisticRepair.ui.RepairMenuUI")
require("mer.RealisticRepair.ui.TooltipUI")

---Load modules (thin orchestrators that register events)
require("mer.RealisticRepair.modules.deathDamage")
require("mer.RealisticRepair.modules.stations")
require("mer.RealisticRepair.modules.degradation")

event.register("initialized", function()
    logger:info("Realistic Repair initialized.")
    logger:debug("DEBUG logging enabled.")
end)