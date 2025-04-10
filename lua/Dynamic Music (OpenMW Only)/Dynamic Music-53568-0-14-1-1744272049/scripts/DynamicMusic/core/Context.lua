local GameState = require('scripts.DynamicMusic.core.GameState')

---@class Context
---@field ambient any
---@field gameState GameState
---@field includeEnemies table<string>
---@field ignoreEnemies table<string>
---@field player any The player object for this context.
local Context = {}

---@return Context context A Context instance
---@param player any The OpenMW player object for this context.
---@param ambient any The OpenMW ambient object for this context.
function Context.Create(player, ambient)
    local context = {}

    --fields
    context.player = player
    context.ambient = ambient
    context.gameState = GameState.Create(context)
    context.includeEnemies = {}
    context.ignoreEnemies = {}

    --functions
    context.getPlayer = Context.getPlayer

    return context
end

---@return any player The OpenMW player object for this context.
function Context.getPlayer(self)
    return self.player
end

return Context