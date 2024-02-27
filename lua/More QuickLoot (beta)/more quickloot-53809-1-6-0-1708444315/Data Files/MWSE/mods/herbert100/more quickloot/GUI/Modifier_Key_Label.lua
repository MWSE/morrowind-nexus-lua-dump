local Class = require("herbert100.Class")
local Key_Label = require("herbert100.more quickloot.GUI.Key_Label")


---@class MQL.GUI.Modifier_Key_Label : MQL.GUI.Key_Label, {[MQL.GUI.key_name]:tes3uiElement}
---@field divider tes3uiElement
---@field block tes3uiElement
local Modifier_Key_Label = Class.new{name="Modifier_Key_Label", parents = {Key_Label},
    init=function(self, ...)
        Key_Label.__secrets.init(self, ...)
        if not require("herbert100.more quickloot.config").UI.show_controls_m then
            self.divider.visible = false
            self.block.visible = false
        end
    end
}

---@param p {[MQL.GUI.key_name]: string}
---@param update boolean? update the label block?
function Modifier_Key_Label:update_labels(p, update)
    if not p then return end
    for k, v in pairs(p) do 
        self[k].text = v and string.format("(%s)", v) or ""
    end
    if update then
        -- stuff should be visible if at least one thing has a label
        local vis = self.open.text ~= "" or self.take.text ~= "" or self.take_all.text ~= ""
        self.block.visible = vis
        if self.divider then
            self.divider.visible = vis
        end
        self.block:updateLayout()
    end
end

return Modifier_Key_Label