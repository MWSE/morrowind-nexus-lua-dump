local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local time = require('openmw_aux.time')

local settings = storage.globalSection('SettingsSkoomaesthesia_Addiction')

local attributes = types.Actor.stats.attributes
local l10n = core.l10n('Skoomaesthesia')

local function applyWithdrawalChange(active)
    local withdrawalChange = settings:get('withdrawalIntensity')
    local attributes = {
        attributes.intelligence(self),
        attributes.agility(self),
    }
    if not active then
        withdrawalChange = -withdrawalChange
    end
    for _, attr in ipairs(attributes) do
        attr.damage = math.max(0, attr.damage + withdrawalChange)
    end
end

local function rescale(value, minIn, maxIn, minOut, maxOut)
    local t = (value - minIn) / (maxIn - minIn)
    t = math.min(1, math.max(0, t))
    return minOut + t * (maxOut - minOut)
end

local function addictionTest()
    local willpowerValue = attributes.willpower(self).modified
    local resistChance = rescale(
        willpowerValue,
        0, 100,
        settings:get('minResistance'), settings:get('maxResistance')
    )
    local addictionChance = settings:get('baseChance') / resistChance
    return math.random() < addictionChance
end

local state = {
    lastDoseTime = nil,
    hasWithdrawal = false,
    addicted = false,
}

local function dose()
    state.lastDoseTime = core.getGameTime()
    if not state.addicted and addictionTest() then
        state.addicted = true
        ui.showMessage(l10n('message_addicted'))
    end
end

local function update()
    if not state.lastDoseTime or not state.addicted then return end
    local now = core.getGameTime()
    local timeSinceDose = now - state.lastDoseTime
    local hoursSinceDose = timeSinceDose / time.hour

    local hoursToWithdrawal = settings:get('hoursToWithdrawal')
    local hoursToRecovery = settings:get('hoursToRecovery')

    local hasWithdrawal = hoursToWithdrawal < hoursSinceDose
        and hoursSinceDose < hoursToRecovery

    if state.hasWithdrawal ~= hasWithdrawal then
        applyWithdrawalChange(hasWithdrawal)
        state.hasWithdrawal = hasWithdrawal
        if hasWithdrawal then
            ui.showMessage(l10n('message_withdrawal'))
        end
    end

    if hoursSinceDose > hoursToRecovery then
        state.addicted = false
        ui.showMessage(l10n('message_recovery'))
    end
end

local function save()
    return state
end

local function load(savedState)
    if not savedState then return end
    state.lastDoseTime = savedState.lastDoseTime
    state.hasWithdrawal = savedState.hasWithdrawal
    state.addicted = savedState.addicted
end

return {
    dose = dose,
    update = update,
    save = save,
    load = load
}
