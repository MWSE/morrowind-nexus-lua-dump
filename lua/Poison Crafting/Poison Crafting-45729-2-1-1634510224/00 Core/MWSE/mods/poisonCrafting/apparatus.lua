local config = require("poisonCrafting.config")

do
    -- Ensure compatibility with skoomaesthesia mod.
    local cfg = include("mer.skoomaesthesia.config")
    if cfg then
        for id in pairs(cfg.static.pipeIds) do
            config.ignore[id] = true
        end
    end
end

-- Verify that the given item is an apparatus that is not ignore listed.
local function isValidApparatus(item)
    return (
        item.objectType == tes3.objectType.apparatus
        and not config.ignore[item.id:lower()]
        and not config.skipApparatusEvents
    )
end

-- Toggles the 'isHarmful' flag on all magic effects.
local function toggleEffectFlags()
    for _, effect in pairs(tes3.dataHandler.nonDynamicData.magicEffects) do
        effect.isHarmful = not effect.isHarmful
    end
end

-- Add bonus skill progression based on the number of effects.
local function addBonusProgress(potion)
    local alchemy = tes3.skill.alchemy + 1
    local progress = tes3.mobilePlayer.skillProgress
    local skills = tes3.dataHandler.nonDynamicData.skills

    for i, effect in ipairs(potion.effects) do
        if not effect.object then
            progress[alchemy] = progress[alchemy] + (
                skills[alchemy].actions[1] * (i-1) * 0.1
            )
            break
        end
    end
end

-- Temporarily copy all accessible apparatus to player inventory.
local function collectApparatus()
    local apparatus = {}
    local hasMortar = false

    local position = tes3.player.position
    local inventory = tes3.player.object.inventory

    -- scan current cell apparatus
    for _, cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(tes3.objectType.apparatus) do
            local item = ref.object
            if not (
                apparatus[item]
                or ref.disabled
                or ref.deleted
                or ref.position:distance(position) > 768
                or tes3.hasOwnershipAccess{target=ref} == false
                or inventory:contains(item)
            ) then
                apparatus[item] = true
                if item.type == tes3.apparatusType.mortarAndPestle then
                    hasMortar = true
                end
            end
        end
    end

    -- check for mortar and pestle
    if not hasMortar then
        for _, stack in pairs(tes3.player.object.inventory) do
            local item = stack.object
            if item.objectType == tes3.objectType.apparatus
                and item.type == tes3.apparatusType.mortarAndPestle
            then
                hasMortar = true
                break
            end
        end
    end

    -- copy apparatus to inventory
    if hasMortar then
        -- add temporary apparatus
        for item in pairs(apparatus) do inventory:addItem{item=item} end
        tes3.updateInventoryGUI{reference=tes3.player}
        -- remove after menu close
        timer.delayOneFrame(function()
            for item in pairs(apparatus) do inventory:removeItem{item=item} end
            tes3.updateInventoryGUI{reference=tes3.player}
        end)
    end

    return hasMortar
end

local isPoisonCrafting = false
local function startAlchemy(poisonMode)
    --
    if tes3.mobilePlayer.inCombat then
        tes3.messageBox("You cannot make potions during combat.")
        return
    end

    if not collectApparatus() then
        tes3.messageBox("Requires access to a Mortar and Pestle.")
        return
    end

    isPoisonCrafting = poisonMode

    -- apply GMST strings
    local effects = tes3.findGMST(tes3.gmst.sCreatedEffects)
    local message = tes3.findGMST(tes3.gmst.sNotifyMessage8)
    local success = tes3.findGMST(tes3.gmst.sPotionSuccess)
    effects.value = poisonMode and "Poison Effects" or "Potion Effects"
    message.value = poisonMode and "Your poison failed." or "Your potion failed."
    success.value = poisonMode and "You created a poison." or "You created a potion."

    -- bypass equip event
    tes3.showAlchemyMenu()

    -- detect menu closed
    timer.delayOneFrame(function()
        isPoisonCrafting = false
    end)
end

local function onActivate(e)
    if tes3ui.menuMode()
        or e.activator ~= tes3.player
        or tes3.mobilePlayer.isSneaking
        or not isValidApparatus(e.target.object)
    then
        return
    end

    tes3.messageBox{
        message = "What do you want to do?",
        buttons = {"Cancel", "Pick Up", "Brew Potion", "Brew Poison"},
        callback = function(b)
            if b.button == 1 then
                timer.delayOneFrame(function()
                    local temp = config.skipApparatusEvents
                    config.skipApparatusEvents = true
                    tes3.player:activate(e.target)
                    config.skipApparatusEvents = temp
                end)
            elseif b.button == 2 then
                startAlchemy(false)
            elseif b.button == 3 then
                startAlchemy(true)
            end
        end,
    }

    return false
end
event.register("activate", onActivate)

local function onEquip(e)
    if e.reference ~= tes3.player
        or not isValidApparatus(e.item)
    then
        return
    end

    tes3.messageBox{
        message = "What do you want to do?",
        buttons = {"Cancel", "Brew Potion", "Brew Poison"},
        callback = function(msg)
            if msg.button == 1 then
                startAlchemy(false)
            elseif msg.button == 2 then
                startAlchemy(true)
            end
        end,
    }

    return false
end
event.register("equip", onEquip)

local function onBrewSkillCheck(e)
    if config.useBaseStats then
        local mob = tes3.mobilePlayer
        local x = mob.alchemy.base + 0.1 * mob.intelligence.base + 0.1 * mob.luck.base

        local roll = math.random(0, 100)
        if roll <= x then
            local gmst = tes3.findGMST(tes3.gmst.fPotionStrengthMult).value
            e.potionStrength = gmst * e.mortar.quality * x
            e.success = true
        else
            e.potionStrength = -1
            e.success = false
        end
    end
    if isPoisonCrafting then
        toggleEffectFlags()
        -- ensure they're restored on the next frame
        timer.frame.delayOneFrame(toggleEffectFlags) ---@diagnostic disable-line: undefined-field
    end
end
event.register("potionBrewSkillCheck", onBrewSkillCheck, { priority = -700 })

local function onPotionBrewed(e)
    if config.useBonusProgress then
        addBonusProgress(e.object)
    end
end
event.register("potionBrewed", onPotionBrewed)
