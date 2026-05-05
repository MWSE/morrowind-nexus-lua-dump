local self = require("openmw.self")
local I = require("openmw.interfaces")
local core = require("openmw.core")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

local animKeys = {
    ["self start"] = true,
    ["touch start"] = true,
    ["target start"] = true,
}

-- by id in lowercase
local whitelistedSpells = {
    -- ["fire bite"] = true,
}

I.CharacterTraits.addTrait {
    id = "artificer",
    type = traitType,
    name = "Artificer",
    description = (
        "You can sense the inner most magical properties within any object, " ..
        "giving you an innate aptitude for enchanting. " ..
        "However, this seems to be your only outlet for magic, as you are utterly " ..
        "incapable of casting spells.\n" ..
        "\n" ..
        "+20 Enchant\n" ..
        "> Can't cast any spells with your own magicka."
    ),
    doOnce = function()
        local enchant = self.type.stats.skills.enchant(self)
        enchant.base = enchant.base + 20
    end,
    onLoad = function()
        I.AnimationController.addTextKeyHandler('spellcast', function(groupname, key)
            if not animKeys[key] then return end

            local selectedEnchItem = self.type.getSelectedEnchantedItem(self)
            local selectedSpell = self.type.getSelectedSpell(self)
            if selectedEnchItem
                or not selectedSpell
                or selectedSpell.type ~= core.magic.SPELL_TYPE.Spell
                or whitelistedSpells[selectedSpell.id]
            then
                return
            end

            local activeSpells = self.type.activeSpells(self)
            activeSpells:add {
                id = "mer_bg_artificer",
                ---@diagnostic disable-next-line: assign-type-mismatch
                effects = { 0 },
                ignoreResistances = true,
                ignoreSpellAbsorption = true,
                ignoreReflect = true,
                quiet = true,
            }
        end)
    end
}
