local Generics = {
    -- Shared response pools
    ["Agreement"] = {
        { text = "Indeed.", id = "genAgreement01" },
        { text = "I agree.", id = "genAgreement02" },
        { text = "True enough.", id = "genAgreement03" },
        { text = "You are right.", id = "genAgreement04", animation = { template = "thumbsup" } },
        { text = "Exactly.", id = "genAgreement05" },
        { text = "I was thinking the same.", id = "genAgreement06" },
        { text = "Without a doubt.", id = "genAgreement07", animation = { template = "thumbsup" } },
        { text = "Certainly.", id = "genAgreement08" }
    },
    ["Disagreement"] = {
        { text = "I doubt that.", id = "genDisagreement01" },
        { text = "Unlikely.", id = "genDisagreement02" },
        { text = "I don't think so.", id = "genDisagreement03" },
        { text = "That can't be right.", id = "genDisagreement04" },
        { text = "I disagree.", id = "genDisagreement05" },
        { text = "That sounds wrong.", id = "genDisagreement06" },
        { text = "Impossible.", id = "genDisagreement07" },
        { text = "I'm not so sure.", id = "genDisagreement08" }
    },
    ["Interest"] = {
        { text = "Interesting.", id = "genInterest01" },
        { text = "Is that so?", id = "genInterest02" },
        { text = "News to me.", id = "genInterest03" },
        { text = "Go on.", id = "genInterest04" },
        { text = "I see.", id = "genInterest05" },
        { text = "Fascinating.", id = "genInterest06" },
        { text = "Do tell.", id = "genInterest07" },
        { text = "Really?", id = "genInterest08" }
    },
    ["Surprise"] = {
        { text = "By the gods!", id = "genSurprise01" },
        { text = "Really?", id = "genSurprise02" },
        { text = "Incredible!", id = "genSurprise03" },
        { text = "I can't believe it.", id = "genSurprise04" },
        { text = "Are you serious?", id = "genSurprise05" },
        { text = "Shocking.", id = "genSurprise06" },
        { text = "Who would have thought?", id = "genSurprise07" },
        { text = "Amazing.", id = "genSurprise08" }
    },
    ["FollowUp"] = {
        { text = "Tell me more.", id = "genFollowUp01" },
        { text = "What else?", id = "genFollowUp02" },
        { text = "And then?", id = "genFollowUp03" },
        { text = "Go on.", id = "genFollowUp04" },
        { text = "What happened next?", id = "genFollowUp05" },
        { text = "Continue.", id = "genFollowUp06" },
        { text = "I'm listening.", id = "genFollowUp07" },
        { text = "Then what?", id = "genFollowUp08" }
    },
    ["Thanks"] = {
        { text = "I appreciate that greatly.", id = "genThanks01" },
        { text = "Thank you.", id = "genThanks02" },
        { text = "My thanks.", id = "genThanks03" },
        { text = "You have my gratitude.", id = "genThanks04" },
        { text = "Much obliged.", id = "genThanks05" },
        { text = "That is kind of you.", id = "genThanks06" },
        { text = "Thanks.", id = "genThanks07" },
        { text = "I am in your debt.", id = "genThanks08" }
    },
    ["Neutral"] = {
        { text = "I see.", id = "genNeutral01" },
        { text = "Is that right?", id = "genNeutral02" },
        { text = "Hmm.", id = "genNeutral03" },
        { text = "Fair enough.", id = "genNeutral04" },
        { text = "I suppose so.", id = "genNeutral05" },
        { text = "If you say so.", id = "genNeutral06" },
        { text = "Okay.", id = "genNeutral07" },
        { text = "Noted.", id = "genNeutral08" }
    },
    ["Dismissive"] = {
        { text = "Hmph.", id = "genDismissive01" },
        { text = "I don't care.", id = "genDismissive02", animation = { template = "thumbsdown" } },
        { text = "Boring.", id = "genDismissive03" },
        { text = "So what?", id = "genDismissive04" },
        { text = "Whatever.", id = "genDismissive05" },
        { text = "Waste of my time.", id = "genDismissive06", animation = { template = "thumbsdown" } },
        { text = "Not my problem.", id = "genDismissive07" },
        { text = "Trivial.", id = "genDismissive08" }
    },
}

return Generics
