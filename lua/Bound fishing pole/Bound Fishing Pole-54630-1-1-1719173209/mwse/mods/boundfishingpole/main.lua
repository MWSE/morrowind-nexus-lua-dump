local Interop = require("mer.fishing")

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

-- local tomes = {
  -- {
    -- id = "STE_ME_TomeBoundFishingPole",
    -- spellId = spellIds.boundFishingPole
  -- }, 
-- }

-- local function addTomesToLists()
  -- local listId = "OJ_ME_LeveledList_Common"
  -- for _, tome in pairs(tomes) do
    -- mwscript.addToLevItem({
      -- list = listId,
      -- item = tome.id,
      -- level = 1
    -- })
  -- end
-- end

-- event.register("initialized", addTomesToLists)

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

-- npc = {"diren vendu", "felen maryon", "farena arelas", "estirdalin", "erer darothril", "heem_la", "masalinie merian", "medila indaren", "nelso salenim", "urtiso faryon"}

--tes3.getGlobal(T_Glob_Installed_TR) == 1
