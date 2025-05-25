local apparatusState = {}

local values = require("vozhban.lordofskooma.values")

function apparatusState.get(reference)
    if not reference or reference.stackSize > 1 then
        return {}
    end
    reference.data.lordOfSkooma = reference.data.lordOfSkooma or {
    mainIngredId = "",
    secondaryIngreds = {},
    isRunning = false,
    startTime = nil,
    mode = 1, -- 1 = once, 0 = until ingredients run out
    storage = {},
    upgrades = {},
    prowessSamples = {}
    }

    return reference.data.lordOfSkooma
end

function apparatusState.clear(reference, full)
    local upgrades = reference.data.lordOfSkooma and reference.data.lordOfSkooma.upgrades
    if full then
        reference.data.lordOfSkooma = nil
        return
    else
        reference.data.lordOfSkooma = {
        mainIngredId = "",
        secondaryIngreds = {},
        isRunning = false,
        startTime = nil,
        mode = 1,
        storage = {},
        upgrades = upgrades or {},
        prowessSamples = {}
        }
    end
end

function apparatusState.setValue(reference, param, value)
    local losData = apparatusState.get(reference)
    losData[param] = value
end

function apparatusState.setForceVanilla(ref, flag)
    apparatusState.get(ref).forceVanilla = flag and true or false
end

function apparatusState.getForceVanilla(ref)
    return apparatusState.get(ref).forceVanilla or false
end

function apparatusState.getTotals(state)
    local totals = {mortar = 0, calcinator = 0, alembic = 0, retort = 0}
    for i = 1, values.maxUpgradeSlots do
        local upgrade = state.upgrades and state.upgrades[i]
        if upgrade then
            local item = tes3.getObject(upgrade)
            if item then
                if item.type == tes3.apparatusType.mortarAndPestle then totals.mortar = totals.mortar + item.quality
                elseif  item.type == tes3.apparatusType.calcinator then totals.calcinator = totals.calcinator + item.quality
                elseif  item.type == tes3.apparatusType.alembic then totals.alembic = totals.alembic + item.quality
                elseif  item.type == tes3.apparatusType.retort then totals.retort = totals.retort + item.quality
                end
            end
        end
    end
    return totals
end

function apparatusState.getMortarQuality(totals) return (totals.mortar) end
function apparatusState.getCalcinatorQuality(totals) return (totals.calcinator) end
function apparatusState.getAlembicQuality(totals) return (totals.alembic) end
function apparatusState.getRetortQuality(totals) return (totals.retort) end

function apparatusState.getMortarBonus(totals) return (totals.mortar) * values.mortarMult end --Difficulty
function apparatusState.getCalcinatorBonus(totals) return (totals.calcinator) * values.calcinatorMult end --Consumption
function apparatusState.getAlembicBonus(totals) return (totals.alembic) * values.alembicMult end --Time
function apparatusState.getRetortBonus(totals) return (totals.retort) * values.retortMult end --Output

--[[

function apparatusState.setRunning(reference, running)
    local losData = reference.data.lordOfSkooma
    losData.isRunning = running
end

function apparatusState.setMainIngred(reference, ingredId)
    local losData = reference.data.lordOfSkooma
    losData.mainIngredId = ingredId
end

function apparatusState.setMode(reference, mode)
    local losData = reference.data.lordOfSkooma
    losData.get(reference).mode = mode
end

]]

return apparatusState
