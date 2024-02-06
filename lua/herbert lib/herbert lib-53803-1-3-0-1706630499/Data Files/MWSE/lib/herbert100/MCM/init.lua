
---@class herbert.MCM.new_params
---@field mod_name string name of the mod to make a menu for
---@field config table config of the mod in question
---@field keywords string[]|string? string of keywords to use when searching
---@field id string? subtable where all MCM settings are stored. default: "MCM"
---@field i18n fun(string, ...)? i18n translator
---@field closed fun()? function that happens whenever the MCM is closed

local function template_factory(self)
 return mwse.mcm.createTemplate{
        name = self.mod_name, 
        onClose = function ()
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
---@field new fun(p:herbert.MCM.new_params): herbert.MCM
local MCM = require("herbert100.Class").new{name="MCM",
    fields={
        {"mod_name"},
        {"config", tostring=json.encode},
        {"keywords", converter=keywords_converter},
        {"template", factory=template_factory},
        {"closed", default=function() end},
        {"id", default = "MCM"}
    },
}

function MCM:register()
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

return MCM