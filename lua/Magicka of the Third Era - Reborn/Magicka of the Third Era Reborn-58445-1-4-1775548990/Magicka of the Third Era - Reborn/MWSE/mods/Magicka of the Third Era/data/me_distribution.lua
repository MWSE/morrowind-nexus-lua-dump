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
    "OJ_ME_BoundShortswordSpell"
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

-- NOT distributed: imperfect (too broken), werewolf (bugged)
me_distribution.summoning = {
  ["felen maryon"] = {
    "OJ_ME_SummAscendedSleeperSpell", -- hard to justify lorewise
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
    "OJ_ME_SummCenturionSteamSpell", -- also hard to justify lorewise
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

-- not distributed: Silt Strider and Wereboar (too silly imo)
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

-- unsupported for now
me_distribution.cortex = {
}

return me_distribution
