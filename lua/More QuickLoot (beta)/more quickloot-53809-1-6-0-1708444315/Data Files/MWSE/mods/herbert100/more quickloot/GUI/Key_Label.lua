local Class = require("herbert100.Class")
local config = require("herbert100.more quickloot.config")
local key_cfg = config.keys
local log = require("herbert100.logger").new("More QuickLoot/GUI")
local common = require("herbert100.more quickloot.common")

---@alias MQL.GUI.key_name
---|'"take"'     take an item 
---|'"take_all"' take all items 
---|'"open"'     open the container


local key_names = {"take", "take_all", "open"}
local default_positions = {open=0.05, take=0.5, take_all=0.95 }

---@alias MQL.GUI.Key_Label.keybinds {[MQL.GUI.key_name]:string}
---@alias MQL.GUI.Key_Label.positions {[MQL.GUI.key_name]:number}

---@class MQL.GUI.Key_Label : herbert.Class, {[MQL.GUI.key_name]:tes3uiElement}
---@field new fun(parent_block: tes3uiElement, keybinds: MQL.GUI.Key_Label.keybinds?, positions: MQL.GUI.Key_Label.positions?, make_divider: boolean?): MQL.GUI.Key_Label
---@field key_names {[MQL.GUI.key_name]: string}
---@field divider tes3uiElement
---@field block tes3uiElement
local Key_Label = Class.new{name="Key_Label",
    fields={
    },
    new_obj_func="no_obj_data_table",

    ---@param self MQL.GUI.Key_Label
    ---@param parent_block tes3uiElement
    ---@param keybinds MQL.GUI.Key_Label.keybinds?
    ---@param positions MQL.GUI.Key_Label.positions?
    ---@param make_divider boolean?
    init=function(self, parent_block, keybinds, positions, make_divider)
        self.key_names = {}
        self:update_key_names()
        log("making new keylabel with %s", json.encode, keybinds)
        if make_divider ~= false then
            self.divider = parent_block:createDivider()
        end

        local block = parent_block:createBlock()
        self.block = block
        block.alpha = 0.75
        block.flowDirection = "left_to_right"
        block.widthProportional = 1.0
        block.autoHeight = true
        block.paddingAllSides = 3
        block.minWidth = 300 -- new
        for _, k in pairs(key_names) do
            local lbl = block:createLabel{id=k, text=""}
            lbl.absolutePosAlignX = positions and positions[k] or default_positions[k]
            -- lbl.absolutePosAlignY = 0.5
            self[k] = lbl
        end
        if keybinds and config.UI.show_controls then
            self:update_labels(keybinds)
        else
            self.block.visible = false
            if make_divider ~= false then
                self.divider.visible = false
            end
        end
    end
}

---@param p {[MQL.GUI.key_name]: string}
---@param update boolean? update the label block?
function Key_Label:update_labels(p, update)
    log("updating key labels to %s", json.encode, p)
    if not p then return end
    for k, v in pairs(p) do 
        self[k].text = v and string.format("%s) %s", self.key_names[k], v) or ""
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

function Key_Label:update_key_names()
    local spcbr = tes3.scanCode.space
    -- -------------------------------------------------------------------------
    -- TAKE/OPEN
    -- -------------------------------------------------------------------------
    local custom, activate
    if key_cfg.custom.keyCode ~= nil then
        if key_cfg.custom.keyCode == spcbr then
            custom = "SPC"
        else
            custom = common.get_key_name(key_cfg.custom.keyCode)
        end
    else
        custom = "M" .. key_cfg.custom.mouseButton
    end

    local act_inp = tes3.getInputBinding(tes3.keybind.activate)
    if act_inp.device == 0 then
        if act_inp.code == spcbr then
            activate = "SPC"
        else
            activate = common.get_key_name(act_inp.code)
        end
    else
        activate = "M" .. act_inp.code
    end

    if key_cfg.use_activate_btn then
        self.key_names.take = activate
        self.key_names.open = custom
    else
        self.key_names.take = custom
        self.key_names.open = activate
    end

    -- -------------------------------------------------------------------------
    -- TAKE ALL
    -- -------------------------------------------------------------------------

    if key_cfg.take_all.keyCode ~= nil then
        if key_cfg.take_all.keyCode == spcbr then
            self.key_names.take_all = "SPC"
        else
            self.key_names.take_all = common.get_key_name(key_cfg.take_all.keyCode)
        end
    else
        self.key_names.take_all = "M" .. key_cfg.take_all.mouseButton
    end
end
return Key_Label