local Interop = require("mer.fishing")
local SkillsModule = require("SkillsModule")

---@type Fishing.FishingRod.config[]
local fishingRods = {
    {
        id = "ste_fishing_pole_deadric_01",
        quality = 1.0
    },
}

event.register("initialized", function (e)
    for _, data in ipairs(fishingRods) do
        Interop.registerFishingRod(data)
    end
end)

local framework = require("OperatorJack.MagickaExpanded")

tes3.claimSpellEffectId("boundFishingPole", 3031)

local function getDescription(weaponName)
    return "The spell effect conjures a lesser Daedra bound in the form of  amagical, wondrously light Daedric " ..
    weaponName .. ". The ".. weaponName .. " appear automatically equipped on the caster, displacing any currently " ..
    " equipped weapon to inventory.  When the effect ends, the ".. weaponName .. " disappears, and any previously " .. 
    " equipped weapon is automatically re-equipped."
end

local function addBoundWeaponEffects()
    framework.effects.conjuration.createBasicBoundWeaponEffect({
        id = tes3.effect.boundFishingPole,
        name = "Bound Fishing Pole",
        description = getDescription("Bound Fishing Pole"),
        baseCost = 1,
        weaponId = "ste_fishing_pole_deadric_01",
		icon = "s\\Tx_S_Bd_Dagger.tga"
    })
end

event.register("magicEffectsResolved", addBoundWeaponEffects)

local spellIds = {
  boundFishingPole = "STE_ME_BoundFishingPoleSpell"
}

SkillsModule.registerBaseModifier{
    id = "ste_fortify_fishing",
    skill = "fishing",
    callback = function()
        local weapon = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.weapon
        }
        if weapon and weapon.object.id:lower() == "ste_fishing_pole_deadric_01" then
            return 50
        end
    end
}

local function applyTooltips(e)
	if e.object.id:lower() == "ste_fishing_pole_deadric_01" then
		local tooltip = e.tooltip
		local text = "Fortify Fishing 50 pts on self"
		local color = { 0.1, 0.8, 0.1}
		local function setupOuterBlock(e)
			e.flowDirection = 'left_to_right'
			e.paddingTop = 0
			e.paddingBottom = 2
			e.paddingLeft = 6
			e.paddingRight = 6
			e.autoWidth = true
			e.autoHeight = true
			e.childAlignX = 0.5
		end
		--Get main block inside tooltip
		local partmenuID = tes3ui.registerID('PartHelpMenu_main')
		local mainBlock = tooltip:findChild(partmenuID)
			and tooltip:findChild(partmenuID):findChild(partmenuID):findChild(partmenuID)
			or tooltip

		local outerBlock = mainBlock:createBlock{ id = "SkillFortify_EffectBlock" }
		setupOuterBlock(outerBlock)

		local insertBefore = mainBlock:findChild("HelpMenu_weaponType") or -2

		--mainBlock:reorderChildren(insertBefore, -1, 1)
		mainBlock:updateLayout()

		if text then
			local label = outerBlock:createLabel({text = text})
			label.autoHeight = true
			label.autoWidth = true
			label.widthProportional = 1.0
			if color then label.color = color end
			return label
		end
		return outerBlock
	end
end

local function registerSpells()
  framework.spells.createBasicSpell({
    id = spellIds.boundFishingPole,
    name = "Bound Fishing Pole",
    effect = tes3.effect.boundFishingPole,
        rangeType = tes3.effectRange.self,
    duration = 120
  })
  -- framework.tomes.registerTomes(tomes)
end
event.register("MagickaExpanded:Register", registerSpells)

local boundFishingPoleNPC = {
  ["diren vendu"] = {
    "STE_ME_BoundFishingPoleSpell"
  },
  ["felen maryon"] = {
    "STE_ME_BoundFishingPoleSpell"
  },
  ["farena arelas"] = {
    "STE_ME_BoundFishingPoleSpell"
  },
  ["estirdalin"] = {
    "STE_ME_BoundFishingPoleSpell"
  },
  ["erer darothril"] = {
    "STE_ME_BoundFishingPoleSpell"
  },
  ["heem_la"] = {
    "STE_ME_BoundFishingPoleSpell"
  },
  ["masalinie merian"] = {
    "STE_ME_BoundFishingPoleSpell"
  },
  ["medila indaren"] = {
    "STE_ME_BoundFishingPoleSpell"
  },
  ["nelso salenim"] = {
    "STE_ME_BoundFishingPoleSpell"
  },
  ["urtiso faryon"] = {
    "STE_ME_BoundFishingPoleSpell"
  }
}
  
local function magicka_expanded_spells(e)

  timer.start{type = timer.real, duration = 3, callback = function()

    for npc_id, dist_spell_id in pairs(boundFishingPoleNPC) do
          local npc = tes3.getObject(npc_id)
          if (npc) then
            if (type(dist_spell_id) ~= "table") then
              local spell = tes3.getObject(dist_spell_id)
              if (spell) then
                npc.spells:add(spell)
              end
            else
              for _, spell_id in pairs(dist_spell_id) do
                local spell = tes3.getObject(spell_id)
                if (spell) then
                  npc.spells:add(spell)
                end
              end
            end
          end
    end
  end}
end

  local function initialized()
  event.register(tes3.event.loaded, magicka_expanded_spells)
end

event.register(tes3.event.initialized, initialized)
event.register("uiObjectTooltip", applyTooltips)
