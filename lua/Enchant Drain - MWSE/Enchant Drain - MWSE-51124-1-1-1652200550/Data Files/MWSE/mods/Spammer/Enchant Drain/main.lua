local mod = {
    name = "Enchant Drain",
    ver = "1.0",
    cf = {onOff = false, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {},}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)

local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

local count = 0


tes3.claimSpellEffectId("enchantDrain", 786)

local function addWeaponDrainEffect()
	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.enchantDrain,
		name = "Drain Enchant",
		description = "While active, the subject drains charge from their equipped Weapon, Amulet or Rings as a substitute for their Magicka pool.",

		-- Basic dials.
		baseCost = 1.0,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        canCastSelf = true,
        canCastTouch = false,
        canCastTarget = false,
        hasContinuousVFX = true,
        nonRecastable = true,

		-- Graphics/sounds.
		icon = "Spammer\\b_spa_drain.dds",
        lighting = { 1, 0, 1 },
		-- Required callbacks.
		onTick = function(e) e:trigger() end,
	})
end event.register("magicEffectsResolved", addWeaponDrainEffect)

local function onSpellCast(e)
    local chargeW = nil
    local chargeA = nil
    local chargeR = nil
    local isAffected = tes3.isAffectedBy({
        reference = tes3.player,
        effect = tes3.effect.enchantDrain
    })

    if not isAffected then
        return
    end

    if e.caster ~= tes3.player then
        return
    end

    local magnitude = tes3.getEffectMagnitude({reference = tes3.player, effect = tes3.effect.enchantDrain})

    if e.cost > magnitude then
        tes3.messageBox("Your Drain Enchant is not powerful enough to affect this spell!")
        return
    end
    local equippedW = tes3.getEquippedItem({ actor = tes3.player, enchanted = true, objectType = tes3.objectType.weapon, type = tes3.weaponType.bluntTwoWide })
    local equippedR = tes3.getEquippedItem({ actor = tes3.player, enchanted = true, objectType = tes3.objectType.clothing, slot = 8})
    local equippedA = tes3.getEquippedItem({ actor = tes3.player, enchanted = true, objectType = tes3.objectType.clothing, slot = 9})
    if equippedW then
        chargeW = equippedW.itemData.charge
    end
    if equippedR then
        chargeR = equippedR.itemData.charge
    end
    if equippedA then
        chargeA = equippedA.itemData.charge
    end
    if chargeW and chargeW >= e.cost then
        equippedW.itemData.charge = ((chargeW)-(e.cost))
        e.cost = 0
    elseif chargeA and chargeA >= e.cost then
        equippedA.itemData.charge = ((chargeA)-(e.cost))
        e.cost = 0
    elseif chargeR and chargeR >= e.cost then
        equippedR.itemData.charge = ((chargeR)-(e.cost))
        e.cost = 0
    end
end event.register("spellMagickaUse", onSpellCast)

local function registerSpells()
    framework.spells.createBasicSpell({
        id = "Spa_ME_EnchantDrainSpell",
        name = "Drain Enchant",
        effect = tes3.effect.enchantDrain,
        range = tes3.effectRange.self,
        duration = 30,
        min = 20,
        max = 20
    })
end event.register("MagickaExpanded:Register", registerSpells)

local function onMobileActivated(e)
    if e.reference.object.objectType ~= tes3.objectType.npc then
        return
    end
    if e.reference.data.spammer_eddoonce then
        return
    end
        if (e.mobile.object:offersService(tes3.merchantService.spells)) and math.random(0, 100) < 5 then
            tes3.addSpell({reference = e.mobile, spell = "Spa_ME_EnchantDrainSpell"})
            --print(e.mobile.object.name)
            count = 0
        elseif e.mobile.object:offersService(tes3.merchantService.spells) then
            count = count+1
            --print(count)
            if count >= 20 then
                tes3.addSpell({reference = e.mobile, spell = "Spa_ME_EnchantDrainSpell"})
                --print(e.mobile.object.name)
                count = 0
            end
        end
        e.reference.data.spammer_eddoonce = true
end event.register("mobileActivated", onMobileActivated)

local function onLoad()
    if cf.onOff then tes3.addSpell({reference = tes3.player, spell = "Spa_ME_EnchantDrainSpell"}) end
end event.register("loaded", onLoad, {priority = -500})

local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category = page:createCategory("Debug Mode")
    category:createOnOffButton{label = "On/Off", description = "If turned on, will automatically give you the spell on your next loading of a save.", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}

   --[[ category:createKeyBinder{label = " ", description = " ", allowCombinations = false, variable = mwse.mcm.createTableVariable{id = "key", table = cf, restartRequired = true, defaultSetting = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}}}

    local category1 = page:createCategory(" ")
    local elementGroup = category1:createCategory("")
    elementGroup:createDropdown { description = " ",
        options  = {
            { label = " ", value = 0 },
            { label = " ", value = 1 },
            { label = " ", value = 2 },
            { label = " ", value = 3 },
            { label = " ", value = 4 },
            { label = " ", value = -1}
        },
        variable = mwse.mcm:createTableVariable {
            id    = "dropDown",
            table = cf
        }
    }

    local category2 = page:createCategory(" ")
    local subcat = category2:createCategory(" ")
    subcat:createSlider{label = " ", description = " ", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}}

    subcat:createSlider{label = " ".."%s%%", description = " ", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}

    template:createExclusionsPage{label = " ", description = " ", variable = mwse.mcm.createTableVariable{id = "blocked", table = cf}, filters = {{label = " ", callback = getExclusionList}}}

    template:createExclusionsPage{label = " ", description = " ", variable = mwse.mcm.createTableVariable{id = "npcs", table = cf}, filters = {{label = "NPCs", type = "Object", objectType = tes3.objectType.npc}}}]]
end event.register("modConfigReady", registerModConfig)

local function initialized()
    print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
end event.register("initialized", initialized)

