
---@class herbert.MCM.new_component.params
---@field label string? label of this component
---@field desc string? description for this component
---@field description string? alternate syntax for description
---@field config table? new config to use for this component. if not passed, it will be inherited from its parent
---@field id string|integer? i18n index of the relevant table


-- an entry in the `layout` that we're going to define below
---@class herbert.MCM.new_setting.params : herbert.MCM.new_component.params
---@field callback fun(self:mwseMCMSetting)? callback to use when the setting is updated
---@field id string|integer config/i18n index of relevant setting
---@field converter nil|fun(new_value:unknown):unknown converter for variable
---@field restart boolean? is a restart required?
---@field variable mwseMCMVariable?
---@field convert_label nil|fun(self:mwseMCMSetting, value):string|number


---@alias herbert.MCM.container_type "page"|"sidebar_page"|"category"

---@class herbert.MCM.Setting_Creator.new_params : herbert.MCM.new_component.params
---@field config table config to manage
---@field i18n nil|fun(string, ...): string i18n translator
---@field i18n_prefix string?
---@field type herbert.MCM.container_type
---@field parent_comp mwseMCMPage|mwseMCMSideBarPage|mwseMCMCategory|mwseMCMTemplate


local MCM_log = Herbert_Logger()


-- creates settings and manages a Page, Sidebar Page, or Category. this will let you add settings to any of those components
---@class herbert.MCM.Setting_Creator : herbert.Class
---@field i18n nil|fun(string, ...): string i18n translator
---@field config table config to manage
---@field component mwseMCMPage|mwseMCMSideBarPage|mwseMCMCategory component being managed
---@field id string?
---@field new fun(p:herbert.MCM.Setting_Creator.new_params): herbert.MCM.Setting_Creator
local SC = require("herbert100.Class").new{name="MCM Setting Creator",
    {"component", tostring=function (v) return v and v.label or "none" end},
    {"config", tostring=json.encode},
    {"id", },
    {"i18n", },

    new_obj_func="no_obj_data_table",

    ---@param self herbert.MCM.Setting_Creator
    ---@param p herbert.MCM.Setting_Creator.new_params
    init = function (self, p)
        self.config = p.config

        if p.i18n and p.i18n_prefix then
            self.i18n = p.i18n
            if p.id then
                self.id = string.format("%s.%s", p.i18n_prefix, p.id)
            else
                self.id = p.i18n_prefix
            end
        end

        local params = { 
            label = p.label or self:get_label(), 
            description = p.desc or self:get_description()
        }
        self.component = p.type == "category" and p.parent_comp:createCategory(params)
                        or p.type == "sidebar_page" and p.parent_comp:createSideBarPage(params)
                        or p.parent_comp:createPage(params)
    end
}

---@param p herbert.MCM.new_component.params?
---@return string?
function SC:get_label(p)
    local label
    if not p then
        label = self.i18n and self.id and self.i18n(string.format("%s.label", self.id))
        if label then return label end

        local mod_name = self:get_mod_name()
        if mod_name then
            -- MCM_log:error("No label found for mod %q: %s", mod_name, self)
        end
        return
    end

    label = p.label or self.i18n and self.id and self.i18n(string.format("%s.%s.label", self.id, p.id))
    if label then return label end
    -- error handling
    local mod_name = self:get_mod_name()
    if mod_name then
        -- MCM_log:error("No label found for mod %q: %s",  p.id, self.id, mod_name)
    end
end

---@param p herbert.MCM.new_component.params?
---@return string?
function SC:get_description(p)
    local desc
    if not p then
        return self.i18n and self.id and (
            self.i18n(string.format("%s.description", self.id))
                or self.i18n(string.format("%s.desc", self.id))
        )
        
        -- if desc then return desc end

        -- local mod_name = self:get_mod_name()
        -- if mod_name then
        --     Logger.new{mod_name=mod_name, module_name="MCM"}:error("No description found for %s", self)
        -- end
        -- return
    end
    desc = p.desc or p.description or self.i18n and self.id and (
        self.i18n(string.format("%s.%s.description", self.id, p.id)) 
            or self.i18n(string.format("%s.%s.desc", self.id, p.id))
    )
    if desc then return desc end
    -- error handling
    -- local mod_name = self:get_mod_name()

    -- if mod_name then
    --     Logger.new{mod_name=mod_name, module_name="MCM"}
    --         :error("No description found for setting %q in component %s, for %s", p.id, self.id, self)
    -- end
