local animation = require('openmw.animation')
local self = require('openmw.self')

local SLOT = self.type.EQUIPMENT_SLOT
local LGauntlet = SLOT.LeftGauntlet
local Spells = self.type.spells(self)

local LogMessage = require('scripts.sw4.helper.logmessage')

local SpeederItems = {
    -- Traditional speeders
    ["sw_speeder1test"] = 'cpp_mnt_speederblastweak',
    ["sw_speeder2test"] = 'cpp_mnt_speederblastweak',
    ["sw_speeder3test"] = 'cpp_mnt_speederblastweak',
    ["sw_speeder4test"] = 'cpp_mnt_speederblastweak',
    ["sw_speeder5test"] = 'cpp_mnt_speederblaststrong',
    ["sw_speederpodrace"] = 'cpp_mnt_speederblaststrong',
    -- Cut speeders
    ["sw_speedertank"] = 'cpp_mnt_tankblast',
    -- Animal mounts
    ["sw_speedercancell"] = 'cpp_mnt_cancellspell',
    ["sw_speederbantha"] = 'cpp_mnt_banthaspell',
    ["sw_speederalit"] = 'cpp_mnt_alitspell',
    ["sw_speederrancor"] = 'cpp_mnt_rancorspell',
}

local MountFunctions = {
    State = {
        None = 1,
        Equipping = 2,
        Equipped = 3,
        Removing = 4
    },
    Actions = {
        ActivateSpell = 1,
        EngageStance = 2,
        DisengageStance = 3,
    },
    ActionQueue = {},
}

MountFunctions.SavedState = {
    prevGauntlet = nil,
    prevSpellOrEnchantedItem = nil,
    currentMountSpell = nil,
    equipState = MountFunctions.State.None
}

