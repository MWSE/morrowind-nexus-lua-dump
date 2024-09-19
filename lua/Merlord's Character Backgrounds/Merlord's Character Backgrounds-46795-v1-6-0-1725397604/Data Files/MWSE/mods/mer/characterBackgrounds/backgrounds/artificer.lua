---@class CharacterBackgrounds.Config.mcm
---@field artificer_allowedSpells table<string, boolean> Whitelist of spells that can be cast by the artificer

local interop = require('mer.characterBackgrounds.interop')
local config = require('mer.characterBackgrounds.config')
local common = require('mer.characterBackgrounds.common')

local logger = common.createLogger('Artificer')

local background = interop.addBackground{
    id = "artificer",
    name = "Artificer",
    description = (
        "You can sense the inner most magical properties within any object, " ..
        "giving you an innate aptitude for enchanting (+50 Enchanting). " ..
        "However, this seems to be your only outlet for magic, as you are utterly " ..
        "incapable of casting spells. "
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant,
            value = 50
        })
        tes3.findGMST(tes3.gmst.sMagicSkillFail).value = "You are incapable of casting spells."
    end,
    createMcm = function(_self, template)
        template:createExclusionsPage{
            label = "Artificer",
            description = "The Artificer background blocks the use of spells. Add spells to the whitelist to allow them to be cast. This is intended for compatibility with mods that require casting spells for things like summoning companions. ",
            leftListLabel = "Allowed Spells",
            rightListLabel = "Known Spells",
            variable = mwse.mcm.createTableVariable{
                id = "artificer_allowedSpells",
                table = config.mcm,
                defaultSetting = {}
            },
            filters = {
                {
                    label = "Spells",
                    callback = function()
                        local list = {}
                        if tes3.player then
                            ---@param spell tes3spell
                            for spell  in tes3.iterate(tes3.player.object.spells.iterator) do
                                table.insert(list, spell.name)
                            end
                        end
                        return list
                    end
                }
            }
        }
    end
}
if not background then return end

---@param e spellCastEventData
event.register("spellCast", function(e)
    if not background:isActive() then return end
    if e.caster == tes3.player then
        config.mcm.artificer_allowedSpells = config.mcm.artificer_allowedSpells or {}
        local allowedSpells = config.mcm.artificer_allowedSpells
        if not allowedSpells[e.source.name] then
            e.castChance = 0
        end
    end
end)

event.register("menuEnter", function()
    if not background:isActive() then return end
    local menu = tes3ui.findMenu("MenuMagic")
    if not menu then return end
    logger:debug("Magic Menu UI Activated")
    local spellCostsList = menu:findChild("MagicMenu_spell_percents")
    if spellCostsList then
        for _, element in ipairs(spellCostsList.children) do
            element.text = "/0"
        end
    end
end)

local cachedGMST
event.register("initialized", function()
    cachedGMST = tes3.findGMST(tes3.gmst.sMagicSkillFail).value
end)

event.register("loaded", function()
    if background:isActive() then
        tes3.findGMST(tes3.gmst.sMagicSkillFail).value = "You are incapable of casting spells."
    else
        tes3.findGMST(tes3.gmst.sMagicSkillFail).value = cachedGMST
    end
end)