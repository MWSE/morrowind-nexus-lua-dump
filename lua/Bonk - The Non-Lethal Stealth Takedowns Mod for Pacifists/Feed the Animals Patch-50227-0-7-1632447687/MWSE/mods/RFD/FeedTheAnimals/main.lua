local o = {}

o.conf            = mwse.loadConfig("Feed the Animals") or {
  halt            = true,
  debug           = false,
  message         = true,
  overfeed        = false,
  gain            = 5,
  base            = 40,
  luck            = 4,
  personality     = 2,
  key             = {
    keyCode       = tes3.scanCode.lShift,
    isShiftDown   = true,
    isControlDown = false,
    isAltDown     = false
  }
}

o.meshes = {
  ["r\\duskyalit.nif"]                = "Alit",
  ["oaab\\r\\bat.nif"]                = "Bat",
  ["oaab\\r\\r0_s-fish_blind.nif"]    = "Blind Slaughterfish",
  ["r\\cliffracer.nif"]               = "Cliffracer",
  ["r\\durzog.nif"]                   = "Durzog",
  ["r\\durzog_collar.nif"]            = "Durzog",
  ["r\\guar.nif"]                     = "Guar",
  ["r\\guar_white.nif"]               = "Guar",
  ["r\\guar_withpack.nif"]            = "Guar",
  ["r\\leastkagouti.nif"]             = "Kagouti",
  ["r\\kwama forager.nif"]            = "Kwama Forager",
  ["oaab\\r\\kwama grubber.nif"]      = "Kwama Grubber",
  ["r\\kwama queen.nif"]              = "Kwama Queen",
  ["r\\kwama warrior.nif"]            = "Kwama Warrior",
  ["r\\kwama worker.nif"]             = "Kwama Worker",
  ["r\\cavemudcrab.nif"]              = "Mudcrab",
  ["r\\mushroomcrab.nif"]             = "Mushroom Crab",
  ["r\\tr_molecrab_vo.nif"]           = "Molecrab",
  ["r\\netch_betty.nif"]              = "Netch",
  ["r\\netch_bull.nif"]               = "Netch",
  ["r\\nixhound.nif"]                 = "Nix-Hound",
  ["oaab\\r\\lidicus_cspider.nif"]    = "Parasol Spider",
  ["r\\packrat.nif"]                  = "Rat",
  ["r\\rust rat.nif"]                 = "Rat",
  ["r\\minescrib.nif"]                = "Scrib",
  ["r\\slaughterfish.nif"]            = "Slaughterfish"
}

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

