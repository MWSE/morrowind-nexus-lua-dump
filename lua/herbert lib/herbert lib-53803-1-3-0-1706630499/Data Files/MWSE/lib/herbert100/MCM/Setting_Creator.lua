---@class herbert.MCM.new_component.params
---@field label string? label of this component
---@field desc string? description for this component
---@field config table? new config to use for this component. if not passed, it will be inherited from its parent
---@field id string|integer? i18n index of the relevant table


-- an entry in the `layout` that we're going to define below
---@class herbert.MCM.new_setting.params : herbert.MCM.new_component.params
---@field callback fun(self:mwseMCMSetting)? callback to use when the setting is updated
---@field id string|integer config/i18n index of relevant setting
---@field converter nil|fun(new_value:unknown):unknown converter for variable
---@field restart boolean? is a restart required?


---@alias herbert.MCM.container_type "page"|"sidebar_page"|"category"

---@class herbert.MCM.Setting_Creator.new_params : herbert.MCM.new_component.params
---@field config table config to manage
---@field i18n nil|fun(string, ...): string i18n translator
---@field i18n_prefix string?
---@field type herbert.MCM.container_type
---@field parent_comp mwseMCMPage|mwseMCMSideBarPage|mwseMCMCategory|mwseMCMTemplate





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
---@return string
function SC:get_label(p)
    if not p then
        if self.i18n and self.id then
            return self.i18n(string.format("%s.label", self.id)) 
        end
        error(string.format("No label found for component %s", self.id))
    end
    if p.label then 
        return p.label 
    end

    if self.i18n and self.id then
        return self.i18n(string.format("%s.%s.label", self.id, p.id))
    end
    error(string.format("No label found for setting %q in component %s", p.id, self.id))
end

---@param p herbert.MCM.new_component.params?
---@return string?
function SC:get_description(p)
    if not p then
        if self.i18n and self.id then
            return self.i18n(string.format("%s.description", self.id))
                or self.i18n(string.format("%s.desc", self.id))
        end
        return
    end
    if p.desc then 
        return p.desc 
    end

    if self.i18n and self.id then
        return self.i18n(string.format("%s.%s.description", self.id, p.id)) 
            or self.i18n(string.format("%s.%s.desc", self.id, p.id))
    end
end

---@param mod_name string? if not provided, the name of the MCM template will be used.
function SC:add_log_settings(mod_name)
    if type(mod_name) ~= "string" then
        local parent_comp = self.component---@type mwseMCMComponent

        ---@diagnostic disable-next-line: need-check-nil
        while parent_comp.parentComponent ~= nil and parent_comp.componentType ~= "Template" do
            parent_comp = parent_comp.parentComponent
        end

        mod_name = parent_comp and (parent_comp.name or parent_comp.label)
    end

    local log = require("herbert100.logger").new{mod_name=mod_name}
    return log:add_to_MCM{component=self.component, config=self.config}
end

-- make a new variable
---@param id string|integer id of the setting
---@param config table? config to use (if different from the one that's already stored)
---@param converter fun(new_value:unknown):unknown a converter to use for this setting
---@return mwseMCMVariable
function SC:new_variable(id, config, converter)
    return mwse.mcm.createTableVariable{ id=id, table=config or self.config, converter=converter }
end

-- make a new Yes/No button
---@param p herbert.MCM.new_setting.params
---@return mwseMCMYesNoButton
function SC:new_button(p)
    return self.component:createYesNoButton{
        label=self:get_label(p), 
        description=self:get_description(p),
        variable=self:new_variable(p.id, p.config, p.converter),
        callback=p.callback, 
        restartRequired=p.restart,
    }
end

---@class herbert.MCM.new_callback_button.params : herbert.MCM.new_setting.params
---@field btn_text string? text to use for the button

-- make a new callback button, with customizable text
---@param p herbert.MCM.new_callback_button.params
---@return mwseMCMButton
function SC:new_callback_button(p)
    return self.component:createButton{
        label=self:get_label(p), 
        description=self:get_description(p),
        callback=p.callback, 
        buttonText=p.btn_text,
        restartRequired=p.restart,
    }
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
    return self.component:createSlider{ 
        label=self:get_label(p), 
        description=self:get_description(p), 
        callback=p.callback,
        variable=self:new_variable(p.id, p.config, p.converter),
        min=p.min, 
        max=p.max, 
        step=p.step,
        jump=p.jump, 
        restartRequired=p.restart,
    }
end

---@class herbert.MCM.new_dslider.params : herbert.MCM.new_slider.params
---@field dp integer? number of decimal places

-- make a new decimal slider
---@param p herbert.MCM.new_dslider.params
---@return mwseMCMDecimalSlider
function SC:new_dslider(p)
    return self.component:createDecimalSlider{ 
        label=self:get_label(p),
        description=self:get_description(p),
        callback=p.callback,
        variable=self:new_variable(p.id, p.config, p.converter),
        min=p.min, 
        max=p.max,
        step=p.step, 
        jump=p.jump, 
        decimalPlaces=p.dp,
        restartRequired=p.restart,
    }
end

-- used internally to make new percentage variables
local function make_new_percentage_variable(cfg, k, converter)
    return mwse.mcm.createCustom{
        converter=converter,
        getter=function () return math.floor(cfg[k] * 100) end,
        setter=function (_, newValue) cfg[k] = newValue / (100) end
    }
end

-- make a percentage slider. this is basically a decimal slider, but the value will display as an integer while the value will be stored in the config as a decimal number.
---@param p herbert.MCM.new_slider.params
function SC:new_pslider(p)
    local label = self:get_label(p)
    return self.component:createSlider{
        label = label:find("%s", 1, true) and label or label .. ": %s%%",
        description = self:get_description(p), 
        callback = p.callback,
        min = p.min and math.floor(p.min * 100),
        max = p.max and math.floor(p.max * 100),
        step = p.step and math.floor(p.step * 100),
        jump = p.jump and math.floor(p.jump * 100),
        variable = make_new_percentage_variable(p.config or self.config, p.id, p.converter),
        restartRequired=p.restart,
    }
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
    local options = {} ---@type mwseMCMDropdownOption[]
    local p_options = p[1] and p or p.options

    for i, option in ipairs(p_options) do
        local label, value
        if type(option) == "string" then
            label, value = option, i
        elseif type(option) == "table" then
            if option.label ~= nil then
                label, value = option.label, option.value
            else
                label, value = table.unpack(option)
            end
        else
            error("invalid option was passed.")
        end
        options[i] = {label=label, value=value or i}
    end
    return self.component:createDropdown{ 
        label=self:get_label(p), 
        description=self:get_description(p), 
        callback=p.callback,
        options=options,
        variable=self:new_variable(p.id, p.config, p.converter), 
        restartRequired=p.restart,
    }
end

---@class herbert.MCM.new_textfield.params : herbert.MCM.new_setting.params
---@field numeric boolean? should this setting only display numbers? if this is true and a converter isnt passed, then the converter will default to `tonumber`

-- add a textfield to the component
---@param p herbert.MCM.new_textfield.params
---@return mwseMCMTextField
function SC:new_textfield(p)
    local converter = p.converter or p.numeric and tonumber
    return self.component:createTextField{
        label=self:get_label(p), 
        description=self:get_description(p), 
        callback=p.callback,
        variable=self:new_variable(p.id, p.config, converter), 
        numbersOnly=p.numeric,
        restartRequired=p.restart,
    }
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