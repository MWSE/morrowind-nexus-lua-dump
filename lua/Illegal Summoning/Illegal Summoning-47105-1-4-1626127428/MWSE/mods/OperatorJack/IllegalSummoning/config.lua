-- Load configuration.
return mwse.loadConfig("Illegal-Summoning") or {
    -- Initialize Settings
    bountyValue = 500,
    npcTriggerDistance = 3000,
    
    effectBlacklist = { 
        ["summon ash ghoul"] = true,
        ["summon ash zombie"] = true,
        ["summon ash slave"] = true,
        ["summon ascended sleeper"] = true
    },
    effectWhitelist = { 
        ["summon ancestral ghost"] = true
    },
    npcWhitelist = { 
        ["telvanni guard"] = true,
        ["telvanni sharpshooter"] = true,
        ["gothren"] = true,
        ["neloth"] = true,
        ["therana"] = true,
        ["dratha"] = true,
        ["aryon"] = true,
    }
}