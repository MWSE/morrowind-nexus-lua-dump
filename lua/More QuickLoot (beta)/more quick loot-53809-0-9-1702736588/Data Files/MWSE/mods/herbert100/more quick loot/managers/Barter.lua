local Class, Living = require("herbert100.Class"), require("herbert100.more quick loot.managers.abstract.Living")
local Item = require("herbert100.more quick loot.Item")



---@class MQL.Manager.Barter : MQL.Managers.Living
---@field disposition integer the disposition of the seller
local Barter = Class.new({name="Barter Manager", parents={Living},}, {loot_verb = "Bought"})


function Barter:_get_key_btn_info()
    return {
        take = {label = "Buy 1", pos = 0.05},
        open = {label = "Talk", pos = 0.95},
        take_all = {label = "Sell Mode", pos = 0.5}
    }

end

return Barter