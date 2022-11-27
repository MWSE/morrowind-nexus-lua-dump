local log = require("logging.logger").new({
    name = "OotG Sixth House Quest",
    logLevel = "INFO"
})
local sixthHouseQuestID = "GG_6thHouse"
local bouncerForceGreetInfoID = "2020366741859230377"
local dagothID = "GG_6_ash_ghoul_nasro"
local troopers = {
    "GG_alynu_menas", "GG_dartis_iba", "GG_dralane_murith", "GG_tennus_dolovas"
}
local skullID = "GG_Bleeding_Skull_Identified"
local isDamageHealthEffect = {
    [tes3.effect.fireDamage] = true,
    [tes3.effect.shockDamage] = true,
    [tes3.effect.frostDamage] = true,
    [tes3.effect.drainHealth] = true,
    [tes3.effect.damageHealth] = true,
    [tes3.effect.poison] = true,
    [tes3.effect.absorbHealth] = true,
    [tes3.effect.sunDamage] = true
}

local function bleedingSkullTooltip(e)
    if e.object.id == skullID then
        local block = e.tooltip:createBlock{}
        block.minWidth = 1
        block.maxWidth = 440
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = 4
        local label = (block:createLabel{
            id = tes3ui.registerID("GG_Bleeding_Skull_desc"),
            text = "Take One Death Blow for the Carrier"
        })
        label.wrapText = true
    end
end

--- @param e spellResistEventData
local function onSpellResistBleedingSkullEffect(e)
    if tes3.getItemCount({reference = tes3.player, item = skullID}) > 0 and
        e.target == tes3.player and e.effect and
        isDamageHealthEffect[e.effect.object.id] then
        log:debug("spell effect %s max magnitude is %s", e.effect.object.name,
                  e.effect.max)
        if e.effect.max >= tes3.player.mobile.health.current then
            log:debug(
                "the max damage the player will take will kill the player!")
            e.resistedPercent = 100
            timer.delayOneFrame(function()
                if tes3.getItemCount({reference = tes3.player, item = skullID}) >
                    0 then
                    tes3.removeItem({
                        reference = tes3.player,
                        item = skullID,
                        playSound = false
                    })
                    tes3.playSound({sound = "restoration hit"})
                    tes3.messageBox({
                        message = "The Bleeding Skull took the damage for you."
                    })
                end
            end, timer.simulate)
        end
    end
end

--- @param e damageEventData
local function onDamageBleedingSkullEffect(e)
    if tes3.getItemCount({reference = tes3.player, item = skullID}) > 0 then
        if e.reference == tes3.player then
            if e.damage then
                log:debug("player is taking this amount of damage: %s!",
                          e.damage)
            end
            if e.source then
                log:debug("player is taking damage from source: %s!", e.source)
            end
            if e.damage >= tes3.player.mobile.health.current then
                log:debug(
                    "the damage the player will take will kill the player!")
                tes3.removeItem({
                    reference = tes3.player,
                    item = skullID,
                    playSound = false
                })
                tes3.playSound({sound = "restoration hit"})
                tes3.messageBox({
                    message = "The Bleeding Skull took the damage for you."
                })
                return false
            end
        end
    end
end

local function trooperForceGreetPlayer()
    if tes3.player.cell.id ~= "Western Catacombs" then return end
    local dagothRef = tes3.getReference(dagothID)
    if tes3.getJournalIndex {id = sixthHouseQuestID} >= 60 then return end
    if tes3.player.data.OotG.trooperGreeted then return end
    if not dagothRef.mobile.isDead then return end
    for _, trooperID in pairs(troopers) do
        log:debug("%s scanned", trooperID)
        local trooperRef = tes3.getReference(trooperID)
        if not trooperRef.mobile.inCombat then
            log:debug("%s is not in combat", trooperID)
            if trooperRef.mobile.playerDistance < 256 then
                log:debug("%s is close to the player", trooperID)
                if trooperRef.mobile.position:distance(dagothRef.mobile.position) >=
                    256 then
                    log:debug("%s is far away enough from dagoth nasro",
                              trooperID)
                    if tes3.testLineOfSight({
                        reference1 = trooperRef,
                        reference2 = tes3.player
                    }) then
                        local wasShown =
                            tes3.showDialogueMenu({reference = trooperRef})
                        if wasShown then
                            tes3.player.data.OotG.trooperGreeted = true
                            return
                        end
                    end
                end
            end
        end
    end
end

--- @param e infoGetTextEventData
local function onBouncerInfoGetText(e)
    if e.info.id == bouncerForceGreetInfoID then
        if tes3.player.cell.id == "Ossuary of Ayem, Bone Pit" then
            if tes3.player.data.OotG.playerEnteredFromWesternCatacombs then
                e.text =
                    "Hey, you're not one of the Ghosts. How did you get in there?"
            end
        end
    end
end

--- @param e cellChangedEventData
local function checkIfEnterFromWesternCatacombs(e)
    if e.cell.id == "Ossuary of Ayem, Bone Pit" then
        if tes3.getJournalIndex {id = sixthHouseQuestID} >= 10 then
            if e.previousCell.id == "Western Catacombs" then
                tes3.player.data.OotG.playerEnteredFromWesternCatacombs = true
            end
        end
    end
end

local function changeBleedingSkullValue()
    local skull = tes3.getObject(skullID)
    if skull then skull.value = 250 end
end

local function onInit()
    event.register("loaded", function(e)
        tes3.player.data.OotG = tes3.player.data.OotG or {}
    end)
    event.register("cellChanged", checkIfEnterFromWesternCatacombs)
    event.register("infoGetText", onBouncerInfoGetText)
    event.register("simulate", trooperForceGreetPlayer)
    event.register("damage", onDamageBleedingSkullEffect)
    event.register("spellResist", onSpellResistBleedingSkullEffect)
    event.register("uiObjectTooltip", bleedingSkullTooltip)
    changeBleedingSkullValue()
end
event.register("initialized", onInit)

