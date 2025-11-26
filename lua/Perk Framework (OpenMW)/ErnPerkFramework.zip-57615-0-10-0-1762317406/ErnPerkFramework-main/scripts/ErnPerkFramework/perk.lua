--[[
ErnPerkFramework for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local MOD_NAME = require("scripts.ErnPerkFramework.settings").MOD_NAME
local pself = require("openmw.self")
local interfaces = require("openmw.interfaces")
local ui = require('openmw.ui')
local vfs = require('openmw.vfs')
local util = require('openmw.util')
local core = require("openmw.core")
local localization = core.l10n(MOD_NAME)
local myui = require('scripts.ErnPerkFramework.pcp.myui')

local PerkFunctions = {}
PerkFunctions.__index = PerkFunctions

--- Resolves a field that might be a literal value or a function that returns a value.
--- @param field any A literal value or a function.
--- @return any The value of the field, or the return value of the function.
local function resolve(field)
    if type(field) == 'function' then
        return field()
    else
        return field
    end
end

--- NewPerk makes a new perk object from a record data table.
--- It attaches the PerkFunctions metatable.
--- @param data table The raw perk record data (must include id, requirements, onAdd, onRemove).
--- @return table A new perk object.
function NewPerk(data)
    local new = {
        added = false,
        record = data
    }
    setmetatable(new, PerkFunctions)
    return new
end

--- Calls the onAdd function defined in the perk record if the perk is not already added.
--- @param self table The perk object.
--- @return any The return value of the record's onAdd function.
function PerkFunctions.onAdd(self)
    if self.added then
        return
    end
    self.added = true
    return self.record.onAdd()
end

--- Calls the onRemove function defined in the perk record if the perk is currently added.
--- @param self table The perk object.
--- @return any The return value of the record's onRemove function.
function PerkFunctions.onRemove(self)
    if not self.added then
        return
    end
    self.added = false
    return self.record.onRemove()
end

--- Gets the localized name of the perk, falling back to the ID.
--- If `localizedName` in the record is a function, it's called to get the name.
--- @param self table The perk object.
--- @return string The perk's name.
function PerkFunctions.name(self)
    local name = self.record.id
    if self.record.localizedName ~= nil then
        name = resolve(self.record.localizedName)
    end
    return name
end

--- Gets the unique identifier (ID) of the perk.
--- @param self table The perk object.
--- @return string The perk's ID.
function PerkFunctions.id(self)
    return self.record.id
end

--- Gets the cost of the perk, defaulting to 1.
--- If `cost` in the record is a function, it's called to get the cost.
--- @param self table The perk object.
--- @return number The perk's cost, floored to an integer.
function PerkFunctions.cost(self)
    local cost = 1
    if self.record.cost ~= nil then
        cost = resolve(self.record.cost)
    end
    return math.floor(cost)
end

--- Determines if the perk should normally appear in the perk window or not.
--- Defaults to false.
--- If `hidden` in the record is a function, it's called to get the cost.
--- @param self table The perk object.
--- @return number A boolean indicating if the perk should normally be hidden.
function PerkFunctions.hidden(self)
    local hide = false
    if self.record.hidden ~= nil then
        hide = resolve(self.record.hidden)
    end
    return hide
end

--- Gets the localized description of the perk, falling back to a default string.
--- If `localizedDescription` in the record is a function, it's called to get the description.
--- @param self table The perk object.
--- @return string The perk's description.
function PerkFunctions.description(self)
    local description = self.record.id .. " description"
    if self.record.localizedDescription ~= nil then
        description = resolve(self.record.localizedDescription)
    end
    return description
end

-- Returns true if the player currently has the perk.
--- @return boolean Whether the player has the perk.
function PerkFunctions.active(self)
    -- TODO: maybe cache this
    for _, foundID in ipairs(interfaces.ErnPerkFramework.getPlayerPerks()) do
        if foundID == self:id() then
            return true
        end
    end
    return false
end

--- Evaluates all requirements for the perk.
--- @param self table The perk object.
--- @return table A table with two fields:
--- * `requirements`: a list of requirement info tables (with fields id, name, satisfied, hidden).
--- * `satisfied`: a boolean, true if all requirements are met.
function PerkFunctions.evaluateRequirements(self)
    local reqs = {}
    local allMet = true
    for i, r in ipairs(self.record.requirements) do
        local satisfied = r.check()
        if not satisfied then
            allMet = false
        end
        local name = r.id
        if r.localizedName ~= nil then
            name = resolve(r.localizedName)
        end
        local hide = resolve(r.hidden)

        table.insert(reqs, { id = r.id, name = name, satisfied = satisfied, hidden = (hide and (not satisfied)) })
    end

    -- sort reqs by name
    table.sort(reqs, function(a, b) return string.lower(a.name) < string.lower(b.name) end)

    return {
        requirements = reqs,
        satisfied = allMet,
    }
end

--- Creates the UI layout for the perk's art/icon.
--- Uses a default placeholder if no art is specified or found.
--- @param self table The perk object.
--- @return table The OpenMW UI layout table for the perk art.
function PerkFunctions.artLayout(self)
    -- These texture dimensions are derived from the Class icon textures.
    -- That way people that don't want to make art can just supply "archer"
    -- or whatever and it will fit.
    local path = "textures\\perk_placeholder"
    if self.record.art ~= nil then
        path = resolve(self.record.art)
    end

    if not vfs.fileExists(path) then
        for p in vfs.pathsWithPrefix(path) do
            path = p
            break
        end
    end
    if not vfs.fileExists(path) then
        error("can't find path to art for perk " .. tostring(self:id() .. ": " .. path))
    end

    local img = {
        type = ui.TYPE.Image,
        alignment = ui.ALIGNMENT.Center,
        template = interfaces.MWUI.templates.borders,
        props = {
            resource = ui.texture {
                path = path
            },
            size = util.vector2(256, 128),
            relativePosition = util.vector2(0.5, 0),
            anchor = util.vector2(0.5, 0),
        },
        external = {
            grow = 0,
        }
        --size = util.vector2(256, 128)
        --relativeSize = util.vector2(1, 0.3),
    }

    return {
        type = ui.TYPE.Widget,
        props = {
            arrange = ui.ALIGNMENT.Center,
            relativeSize = util.vector2(1, 0),
            size = util.vector2(0, 128),
        },
        external = { grow = 0 },
        content = ui.content { img }
    }
end

--- Creates the UI layout for the perk's requirements list.
--- Displays localized requirement names, colored red if unsatisfied.
--- Hidden requirements that are not satisfied are displayed as a generic "hiddenRequirement" string.
--- @param self table The perk object.
--- @return table The OpenMW UI layout table for the requirements list.
function PerkFunctions.requirementsLayout(self)
    local vFlexLayout = {
        name = "vflex",
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Start,
            horizontal = false,
            relativeSize = util.vector2(1, 0),
        },
        content = ui.content {},
    }

    local reqs = self:evaluateRequirements()

    for i, req in ipairs(reqs.requirements) do
        local reqLayout = {
            template = interfaces.MWUI.templates.textParagraph,
            --type = ui.TYPE.Text,
            alignment = ui.ALIGNMENT.End,
            props = {
                textAlignH = ui.ALIGNMENT.Start,
                textAlignV = ui.ALIGNMENT.Start,
                --relativePosition = util.vector2(0, 0.5),
                text = req.name,
                relativeSize = util.vector2(1, 0),
            },
        }
        if not req.satisfied then
            reqLayout.props.textColor = myui.textColors.negative
        end

        local hide = resolve(req.hidden)
        if hide then
            reqLayout.props.text = localization("hiddenRequirement", {})
        end

        vFlexLayout.content:add(reqLayout)
    end

    -- put in <None> if no elements
    if #(vFlexLayout.content) == 0 then
        local reqLayout = {
            template = interfaces.MWUI.templates.textParagraph,
            --type = ui.TYPE.Text,
            alignment = ui.ALIGNMENT.End,
            props = {
                textAlignH = ui.ALIGNMENT.Start,
                textAlignV = ui.ALIGNMENT.Start,
                --relativePosition = util.vector2(0, 0.5),
                text = localization("noRequirement", {}),
                relativeSize = util.vector2(1, 0),
            },
        }
        vFlexLayout.content:add(reqLayout)
    end

    local padded = {
        name = "vflex",
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Start,
            horizontal = true,
            --relativeSize = util.vector2(1, 1),
        },
        content = ui.content {
            myui.padWidget(8, 0),
            vFlexLayout
        },
    }

    return padded
