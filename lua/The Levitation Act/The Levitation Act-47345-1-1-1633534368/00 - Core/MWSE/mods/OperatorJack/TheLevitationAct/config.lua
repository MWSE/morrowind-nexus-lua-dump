-- Load configuration.
return mwse.loadConfig("The-Levitation-Act") or {
    -- Initialize Settings
    bountyValue = 500,
    
    cellWhitelist = { 
        ["sadrith mora"] = true,
        ["tel aruhn"] = true,
        ["tel branora"] = true,
        ["tel fyr"] = true,
        ["tower of tel fyr"] = true,
        ["corprusarium"] = true,
        ["corprusarium bowels"] = true,
        ["tel mora"] = true,
        ["tel uvirith"] = true,
        ["tel vos"] = true,
        ["vos"] = true,
    }
}