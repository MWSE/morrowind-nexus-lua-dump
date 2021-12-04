return {
    ["english"] = {
        -- guards might say this every so often to players who are sneaking
        -- %s is replaced with race or class
        ["sneaking"] = {
            "Why are you sneaking around like a s'wit?",
            "What are you up to, %s...?",
            "What are you up to...?",
            "I'm watching you, %s...",
            "I'm watching you...",
            "I've got my eye on you, %s...",
            "I've got my eye on you..."
        },
        -- guards say this when players stop sneaking while being followed
        -- %s is replaced with race or class
        ["stop_sneaking"] = {
            "That's what I thought.",
            "That's better, %s.",
        },
        -- guards say this when they're satisfied that the player is not doing anything illegal
        -- %s is replaced with race or class
        ["stop_following"] = {
            "I don't have time for this...",
            "Sneaking around for no reason, are we...?",
            "Sneaking around for no reason, are we...? Alright then, %s.",
        },
        -- guards say this when coming to player's rescue when they're attacked unprovoked
        -- %s is replaced with the name of the npc or creature attacking the player
        ["join_combat"] = {
            "Not today %s!",
            "You n'wah!",
            "Stop right there, criminal scum!"
        }
    }
}
