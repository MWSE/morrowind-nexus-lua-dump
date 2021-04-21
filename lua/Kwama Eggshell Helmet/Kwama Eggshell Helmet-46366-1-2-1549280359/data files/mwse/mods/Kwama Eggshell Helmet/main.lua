local defaultFightValues = {
    ["kwama forager"] = 85,
    ["kwama warrior"] = 90,
    ["kwama worker blighted"] = 90,
    ["kwama warrior blighted"] = 90,
    ["kwama forager blighted"] = 85,
    ["kwama forager_tb"] = 85,
    ["kwama warrior shurdan"] = 90,
}


local function updateCombatState(ref, aggressive)
    if aggressive == false then
        mwscript.stopCombat{reference=ref, target=tes3.player}
    elseif ref.position:distance(tes3.player.position) < 512 then
        mwscript.startCombat{reference=ref, target=tes3.player}
    end
end


local function onHelmetEquipped(e)
    if e.reference ~= tes3.player then
        -- don't do anything if it wasnt the player equipping
        return
    elseif e.item.id ~= "egghelmet" then
        -- don't do anything if it wasnt your helmet equipped
        return
    end

    -- figure out if should be aggressive based on event type
    local aggressive = true
    if e.eventType == "equipped" then
        aggressive = false
    end

    -- update fight value for all kwama creatures in the cell
    for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.creature) do
    	local obj = ref.object.baseObject
        local fightValue = obj and defaultFightValues[obj.id:lower()]
        if fightValue then
            ref.mobile.fight = aggressive and fightValue or 0
            updateCombatState(ref, aggressive)
        end
    end
end
event.register("equipped", onHelmetEquipped)
event.register("unequipped", onHelmetEquipped)


local function onKwamaLoaded(e)
    local ref = e.reference
    local obj = ref.object.baseObject
    local fightValue = obj and defaultFightValues[obj.id:lower()]
    if fightValue then
        if mwscript.hasItemEquipped{reference=tes3.player, item="egghelmet"} then
            ref.mobile.fight = 0
        else
            ref.mobile.fight = fightValue
        end
    end
end
event.register("mobileActivated", onKwamaLoaded)
