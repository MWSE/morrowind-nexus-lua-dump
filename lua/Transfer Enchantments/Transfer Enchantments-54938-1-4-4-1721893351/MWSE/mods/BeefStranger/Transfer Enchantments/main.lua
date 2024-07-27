local ui = require("BeefStranger.Transfer Enchantments.ui")
local bs = require("BeefStranger.Transfer Enchantments.common")
local cfg = require("BeefStranger.Transfer Enchantments.config")
local menu = require("BeefStranger.Transfer Enchantments.menu.menuUtil")
local transfer = require("BeefStranger.Transfer Enchantments.menu.transfer")
local itemSelect = require("BeefStranger.Transfer Enchantments.menu.itemSelect")

---@param e keyDownEventData
event.register(tes3.event.keyDown, function (e)
    if cfg.enabled and e.keyCode == cfg.keycode.keyCode then
        if not e.isShiftDown or not e.isAltDown or not e.isControlDown then
            if not tes3.menuMode() and tes3.mobilePlayer then
                transfer.create()
            end
        end
    end
end)


event.register("initialized", function()
    ui.register()
    print("[MWSE:Transfer Enchantments] initialized")
end)


