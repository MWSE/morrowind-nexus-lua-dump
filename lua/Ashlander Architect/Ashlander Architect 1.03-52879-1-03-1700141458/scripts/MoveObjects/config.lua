local core = require("openmw.core")
local isUpdated = core.API_REVISION >= 49
return {isUpdated = isUpdated}