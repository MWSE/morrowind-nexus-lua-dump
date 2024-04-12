--local default_config = {
--distribute_magicka_expanded_spells = true,
--}
-- Copy
local config = {
    log_level = "INFO",
    distribute_magicka_expanded_spells = true,
}

local logger = require("logging.logger")
local log = logger.new{
    name = "ME Tweaks",
    logLevel = config.log_level,
}

local version = "1.0.0"


local me_known_packs = {"lore_friendly", "summoning", "teleportation", "tr", "weather", "cortex"}

local me_packs = {lore_friendly = false, summoning = false, teleportation = false, tr = false, weather = false, cortex = false}

local me_distribution = {lore_friendly = {}, summoning = {}, teleportation = {}, tr = {}, weather = {}, cortex = {}}

me_distribution.lore_friendly = {
  ["ferise varo"] = {
    "OJ_ME_BoundGreavesSpell",
    "OJ_ME_BoundPauldronsSpell",
    "OJ_ME_BoundWarAxeSpell",
    "OJ_ME_BoundShortswordSpell"
  },
  ["eldrilu dalen"] = {
    "OJ_ME_BanishDaedraSpell"
  },
  ["folvys andalor"] = {
    "OJ_ME_BanishDaedraSpell"
  },
  ["urtiso faryon"] = {
    "OJ_ME_BoundClaymoreSpell",
    "OJ_ME_BoundTantoSpell"
  },
  ["erer darothril"] = {
    "OJ_ME_BoundWakizashiSpell",
    "OJ_ME_BoundStaffSpell"
  },
  ["marayn dren"] = {
    "OJ_ME_BoundClubSpell",
    "OJ_ME_BoundGreavesSpell",
    "OJ_ME_BoundStaffSpell"
  },
  ["heem_la"] = {
    "OJ_ME_BoundPauldronsSpell",
    "OJ_ME_BoundWarhammerSpell",
    "OJ_ME_BoundKatanaSpell"
  },
  ["aldaril"] = {
    "OJ_ME_BoundDaiKatanaSpell",
    "OJ_ME_BoundWarhammerSpell"
  },
  ["farena arelas"] = {
    "OJ_ME_BoundClubSpell",
    "OJ_ME_BoundDaiKatanaSpell"
  },
  ["bratheru oran"] = {
    "OJ_ME_BoundTantoSpell"
  },
  ["diren vendu"] = {
    "OJ_ME_BoundClaymoreSpell",
    "OJ_ME_BoundKatanaSpell",
    "OJ_ME_BoundWarAxeSpell"
  },
  ["TR_m1_Nilena_Othril"] = {
    "OJ_ME_BoundStaffSpell",
    "OJ_ME_BoundDaiKatanaSpell",
    "OJ_ME_BoundGreavesSpell"
  },
  ["estoril"] = {
    "OJ_ME_BoundWakizashiSpell"
  }
}

-- NOT distributed: imperfect (too broken), werewolf (bugged) -- Brujo: I believe this as well, leaving "vanilla"
me_distribution.summoning = {
  ["felen maryon"] = {
    "OJ_ME_SummAscendedSleeperSpell", -- hard to justify lorewise -- Brujo: I should comment this out
    "OJ_ME_SummAshGhoulSpell",
    "OJ_ME_SummAshZombieSpell",
    "OJ_ME_SummAshSlaveSpell"
  },
  ["nelso salenim"] = {
    "OJ_ME_SummOgrimSpell",
    "OJ_ME_SummLichSpell"
  },
  ["a_ve_service01"] = {
    "OJ_ME_SummSprigganSpell",
    "OJ_ME_SummDraugrSpell"
  },
  ["salver lleran"] = {
    "OJ_ME_SummCenturionSteamSpell", -- also hard to justify lorewise - Brujo: ditto
    "OJ_ME_SummCenturionArcherSpell",
    "OJ_ME_SummCenturionSpiderSpell",
    "OJ_ME_SummCenturionSphereSpell"
  },
  ["Nebia Amphia"] = {
    "OJ_ME_SummWarDurzogSpell",
    "OJ_ME_SummGoblinGruntSpell",
    "OJ_ME_SummGoblinOfficerSpell",
    "OJ_ME_SummGoblinWarchiefSpell"
  },
  ["solea nuccusius"] = {
    "OJ_ME_SummHulkingFabSpell"
  },
  ["estirdalin"] = {
    "OJ_ME_SummOgrimSpell"
  },
  ["medila indaren"] = {
    "OJ_ME_SummOgrimSpell"
  },
  ["malven romori"] = {
    "OJ_ME_SummLichSpell"
  },
  ["TR_m1_Vendil_Tras"] = {
    "OJ_ME_SummOgrimSpell",
    "OJ_ME_SummLichSpell"
  }
}