end

--- Creates the full detail UI layout for the perk, including art, requirements, name, and description.
--- @param self table The perk object.
--- @return table The OpenMW UI layout table for the perk details panel.
function PerkFunctions.detailLayout(self)
    local vFlexLayout = {
        name = "detailLayout",
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Start,
            horizontal = false,
            autoSize = false,
            relativeSize = util.vector2(1, 1),
            anchor = util.vector2(0.5, 0),
            relativePosition = util.vector2(0.5, 0),
        },
        external = {
            grow = 1,
            --stretch = 1
        },
        content = ui.content {},
    }

    local requirementsHeader = {
        template = interfaces.MWUI.templates.textHeader,
        type = ui.TYPE.Text,
        alignment = ui.ALIGNMENT.Start,
        props = {
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
            --relativePosition = util.vector2(0, 0.5),
            text = localization("requirements", {}),
        },
    }

    local nameHeader = {
        template = interfaces.MWUI.templates.textHeader,
        type = ui.TYPE.Text,
        alignment = ui.ALIGNMENT.Start,
        props = {
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
            --relativePosition = util.vector2(0, 0.5),
            text = self:name(),
        },
    }

    local paddedDetailText = {
        name = "vflex",
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Start,
            horizontal = true,
            --relativeSize = util.vector2(1, 1),
        },
        content = ui.content {
            myui.padWidget(8, 0),
            {
                template = interfaces.MWUI.templates.textParagraph,
                --type = ui.TYPE.Text,
                alignment = ui.ALIGNMENT.Start,
                props = {
                    --autoSize = false,
                    --relativeSize = util.vector2(0, 1),
                    textAlignH = ui.ALIGNMENT.Start,
                    textAlignV = ui.ALIGNMENT.Start,
                    --relativePosition = util.vector2(0, 0.5),
                    text = self:description(),
                },
                external = {
                    grow = 1,
                    stretch = 1,
                }
            }
        },
        external = {
            grow = 1,
            stretch = 1,
        }
    }

    vFlexLayout.content:add(self:artLayout())
    vFlexLayout.content:add(myui.padWidget(0, 4))
    vFlexLayout.content:add(requirementsHeader)
    vFlexLayout.content:add(self:requirementsLayout())
    vFlexLayout.content:add(myui.padWidget(0, 4))
    vFlexLayout.content:add(nameHeader)
    vFlexLayout.content:add(paddedDetailText)

    return vFlexLayout
end

return {
    NewPerk = NewPerk
}
