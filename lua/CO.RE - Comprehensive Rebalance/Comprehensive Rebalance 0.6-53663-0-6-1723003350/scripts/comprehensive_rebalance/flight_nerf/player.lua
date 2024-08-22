local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local ui = require('openmw.ui');
local settings = require("scripts.comprehensive_rebalance.lib.settings")
local spells = require("scripts.comprehensive_rebalance.lib.spells")

local Actor = types.Actor
local Player = types.Player
local Effects = core.magic.EFFECT_TYPE
local SpellType = core.magic.SPELL_TYPE

local function flightHandler()

    local section = settings.GetSection("misc")

    local noDeathFromAbove = section:get("noDeathFromAbove")
    local grounded = Actor.isOnGround(self);

    --If we are in levitation or slowfall, we can't use weapons,
    local stance = Actor.getStance(self)
    local flyingSpell = false

    for _, spell in pairs(Actor.activeSpells(self)) do
        if spell.type ~= SpellType.Ability then
            for _, effect in pairs(spell.effects) do
                if effect.id == Effects.Levitate or effect.id == Effects.SlowFall then
                    if stance == Actor.STANCE.Weapon and noDeathFromAbove then
                        Actor.activeSpells(self):remove(spell.activeSpellId)
                    else
                        flyingSpell = noDeathFromAbove;
                    end
                end
            end
        end
    end

    --if we are using one of these spells, add a 100% cast rate penalty
    --TODO: Make this work whenever the player is not on the ground (Actor.isOnGround(self).
    --Currently disabled due to occasional "pop" sounds when AddSpell tries to remove the awful Sound effect.
    --When it's possible to dynamically remove the effect from the Sound magic effect, then do it.
    --OR just simply remove that sound entirely, idk
    --spells.addOrRemoveSpell('flying cast penalty',not Actor.isOnGround(self))
    spells.addOrRemoveSpell('flying cast penalty',flyingSpell)
    --Player.setControlSwitch(self, Player.CONTROL_SWITCH.Magic, not flyingSpell)
    flyingSpell = false;
end

return
{
	engineHandlers =
	{
		onUpdate = flightHandler,
	}
}
