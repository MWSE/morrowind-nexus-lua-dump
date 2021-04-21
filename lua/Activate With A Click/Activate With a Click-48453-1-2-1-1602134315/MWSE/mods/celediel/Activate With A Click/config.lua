local common = require("celediel.Activate With A Click.common")
local defaultConfig = {clickActivate = true, activateMouseButton = common.click.right, disableWithWeapon = false}

local config = mwse.loadConfig(common.configString, defaultConfig)

-- mwse.log("[%s] Loaded config:", common.modName)
-- mwse.log(json.encode(config, {indent = true}))

return config
