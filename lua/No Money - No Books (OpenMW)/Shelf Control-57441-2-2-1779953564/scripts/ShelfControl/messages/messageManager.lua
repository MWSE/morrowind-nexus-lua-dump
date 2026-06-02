local storage = require("openmw.storage")

require("scripts.ShelfControl.messages.buyable")
require("scripts.ShelfControl.messages.npcOwned")
require("scripts.ShelfControl.messages.factionOwned")

local sectionMisc = storage.globalSection("SettingsShelfControl_misc")

local dispatch = {
    { check = function(o) return o.recordId and not o.sellsBooks end, fn = PickNPCOwnedMessage },
    { check = function(o) return o.recordId and o.sellsBooks end,     fn = PickBuyableMessage },
    { check = function(o) return o.factionId end,                     fn = PickFactionOwnedMessage },
}

function ShowMessage(ctx)
    if not sectionMisc:get("enableMessages") then return end

    for _, rule in ipairs(dispatch) do
        if rule.check(ctx.owner) then
            local msg = rule.fn(ctx)
            ctx.player:sendEvent("ShowMessage", { message = msg })
            break
        end
    end
end
