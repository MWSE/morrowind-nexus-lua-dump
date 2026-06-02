--[[
ErnPerkFramework for OpenMW.
Copyright (C) 2026 See AUTHORS.txt

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
local interfaces = require("openmw.interfaces")
local ui = require('openmw.ui')
local vfs = require('openmw.vfs')
local util = require('openmw.util')
local core = require("openmw.core")
local localization = core.l10n(MOD_NAME)
local myui = require('scripts.ErnPerkFramework.pcp.myui')

local PerkFunctions = {}
PerkFunctions.__index = PerkFunctions

-- ============================================================
--  TEXT SANITIZATION
--
--  sanitizeText() must be called on EVERY string before it is
--  assigned to a UI text widget.  It strips characters that are
--  safe in Lua string literals but cause MyGUI's text renderer
--  to hard-crash the game:
--
--   \f (form-feed, ASCII 12) - used as a page-break sentinel in
--      description strings; paginateDescription() should already
--      have split these out, but this is a defensive last resort.
--
--  Add any additional control characters here as they are found.
-- ============================================================

local function sanitizeText(text)
    if type(text) ~= "string" then
        text = tostring(text or "")
    end
    -- Strip form-feed characters (page-break sentinels that must
    -- never reach a text widget).
    -- NOTE: string.gsub returns (result, count). The outer parentheses
    -- discard the count so callers always receive exactly one value.
    -- Without this, table.insert(pages, sanitizeText(x)) expands to
    -- table.insert(pages, str, count) which errors: "number expected".
    return (text:gsub("\f", ""))
end

local DETAIL_TEXT_WIDTH = 500

-- Reduced from 24 to 16 to keep the requirements section compact.
-- Multi-branch faction orGroup names can get long; the smaller height
-- prevents the requirements block from dominating the panel.
local REQUIREMENT_LINE_HEIGHT = 16

local REQUIREMENT_CHARS_PER_LINE = 58

-- Height of the main description text area.
-- Pagination (see perkpage.lua) splits descriptions longer than
-- DESCRIPTION_PAGE_SIZE characters across multiple pages, so this
-- fixed height is generally sufficient for a single page.
local DESCRIPTION_TEXT_HEIGHT = 210

-- Minimum height (px) reserved for the flavour text block so that a
-- very short flavour string still has some breathing room.
-- The actual height is calculated dynamically via wrappedTextHeight()
-- so long flavour strings (e.g. EEC's multi-sentence treasury text)
-- are never clipped.
local FLAVOUR_TEXT_MIN_HEIGHT = 20

local ART_SIZE = util.vector2(224, 112)

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

local function wrappedTextHeight(text, charsPerLine, lineHeight)
    local lineCount = 0
    text = tostring(text or "")
    for line in (text .. "\n"):gmatch("(.-)\n") do
        lineCount = lineCount + math.max(1, math.ceil(#line / charsPerLine))
    end
    return lineCount * lineHeight
end

-- ============================================================
--  REQUIREMENT TEXT FORMATTING
--
--  The ErnPerkFramework builds orGroup requirement strings using
--  the localization list_join / list_join_or keys, producing text
--  like "A, B or C".  For faction rank requirements, each item is
--  "{factionName} {rankName}".
--
--  Multi-branch guild requirements (e.g. Mages Guild + TR Skyrim/
--  Cyrodiil/Hammerfell branches) appear as:
--    "Mages Guild Evoker, Skyrim Mages Guild Evoker,
--     Cyrodiil Mages Guild Evoker or Hammerfell Mages Guild Evoker"
--
--  Mixed-faction orGroups (e.g. Imperial Cult + Itinerant Priests)
--  appear as:
--    "Imperial Cult Layman, Order of Itinerant Priests Mendicant"
--
--  formatRequirement() detects which case it is and reformats:
--    - Same rank + common guild core  -
--        "Mages Guild Evoker in: Morrowind, Skyrim, Cyrodiil or Hammerfell"
--    - Different ranks or no common core -
--        "Imperial Cult Layman or Order of Itinerant Priests Mendicant"
-- ============================================================

--- Splits a localised orList string ("A, B or C") into its parts.
--- Normalises " or " to ", " first so both separators are handled
--- uniformly, regardless of how the mod author built the list.
local function splitOrList(text)
    -- Replace all " or " with ", " so we have a single separator
    local normalized = text:gsub(" or ", ", ")
    local parts = {}
    for part in (normalized .. ","):gmatch("([^,]+),") do
        local trimmed = part:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            table.insert(parts, trimmed)
        end
    end
    return parts
end

--- Returns the longest word-sequence from the END shared by all
--- strings in the list, or nil if there is no common suffix.
--- Used to identify the "core guild name" across regional branches.
local function commonWordSuffix(strings)
    -- Split each string into words
    local wordLists = {}
    for _, s in ipairs(strings) do
        local words = {}
        for w in s:gmatch("%S+") do table.insert(words, w) end
        table.insert(wordLists, words)
    end

    local first = wordLists[1]
    -- Try suffix lengths from longest to shortest
    for suffixLen = #first, 1, -1 do
        -- Build the candidate suffix from the first string
        local suffix = {}
        for i = #first - suffixLen + 1, #first do
            table.insert(suffix, first[i])
        end
        local suffixStr = table.concat(suffix, " ")

        local allMatch = true
        for _, words in ipairs(wordLists) do
            if #words < suffixLen then
                allMatch = false
                break
            end
            local tail = {}
            for i = #words - suffixLen + 1, #words do
                table.insert(tail, words[i])
            end
            if table.concat(tail, " ") ~= suffixStr then
                allMatch = false
                break
            end
        end

        if allMatch then
            return suffixStr
        end
    end

    return nil  -- no common suffix found
end

--- Formats a requirement display string for compact presentation.
---
--- If the text contains multiple faction rank requirements that share
--- the same rank and a common guild name core, they are collapsed to:
---   "Guild Rank in: Morrowind, Skyrim, Cyrodiil or Hammerfell"
--- (the base/default faction branch is always labelled "Morrowind").
---
--- If the parts are genuinely different factions (different ranks or no
--- shared guild core), they are joined with " or ":
---   "Imperial Cult Layman or Order of Itinerant Priests Mendicant"
---
--- Single-item strings are returned unchanged.
local function formatRequirement(text)
    local parts = splitOrList(text)

    -- Single item: nothing to reformat
    if #parts <= 1 then
        return text
    end

    -- Extract the last word (rank name) and the preceding words (guild name)
    -- from each part.  e.g. "Skyrim Mages Guild Evoker" - guild="Skyrim Mages Guild", rank="Evoker"
    local ranks      = {}
    local guildNames = {}
    for _, part in ipairs(parts) do
        local guild, rank = part:match("^(.+)%s+(%S+)$")
        if rank then
            table.insert(ranks,      rank)
            table.insert(guildNames, guild)
        else
            -- Single-word entry - treat the whole thing as the rank
            table.insert(ranks,      part)
            table.insert(guildNames, "")
        end
    end

    -- If ranks differ, these are genuinely different factions; join with "or"
    for _, rank in ipairs(ranks) do
        if rank ~= ranks[1] then
            return table.concat(parts, " or ")
        end
    end

    -- Same rank across all parts: look for a shared guild name core
    local coreGuild = commonWordSuffix(guildNames)
    if not coreGuild or coreGuild == "" then
        -- No common core: different factions that happen to share a rank name
        return table.concat(parts, " or ")
    end

    -- Build region labels by stripping the core guild name from each guild string.
    -- An empty prefix means this IS the base/default (Morrowind) faction.
    local regions = {}
    for _, guildName in ipairs(guildNames) do
        local prefix
        if guildName == coreGuild then
            prefix = "Morrowind"
        else
            -- Remove the core suffix (e.g. "Skyrim Mages Guild" - "Skyrim")
            prefix = guildName:sub(1, #guildName - #coreGuild)
            prefix = prefix:match("^%s*(.-)%s*$")
            if prefix == "" then prefix = "Morrowind" end
        end
        table.insert(regions, prefix)
    end

    -- Build the region list string: "Morrowind, Skyrim, Cyrodiil or Hammerfell"
    local regionStr
    if #regions == 1 then
        regionStr = regions[1]
    elseif #regions == 2 then
        regionStr = regions[1] .. " or " .. regions[2]
    else
        local allButLast = {}
        for i = 1, #regions - 1 do
            table.insert(allButLast, regions[i])
        end
        regionStr = table.concat(allButLast, ", ") .. " or " .. regions[#regions]
    end

    -- "Mages Guild Evoker in: Morrowind, Skyrim, Cyrodiil or Hammerfell"
    return coreGuild .. " " .. ranks[1] .. " in: " .. regionStr
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
---
--- Pagination note: in perkpage.lua, long descriptions are automatically split
--- into pages of ~DESCRIPTION_PAGE_SIZE characters.  You can also insert a form-feed
--- character (\f) anywhere in the description string to force an explicit page break
--- at that point, giving you full control over what appears on each page.
---
--- @param self table The perk object.
--- @return string The perk's description.
function PerkFunctions.description(self)
    local description = self.record.id .. " description"
    if self.record.localizedDescription ~= nil then
        description = resolve(self.record.localizedDescription)
    end
    return description
end

--- Gets the optional flavour text of the perk.
--- Flavour text is a short, lore-flavoured sentence displayed above the mechanical
--- description.  It is purely cosmetic and entirely optional; perks that do not
--- supply it simply omit that block from the detail panel with no ill effect.
---
--- Both "localizedFlavour" and "localizedFlavor" spellings are accepted.
--- Returns nil when absent or empty, so callers can safely nil-check it.
---
--- @param self table The perk object.
--- @return string|nil The perk's flavour text, or nil if none was provided.
function PerkFunctions.flavour(self)
    local flavour = self.record.localizedFlavour
    if flavour == nil then
        flavour = self.record.localizedFlavor
    end
    if flavour ~= nil then
        flavour = resolve(flavour)
    end
    if flavour == "" then
        flavour = nil
    end
    return flavour
end

--- Gets the category of the perk, or nil if none was specified.
--- Returns the raw 3-element table { typeName, groupName, sortOrder }.
--- @param self table The perk object.
--- @return table|nil The category table, or nil.
function PerkFunctions.category(self)
    return self.record.category
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
            size = ART_SIZE,
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
            autoSize = false,
            size = util.vector2(DETAIL_TEXT_WIDTH + 8, ART_SIZE.y),
        },
        external = { grow = 0 },
        content = ui.content { img }
    }
end

--- Creates the UI layout for the perk's requirements list.
--- Displays localized requirement names, colored red if unsatisfied.
--- Hidden requirements that are not satisfied are displayed as a generic "hiddenRequirement" string.
--- Requirements use a compact line height to prevent long orGroup faction names
--- (e.g. multi-branch TR guilds) from dominating the panel.
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
        -- Format the requirement text for compact display.
        -- Multi-branch guild chains (e.g. TR regional Mages Guild branches)
        -- are collapsed to "Guild Rank in: Morrowind, Skyrim, Cyrodiil or Hammerfell".
        -- Genuinely different factions are joined with " or ".
        local displayText = formatRequirement(req.name)
        local reqLayout = {
            template = interfaces.MWUI.templates.textParagraph,
            --type = ui.TYPE.Text,
            alignment = ui.ALIGNMENT.End,
            props = {
                autoSize = false,
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Start,
                textAlignV = ui.ALIGNMENT.Start,
                text = displayText,
            },
        }
        if not req.satisfied then
            reqLayout.props.textColor = myui.textColors.negative
        end

        local hide = resolve(req.hidden)
        if hide then
            reqLayout.props.text = localization("hiddenRequirement", {})
        end
        reqLayout.props.size = util.vector2(
            DETAIL_TEXT_WIDTH,
            wrappedTextHeight(reqLayout.props.text, REQUIREMENT_CHARS_PER_LINE, REQUIREMENT_LINE_HEIGHT))

        vFlexLayout.content:add(reqLayout)
    end

    -- put in <None> if no elements
    if #(vFlexLayout.content) == 0 then
        local reqLayout = {
            template = interfaces.MWUI.templates.textParagraph,
            --type = ui.TYPE.Text,
            alignment = ui.ALIGNMENT.End,
            props = {
                autoSize = false,
                multiline = true,
                wordWrap = true,
                textAlignH = ui.ALIGNMENT.Start,
                textAlignV = ui.ALIGNMENT.Start,
                --relativePosition = util.vector2(0, 0.5),
                text = localization("noRequirement", {}),
            },
        }
        reqLayout.props.size = util.vector2(
            DETAIL_TEXT_WIDTH,
            wrappedTextHeight(reqLayout.props.text, REQUIREMENT_CHARS_PER_LINE, REQUIREMENT_LINE_HEIGHT))
        vFlexLayout.content:add(reqLayout)
    end

    local padded = {
        name = "vflex",
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Start,
            horizontal = true,
            -- relativeSize width=1 propagates a concrete pixel width down to
            -- the text widgets inside, which is what makes word-wrap work.
            relativeSize = util.vector2(1, 0),
        },
        content = ui.content {
            myui.padWidget(8, 0),
            vFlexLayout
        },
    }

    return padded
end

--- Creates the full detail UI layout for the perk.
---
--- Panel order (top to bottom):
---   1. Art image
---   2. "Requirements" header + requirements list
---   3. Flavour text block  (OPTIONAL - omitted entirely when nil, so perks
---      that do not define localizedFlavour/localizedFlavor are unaffected)
---   4. Perk name header
---   5. Description text   (may be paginated; descriptionText receives the
---      current page's text from perkpage.lua's selectedDescriptionText())
---
--- Flavour text is rendered in a muted colour and wrapped in curly quotes to
--- visually distinguish it from the mechanical description below.
---
--- @param self table The perk object.
--- @param descriptionText string|nil The (possibly paginated) description to show,
---   or nil to fall back to the full self:description() string.
--- @return table The OpenMW UI layout table for the perk details panel.
function PerkFunctions.detailLayout(self, descriptionText)
    local vFlexLayout = {
        name = "detailLayout",
        type = ui.TYPE.Flex,
        props = {
            arrange      = ui.ALIGNMENT.Start,
            horizontal   = false,
            autoSize     = false,
            -- relativeSize(1,1): fills the top content section, which has a
            -- concrete pixel size from grow=1 on its parent. This gives all
            -- text children a concrete pixel width for word-wrap, and a
            -- concrete height so the art widget and description are visible.
            relativeSize = util.vector2(1, 1),
        },
        external = {
            grow = 1,
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

    -- ----------------------------------------------------------------
    -- FLAVOUR TEXT (optional)
    -- Only constructed when localizedFlavour / localizedFlavor is set.
    -- Rendered in a muted notify colour with plain ASCII double-quote
    -- wrapping.  We deliberately avoid \u{...} Unicode escapes here:
    -- multi-byte UTF-8 literals can crash MyGUI's text renderer on
    -- some OpenMW builds.  Plain ASCII quotes are safe everywhere.
    -- Perks without flavour text skip this block entirely; no empty
    -- space is reserved.
    -- ----------------------------------------------------------------
    local flavourText = self:flavour()
    local paddedFlavourText = nil
    if flavourText ~= nil then
        -- Wrap in plain ASCII double-quotes for a lore-quote aesthetic.
        -- sanitizeText() strips any control characters that would crash MyGUI.
        local quotedFlavour = '"' .. sanitizeText(flavourText) .. '"'
        -- Calculate the height dynamically so long flavour strings are never
        -- clipped.  wrappedTextHeight() counts wrapped lines using the same
        -- chars-per-line constant as the requirements list.
        local flavourHeight = math.max(
            FLAVOUR_TEXT_MIN_HEIGHT,
            wrappedTextHeight(quotedFlavour, REQUIREMENT_CHARS_PER_LINE, REQUIREMENT_LINE_HEIGHT))
        paddedFlavourText = {
            name = "flavourText",
            type = ui.TYPE.Flex,
            props = {
                arrange = ui.ALIGNMENT.Start,
                horizontal = true,
                relativeSize = util.vector2(1, 0),
            },
            content = ui.content {
                myui.padWidget(8, 0),
                {
                    template = interfaces.MWUI.templates.textParagraph,
                    alignment = ui.ALIGNMENT.Start,
                    props = {
                        autoSize = false,
                        multiline = true,
                        wordWrap = true,
                        textAlignH = ui.ALIGNMENT.Start,
                        textAlignV = ui.ALIGNMENT.Start,
                        -- Muted notify colour gives a visually distinct
                        -- "flavour" feel separate from the mechanical text.
                        textColor = myui.textColors.notify,
                        text = quotedFlavour,
                        size = util.vector2(DETAIL_TEXT_WIDTH, flavourHeight),
                    },
                }
            },
        }
    end

    -- ----------------------------------------------------------------
    -- DESCRIPTION TEXT
    -- descriptionText is supplied by perkpage.lua's selectedDescriptionText(),
    -- which returns the correct page of a potentially paginated description.
    -- Falls back to the full description string when called outside that context.
    -- sanitizeText() is applied in BOTH paths: the caller should never pass
    -- raw \f characters, but this is a hard guarantee against MyGUI crashes.
    -- ----------------------------------------------------------------
    local paddedDetailText = {
        name = "vflex",
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Start,
            horizontal = true,
            -- Width propagation: needed so the inner text widget wraps.
            relativeSize = util.vector2(1, 0),
        },
        content = ui.content {
            myui.padWidget(8, 0),
            {
                template = interfaces.MWUI.templates.textParagraph,
                alignment = ui.ALIGNMENT.Start,
                props = {
                    autoSize = false,
                    multiline = true,
                    wordWrap = true,
                    textAlignH = ui.ALIGNMENT.Start,
                    textAlignV = ui.ALIGNMENT.Start,
                    text = sanitizeText(descriptionText or self:description()),
                    size = util.vector2(DETAIL_TEXT_WIDTH, DESCRIPTION_TEXT_HEIGHT),
                },
            }
        },
    }

    vFlexLayout.content:add(self:artLayout())
    vFlexLayout.content:add(myui.padWidget(0, 2))
    vFlexLayout.content:add(requirementsHeader)
    vFlexLayout.content:add(self:requirementsLayout())
    vFlexLayout.content:add(myui.padWidget(0, 2))
    -- Add flavour text block only when it was provided
    if paddedFlavourText ~= nil then
        vFlexLayout.content:add(paddedFlavourText)
        vFlexLayout.content:add(myui.padWidget(0, 2))
    end
    vFlexLayout.content:add(nameHeader)
    vFlexLayout.content:add(paddedDetailText)

    return vFlexLayout
end

return {
    NewPerk = NewPerk
}