o.food                    = {
  Alit                    = {
    ["softPlant"]         = true,
    ["mediumPlant"]       = true,
    ["hardPlant"]         = true,
    ["softMeat"]          = true,
    ["mediumMeat"]        = true,
    ["hardMeat"]          = true
  },
  Bat                     = {
    ["softMeat"]          = true,
    ["mediumMeat"]        = true
  },
  ["Blind Slaughterfish"] = {
    ["softMeat"]          = true,
    ["mediumMeat"]        = true,
    ["hardMeat"]          = true
  },
  Cliffracer              = {
    ["softPlant"]         = true,
    ["softMeat"]          = true,
    ["mediumMeat"]        = true
  },
  Durzog                  = {
    ["softMeat"]          = true,
    ["mediumMeat"]        = true,
    ["hardMeat"]          = true
  },
  Guar                    = {
    ["mediumPlant"]       = true,
    ["hardPlant"]         = true
  },
  Kagouti                 = {
    ["mediumMeat"]        = true,
    ["hardMeat"]          = true
  },
  ["Kwama Forager"]       = {
    ["softPlant"]         = true,
    ["softMeat"]          = true
  },
  ["Kwama Grubber"]       = {
    ["softPlant"]         = true,
    ["softMeat"]          = true
  },
  ["Kwama Queen"]         = {
    ["softPlant"]         = true,
    ["mediumPlant"]       = true,
    ["softMeat"]          = true,
    ["mediumMeat"]        = true,
    ["hardMeat"]          = true
  },
  ["Kwama Worker"]        = {
    ["softPlant"]         = true,
    ["mediumPlant"]       = true,
    ["softMeat"]          = true,
    ["mediumMeat"]        = true
  },
  ["Kwama Warrior"]       = {
    ["softPlant"]         = true,
    ["mediumPlant"]       = true,
    ["softMeat"]          = true,
    ["mediumMeat"]        = true,
    ["hardMeat"]          = true
  },
  Mudcrab                 = {
    ["softPlant"]         = true,
    ["mediumPlant"]       = true,
    ["softMeat"]          = true
  },
  ["Mushroom Crab"]       = {
    ["softPlant"]         = true,
    ["mediumPlant"]       = true,
    ["softMeat"]          = true
  },
  Molecrab                = {
    ["softPlant"]         = true,
    ["mediumPlant"]       = true,
    ["softMeat"]          = true,
    ["mediumMeat"]        = true
  },
  Netch                   = {
    ["softPlant"]         = true,
    ["mediumPlant"]       = true
  },
  ["Nix-Hound"]           = {
    ["softMeat"]          = true,
    ["mediumMeat"]        = true
  },
  Rat                     = {
    ["softPlant"]         = true,
    ["mediumPlant"]       = true,
    ["softMeat"]          = true,
    ["mediumMeat"]        = true
  },
  Scrib                   = {
    ["softPlant"]         = true
  },
  Slaughterfish           = {
    ["softMeat"]          = true,
    ["mediumMeat"]        = true,
    ["hardMeat"]          = true
  }
}

function o.process()
  for animal in pairs(o.food) do
    for food in pairs(o.food[animal]) do
      if o[food] then
        for i = 1, #o[food] do
          o.food[animal][o[food][i]] = true
        end

        o.food[animal][food] = nil
      end
    end
  end
end

function o.mcm()
  o.template = mwse.mcm.createTemplate{name = "Feed the Animals"}
  o.page = o.template:createPage{label  = "Feed the Animals Settings"}

  o.template:register()
  o.template:saveOnClose("Feed the Animals", o.conf)

  o.page:createKeyBinder{
    label             = "Keybind",
    allowCombinations = true,
    variable          = mwse.mcm.createTableVariable{
      id              = "key",
      table           = o.conf
    }
  }

  o.page:createYesNoButton{
    label    = "End Combat on Successful Feed",
    variable = mwse.mcm.createTableVariable{
      id     = "halt",
      table  = o.conf
    }
  }

  o.page:createYesNoButton{
    label    = "Allow Overfeeding (Where Feeding Has No Effect)",
    variable = mwse.mcm.createTableVariable{
      id     = "overfeed",
      table  = o.conf
    }
  }

  o.page:createYesNoButton{
    label    = "Show Notification Messages",
    variable = mwse.mcm.createTableVariable{
      id     = "message",
      table  = o.conf
    }
  }

  o.page:createYesNoButton{
    label    = "Debug Log",
    variable = mwse.mcm.createTableVariable{
      id     = "debug",
      table  = o.conf
    }
  }

  o.page:createSlider{
    label          = "Speechcraft amount gained for ending combat (tenth of value shown)",
    variable       = mwse.mcm.createTableVariable{
      id           = "gain",
      table        = o.conf
    },
    min            = 0,
    max            = 10,
    step           = 1
  }

  o.page:createSlider{
    label          = "Fraction of player's luck used in checks",
    variable       = mwse.mcm.createTableVariable{
      id           = "luck",
      table        = o.conf
    },
    min            = 2,
    max            = 10,
    step           = 1
  }

  o.page:createSlider{
    label          = "Fraction of player's personality used in checks",
    variable       = mwse.mcm.createTableVariable{
      id           = "personality",
      table        = o.conf
    },
    min            = 2,
    max            = 10,
    step           = 1
  }

  o.page:createSlider{
    label          = "Base success (out of 100) needed to end combat",
    variable       = mwse.mcm.createTableVariable{
      id           = "base",
      table        = o.conf
    },
    min            = 1,
    max            = 100,
    step           = 1
  }
