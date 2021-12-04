return function(o)
  o.softPlant = {
    "ab_ingflor_bluekanet_01",
    "ab_ingflor_bloodgrass_01",
    "ab_ingflor_bloodgrass_02",
    "ingred_black_lichen_01",
    "ingred_comberry_01",
    "ingred_green_lichen_01",
    "ingred_heather_01",
    "ingred_muck_01",
    "ingred_marshmerrow_01",
    "ingred_red_lichen_01",
    "ingred_russula_01",
    "ingred_sweetpulp_01"  
  }

  o.mediumPlant = {
    "ingred_bc_bungler's_bane",
    "ingred_bc_hypha_facia",
    "ingred_coprinus_01",
    "ingred_kresh_fiber_01" 
  }

  o.hardPlant = {
    "ingred_chokeweed_01",
    "ingred_kresh_fiber_01",
    "ingred_marshmerrow_01",
    "ingred_saltrice_01",
    "ingred_wickwheat_01"
  }

  o.softMeat = {
    "ab_ingfood_kwamaeggcentcut",
    "ab_ingfood_kwamaeggspoillarge",
    "ab_ingfood_kwamaeggspoilsmall",
    "food_kwama_egg_01",
    "food_kwama_egg_02",
    "ingred_crab_meat_01",
    "ingred_scuttle_01",
    "ingred_scrib_jelly_01"
  }

  o.mediumMeat = {
    "ab_ingcrea_guarmeat_01",
    "ab_ingcrea_horsemeat01",
    "ingred_hound_meat_01",
    "ingred_rat_meat_01"
  }

  o.hardMeat = {
    "ab_ingcrea_sfmeat_01",
    "ingred_durzog_meat_01",
    "ingred_kwama_cuttle_01",
    "ingred_scrib_jerky_01"
  }

  o.food          = {
    alit          = {
      softPlant   = true,
      mediumPlant = true,
      hardPlant   = true,
      softMeat    = true,
      mediumMeat  = true,
      hardMeat    = true
    },
    bat           = {
      softMeat    = true,
      mediumMeat  = true
    },
    cliffRacer    = {
      softPlant   = true,
      softMeat    = true,
      mediumMeat  = true
    },
    durzog        = {
      softMeat    = true,
      mediumMeat  = true,
      hardMeat    = true
    },
    guar          = {
      mediumPlant = true,
      hardPlant   = true
    },
    kagouti       = {
      mediumMeat  = true,
      hardMeat    = true
    },
    kwamaForager  = {
      softPlant   = true,
      softMeat    = true
    },
    kwamaGrubber  = {
      softPlant   = true,
      softMeat    = true
    },
    kwamaQueen    = {
      softPlant   = true,
      mediumPlant = true,
      softMeat    = true,
      mediumMeat  = true,
      hardMeat    = true
    },
    kwamaWorker   = {
      softPlant   = true,
      mediumPlant = true,
      softMeat    = true,
      mediumMeat  = true
    },
    kwamaWarrior  = {
      softPlant   = true,
      mediumPlant = true,
      softMeat    = true,
      mediumMeat  = true,
      hardMeat    = true
    },
    mudCrab       = {
      softPlant   = true,
      mediumPlant = true,
      softMeat    = true
    },
    moleCrab      = {
      softPlant   = true,
      mediumPlant = true,
      softMeat    = true,
      mediumMeat  = true
    },
    netch         = {
      softPlant   = true,
      mediumPlant = true
    },
    nixHound      = {
      softMeat    = true,
      mediumMeat  = true
    },
    rat           = {
      softPlant   = true,
      mediumPlant = true,
      softMeat    = true,
      mediumMeat  = true
    },
    scrib         = {
      softPlant   = true
    },
    shalk         = {
      mediumMeat  = true,
      hardMeat    = true
    },
    slaughterFish = {
      softMeat    = true,
      mediumMeat  = true,
      hardMeat    = true
    }
  }

  o.info = {}

  return o
end