function MountFunctions.queueMountAction(action)
    MountFunctions.ActionQueue[#MountFunctions.ActionQueue + 1] = action
end

--- Determines whether the player's wearing a speeder item for stance management purposes
---@return string|nil whether the player's wearing a speeder item. If they are, returns the spell ID of the speeder item
function MountFunctions.hasSpeederEquipped()
    local equipment = self.type.getEquipment(self, LGauntlet)
    if not equipment then return end

    local targetSpell = SpeederItems[equipment.recordId]
    if targetSpell then
        return targetSpell
    end
end

function MountFunctions.restoreSpellOrEnchantment()
    if not MountFunctions.SavedState.prevSpellOrEnchantedItem then return end

    local targetSpell = MountFunctions.SavedState.prevSpellOrEnchantedItem

    ---@diagnostic disable-next-line: need-check-nil, undefined-field
    local objectType = targetSpell.__type.name

    if objectType == 'ESM::Spell' then
        self.type.setSelectedSpell(self, targetSpell)
    elseif objectType == 'MWLua::LObject' then
        self.type.setSelectedEnchantedItem(self, targetSpell)
    end

    MountFunctions.SavedState.prevSpellOrEnchantedItem = nil
end

function MountFunctions.isMountSpell(spell)
    if not spell then return false end

    local spellId = spell.id:lower()

    LogMessage("MountFunctions: Checking if spell is a mount spell: " .. spellId)

    for _, speederSpell in pairs(SpeederItems) do
        if spellId == speederSpell then
            return true
        end
    end

    return false
end

function MountFunctions.onUpdate(dt)
    local speederSpell = MountFunctions.hasSpeederEquipped()
    if speederSpell then
        --- Engage the mount stance if not already engaged
        if MountFunctions.SavedState.equipState == MountFunctions.State.None then
            MountFunctions.queueMountAction(MountFunctions.Actions.ActivateSpell)
            MountFunctions.SavedState.equipState = MountFunctions.State.Equipping
            --- Override the mount spell if it's not the current one, whilst mounted
        elseif MountFunctions.SavedState.equipState == MountFunctions.State.Equipped then
            local currentSpell = self.type.getSelectedSpell(self)

            if currentSpell and currentSpell.id:lower() ~= speederSpell then
                LogMessage('MountFunctions: Overriding mount spell: ' .. currentSpell.id)
                self.type.setSelectedSpell(self, speederSpell)
            end
        end
    else
        --- Track the previously used left gauntlet and ensure mount spells aren't usable whilst off mounts
        MountFunctions.SavedState.prevGauntlet = self.type.getEquipment(self, LGauntlet)

        if MountFunctions.SavedState.equipState ~= MountFunctions.State.None then
            LogMessage("MountFunctions: Disengaging mount!")
            MountFunctions.queueMountAction(MountFunctions.Actions.DisengageStance)
        end

        local checkSpell = self.type.getSelectedSpell(self)
        if checkSpell and MountFunctions.isMountSpell(checkSpell) then
            if Spells[checkSpell.id] then
                Spells:remove(checkSpell)
            end

            if MountFunctions.SavedState.prevSpellOrEnchantedItem then
                MountFunctions.restoreSpellOrEnchantment()
            else
                self.type.setSelectedSpell(self, nil)
            end
        end
    end

    local nextAction = table.remove(MountFunctions.ActionQueue, 1)
    if not nextAction then return end

    local actionName
    if nextAction == MountFunctions.Actions.ActivateSpell then
        actionName = "ActivateSpell"
    elseif nextAction == MountFunctions.Actions.EngageStance then
        actionName = "EngageStance"
    elseif nextAction == MountFunctions.Actions.DisengageStance then
        actionName = "DisengageStance"
    else
        actionName = "Unknown"
    end

    LogMessage("MountFunctions: Executing action: " .. actionName)

    local nextActionHandler = MountFunctions.ActionHandlers[nextAction]
    assert(nextActionHandler, "No handler for action: " .. tostring(nextAction))
    nextActionHandler()
end

MountFunctions.ActionHandlers = {
    [MountFunctions.Actions.ActivateSpell] = function()
        LogMessage("MountFunctions: Activating mount spell!")

        MountFunctions.SavedState.currentMountSpell = MountFunctions.hasSpeederEquipped()

        local checkSpell = self.type.getSelectedSpell(self) or self.type.getSelectedEnchantedItem(self)

        if not MountFunctions.isMountSpell(checkSpell) then
            MountFunctions.SavedState.prevSpellOrEnchantedItem = checkSpell
        end

        assert(MountFunctions.SavedState.currentMountSpell,
            "Mount spell not found in equipment, but ActivateSpell was queued!")

        Spells:add(MountFunctions.SavedState.currentMountSpell)
        self.type.setSelectedSpell(self, MountFunctions.SavedState.currentMountSpell)
        MountFunctions.queueMountAction(MountFunctions.Actions.EngageStance)
    end,
    [MountFunctions.Actions.EngageStance] = function()
        LogMessage("MountFunctions: Engaging mount stance!")
        self.type.setStance(self, self.type.STANCE.Spell)
    end,
    [MountFunctions.Actions.DisengageStance] = function()
        LogMessage("MountFunctions: Disengaging mount stance!")

        local currentEquipment = self.type.getEquipment(self)
        currentEquipment[LGauntlet] = MountFunctions.SavedState.prevGauntlet
        self.type.setEquipment(self, currentEquipment)
        MountFunctions.SavedState.prevGauntlet = nil

        MountFunctions.restoreSpellOrEnchantment()

        if MountFunctions.SavedState.currentMountSpell then
            Spells:remove(MountFunctions.SavedState.currentMountSpell)
            MountFunctions.SavedState.currentMountSpell = nil
        end

        MountFunctions.SavedState.equipState = MountFunctions.State.None
    end
}

---@return boolean whether the key was handled
function MountFunctions.handleMountCast(group, key)
    if not MountFunctions.hasSpeederEquipped() then return false end

    local handled = true
    if key == 'unequip stop' then
        MountFunctions.queueMountAction(MountFunctions.Actions.DisengageStance)
    elseif key == 'equip stop' then
        MountFunctions.SavedState.equipState = MountFunctions.State.Equipped
        -- elseif key == 'target release' then
    elseif key == 'target start' then
        animation.setSpeed(self, 'spellcast', 50)
    else
        handled = false
    end

    return handled
end

return MountFunctions
