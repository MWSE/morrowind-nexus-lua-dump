--[[
    Plugin: Vaba-Amus_Companion_Character.esp
--]]

local beverages = {
    p_vintagecomberrybrandy1 = true,
    potion_ancient_brandy = true,
    potion_comberry_brandy_01 = true,
    potion_comberry_wine_01 = true,
    potion_cyro_brandy_01 = true,
    potion_cyro_whiskey_01 = true,
    potion_local_brew_01 = true,
    potion_local_liquor_01 = true,
    potion_skooma_01 = true,
}


-- Controlled Consumption compatibility
local cc = include("nc.consume.interop")

-- Easy Escord compatibility
local ee = include("nc.escort.interop")
if ee then
    ee.addToBlacklist("TDM_VA_Companion")
    ee.addToBlacklist("TDM_VA_Racer")
end


local function scribMaker(target)
    -- disable the npc
    mwscript.disable{reference=target}

    -- spawn the scrib
    local scrib = mwscript.placeAtPC{object="Scrib"}

    -- save the npc id
    scrib.data.tdm_va = target.id

    -- update position
    scrib.position = target.position

    -- do fancy sounds
    tes3.playSound{reference=scrib, sound="scrib moan", pitch=0.75}
    tes3.playSound{reference=scrib, sound="scrib roar", pitch=0.50}
    tes3.playSound{reference=scrib, sound="scrib scream", picth=0.25}

    -- spawn fancy gfx
    mwscript.equip{reference=scrib, item="TDM_VA_MQ10_PotEffect"}
end


local function updateStats(potion)
    --
    local MGEF = tes3.getDataHandler().nonDynamicData.magicEffects

    for e = 1, 8 do
        -- update effect info
        e = potion.effects[e]
        if (e.id ~= -1) then
            -- reducing harmful magnitudes
            if MGEF[e.id].isHarmful then
                e.min = math.max(0, e.min - 30)
                e.max = math.max(0, e.max - 30)
            end
            -- double all effect durations
            if e.duration > 0 then
                e.duration = e.duration * 2
            end
        end
    end
end


local function getBeverage(potion)
    --
    local id = "TDM_" .. potion.id
    local obj = tes3.getObject(id)

    if not obj then
        obj = tes3alchemy.create{id=id, name=potion.name, effects=potion.effects}
        updateStats(obj)
    end


    return obj
end


local function onEquip(e)
    --
    if (e.item.objectType == tes3.objectType.alchemy
        and e.reference == tes3.getPlayerRef()
        and beverages[ e.item.id:lower() ] == true
        and tes3.getGlobal("TDM_VA_DrinkPerk") == 1
        and tes3.getGlobal("TDM_VA_Follow") == 1
        )
    then
        local potion = getBeverage(e.item)

        timer.frame.delayOneFrame(
            function ()
                if cc then cc.skipNextConsumptionCheck = true end
                mwscript.equip{reference=e.reference, item=potion.id}
                mwscript.removeItem{reference=e.reference, item=e.item.id}
            end
        )

        return false
    end
end


local function onAttack(e)
    local target = e.targetReference
    local action = e.mobile.actionData
    local weapon = e.mobile.readiedWeapon

    if (not (weapon and target)
        or action.physicalDamage <= 0
        or weapon.object.id ~= "TDM_VA_MQ10_ScribStaff")
    then -- not a successful attack with scrib staff
        return
    end

    -- one use per day
    local day = tes3.getGlobal("DaysPassed")
    if tes3.getGlobal("TDM_VA_ScribmakerDay") >= day then
        mwscript.playSound{sound="enchant fail"}
        return
    end

    -- usage threshold
    local health = target.attachments.actor.health.current
    if health >= 150 then
        tes3.messageBox{message="Your target needs to be weakened first."}
        return
    end

    -- update cooldown
    tes3.setGlobal("TDM_VA_ScribmakerDay", day)

    -- queue transform
    timer.start(0.25, function () scribMaker(target) end)
end


local function onDeath(e)
    -- only trigger on scrib deaths
    if e.reference.object.baseObject.id ~= "scrib" then
        return
    end

    -- get original actor reference
    local ref = tes3.getReference(e.reference.data.tdm_va)
    if not ref then
        return
    end

    -- swap dead scrib for dead npc
    ref.attachments.actor.health.current = -1
    mwscript.disable{reference=e.reference}
    mwscript.enable{reference=ref}
end


local function initialized(e)
    if tes3.isModActive("Vaba-Amus_Companion_Character.esp") then
        event.register("equip", onEquip)
        event.register("attack", onAttack)
        event.register("death", onDeath)
        print("[TDM] Initialized Vaba-Amus_Companion_Character")
    end
end
event.register("initialized", initialized)
