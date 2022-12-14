local stuff = {}

--Flavor Messages------------------------------------------------------------------------------------------------------

stuff.cdFlavor = {
    [1] = "You feel that you're ready to train again.",
    [2] = "Perhaps you should train again soon.",
    [3] = "When did you train last?",
    [4] = "It may be about time for some more training.",
    [5] = "You think on improving your skills a bit more.",
    [6] = "It's been a while since you've trained...",
    [7] = "Best not to let yourself slip...you'd better train.",
    [8] = "You feel fairly energetic...and realize it's due to lack of recent training.",
    [9] = "Need to make some time for training.",
    [10] = "You've recovered from the last session a while ago. Time to train perhaps?",
    [11] = "Perhaps some more training is in order.",
    [12] = "You feel like you should exercise your skills again.",
    [13] = "Another training session?",
    [14] = "Time to decide on when to train again.",
    [15] = "It would be wise to train today.",
    [16] = "Is it that time again?",
    [17] = "Trying your hand at some practice doesn't sound too bad.",
    [18] = "Training might help prepare you for the day...",
    [19] = "More practice is needed.",
    [20] = "You've had many hours to reflect. It's time for the next lesson.",
    [21] = "You could make use of some more practice.",
    [22] = "Training time.",
    [23] = "You're ready to make time for some training.",
    [24] = "You feel compelled to practice again today.",
    [25] = "Enough time has passed. You can train now.",
    [26] = "You figure that you'll have time to study a skill soon.",
    [27] = "It might be worthwhile to train later.",
    [28] = "You feel like training again.",
    [29] = "Something inside you tells you that you're ready for more practice.",
    [30] = "You've had some time to think on what you've learned last time. You decide you're ready for more.",
    [31] = "A few insights were gained since you last trained. Why not learn to apply them now?",
    [32] = "The path to mastery lies ahead. All you need do is continue your training.",
    [33] = "Now may be a good time to go through some exercises.",
    [34] = "You wonder if you should go over what you've learned once again."
}

stuff.scribFlavor = {
    [1] = "Ah. A scrib. Anyway...",
    [2] = "It was just a scrib. Might as well continue where you left off...",
    [3] = "Oh, a scrib. Hopefully it doesn't get in your way.",
    [4] = "Another scrib. At least it's not something dangerous.",
    [5] = "Ah, so that was what that thumping sound was.",
    [6] = "Nothing to worry about. Better continue the session.",
    [7] = "Perhaps it wants to watch?",
    [8] = "Thankfully something tame this time.",
    [9] = "The most welcome interruption you could have asked for.",
    [10] = "Great, a scrib. No need to stop now.",
    [11] = "Why stop now?",
    [12] = "Okay. Continuing on...",
    [13] = "..."
}

stuff.sounds = {
    [0] = "Heavy Armor Hit",
    [1] = "repair fail",
    [2] = "Medium Armor Hit",
    [3] = "Item Armor Heavy Up",
    [4] = "Item Weapon Blunt Down",
    [5] = "Item Weapon Longblade Down",
    [6] = "Item Weapon Blunt Down",
    [7] = "Item Weapon Spear Down",
    [8] = "FootBareRight",
    [9] = "enchant fail",
    [10] = "destruction cast",
    [11] = "alteration cast",
    [12] = "illusion cast",
    [13] = "conjuration cast",
    [14] = "mysticism cast",
    [15] = "restoration cast",
    [16] = "potion fail",
    [17] = "miss",
    [18] = "LockedChest",
    [19] = "corpDRAG",
    [20] = "LeftS",
    [21] = "Light Armor Hit",
    [22] = "Item Weapon Shortblade Down",
    [23] = "Item Weapon Bow Down",
    [24] = "scroll",
    [25] = "",
    [26] = "Hand To Hand Hit"
}

----Specialization Skills----------------------------------------------------

----Acrobatics, Light Armor, Marksman, Sneak, Hand to Hand, Short Blade, Mercantile, Speechcraft, Security
stuff.stealthSkillTable = {
    [1] = 20,
    [2] = 21,
    [3] = 23,
    [4] = 19,
    [5] = 26,
    [6] = 22,
    [7] = 24,
    [8] = 25,
    [9] = 18
}

----Unarmored, Illusion, Alchemy, Conjuration, Enchant, Alteration, Destruction, Mysticism, Restoration
stuff.magicSkillTable = {
    [1] = 17,
    [2] = 12,
    [3] = 16,
    [4] = 13,
    [5] = 9,
    [6] = 11,
    [7] = 10,
    [8] = 14,
    [9] = 15
}

----Heavy Armor, Medium Armor, Spear, Armorer, Axe, Blunt Weapon, Long Blade, Block, Athletics
stuff.combatSkillTable = {
    [1] = 3,
    [2] = 2,
    [3] = 7,
    [4] = 1,
    [5] = 6,
    [6] = 4,
    [7] = 5,
    [8] = 0,
    [9] = 8
}

return stuff
