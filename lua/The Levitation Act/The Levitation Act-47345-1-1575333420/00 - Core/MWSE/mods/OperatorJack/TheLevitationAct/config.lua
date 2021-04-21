-- Load configuration.
return mwse.loadConfig("The-Levitation-Act") or {
    -- Initialize Settings
    bountyValue = 500,
    
    cellWhitelist = { 
        ["sadrith mora"] = true,
        ["tel aruhn"] = true,
        ["tel branora"] = true,
        ["tel fyr"] = true,
        ["tel mora"] = true,
        ["tel uvirith"] = true,
        ["tel vos"] = true,
    }
}