local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local async = require('openmw.async')

local filterText = ''

local function setFilterText(text)
        filterText = text
end

---@param spell Spell
---@return boolean
local function filterSpell(spell)
        if filterText == "" then
                return true
        end

        filterText = string.lower(filterText)
        local name = string.lower(spell.name)

        if string.find(name, filterText, 1, true) then
                return true
        end

        for i, effect in pairs(spell.effects) do
                if string.find(effect.id, filterText, 1, true) then
                        return true
                elseif effect.affectedAttribute and string.find(effect.affectedAttribute, filterText, 1, true) then
                        return true
                elseif effect.affectedSkill and string.find(effect.affectedSkill, filterText, 1, true) then
                        return true
                end
        end

        return false
end

local filteredList

---@param UIState UIState
---@return ui.Layout
local function createFilterBlock(UIState)
        local filterInput = {
                template = I.MWUI.templates.textEditLine,
                props = { text = filterText },
                events = {
                        textChanged = async:callback(function(newText, l)
                                -- filterText = newText
                                setFilterText(newText)
                                l.props.text = newText

                                UIState.allSpells.expTargetSize = 0

                                filteredList = {}

                                for i = 2, #UIState.allSpells.items do
                                        local el = UIState.allSpells.items[i]
                                        if filterSpell(el.props.spell) then
                                                table.insert(filteredList, el)
                                        end
                                end

                                table.insert(filteredList, 1, UIState.allSpells.expandable)

                                UIState.mainWindow.layout.content.mainFlex.content.mainContent.content.list.content = ui
                                    .content(
                                            filteredList)

                                UIState.mainWindow:update()
                        end)
                }
        }

        return {
                type = ui.TYPE.Flex,
                external = { grow = 0, stretch = 1 },
                props = {
                        arrange = ui.ALIGNMENT.Center,
                        align = ui.ALIGNMENT.Start,
                        horizontal = true,
                        size = util.vector2(100, 0)
                },

                content = ui.content {
                        -- { template = I.MWUI.templates.textNormal, props = { text = ' Filter: ' } },
                        { template = I.MWUI.templates.box, content = ui.content { filterInput } }
                }
        }
end




local filter = {
        createFilterBlock = createFilterBlock,
        filterSpell = filterSpell,
        setFilterText = setFilterText,

}


return { filter = filter }
