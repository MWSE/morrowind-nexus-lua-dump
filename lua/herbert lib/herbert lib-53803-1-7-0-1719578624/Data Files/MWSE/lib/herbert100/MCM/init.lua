local utils = require("herbert100.utils")
local logger = require("herbert100.logger").new{mod_name="herbert lib",mod_dir="lib/herbert100", file_path="MCM/init.lua"}


---@class herbert.MCM.new_params
---@field mod_name string? name of the mod to make a menu for
---@field config table? config of the mod in question
---@field keywords string[]|string? string of keywords to use when searching
---@field id string? subtable where all MCM settings are stored. default: "MCM"
---@field i18n fun(string, ...)? i18n translator
---@field closed fun()? function that happens whenever the MCM is closed

local function template_factory(self)
 return mwse.mcm.createTemplate{
        name = self.mod_name,
        onClose = function ()
            ---@type herbert.events.MCM_closed.data
            local payload = {mod_name = self.mod_name, MCM = self}
            payload = event.trigger("herbert:MCM_closed", payload, {filter=self.mod_name})
            
            if payload.block then return end 

            self.closed()
            mwse.saveConfig(self.mod_name, self.config)
        end,

        onSearch = self.keywords and function(searchText)
            return string.find(self.keywords, searchText, nil, true)
        end or nil,
    }
end

local function keywords_converter(keywords)
    if type(keywords) == "table" then
        return table.concat(keywords, " ")
    elseif type(keywords) == "string" then
        return keywords
    end
end

--- manages the MCM
---@class herbert.MCM : herbert.MCM.new_params, herbert.Class
---@field template mwseMCMTemplate? the template (made after object creation)
---@field new fun(p:herbert.MCM.new_params?): herbert.MCM
local MCM = require("herbert100.Class").new{name="MCM",
    fields={
        {"mod_name",},
        {"config", tostring=json.encode},
        {"keywords", converter=keywords_converter},
        {"template", factory=template_factory},
        {"closed", default=function() end},
        {"id", default = "MCM"}
    },
    init=function (self, ...)
        if self.mod_name and self.config then return end

        local info = utils.get_mod_info(1)
        if not info then
            logger:error("a mod tried to make an MCM, but it did not provide a mod name and config, and its mod information could not be loaded.")
            return
        end
        self.mod_name = self.mod_name or info.mod_name
        if not self.config then
            local cfg_path = info.mod_dir .. ".config"
            -- logger:info("trying to load config from %q", cfg_path)
            self.config = include(cfg_path)
        end
        if not self.mod_name or not self.config then
            logger:error("a mod tried to make an MCM, \z
                but it did not provide a mod name and config, and its mod information could not be loaded. \z
                mod information: %s", require("inspect"), info, {depth=2})
        end
    end,
    post_init=function (self)
        if tes3.isInitialized() then
            self.template:register()
        else
            event.register("modConfigReady",function() self.template:register() end, {doOnce=true})
        end
    end,
}
---@deprecated
function MCM.closed() end

function MCM:register()
    if true then return end
    self.template:register()
end



---@param p herbert.MCM.new_component.params
---@return herbert.MCM.Setting_Creator
function MCM:new_page(p)
    return require("herbert100.MCM.Setting_Creator").new{
        label = p.label,
        desc = p.desc,
        config = p.config or self.config,

        i18n = self.i18n,
        i18n_prefix = self.id,
        id = p.id,

        type = "page",
        parent_comp = self.template,
    }
end

---@param p herbert.MCM.new_component.params
---@return herbert.MCM.Setting_Creator
function MCM:new_sidebar_page(p)
    return require("herbert100.MCM.Setting_Creator").new{
        label = p.label,
        desc = p.desc,
        config = p.config or self.config,

        i18n = self.i18n,
        i18n_prefix = self.id,
        id = p.id,

        type = "sidebar_page",
        parent_comp = self.template,
    }
end


local function is_subset(t1, t2)
    for k in pairs(t1) do
        if t2[k] == nil then return false end
    end
    return true
end


-- finds a default value, given a config key
---@param var mwseMCMTableVariable
---@param def_tbl table
---@return string?
local function find_recursive(var, def_tbl)

    -- config table could have keys that are not in the default table.
    -- but, if it was loaded with `mwse.loadConfig`, then every key in `var.table` will be in `def_tbl`.
    if is_subset(def_tbl, var.table) then
        return def_tbl[var.id]
    end

    for _, def_val in pairs(def_tbl) do
        if type(def_val) == "table" then
            local res = find_recursive(var, def_val)
            if res ~= nil then 
                return res
            end
        end
    end
end

---@param comp mwseMCMSetting
---@param default_config table
local function add_default(comp, default_config)
    local var = comp.variable ---@cast var -nil

    -- only works for table variables
    if var.class ~= "TableVariable" then return end

    local default_val = find_recursive(var, default_config)

    if default_val ~= nil then
        local default_str = comp:convertToLabelValue(default_val)
        if comp.description == nil then
            comp.description = string.format("Default = %s", default_str)
        else
            comp.description = string.format("%s\n\nDefault = %s", comp.description, default_str)

        end
    end
end

---@param comp mwseMCMComponent|mwseMCMCategory|mwseMCMSetting|mwseMCMPage
---@param default_config table
local function recursive_add_defaults(comp, default_config)
    if comp.variable then
        add_default(comp, default_config)
    end
    if comp.componentType == "Category" or comp.componentType == "Page" then
        for _, sub_comp in ipairs(comp.components) do
            recursive_add_defaults(sub_comp, default_config)
        end
    end
end


-- recursive_add_defaults(page.component)

--- This will recursively go through your MCM and append the text "Default = ___" to the description of each setting.
---@param default_config table? the default config of your mod. if not provided, it will try to be retrieved, 
-- using the path "config.default"
function MCM:add_defaults_to_descriptions(default_config)
    if not default_config then
        local info = utils.get_mod_info(2)
        if info then
            default_config = include(info.mod_dir .. ".config.default")
        end
    end
    if not default_config then
        logger:error("default config could not be found! %s", debug.traceback)
    end
    for _, page in ipairs(self.template.pages) do
        recursive_add_defaults(page, default_config)
    end
end

return MCM