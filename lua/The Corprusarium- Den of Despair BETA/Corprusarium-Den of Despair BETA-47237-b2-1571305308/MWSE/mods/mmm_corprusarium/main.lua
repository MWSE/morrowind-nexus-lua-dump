local function toxicWaters(e)
    local isBelowWater = tes3.player.position.z < tes3.player.cell.waterLevel
    local isToxinActive = tes3.player.object.spells:contains("bal_water_curse")
    if isBelowWater and not isToxinActive then
        mwscript.addSpell{reference=tes3.player, spell="bal_water_curse"}
    elseif isToxinActive and not isBelowWater then
        mwscript.removeSpell{reference=tes3.player, spell="bal_water_curse"}
    end
end


local function hasFireEffect(effects)
    for i=1, 8 do
        if effects[i].id == tes3.effect.fireDamage then
            return true
        end
    end
end


local function onMagicCasted(e)
    if (e.caster.cell.id == "Corprusarium Maze"
        and hasFireEffect(e.source.effects)
        and e.caster == tes3.player
        )
    then
        local eyevec = tes3.getPlayerEyeVector()
        local eyepos = tes3.getPlayerEyePosition()
        local rayhit = tes3.rayTest{position=eyepos, direction=eyevec, ignore={e.caster}}

        local ref = rayhit and rayhit.reference
        if ref and ref.id == "bal_fire_obstacle" then
            mwscript.explodeSpell{reference=ref, spell="bal_fire_explodespell"}
            ref:disable()
            timer.start{iterations=1, duration=0.5, callback=function()
                ref.position = ref.position * 9999 -- remove collision
            end}
        end
    end
end


local function onAttack(e)
    local source = e.reference
    local target = e.targetReference
    if source == tes3.player and target.id:lower():find("^corprus") then
        for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
            local id = ref.baseObject.id
            if (id == "bal_corp_guard"
                or id == "vistha_kai"
                or id == "yagrum bagarn"
                or id == "uupse fyr"
                )
            then
                if ref.mobile then
                    ref.mobile.fight = 100
                end
            end
        end
    end
end


local corprusariumCells
local function getCorprusariumCells()
    return {
        [tes3.getCell{id="corprusarium"}] = true,
        [tes3.getCell{id="corprusarium maze"}] = true,
        [tes3.getCell{id="corprusarium bowels"}] = true,
        [tes3.getCell{id="corprusarium passage"}] = true,
    }
end


local function enterCorprusarium()
    event.unregister("magicCasted", onMagicCasted)
    event.register("magicCasted", onMagicCasted)
    event.unregister("attack", onAttack)
    event.register("attack", onAttack)
end


local function leaveCorprusarium()
    event.unregister("magicCasted", onMagicCasted)
    event.unregister("attack", onAttack)
end


local function cellChanged(e)
    local isCorprusarium = corprusariumCells[e.cell]
    local wasCorprusarium = e.previousCell and corprusariumCells[e.previousCell]
    if isCorprusarium and not wasCorprusarium then
        enterCorprusarium(e.cell)
    elseif wasCorprusarium and not isCorprusarium then
        leaveCorprusarium(e.cell)
    end
end


local function initialized(e)
    if tes3.isModActive("mmm_corprusarium_beta.esp") then
        -- setup
        corprusariumCells = getCorprusariumCells()
        mwse.overrideScript("bal_maze_script", toxicWaters)
        --events
        event.register("cellChanged", cellChanged)
        event.register("loaded", function() cellChanged{cell=tes3.player.cell} end)

        mwse.log("[BAL Corprusarium] Initialized Version 0.1")
    end
end
event.register("initialized", initialized)
