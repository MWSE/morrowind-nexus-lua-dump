local config = require("Reactive Resistance.config")
local clock
local startClock
local function onSpellTick(e)
    if(e.sourceInstance.sourceType == tes3.magicSourceType.spell and e.source.castType ~= tes3.spellType.spell) then
        return
        -- we only care about spell spells, not abilities and powers.
    end
    if(e.sourceInstance.sourceType == tes3.magicSourceType.enchantment and e.source.castType == tes3.enchantmentType.constant) then
        return
        -- Don't bother with effects caused by constant effect enchants.
    end
    if(e.sourceInstance.sourceType == tes3.magicSourceType.alchemy) then
        return
        --Don't trigger on alchemy effects.
    end
    if(config.aryonsDominatorOverride and e.source.id == "aryongloveleft_en_unique") then
        return
        -- preserve the full effect of the unique glove enchant.
    end
    if(config.spearOfTheHuntOverride and e.source.id == "bm_hunterspear") then
        return
        -- preserve the full effect of the unique spear enchant.
    end
    for key, value in pairs(config.effects) do
        if(value.resist and e.effectId == tes3.effect[key]) then
            local currentTime = clock + (mwse.simulateTimers.clock - startClock)
            local universalDisableTime = nil
            local universalTimeOutTime = nil
            if (config.useUniversalDisableTime) then
                universalDisableTime = tonumber(config.universalDisableTime)
            end
            if (config.useUniversalTimeOutTime) then
                universalTimeOutTime = tonumber(config.universalTimeOutTime)
            end
            local disableTime = universalDisableTime or tonumber(value.disableTime)
            local timeOutTime = universalTimeOutTime or tonumber(value.timeOutTime)
            if(not e.target.data.JaceyS) then
                e.target.data.JaceyS = {}
            end
            if(not e.target.data.JaceyS.RR) then
                e.target.data.JaceyS.RR = {}
            end
            if(not e.target.data.JaceyS.RR[key]) then
                e.target.data.JaceyS.RR[key] = {}
            end
            -- hacky way of making sure that the path I want to index exists.
            local dataTable = e.target.data.JaceyS.RR[key]
            if(not dataTable.accumulateTime) then
                dataTable.accumulateTime = 0
            end
            if(dataTable.lastTick and currentTime - dataTable.lastTick > timeOutTime) then
                dataTable.accumulateTime = 0
            end
            if(value.compound) then
                local adjustedTime = (e.effectInstance.magnitude / tonumber(value.scale)) * e.deltaTime
                dataTable.accumulateTime = dataTable.accumulateTime + adjustedTime
            else
                dataTable.accumulateTime = dataTable.accumulateTime + e.deltaTime
            end
            dataTable.lastTick = currentTime
            if(dataTable.accumulateTime >= disableTime) then
                dataTable.timeOut = currentTime
                dataTable.accumulateTime = 0
            end
            if(dataTable.timeOut and currentTime - dataTable.timeOut <= timeOutTime) then
                e.effectInstance.state = tes3.spellState.ending
                if (e.caster == tes3.player) then
                    tes3.messageBox("Your target is no longer affected by this type of magic." )
                end
            end
            e.target.data.JaceyS.RR[key] = dataTable
            return
        end
    end
end
event.register("spellTick", onSpellTick)

local function onLoaded()
    if (tes3.player.data.JaceyS and tes3.player.data.JaceyS.RR and tes3.player.data.JaceyS.RR.clock) then
        clock = tes3.player.data.JaceyS.RR.clock
    else
        clock = 0
    end
    startClock = mwse.simulateTimers.clock
end
event.register("loaded", onLoaded)

local function onSave()
    if (not tes3.player.data.JaceyS) then
        tes3.player.data.JaceyS = {}
    end
    if (not tes3.player.data.JaceyS.RR) then
        tes3.player.data.JaceyS.RR = {}
    end
    tes3.player.data.JaceyS.RR.clock = clock + mwse.simulateTimers.clock - startClock
end
event.register("save", onSave)

event.register("modConfigReady", function()
	require("Reactive Resistance.mcm")
end)