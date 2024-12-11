local common = require("mer.sigilStones.common")
local logger = common.createLogger("Main")

common.initAll("mer/sigilStones/modules")
common.initAll("mer/sigilStones/integrations")
logger:info("Initialized %s v%s", common.config.metadata.package.name, common.getVersion())

--Initialise MCM
require("mer.sigilStones.mcm")