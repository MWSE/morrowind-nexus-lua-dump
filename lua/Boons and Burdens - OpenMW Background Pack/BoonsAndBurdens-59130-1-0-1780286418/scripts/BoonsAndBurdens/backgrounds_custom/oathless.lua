---@omw-context local
local self = require("openmw.self")

local health = self.type.stats.dynamic.health(self)
health.base = health.base / 2