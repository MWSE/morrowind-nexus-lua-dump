local response = {}

response["mudcrab"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    -- update script variables
    script.luapass = 300
    -- return the message list
    return {
        "Gwen: Mudcrabs are so sneaky. You can hardly see them.",
        "Gwen: Evil little sods these.",
        "Gwen: Careful. These buggers will have your toes.",
        "Gwen: Oh look. Lunch is attacking us.",
    }
end

response["kwama forager"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    -- update script variables
    script.luapass = 400
    -- return the message list
    return {
        "Gwen: Giant dead maggot. That's what that looks like.",
        "Why are these Kwama so nasty and when they grow up they're so docile?",
        "I'm not quite sure which I think are the ugliest. These things or rats.",
    }
end

return response