end

function SC:get_mod_name()
    local parent_comp = self.component---@type mwseMCMComponent
    if not parent_comp then return end
    ---@diagnostic disable-next-line: need-check-nil
    while parent_comp.parentComponent ~= nil and parent_comp.componentType ~= "Template" do
        parent_comp = parent_comp.parentComponent
    end
    return parent_comp and (parent_comp.name or parent_comp.label)
end

---@param mod_name string|herbert.Logger? if not provided, the name of the MCM template will be used.
function SC:add_log_settings(mod_name)
    local logger
    -- if `mod_name` is a logger
    if type(mod_name) == "table" and getmetatable(mod_name) == getmetatable(MCM_log) then
        logger = mod_name
    elseif not mod_name or type(mod_name) ~= "string" then
        local mod_info = require("herbert100").get_active_mod_info()
        if mod_info then
            mod_name = mod_info.short_mod_name or mod_info.mod_name
        end
        mod_name = mod_name or self:get_mod_name()
    end
     logger = logger or Herbert_Logger.get(mod_name) or Herbert_Logger.new(mod_name)
    -- if not logger then
    --     local info = require("herbert100.utils").get_active_mod_info()
    --     if not info then
    --         MCM_log:error("could not get logger for %q", mod_name)
    --         return
    --     end
    --     local mod_dir
    --     if info.dir_has_author_name then
    --         -- e.g. mod_dir = "herbert100.more quickloot"
    --         mod_dir = info.lua_parts[1] .. "." .. info.lua_parts[2]
    --     else
    --         -- e.g. mod_dir = "Expeditious Exit"
    --         mod_dir = info.lua_parts[1]
    --     end
    --     logger = Herbert_Logger.new{mod_dir=mod_dir, mod_name=mod_name}
    -- end

    return logger:add_to_MCM{component=self.component, config=self.config}
end


