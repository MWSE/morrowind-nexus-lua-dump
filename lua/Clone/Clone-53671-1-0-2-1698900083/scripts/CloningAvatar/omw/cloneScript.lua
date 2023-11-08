local self = require("openmw.self")
local core = require("openmw.core")
local types = require("openmw.types")
local lastCell
local function onUpdate(dt)
    if self.cell ~= lastCell then
        lastCell = self.cell
        core.sendGlobalEvent("updateClonedataLocation", self)
    end
end
local function CA_setEquipment(equip)
    types.Actor.setEquipment(self, equip)
end
local function CA_setHealth(num)
    self.type.stats.dynamic.health(self).current = num
end
local function CA_SetStat(data)
    --  actorTarget:sendEvent("CA_SetStat",{stat = "skills",key = key, base = val(actorSource).base, damage = val(actorSource).damage,  modifier = val(actorSource).modifier})

    if data.base then
        self.type.stats[data.stat][data.key](self).base = data.base
        if self.type.stats[data.stat][data.key](self).current and self.type.stats[data.stat][data.key](self).current > data.base then
            self.type.stats[data.stat][data.key](self).current = data.base
        end
    end
    if data.damage then
        self.type.stats[data.stat][data.key](self).damage = data.damage
    end
    if data.modifier then
        self.type.stats[data.stat][data.key](self).modifier = data.modifier
    end
    if data.current then
        self.type.stats[data.stat][data.key](self).current = data.current
    end
end
return { eventHandlers = { CA_setHealth = CA_setHealth, CA_setEquipment = CA_setEquipment, CA_SetStat = CA_SetStat },
    engineHandlers = {
        onUpdate = onUpdate
    }
}