end

function o.msg(msg)
  if o.conf.message then
    tes3.messageBox(msg)
  end
end

function o.debug(msg)
  if o.conf.debug then
    mwse.log("[Feed the Animals] Debug: " .. msg)
  end
end

function o.scan(e)
  if e.current and e.current.mobile then
    o.ref = e.current.mobile

    o.debug("Reference stored from scanning.")
  end
end

function o.pressed(c, e)
  if c.keyCode == e.keyCode and c.isShiftDown == e.isShiftDown and c.isAltDown == e.isAltDown and c.isControlDown == e.isControlDown then
    o.debug("Feeding key pressed.")

    return true
  end
end

function o.id(e)
  return e.item and e.item.id and e.item.id:lower() or "?"
end

function o.filter(e)
  return (e.item.objectType == tes3.objectType.ingredient) and (o.food[o.animal][o.id(e)] == true)
end

function o.handler(e)
  if not e or not e.item then
    o.debug("No data for handler, most likely menu closed.")

    return
  end

  tes3.player.object.inventory:removeItem{
    mobile   = tes3.mobilePlayer,
    item     = e.item,
    itemData = e.itemData
  }

  tes3ui.forcePlayerInventoryUpdate()

  o.message = "You fed the " .. o.animal:lower()

  o.debug("Food Chosen: " .. o.id(e))

  if o.conf.halt then
    o.debug("Call to stop combat occurred...")

    o.rand        = math.random(100)
    o.luck        = math.floor(tes3.mobilePlayer.luck.current        / o.conf.luck)
    o.personality = math.floor(tes3.mobilePlayer.personality.current / o.conf.personality)
    o.rand        = o.rand + o.luck + o.personality

    if o.ref.inCombat and o.rand > o.conf.base then
      o.debug("Combat stopped.")

      o.ref:stopCombat(true)

      if o.conf.gain > 0 then
        o.debug("Gained " .. o.conf.gain/10 .. " points for ending combat.")

        tes3.mobilePlayer:exerciseSkill(tes3.skill.speechcraft, o.conf.gain/10)
      end

      o.message = o.message .. ", they seem calm"
    end

    o.rand        = nil
    o.luck        = nil
    o.personality = nil
  end

  o.ref.fight = o.ref.fight - 10
  o.ref.flee  = o.ref.flee  - 10

  o.msg(o.message .. ".")
end

function o.feed(e)
  if not o.ref then
    o.debug("No entity.")

    return
  end

  if not o.pressed(o.conf.key, e) then
    return
  end

  if o.ref.object.objectType ~= tes3.objectType.creature then
    o.debug("Target isn't an animal.")

    return
  end

  if o.ref.health.current <= 0 then
    o.debug("Target is dead.")

    return
  end

  o.animal = o.meshes[o.ref.object.mesh:lower()]

  if not o.animal then
    o.debug("Name is nil.")

    return
  end

  if o.ref.fight <= 0 and o.ref.flee <= 0 and o.ref.inCombat == false then
    o.debug("There's no reason to feed the animal.")

    if o.conf.overfeed then
      o.debug("Overfeeding is permittted, so continuing...")

    else
      o.msg("The " .. (o.animal or "?"):lower() .. " looks calm, sedated, and uninterested in more food.")

      return
    end
  end

  o.debug("Showing feeding menu.")

  tes3ui.showInventorySelectMenu{
    title         = "Feed " .. o.animal,
    noResultsText = "You have no appropriate food.",
    filter        = o.filter,
    callback      = o.handler
  }
end

o.process()

event.register("modConfigReady",          o.mcm)
event.register("activationTargetChanged", o.scan)
event.register("keyDown",                 o.feed)