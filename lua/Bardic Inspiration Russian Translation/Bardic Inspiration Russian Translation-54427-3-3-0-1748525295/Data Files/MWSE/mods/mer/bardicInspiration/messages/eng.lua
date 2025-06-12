--[[
    Translations may be incomplete, however
    any subtables should be completed entirely. For
    example, if you translate the mcm values, you
    must translate everything in the mcm table
]]
---@class BardicInspiration.Messages
local messages = {

    --General

    modName = "Bardic Inspiration",

    --performances

    notTavern = "Find a tavern in order to perform.",
    notNightTime = "You may only perform between 6pm and 12am.",
    whatToPlay = "Which piece will you perform?",
    noGigScheduled = "You have not booked a performance here.",
    alreadyPlayed = "You have already performed in this tavern today.",
    donePerforming = "You earned %G gold worth of tips, well done! Speak to %s for your payment.",
    donePerformingNoTips = "You earned no tips, better luck next time! Speak to %s for your payment.",

    noSongsKnown = "You don't know any songs.",
    playingSong = "Playing \"%s\".",
    learnedSong = "You learned \"%s\"!",

    stopPlaying = "End your performance early?",

    ---Keep the [[ ]] and don't add indentation!
    songTooltip =
    [[Difficulty: %s
    Times Played: %s
    Taught by: %s]],--

    --song difficulty

    difficulty = "Difficulty",
    difficulty_beginner = "Beginner",
    difficulty_intermediate = "Intermediate",
    difficulty_advanced = "Advanced",

    --dialog


    dialog_teachChoice = "Yes, I may have something suitable for your skill level. This %s song is called \"%s\". Would you like me to teach it to you?",
    dialog_teachChoice_lesser = "I have no more %s songs to teach you, but I do do know a %s song called \"%s\". Would you like me to teach it to you?",
    dialog_teachChoice_advanced = "Your talents are impressive, %s. I have but one song befitting of your skills. It is called \"%s\". Shall I teach it to you?",
    dialog_NoSongsBardMale = "You should actually learn to play something before you embarrass yourself in front of my patrons. %s is a bard, perhaps he could teach you? I'm sure I saw him around here somewhere.",
    dialog_NoSongsBardFemale = "You should actually learn to play something before you embarrass yourself in front of my patrons. %s is a bard, perhaps she could teach you? I'm sure I saw her around here somewhere.",

    --journal updates

    journal_acceptedGig = "I have agreed to perform at %s. I should return after 6pm.",
    journal_completedGig = "I earned %s gold in tips for my performance. I should speak to %s at %s for payment.",
    journal_gotPaid = "I have been paid %s gold for my performance at %s.",

    --mcm

    mcm_page_settings = "Settings",
    mcm_page_description =
    [[Bardic Inspiration allows you to book performances at taverns and perform with a lute.

    Before you can perform, you need a lute, and some music to play. To learn a song, talk to an NPC with the "Bard" class and select the "teach me a song" topic. The NPC must have sufficiently high disposition towards you. If you're having trouble finding a bard, talk to an innkeeper and ask to perform, and they may point out a nearby bard to you.

    To give a performance, speak to an innkeeper before 6pm and select the "give a performance" topic. Once you have accepted the gig, come back after 6pm and ready your lute. You will then be able to select a song to perform.

    As you are performing, you will earn tips from nearby patrons. The amount you earn in tips depends on your Luck, Performance skill, and the difficulty of the song.

    Once you have finished performing, speak to the innkeeper again to get your payment (this is in addition to the tips you earned).

    Songs have 3 difficutly levels: beginner, intermediate and advanced. Bards will only teach you higher difficulty songs if your skill level is high enough. Bards have a limited number of songs they know, and some may know the same songs, so one character is unlikely to learn all ~40 of the songs available.
    ]],

    mcm_baseValue_label = "Base Reward Value",
    mcm_baseValue_description = "The base gold amount you receive when performing in taverns, before skill and disposition effects are taken into account. In other words, this is how much gold you'd get with 0 disposition and 0 Performance skill.",

    mcm_progressTavern_label = "Performance Progress Gain",
    mcm_progressTavern_description = "How much progress in the Performance skill you gain each time you perform in a tavern.",

    mcm_debug_label = "Log Level",
    mcm_debug_description = "Set the logging level for mwse.log. Keep on INFO unless you are debugging.",

    mcm_tavernspage_name = "Innkeepers",
    mcm_tavernspage_description = "In Bardic Inspiration, you can only perform for gold at places that have an Innkeeper. NPCs with the Publican class are automatically considered innkeepers, but you can manually add additional NPCs here to have them accept performances.",
    mcm_tavernspage_leftListLabel = "Innkeepers",
    mcm_tavernspage_rightListLabel = "NPCs",
    --skills

    skills_performance_name = "Performance",
    skills_performance_description = "Determines your ability to perform with musical instruments.",
    skills_warning_install = "Please install Skills Module",
    skills_warning_update = "Please update Skills Module",

    blockLoad = "You can not load a game right now.",

    tips = {
        "A patron loves your performance and gives you %G gold.",
        "A child gives you her %G drakes.",
        "You have received %G gold from a shy child.",
        "A traveler enjoys your music and puts %G gold into the hat.",
        "An old lady tells you to 'Keep it up, child!' and gives you %G septims.",
        "You find %G gold in your hat.",
        "You get %G gold from a peasent who loves your song.",
        "You haven been given %G drakes.",
        "A wealthy merchant has one of his servants bring you %G gold for your playing.",
        "You get %G gold from a mage-in-training.",
        "You get %G gold from a snobby rich kid who is barely amused by your tune.",
        "You get %G gold from a tavern keeper, he wants you to play in his tavern, but didn't say *which* tavern.",
        "You have been given %G gold.",
    },
    --Tip messages that list an NPC name. Bad tips don't have a tip amount
    badTips = {
        "%NPC frowns and says, \"I've heard better singing from guar.\"",
        "%NPC covers their ears, shaking their head, \"Please, no more!\"",
        "%NPC loudly comments, \"Who let a dying cliff racer into town?\"",
        "%NPC sighs deeply, \"And here I thought silence was golden!\"",
        "%NPC groans, \"I'd pay you to stop if I wasn't broke!\"",
        "%NPC winces, \"By Azura, did someone step on a scrib?\"",
        "%NPC mutters loudly, \"My ears may never recover!\"",
        "%NPC scoffs, \"I've heard drunk Nords sing better than that!\"",
        "%NPC rolls their eyes, \"Keep practicing... far away from here!\"",
        "%NPC grimaces, \"Your performance is a true test of patience!\"",
    },
    averageTips = {
        "%NPC tosses you %G drakes, \"Not bad, but I've heard better.\"",
        "%NPC gives you %G gold with a small nod of approval.",
        "%NPC shrugs, dropping %G gold into your hat, \"It passes the time, I suppose.\"",
        "%NPC smiles politely, handing you %G septims, \"Good effort.\"",
        "%NPC says, \"Decent tune,\" and leaves you %G drakes.",
        "%NPC quietly places %G gold at your feet, saying nothing more.",
        "%NPC gives you %G gold, \"Keep practicing, you'll get there.\"",
        "%NPC nods mildly, \"That wasn't terrible,\" and hands you %G gold.",
        "%NPC hands you %G septims, \"I've certainly heard worse.\"",
        "%NPC reluctantly parts with %G gold, \"At least you're trying.\"",
    },
    goodTips = {
        "%NPC applauds enthusiastically, \"Wonderful! Here's %G gold!\"",
        "%NPC beams happily, handing you %G drakes, \"You brightened my day!\"",
        "%NPC excitedly says, \"Marvelous performance!\" and gives you %G gold.",
        "%NPC warmly tells you, \"You have real talent!\" and tips you %G septims.",
        "%NPC grins, clearly moved, giving you %G gold, \"Best performance I've seen!\"",
        "%NPC eagerly hands you %G gold, \"Play it again sometime!\"",
        "%NPC places %G drakes in your hat, \"Music to my ears!\"",
        "%NPC cheers, \"Outstanding!\" and rewards you with %G gold.",
        "%NPC nods approvingly, \"You've earned every drake,' and gives you %G septims.",
        "%NPC joyfully hands you %G gold, \"You've lifted my spirits!\"",
    },
    noNPCNearby = "You don't see any patrons nearby to tip you.",
}

return messages