---@class herbert.MCM.new_variable.params
---@field restart boolean? restart required?
---@field default any default value
---@field in_game_only boolean?
---@field restart_msg string?
---@field id string|integer id of the setting
---@field config table? config to use (if different from the one that's already stored)
---@field converter nil|fun(new_value:unknown):unknown a converter to use for this setting

local mcm_key_converter = {
    default = "defaultSetting",
    restart = "restartRequired",
    restart_msg = "restartRequiredMessage",
    in_game_only = "inGameOnly",
    dp = "decimalPlaces",
    convert_label = "convertToLabelValue",
    numeric = "numbersOnly",

}
---@param id string|integer id of the setting
---@param config table? config to use (if different from the one that's already stored)
---@param converter nil|fun(new_value:unknown):unknown a converter to use for this setting
function SC:new_variable(id, config, converter)
    
    return mwse.mcm.createTableVariable{
        id=id or self.id,
        table=config or self.config,
        converter=converter or self.converter,
    }
end

---@param p herbert.MCM.new_setting.params
---@return herbert.MCM.new_setting.params
function SC:update_parameter(p)
    p.label = self:get_label(p)
    p.description = self:get_description(p)
    p.desc = nil
    
    for _, k in pairs(table.keys(p)) do
        local mcm_key = mcm_key_converter[k]
        if mcm_key then
            p[mcm_key] = p[k]
            p[k] = nil
        end
    end
    if not p.variable and (p.id or self.id) then
        p.variable = p.variable or self:new_variable(p.id, p.config, p.converter)
    end
    if p.step and not p.jump then
        p.jump = p.step * 3
    end
    return p
end





-- make a new Yes/No button
---@param p herbert.MCM.new_setting.params
---@return mwseMCMYesNoButton
function SC:new_button(p)
    return self.component:createYesNoButton(self:update_parameter(p))
end

---@class herbert.MCM.new_callback_button.params : herbert.MCM.new_setting.params
---@field btn_text string? text to use for the button

-- make a new callback button, with customizable text
---@param p herbert.MCM.new_callback_button.params
---@return mwseMCMButton
function SC:new_callback_button(p)
    -- p.label = self:get_label(p)
    -- p.description = self:get_description(p)
    -- p.desc = nil
    -- for _, k in pairs(table.keys(p)) do
    --     local mcm_key = mcm_key_converter[k]
    --     if mcm_key then
    --         p[mcm_key] = p[k]
    --         p[k] = nil
    --     end
    -- end
    return self.component:createButton(self:update_parameter(p))
end

---@class herbert.MCM.new_slider.params : herbert.MCM.new_setting.params
---@field min integer? minimum value for the slider
---@field max integer? maximum value for the slider
---@field step integer? step value to use for the slider
---@field jump integer? jump value to use for the slider

-- make a new slider
---@param p herbert.MCM.new_slider.params
---@return mwseMCMSlider
function SC:new_slider(p)
    return self.component:createSlider(self:update_parameter(p))
end

---@class herbert.MCM.new_dslider.params : herbert.MCM.new_slider.params
---@field dp integer? number of decimal places

-- make a new decimal slider
---@param p herbert.MCM.new_dslider.params
---@return mwseMCMDecimalSlider
function SC:new_dslider(p)
    return self.component:createDecimalSlider(self:update_parameter(p))
end


-- make a percentage slider. this is basically a decimal slider, but the value will display as an integer while the value will be stored in the config as a decimal number.
---@param p herbert.MCM.new_slider.params
function SC:new_pslider(p)
    return self.component:createPercentageSlider(self:update_parameter(p))
end

local function parse_option(index, option)
    if type(option) == "string" then
        return {label=option, value=index}
    elseif type(option) == "table" then
        if option.label ~= nil then
            return option
        else
            return {label=option[1], value=option[2]}
        end
    end
end

function SC:update_dropdown_options(p)
    self:update_parameter(p)
    p.options = p.options and table.copy(p.options) or {}
    for i=1, #p do
        table.insert(p.options, i, p[i])
        p[i] = nil
    end
    p.options = table.map(p.options, parse_option)
end

---@class herbert.MCM.new_dropdown.params : herbert.MCM.new_setting.params
---@field options nil|(string|mwseMCMDropdownOption|(string|number)[])[] options for this setting. 
--- each `option` can be any of the following:
--- 1) a `table` of the form {label=label, value=value}
--- 2) a `table` of the form {label, value}
--- 3) a `string`. in this case, `option` will be its index in the `options` array, and `label` will be the value of this string.

-- add a dropdown menu to the component.
--- each `option` can be any of the following:
--- 1) a `table` of the form `{label="label", value="value"}`
--- 2) a `table` of the form `{"label", "value"}`
--- 3) a `string`. in this case, `option` will be its index in the `options` array, and `label` will be the value of this string.
---@param p herbert.MCM.new_dropdown.params
---@return mwseMCMDropdown
function SC:new_dropdown(p)
    self:update_dropdown_options(p)
    return self.component:createDropdown(p)
end

---@class herbert.MCM.new_textfield.params : herbert.MCM.new_setting.params
---@field numeric boolean? should this setting only display numbers? if this is true and a converter isnt passed, then the converter will default to `tonumber`

-- add a textfield to the component
---@param p herbert.MCM.new_textfield.params
---@return mwseMCMTextField
function SC:new_textfield(p)
    if p.numeric and not p.converter then
        p.converter = tonumber
    end
    self:update_parameter(p)
    return self.component:createTextField(p)
end


-- make a new category
---@param p herbert.MCM.new_component.params
---@return herbert.MCM.Setting_Creator
function SC:new_category(p)
    return SC.new{
        config = p.config or self.config,
        parent_comp = self.component,
        type = "category",
        desc = self:get_description(p),
        i18n = self.i18n,
        i18n_prefix = self.id,
        id = p.id,
        label = p.label,
    }
end

return SC