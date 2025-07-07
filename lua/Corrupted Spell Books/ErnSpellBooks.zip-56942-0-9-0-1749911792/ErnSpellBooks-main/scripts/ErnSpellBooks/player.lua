--[[
ErnSpellBooks for OpenMW.
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
local interfaces = require("openmw.interfaces")
local settings = require("scripts.ErnSpellBooks.settings")
local spellUtil = require("scripts.ErnSpellBooks.spellUtil")
local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local localization = core.l10n(settings.MOD_NAME)
local ui = require('openmw.ui')

interfaces.Settings.registerPage {
    key = settings.MOD_NAME,
    l10n = settings.MOD_NAME,
    name = "name",
    description = "description"
}

local function onActive()
    if settings.debugMode() then
        core.sendGlobalEvent("ernCreateSpellbook", {
            spellID = 'lightning storm',
            corruption = {
                ['prefixID'] = 'restitution',
                ['suffixID'] = 'repetition',
            },
            container = self
        })
        core.sendGlobalEvent("ernCreateSpellbook", {
            spellID = 'lightning storm',
            corruption = {
                ['prefixID'] = 'gnome',
                ['suffixID'] = 'blood'
            },
            container = self
        })
        
        core.sendGlobalEvent("ernCreateSpellbook", {
            spellID = spellUtil.getRandomSpells(3, 1)[1].id,
            corruption = {
                ['prefixID'] = 'giant',
                ['suffixID'] = 'style'
            },
            container = self
        })
    end
end

-- handleSpellCast is invoked once per cast.
local function handleSpellCast(caster, spell)
    settings.debugPrint("Spell Cast: " .. caster.id .. " cast " .. spell.id)

    core.sendGlobalEvent("ernHandleSpellCast", {
        caster = caster,
        spellID = spell.id
    })
end

local spellsSkills = {
    ['alteration']=true,
    ['conjuration']=true,
    ['destruction']=true,
    ['illusion']=true,
    ['mysticism']=true,
    ['restoration']=true
}

-- SkillProgression is used since I can't determine if a spell
-- succeeds from the animation controller.
-- SkillProgression only works for Players, though, so onCast corruptions
-- won't work for NPCs.
interfaces.SkillProgression.addSkillUsedHandler(function(skillID, options)
    if spellsSkills[skillID] and (options.useType == interfaces.SkillProgression.SKILL_USE_TYPES.Spellcast_Success) then
        settings.debugPrint("spell succeeded for actor " .. self.id .. ": " .. skillID)
        local foundSpell = types.Actor.getSelectedSpell(self)
        if (foundSpell ~= nil) then
            settings.debugPrint("selected spell: " .. tostring(foundSpell.id))
            handleSpellCast(self, foundSpell)
        end
    end
end)



local function showLearnMessage(data)
    settings.debugPrint("showLearnMessage")
    if data.spellName == nil then
        error("showLearnMessage() bad spellName")
        return
    end

    ui.showMessage(localization("learnMessage", data))

    -- equip the spell, too.
    local spell = core.magic.spells.records[data.spellID]
    types.Actor.setSelectedSpell(self, spell)
end

-- params: data.spellName
local function showSelectMessage(data)
    settings.debugPrint("showSelectMessage")
    if data.spellName == nil then
        error("showSelectMessage() bad spellName")
        return
    end

    ui.showMessage(localization("selectMessage", data))
end



local lastEquippedSpellID = nil

local function onUpdate()
    local foundSpell = types.Actor.getSelectedSpell(self)
    if (foundSpell == nil) then
        lastEquippedSpellID = nil
        return
    end
    if (foundSpell.id == lastEquippedSpellID) then
        return
    end
    
    
    lastEquippedSpellID = foundSpell.id
    -- spell changed
    core.sendGlobalEvent("ernSelectSpell", {
        caster = self,
        spellID = foundSpell.id
    })
end


return {
    eventHandlers = {
        ernShowLearnMessage = showLearnMessage,
        ernShowSelectMessage = showSelectMessage
    },
    engineHandlers = {
        onActive = onActive,
        onUpdate = onUpdate,
    }
}

