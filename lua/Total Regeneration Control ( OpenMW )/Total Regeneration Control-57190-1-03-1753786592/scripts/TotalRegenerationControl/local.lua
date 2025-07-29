
--! изменять показатели актеров можно только через локальный скрипт ..

local types = require('openmw.types')
local self = require('openmw.self')


local function totalM(total)
    types.Actor.stats.dynamic.magicka(self).current = total
end

local function totalH(total)
    types.Actor.stats.dynamic.health(self).current = total
end

local function totalF(total)
    types.Actor.stats.dynamic.fatigue(self).current = total
end

return {
    eventHandlers = {
        totalM = totalM,
        totalH = totalH,
        totalF = totalF,
    }
}