me_distribution.teleportation = {
  ["masalinie merian"] = {
    "OJ_ME_TeleportToBalmora",
    "OJ_ME_TeleportToAldRuhn",
    "OJ_ME_TeleportToCaldera",
    "OJ_ME_TeleportToVivec"
  },
  ["salam andrethi"] = {
    "OJ_ME_TeleportToTelMora",
    "OJ_ME_TeleportToSuran"
  },
  ["sedris omalen"] = {
    "OJ_ME_TeleportToMaarGan"
  },
  ["saras orelu"] = {
    "OJ_ME_TeleportToMolagMar"
  },
  ["ygfa"] = {
    "OJ_ME_TeleportToPelagiad"
  },
  ["mehra drora"] = {
    "OJ_ME_TeleportToGnisis"
  },
  ["dileno lloran"]= {
    "OJ_ME_TeleportToVivec",
    "OJ_ME_TeleportToMaarGan",
    "OJ_ME_TeleportToBalmora",
    "OJ_ME_TeleportToAldRuhn",
    "OJ_ME_TeleportToGnisis"
  },
  ["elynu saren"] = {
    "OJ_ME_TeleportToSuran"
  },
  ["Synnolian Tunifus"] = {
    "OJ_ME_TeleportToEbonheart"
  },
  ["Laurina Maria"] = {
    "OJ_ME_TeleportToMournhold",
    "OJ_ME_TeleportToEbonheart"
  },
  ["TR_m1_LadiaTunifus"] = {
    "OJ_ME_TeleportToEbonheart",
    "OJ_ME_TeleportToPelagiad"
  },
  ["TR_m1_Nevusa_Lakasyn"] = {
    "OJ_ME_TeleportToMolagMar"
  },
  ["TR_m2_Tiunian Veltrus"] = {
    "OJ_ME_TeleportToCaldera"
  }
}

-- not distributed: Silt Strider and Wereboar (too silly imo) - Brujo: LOL! yeah, I agree 100%
me_distribution.tr = {
  ["TR_m1_LadiaTunifus"] = {
    "OJ_ME_TeleportToFirewatch",
    "OJ_ME_TeleportToHelnim",
    "OJ_ME_TeleportToBalOrya",
    "OJ_ME_TeleportToOldEbonheart"
  },
  ["TR_m1_Aeli_Danym"] = {
    "OJ_ME_TeleportToTelOuada",
    "OJ_ME_TeleportToLlothanis",
    "OJ_ME_TeleportToBalOrya",
    "OJ_ME_TeleportToPortTelvannis"
  },
  ["TR_m1_Nevusa_Lakasyn"] = {
    "OJ_ME_TeleportToMarog",
    "OJ_ME_TeleportToTelMothrivra",
    "OJ_ME_TeleportToHelnim",
    "OJ_ME_TeleportToFirewatch",
    "OJ_ME_TeleportToAltBosara"
  },
  ["TR_m2_Domus Terrinus"] = {
    "OJ_ME_TeleportToOldEbonheart",
    "OJ_ME_TeleportToTelMuthada"
  },
  ["TR_m1_Cerul_Arnem"] = {
    "OJ_ME_TeleportToPortTelvannis",
    "OJ_ME_TeleportToGahSadrith",
    "OJ_ME_TeleportToGorne"
  },
  ["TR_m1_Taldasi_Menguren"] = {
    "OJ_ME_TeleportToPortTelvannis",
    "OJ_ME_TeleportToMeralag",
    "OJ_ME_TeleportToTelAranyon",
    "OJ_ME_TeleportToTelOuada"
  },
  ["eldrilu dalen"] = {
    "OJ_ME_TeleportToNecrom"
  },
  ["TR_m1_Trendil Vas"] = {
    "OJ_ME_TeleportToMeralag"
  },
  ["TR_m1_Ultern"] = {
    "OJ_ME_TeleportToGahSadrith",
    "OJ_ME_TeleportToNecrom",
    "OJ_ME_TeleportToAkamora"
  },
  ["milar maryon"] = {
    "OJ_ME_TeleportToAltBosara"
  },
  ["fanildil"] = {
    "OJ_ME_TeleportToOldEbonheart"
  },
  ["vaval selas"] = {
    "OJ_ME_TeleportToAkamora"
  },
  -- summons
  ["TR_m1_Vendil_Tras"] = {
    "OJ_ME_SummMinotaur",
    "OJ_ME_SummDridrea",
    "OJ_ME_SummFrostLich"
  },
  ["uleni heleran"] = {
    "OJ_ME_SummMudGolem",
    "OJ_ME_SummWelkSpirit",
    "OJ_ME_SummVermai"
  },
  ["TR_m1_Tirele_Edri"] = {
    "OJ_ME_SummRaki",
    "OJ_ME_SummPlainStrider"
  },
  ["a_ve_service01"] = {
    "OJ_ME_SummDraugrHsCrl",
    "OJ_ME_SummDraugrLord",
    "OJ_ME_SummMammoth",
    "OJ_ME_SummGiant"
  },
  ["medila indaren"] = {
    "OJ_ME_SummVermai"
  },
  ["llaalam madalas"] = {
    "OJ_ME_SummMudGolem",
    "OJ_ME_SummVelk"
  },
  ["felen maryon"] = {
    "OJ_ME_SummDridreaMonarch",
    "OJ_ME_SummGreaterLich",
    "OJ_ME_SummSload"
  },
  ["estoril"] = {
    "OJ_ME_SummSabreCat"
  },
  ["TR_m1_Fusath_Relyan"] = {
    "OJ_ME_SummGoblinShaman",
    "OJ_ME_SummLamia",
    "OJ_ME_SummDridrea",
    "OJ_ME_SummDridreaMonarch",
    "OJ_ME_SummTrebataur"
  },
  ["salver lleran"] = {
    "OJ_ME_SummArmorCent",
    "OJ_ME_SummArmorCentChamp"
  },
  ["TR_m1_Olanasa_Wenil"] = {
    "OJ_ME_SummParastylus",
    "OJ_ME_SummSwampTroll"
  },
  ["Jeanne Andre"] = {
    "OJ_ME_SummGoblinShaman",
    "OJ_ME_SummWelkSpirit"
  }
}

