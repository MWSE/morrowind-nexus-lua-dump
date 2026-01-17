--- Handler function for combat switch states. Optionally returns another combat action for the next frame.
---@alias SwitchActionHandler fun(): SwitchStates?

local async = require 'openmw.async'
local gameSelf = require 'openmw.self'
local input = require 'openmw.input'
local types = require 'openmw.types'

local I = require 'openmw.interfaces'

local Stance = gameSelf.type.STANCE
local Slot = gameSelf.type.EQUIPMENT_SLOT
local WeaponTypes = types.Weapon.TYPE

local ModInfo = require 'scripts.sw4.modinfo'

---@enum SwitchStates
local SwitchStates = {
    SwitchFromRanged = 1,
    SwitchFromMelee = 2,
    SwitchFromNone = 3,
    Switching = 4,
    Swinging = 5,
    None = 6,
}

---@enum PrevSelectTypes
local PrevSelectTypes = {
    None = 0,
    Melee = 1,
    Ranged = 2,
    Magic = 3,
}

local SheathDuration = 10.0
local currentDrawTime = 0.0
local GlobalManagement = nil

---@class QuickAttackManager
local QuickAttackManager = I.StarwindVersion4ProtectedTable.new {
    modName = ModInfo.name,
    logPrefix = ModInfo.logPrefix,
    inputGroupName = 'SettingsGlobal' .. ModInfo.name .. 'CoreGroup',
}

QuickAttackManager.state = {
    -- Saved state
    prevMelee = nil,
    prevRanged = nil,
    prevSelectType = PrevSelectTypes.None,
    switchState = SwitchStates.None,
    actions = {},
    -- Non-saved state
}

---@type table<SwitchStates, SwitchActionHandler>
local SwitchActionHandlers = {
    [SwitchStates.SwitchFromNone] = function()
        gameSelf.type.setStance(gameSelf, Stance.Weapon)
    end,
    [SwitchStates.SwitchFromRanged] = function()
    end,
    [SwitchStates.SwitchFromMelee] = function()
    end,
    [SwitchStates.Switching] = function()
    end,
    [SwitchStates.Swinging] = function()
    end,
}

-- This has a minor conflict with the cursor controller as raising the cursor overrides combat controls also
I.Controls.overrideCombatControls(true)
input.registerTriggerHandler('ToggleWeapon',
    async:callback(
        function()
            local currentStance = gameSelf.type.getStance(gameSelf)
            local currentState = QuickAttackManager.state.switchState

            if currentStance == Stance.Nothing then
                QuickAttackManager:queue(SwitchStates.SwitchFromNone)

                if currentState == SwitchStates.None then
                    QuickAttackManager.state.switchState = SwitchStates.Switching
                end
            elseif currentStance == Stance.Weapon then
                QuickAttackManager:queue(SwitchStates.Swinging)

                if currentState == SwitchStates.None then
                    QuickAttackManager.state.switchState = SwitchStates.Swinging
                end
            end
        end
    ),
    {}
)

-- -- Need to know what text keys play when attacks end, to change the state properly
I.AnimationController.addTextKeyHandler('', function(group, key)
    local switchState = QuickAttackManager.state.switchState

    if key == 'equip stop' and switchState == SwitchStates.Switching then
        QuickAttackManager.state.switchState = SwitchStates.Swinging
        QuickAttackManager:queue(SwitchStates.Swinging)
    elseif key:find('max attack') then
        currentDrawTime = 0.0
        gameSelf.controls.use = 0
        QuickAttackManager.state.switchState = SwitchStates.None
    end
end)

--- Adds a combat action to the switch queue
--- Validate function inputs, but do it later when I care
---@param actionType SwitchStates
function QuickAttackManager:queue(actionType)
    self.state.actions[#self.state.actions + 1] = actionType
end

function QuickAttackManager:getNextStance()
    local prevSelection = self.state.prevSelectType
    if prevSelection == PrevSelectTypes.None then return end

    if prevSelection == PrevSelectTypes.Melee and self.state.prevMelee then
        return Stance.Weapon, self.state.prevMelee
    elseif prevSelection == PrevSelectTypes.Ranged and self.state.prevRanged then
        return Stance.Weapon, self.state.prevRanged
        --- This doesn't really actually work yet
    elseif prevSelection == PrevSelectTypes.Magic then
        error('Unsupported prevSelectType')
    end
end

--- On every frame, track the currently selected weapon and stance.
--- Skip this portion of tracking if the player is doing any kind of switchState.
function QuickAttackManager:onFrameBegin(dt, Managers)
    if self.state.switchState ~= SwitchStates.None then return end

    local currentWeapon = gameSelf.type.getEquipment(gameSelf, Slot.CarriedRight)
    if not currentWeapon then
        self.state.prevSelectType = PrevSelectTypes.None
        return
    end

    local weaponRecord = currentWeapon.type.records[currentWeapon.recordId]

    if weaponRecord.type == WeaponTypes.MarksmanBow or weaponRecord.type == WeaponTypes.MarksmanCrossbow or weaponRecord.type == WeaponTypes.MarksmanThrown then
        self.state.prevRanged = currentWeapon
        self.state.prevSelectType = PrevSelectTypes.Ranged
    elseif weaponRecord.type == WeaponTypes.Arrow or weaponRecord.type == WeaponTypes.Bolt then
        error('I don\'t think this actually can happen!')
    else
        self.state.prevMelee = currentWeapon
        self.state.prevSelectType = PrevSelectTypes.Melee
    end
end

--- Actually perform equipment and stance changes
function QuickAttackManager:onFrame(dt, Managers)
    if QuickAttackManager.state.switchState == SwitchStates.Swinging then
        gameSelf.controls.use = 1
        return
    else
        currentDrawTime = currentDrawTime + dt

        if currentDrawTime >= SheathDuration then
            currentDrawTime = 0.0
            gameSelf.type.setStance(gameSelf, Stance.Nothing)
        end
    end

    local switchAction = table.remove(self.state.actions, 1)

    if not switchAction then return end

    assert(SwitchActionHandlers[switchAction])
    local nextAction = SwitchActionHandlers[switchAction]()
    if nextAction then self:queue(nextAction) end
end

return function(globalManagement)
    assert(globalManagement)
    GlobalManagement = globalManagement
    return QuickAttackManager
end
