local util = require("zoom.util")

local interop = {}

interop.setTelescopeRequired = util.setTelescopeRequired
interop.getTelescopeRequired = util.getTelescopeRequired
interop.registerTelescope = util.registerTelescope
interop.registerTelescopes = util.registerTelescopes

return interop
