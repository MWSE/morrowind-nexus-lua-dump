local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("SpellList")
local Validator = require("mer.chargenScenarios.util.validator")
local SpellPick = require("mer.chargenScenarios.component.SpellPick")
--[[
    For specific spells, use "id"
    To pick a random spell from a list, use "ids"
]]

---@class ChargenScenariosSpellList
---@field spells table<number, ChargenScenariosSpellPick> @the list of spells to add to the player's inventory
local SpellList = {
    schema = {
        name = "SpellList",
        fields = {
            spells = { type = "table", childType = SpellPick.schema, required = true },
        }
    }
}

--Constructor
---@param data table<number, ChargenScenariosSpellPickInput>
---@return ChargenScenariosSpellList
function SpellList:new(data)
    local spellList = { spells = table.deepcopy(data)}
    ---validate
    Validator.validate(spellList, self.schema)
    ---Build
    spellList.spells = common.convertListTypes(spellList.spells, SpellPick)
    setmetatable(spellList, self)
    self.__index = self
    return spellList
end

--- Add a spell to this spell list
function SpellList:addSpell(spell)
    local spellPick = SpellPick:new(spell)
    table.insert(self.spells, spellPick)
end

--- Add the spells to the player's spell list
---@return boolean
function SpellList:doSpells()
    if self.spells and #self.spells > 0 then
        for _, spell in ipairs(self.spells) do
            logger:debug("Picking spell")
            local pick = spell:pick()
            if pick then
                logger:debug("Picked spell: %s", pick.id)
                timer.delayOneFrame(function()
                    logger:debug("Adding spell %s", pick)
                    tes3.addSpell{
                        reference = tes3.player,
                        spell = pick
                    }
                end)
            end
        end
        return true
    else
        return false
    end
end

return SpellList
