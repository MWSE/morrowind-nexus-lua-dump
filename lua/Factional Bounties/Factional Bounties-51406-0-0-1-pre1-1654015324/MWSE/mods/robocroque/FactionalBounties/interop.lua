if factionalBounties == nil then factionalBounties = {} end

if factionalBounties.lastChanceGreetings == nil then
    -- This is where the IDs of all the "last chance" greetings go. If your mod adds more specific variations,
    -- require this file and then append them to `factionalBounties.lastChancegreetings`.
    factionalBounties.lastChanceGreetings = {
        -- Default greeting if the player CANNOT pay
        "687645072337924986",
        -- Default greeting if the player CAN pay
        "238295404227316038"
    }
end

if factionalBounties.blacklistedGreetings == nil then
    -- This is where IDs of all the greetings go that we don't want to append anything to.
    -- If your mod adds any greetings we shouldn't attach to, append them here.
    factionalBounties.blacklistedGreetings = {
        -- Our own greeting if the player decided to pay
        "1171526785203271015",
        -- Our own greeting if the player refused to pay
        "17674131532800630427"     
    }
end