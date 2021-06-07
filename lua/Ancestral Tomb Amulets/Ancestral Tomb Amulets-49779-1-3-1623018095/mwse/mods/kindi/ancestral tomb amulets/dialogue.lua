--[[you can add more dialogue response here for little secret topic]]
--[[ACTOR is the actor that will be carrying the amulet]]
--[[use male pronouns, this mod will automatically convert pronouns based on ACTOR gender]]
local dialogue = {}
dialogue.secret = {
    "ACTOR in town is bragging about having an amulet with a unique teleporting magic. I don't think it's true at all.",
    "Maybe it's just me, but ACTOR is looking vain all of a sudden. It must be that amulet he's wearing all the time. Looks pretty and magical. So what?",
    "Psst... Have you seen ACTOR? I feel like there's something valuable in his possession, always seemed to be looking shady as well."
}

dialogue.replaceSecret = {
    "If someone attacks you first, you have the right to defend yourself. If someone DOESN'T attack you first, you're going to break the @law# if you attack him.",
    "Buy from merchants and @trader#s who like you. You get better prices. Members of your own @factions# usually like you best.",
    "@Talk# to everyone. @Talk# is cheap. Ask @questions#. You don't ask, you never learn."
}

return dialogue
