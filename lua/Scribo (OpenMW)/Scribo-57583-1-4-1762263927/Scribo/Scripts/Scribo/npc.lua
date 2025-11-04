local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local AI = require('openmw.interfaces').AI

local function updateTradersItems()
    for _, chest in ipairs(nearby.containers) do
        if chest.owner.recordId == self.recordId then
            -- print('scribo: found trader chest ' .. chest.recordId)
            local inventory = types.Container.inventory(chest)
            core.sendGlobalEvent('UpdateTradersItems', {
                trader = self,
                container = chest
            })
        end
    end

    local misc = 0
    local ingredient = 0

    for _, items in ipairs(nearby.items) do
        if items.owner.recordId == self.recordId then
            -- print('scribo: found trader item ' .. items.recordId)
            if items.type == types.Miscellaneous then
                misc = misc + 1
            end
            if items.type == types.Ingredient then
                ingredient = ingredient + 1
            end
        end
    end
    local inventory = types.Actor.inventory(self)
    core.sendGlobalEvent('UpdateTradersItems', {
        trader = self,
        container = self,
        misc = misc,
        ingredient = ingredient
    })
end

local function checkCombat()
    local pk = AI.getActivePackage()
    local type

    if pk then
        type = pk.type
    else
        type = "Peace"
    end

    if type == "Combat" then
        local target = AI.getActiveTarget(type)
        if target.type ~= types.Player then
            type = "Peace"
        end
    end
    core.sendGlobalEvent('CheckCombat', {
        type = type,
        npc = self.recordId
    })
end

local function onActivated(actor)
    local class = types.NPC.record(self).class

    if class == "trader service" or class == "bookseller" or class == "pawnbroker" then
        --print('scribo: NPC traders activated')
        updateTradersItems()
    end
end
local function onUpdate(dt)
    --if not playerSettings:get('scrbInCombatCheckOff') then
        checkCombat()
    --end
end

return {
    engineHandlers = {
        onActivated = onActivated,
        onUpdate = onUpdate
    }
}