me_distribution.weather = {
  ["leles birian"] = {
    "OJ_ME_WeatherAsh",
    "OJ_ME_WeatherBlight"
  },
  ["gildan"] = {
    "OJ_ME_WeatherClear"
  },
  ["ethasi rilvayn"] = {
    "OJ_ME_WeatherFoggy"
  },
  ["erer darothril"] = {
    "OJ_ME_WeatherThunder",
    "OJ_ME_WeatherRain"
  },
  ["a_ve_service01"] = {
    "OJ_ME_WeatherBlizzard",
    "OJ_ME_WeatherSnow"
  },
  ["TR_m1_Lloryn_Llaram"] = {
    "OJ_ME_WeatherCloudy",
    "OJ_ME_WeatherOvercast"
  }
}

-- unsupported for now - Brujo: Dont even look at me, I am just learning MWSE, like 100% newbie
me_distribution.cortex = {
}

local function magicka_expanded_spells(e)

  log:trace("Looking for Magicka Expanded Spell Packs...")
  -- I don't know if it's a good way to make sure ME creates spells before this check applies
  -- Brujo: I like turtles
  timer.start{type = timer.real, duration = 3, callback = function()

    if tes3.getObject('OJ_ME_BanishDaedraSpell') then
      log:trace("ME Packs: Found Lore-Friendly Pack!")
      me_packs.lore_friendly = true
    end
    if tes3.getObject('OJ_ME_SummWarDurzogSpell') then
      log:trace("ME Packs: Found Summoning Pack!")
      me_packs.summoning = true
    end
    if tes3.getObject('OJ_ME_TeleportToAldRuhn') then
      log:trace("ME Packs: Found Teleportation Pack!")
      me_packs.teleportation = true
    end
    if tes3.getObject('OJ_ME_TeleportToAkamora') then
      log:trace("ME Packs: Found TR Pack!")
      me_packs.tr = true
    end
    if tes3.getObject('OJ_ME_WeatherBlizzard') then
      log:trace("ME Packs: Found Weather Pack!")
      me_packs.weather = true
    end
    if tes3.getObject('OJ_ME_BlinkSpell') then
      log:trace("ME Packs: Found Cortex Pack!")
      me_packs.cortex = true
    end

    -- distribute spells to merchants, using same logic as Enhanced Detection (thanks for the code!) - Brujo : I give thanks as well!
    for i, pack_name in ipairs(me_known_packs) do
      if me_packs[pack_name] then
        log:trace(string.format("Distributing spells from the %s pack...", pack_name))

        for npc_id, dist_spell_id in pairs(me_distribution[pack_name]) do
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
      end
    end


  end}
end

  local function initialized()
  event.register(tes3.event.loaded, magicka_expanded_spells)
end

event.register(tes3.event.initialized, initialized)
