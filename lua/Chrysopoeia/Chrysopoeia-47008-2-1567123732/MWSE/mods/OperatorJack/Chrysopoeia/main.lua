-- Check MWSE Build.
if (mwse.buildDate == nil) or (mwse.buildDate < 20190821) then
    local function warning()
        tes3.messageBox(
            "[Chrysopoeia ERROR] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

-- Check Magicka Expanded framework.
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "[Chrysopoeia ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end


-- Register the Spell Effect ID.
tes3.claimSpellEffectId("chrysopoeia", 266)

-- Function Section --
local function calculateItemValue(item)
    return item.value
end

local function filterItems(e)
    return calculateItemValue(e.item) > 0
end

local function getMultiplier()
    -- Calculate Damage Health multiplier, based on Alteration and Willpower.
    local alterationSkillLvl = tes3.mobilePlayer.alteration.current
    local willpowerAttrLvl = tes3.mobilePlayer.willpower.current

    local multiplier = ((alterationSkillLvl / 100) + (willpowerAttrLvl / 100)) / 2.5

    if (multiplier > .85) then
        multiplier = .85
    end

    return multiplier
end
--------------------

-- Effect Section --

local function onInventoryItemSelected(e)
    -- Make sure the player selected an item.
    if (e.item == nil) then
        return
    end

    -- Remove transmuted item.
    tes3.removeItem({
        reference = tes3.player,
        item = e.item
    });

    -- Calculate Values
    local count =  calculateItemValue(e.item)
    local multiplier = getMultiplier()
    local goldAmount = math.ceil(count * multiplier)
    local damageAmount = math.ceil(count * multiplier * 1.2)

    -- Add gold to the players inventory.
    tes3.addItem({
        reference = tes3.player,
        item = "gold_001",
        count = goldAmount
    })

    -- Add damage health costs from casting spell.
    tes3.mobilePlayer:applyHealthDamage(damageAmount)

    -- Provide some information to the player.
    if (tes3.mobilePlayer.health.current > 0) then
        tes3.messageBox("The blood price has been paid. You  lost " .. damageAmount .. " health." ..
         " You receive " .. goldAmount .. " gold from the transmutation.")
    else
        tes3.messageBox("The blood price proved too great for your body.")
    end
end

local function onChrysopoeiaTick(e)
    -- Trigger into the spell system.
    if (not e:trigger()) then
        return
    end

	tes3ui.showInventorySelectMenu({
		title = "Chrysopoeia",
		noResultsText = "No possible items found.",
		filter = filterItems,
        callback = onInventoryItemSelected
	})
    
    e.effectInstance.state = tes3.spellState.retired
end

local function addChrysopoeiaEffect()
	framework.effects.alteration.createBasicEffect({
		-- Base information.
		id = tes3.effect.chrysopoeia,
		name = "Chrysopoeia",
		description = "Transmute an item into Gold, with the cost paid in blood.",

		-- Basic dials.
		baseCost = 0,

        -- Various flags.
        allowSpellmaking = true,
        allowEnchanting = true,
		appliesOnce = true,
		canCastSelf = true,
		hasNoDuration = true,
		hasNoMagnitude = true,
		nonRecastable = true,

		-- Graphics/sounds.
		icon = "RFD\\RFD_chrysopoeia.dds",

		-- Required callbacks.
		onTick = onChrysopoeiaTick,
	})
end

event.register("magicEffectsResolved", addChrysopoeiaEffect)
-------------------

-- Spell Section --
local function registerSpells()
    framework.spells.createBasicSpell({
        id = "OJ_CH_ChrysopoeiaSpell",
        name = "Chrysopoeia",
        effect = tes3.effect.chrysopoeia,
        range = tes3.effectRange.self
    })
end

event.register("MagickaExpanded:Register", registerSpells)
------------------

-- Book Section --
local function readChrysopoeia(e)
    local player = tes3.getPlayerRef()
    local chrysopoeiaSpell = tes3.getObject( "OJ_CH_ChrysopoeiaSpell" )

    if (not tes3.player.object.spells:contains(chrysopoeiaSpell)) then
        tes3.messageBox("As you read the scroll, you feel the spell drift into your mind.")
        tes3.updateJournal({id="OJ_CH_Chrysopoeia", index=30})
        mwscript.addSpell({reference = player, spell = chrysopoeiaSpell})
    end
end

---------------------------

-- Initilization Section --
local function onInitialized()	
    if not tes3.isModActive("Chrysopoeia.ESP") then
        print("[Chrysopoeia: INFO] ESP not loaded")
        return
    end

    local chrysopoeiaBook = tes3.getObject("OJ_CH_ChrysopoeiaBook") or "nothing"
    event.register("bookGetText", readChrysopoeia, { filter = chrysopoeiaBook } )

	print("[Chrysopoeia: INFO] Initialized Chrysopoeia")
end
event.register("initialized", onInitialized)
----------------------------