local defaultConfig = {
    aiChance = 10,
    alChance = 10,
    acChance = 10,
    bcChance = 10,
    bgChance = 10,
    fcChance = 10,
    glChance = 10,
    hfChance = 10,
    ipChance = 10,
    mmChance = 10,
    maChance = 10,
    rmChance = 10,
    sgChance = 10,
    wgChance = 10,
    testmode = false
  }

  local config = mwse.loadConfig ("NIR", defaultConfig)
  return config