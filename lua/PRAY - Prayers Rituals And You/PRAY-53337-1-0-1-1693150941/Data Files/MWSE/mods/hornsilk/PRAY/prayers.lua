local this = {}

-- use these pages to look up spell effects
-- https://mwse.github.io/MWSE/apis/tes3/?h=script#tes3applymagicsource
-- https://mwse.github.io/MWSE/references/magic-effects/
-- https://mwse.github.io/MWSE/references/attributes/
-- https://mwse.github.io/MWSE/references/skills/
-- https://mwse.github.io/MWSE/references/magic-effects-modded/

this.divinePrayers = {
    {
        name = "Prayer of Akatosh",
        id = "prayer_of_akatosh",
        handler = "Divine Prayers",
        skillReq = 10,
        skill = "divine_theology",
        description = "Pray to Akatosh to fortify Speed.",
        image = "Icons\\PRAY\\art\\akatosh.dds",
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 4, --speed
                duration = 720,
                min = 5,
                max = 5,
            }
        },
        text = "To AKATOSH\n\nwhose Perch from Eternity allowed the Day.",
    },
    {
        name = "Prayer of Arkay",
        id = "prayer_of_arkay",
        handler = "Divine Prayers",
        skillReq = 10,
        skill = "divine_theology",
        description = "Pray to Arkay to fortify Willpower.",
        image = "Icons\\PRAY\\art\\arkay.dds",
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 2, --willpower
                duration = 720,
                min = 5,
                max = 5,
            }
        },
        text = "To ARKAY\n\nwho braves the Diminuendo.",
    },
    {
        name = "Prayer of Dibella",
        id = "prayer_of_dibella",
        handler = "Divine Prayers",
        skillReq = 10,
        skill = "divine_theology",
        description = "Pray to Dibella to fortify Personality.",
        image = "Icons\\PRAY\\art\\dibella.dds",
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 6, --personality
                duration = 720,
                min = 5,
                max = 5,
            }
        },
        text = "To DIBELLA\n\nwho pays Passion in Pleasure.",
    },
    {
        name = "Prayer of Julianos",
        id = "prayer_of_julianos",
        handler = "Divine Prayers",
        skillReq = 10,
        skill = "divine_theology",
        description = "Pray to Julianos to fortify Intelligence.",
        image = "Icons\\PRAY\\art\\julianos.dds",
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 1, --intelligence
                duration = 720,
                min = 5,
                max = 5,
            }
        },
        text = "To JULIANOS\n\nwho incants the Damned Equation",
    },
    {
        name = "Prayer of Kynareth",
        id = "prayer_of_kynareth",
        handler = "Divine Prayers",
        skillReq = 10,
        skill = "divine_theology",
        description = "Pray to Kynareth to fortify Agility.",
        image = "Icons\\PRAY\\art\\kynareth.dds",
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 3, --agility
                duration = 720,
                min = 5,
                max = 5,
            }
        },
        text = "To KYNARETH\n\nwho returns the Masculine Breath.",
    },
    {
        name = "Prayer of Mara",
        id = "prayer_of_mara",
        handler = "Divine Prayers",
        skillReq = 10,
        skill = "divine_theology",
        description = "Pray to Mara to fortify Endurance.",
        image = "Icons\\PRAY\\art\\mara.dds",
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 5, --endurance
                duration = 720,
                min = 5,
                max = 5,
            }
        },
        text = "To MARA\n\nwho fills the Empty and tends the Home.",
    },
    {
        name = "Prayer of Stendarr",
        id = "prayer_of_stendarr",
        handler = "Divine Prayers",
        skillReq = 10,
        skill = "divine_theology",
        description = "Pray to Stendarr to fortify Strength.",
        image = "Icons\\PRAY\\art\\stendarr.dds",
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 0, --strenth
                duration = 720,
                min = 5,
                max = 5,
            }
        },
        text = "To STENDARR\n\nwho suffers Men to read.",
    },
    {
        name = "Prayer of Talos",
        id = "prayer_of_talos",
        handler = "Divine Prayers",
        skillReq = 10,
        skill = "divine_theology",
        description = "Pray to Talos to fortify Attack.",
        image = "Icons\\PRAY\\art\\talos.dds",
        spellEffects = {
            {
                id = 117, --fortifyAttack
                duration = 720,
                min = 5,
                max = 5,
            }
        },
        text = "Scion of Emperors, King of Earth and Sky,\nLord of Shining Hosts,\nProtector of Oathman, Feeman and Yeoman,\nGuarantor of Right and Justice,\nBroad Blessing of Thrones and Powers,\nCynosure of Celestial Glory,\nThe Most High Tiber Septim",
    },
    {
        name = "Prayer of Zenithar",
        id = "prayer_of_zenithar",
        handler = "Divine Prayers",
        skillReq = 10,
        skill = "divine_theology",
        description = "Pray to Zenithar to fortify Luck.",
        image = "Icons\\PRAY\\art\\zenithar.dds",
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 7, --luck
                duration = 720,
                min = 5,
                max = 5,
            }
        },
        text = "To ZENITHAR\n\nthe Provider of our Ease.",
    },
}

this.tribunalPrayers = {
    {
        name = "Restoration of Saint Meris",
        id = "restore_attributes",
        handler = "Tribunal Prayers",
        skillReq = 25,
        skill = "tribunal_theology",
        description = "Restore your attribues",
        image = "Icons\\PRAY\\art\\meris_resto.dds",
        spellEffects = {
            {
                id = 74, --restoreAttribute
                attribute = 0,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 74, --restoreAttribute
                attribute = 1,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 74, --restoreAttribute
                attribute = 2,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 74, --restoreAttribute
                attribute = 3,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 74, --restoreAttribute
                attribute = 4,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 74, --restoreAttribute
                attribute = 5,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 74, --restoreAttribute
                attribute = 6,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 74, --restoreAttribute
                attribute = 7,
                duration = 1,
                min = 100,
                max = 100,
            },
        },
        text = "Your house is safe now\nSo why is it--\nYour house is safe now\nSo why is it--\n\nThe ending of the words is ALMSIVI." -- https://en.uesp.net/wiki/Morrowind:The_36_Lessons_of_Vivec
    },
    {
        name = "Restoration of the Warrior",
        id = "restore_combat_skills", --except for athletics bc space
        handler = "Tribunal Prayers",
        skillReq = 25,
        skill = "tribunal_theology",
        description = "Restore the skills of the Warrior",
        image = "Icons\\PRAY\\art\\alma_resto.dds",
        spellEffects = {
            {
                id = 78, --restoreSkill
                skill = 3,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 2,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 7,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 1,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 6,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 4,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 5,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 0,
                duration = 1,
                min = 100,
                max = 100,
            },
        },
        text = "The Mother is active and clawed like a nix-hound, yet she is the holiest of those that reclaim their days.\n\nThe ending of the words is ALMSIVI." -- https://en.uesp.net/wiki/Morrowind:The_36_Lessons_of_Vivec
    },
    {
        name = "Restoration of the Thief",
        id = "restore_stealth_skills", --except for hand-to-hand bc only space for 8
        handler = "Tribunal Prayers",
        skillReq = 25,
        skill = "tribunal_theology",
        description = "Restore the skills of the Thief",
        image = "Icons\\PRAY\\art\\vivec_resto.dds",
        spellEffects = {
            {
                id = 78, --restoreSkill
                skill = 20,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 21,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 23,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 19,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 22,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 24,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 25,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 18,
                duration = 1,
                min = 100,
                max = 100,
            },
        },
        text = "The Son is myself, Vehk, and I am unto three, six, nine, and the rest that come after, glorious and sympathetic, without borders, utmost in the perfections of this world and the others, sword and symbol, pale like gold.\n\nThe ending of the words is ALMSIVI." -- https://en.uesp.net/wiki/Morrowind:The_36_Lessons_of_Vivec
    },
    {
        name = "Restoration of the Mage",
        id = "restore_magic_skills", --except for unarmored bc only 8
        handler = "Tribunal Prayers",
        skillReq = 25,
        skill = "tribunal_theology",
        description = "Restore the skills of the Mage",
        image = "Icons\\PRAY\\art\\sotha_resto.dds",
        spellEffects = {
            {
                id = 78, --restoreSkill
                skill = 12,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 16,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 13,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 9,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 11,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 10,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 14,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 15,
                duration = 1,
                min = 100,
                max = 100,
            },
        },
        text = "The Father is a machine and the mouth of a machine. His only mystery is an invitation to elaborate further.\n\nThe ending of the words is ALMSIVI." -- https://en.uesp.net/wiki/Morrowind:The_36_Lessons_of_Vivec
    },
    {
        name = "Restoration of the Wanderer",
        id = "restore_monk_skills", --unarmored, hand-to-hand, athletics
        handler = "Tribunal Prayers",
        skillReq = 25,
        skill = "tribunal_theology",
        description = "Restore the skills of the Wanderer, unarmed and unarmored, who walks the ashlands",
        image = "Icons\\PRAY\\art\\nerevar_resto.dds",
        spellEffects = {
            {
                id = 78, --restoreSkill
                skill = 8,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 17,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 26,
                duration = 1,
                min = 100,
                max = 100,
            },
        },
        text = "You can hear the words, so run away\nCome, Hortator, unfold into a clear unknown,\nStay quiet until you've slept in the yesterday,\nAnd say no elegies for the melting stone\n\nThe ending of the words is ALMSIVI." -- https://en.uesp.net/wiki/Morrowind:The_36_Lessons_of_Vivec,
    },
    {
        name = "Vivec Aspect",
        id = "vivec_aspect_prayer",
        handler = "Tribunal Prayers",
        skillReq = 30,
        skill = "tribunal_theology",
        description = "Assume the aspect of Vivec",
        image = "Icons\\PRAY\\art\\vivec_aspect.dds",
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 6, --personality
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 83, --fortifySkill
                skill = 7, --spear
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 5, --lightningShield
                duration = 720,
                min = 20,
                max = 30,
            },
            {
                id = 124, --boundSpear
                duration = 720,
            },
            {
                id = 68, --reflect
                duration = 720,
                min = 5,
                max = 5,
            },
        },
        text = "For I have crushed a world with my left hand,\nhe will say,\nbut in my right hand is how it could have won against me.\nLove is under my will only.\n\nThe ending of the words is ALMSIVI." -- https://en.uesp.net/wiki/Morrowind:The_36_Lessons_of_Vivec
    },
    {
        name = "Sotha Sil Aspect",
        id = "sotha_aspect_prayer",
        handler = "Tribunal Prayers",
        skillReq = 30,
        skill = "tribunal_theology",
        description = "Assume the aspect of Sotha Sil",
        image = "Icons\\PRAY\\art\\sotha_aspect.dds",
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 1, --intelligence
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 83, --fortifySkill
                skill = 14, --mysticism
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 6, --frostShield
                duration = 720,
                min = 20,
                max = 30,
            },
            {
                id = 127, --boundCuirass
                duration = 720,
            },
            {
                id = 67, --spellAbsorption
                duration = 720,
                min = 20,
                max = 20,
            },
        },
        text = "I am the Clockwork King of the Three in One.\nIn you is an egg of my brother-sister, who possesses invisible knowledge of words and swords,\nwhich you shall nurture until the Hortator comes.\n\nThe ending of the words is ALMSIVI." -- https://en.uesp.net/wiki/Morrowind:The_36_Lessons_of_Vivec
    },
    {
        name = "Almalexia Aspect",
        id = "alma_aspect_prayer",
        handler = "Tribunal Prayers",
        skillReq = 30,
        skill = "tribunal_theology",
        description = "Assume the aspect of Almalexia",
        image = "Icons\\PRAY\\art\\alma_aspect.dds",
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 4, --speed
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 83, --fortifySkill
                skill = 6, --axe
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 4, --fireShield
                duration = 720,
                min = 20,
                max = 30,
            },
            {
                id = 128, --boundHelm
                duration = 720,
            },
            {
                id = 117, --fortifyAttack
                duration = 720,
                min = 20,
                max = 20,
            },
        },
        text = "I am the Face-Snaked Queen of the Three in One.\nIn you is an image and a seven-syllable spell,\nAYEM AE SEHTI AE VEHK,\nwhich you will repeat to it until mystery comes.\n\nThe ending of the words is ALMSIVI." -- https://en.uesp.net/wiki/Morrowind:The_36_Lessons_of_Vivec
    },
}

this.ashlanderPrayers = {
    {
        name = "Acknowledge the Ancestors",
        id = "basic_ancestor_prayer",
        handler = "Ashlander Prayers",
        skillReq = 10,
        skill = "ashlander_theology",
        skillProgress = 30,
        description = "Acknowledge the memories of our ancestors.",
        image = "Icons\\PRAY\\art\\wise_woman.dds",
        knowledgeRequirement = function ()
            return tes3.player.data.hasReadAshlanderLit or tes3.getJournalIndex{ id = "A2_1_MeetSulMatuul" } >= 44
        end,
        spellEffects = {
            {
                id = 106, --summonAncestralGhost
                duration = 360,
            }
        },
        text = "I pray for the herder\nThat whistles to his guar at play."
    },
    {
        name = "Venerate the Ancestors",
        id = "ancestor_prayer",
        handler = "Ashlander Prayers",
        skillReq = 10,
        skill = "ashlander_theology",
        description = "Praise the memories of our ancestors.",
        image = "Icons\\PRAY\\art\\wise_woman.dds",
        spellEffects = {
            {
                id = 106, --summonAncestralGhost
                duration = 720,
            }
        },
        text = "I pray for the herder\nThat whistles to his guar at play.\n\nI pray for the hunter\nThat stalks the white walkers.\n\nI pray for the wise one\nThat seeks under the hill,\n\nAnd the wife who wishes\nFor one last touch of her dead child's hand."
    },
    {
        name = "Wanderer Under Moon-and-Star",
        id = "wanderer_prayer",
        handler = "Ashlander Prayers",
        skillReq = 12,
        skill = "ashlander_theology",
        description = "See in the darkness by the light of Moon-and-Star.",
        image = "Icons\\PRAY\\art\\ashland_scout.dds",
        spellEffects = {
            {
                id = 43, --nightEye
                duration = 720,
                min = 20,
                max = 40,
            }
        },
        text = "Never shall I yield my home and hearth.\n\nAnd from my tears shall spring forth\n\nThe flowers of grassland springs."
    },
    {
        name = "Stride 'Cross the Ash-Wastes",
        id = "feather_prayer",
        handler = "Ashlander Prayers",
        skillReq = 14,
        skill = "ashlander_theology",
        description = "Travel light and quietly.",
        image = "Icons\\PRAY\\art\\ashland_vista.dds",
        spellEffects = {
            {
                id = 8, --feather
                duration = 720,
                min = 10,
                max = 30,
            },
            {
                id = 83, --fortifySkill 
                skill = 19, --sneak
                duration = 720,
                min = 10,
                max = 30,
            }
        },
        text = "May I shrink to dust\n\nIn your cold, wild Wastes,\n\nAnd may my tongue speak\n\nIts last hymn to your winds."
    },
    {
        name = "Prayer of the Wise Woman",
        id = "wise_woman_prayer",
        handler = "Ashlander Prayers",
        skillReq = 16,
        skill = "ashlander_theology",
        description = "Step through fire and frost, hold fast your body from disease",
        image = "Icons\\PRAY\\art\\wise_woman_landscape.dds",
        spellEffects = {
            {
                id = 90, --resistFire
                duration = 720,
                min = 20,
                max = 50,
            },
            {
                id = 91, --resistFrost
                duration = 720,
                min = 20,
                max = 50,
            },
            {
                id = 94, --resistCommonDisease
                duration = 720,
                min = 20,
                max = 50,
            },
            {
                id = 95, --resistBlightDisease
                duration = 720,
                min = 20,
                max = 50,
            },
        },
        text = "I will not pray for that which I've lost\nWhen my heart springs forth\nFrom your soil, like a seed,\nAnd blossoms anew beneath tomorrow's sun."
    },
    {
        name = "Prayer of the Ashkhan",
        id = "ashkhan_prayer",
        handler = "Ashlander Prayers",
        skillReq = 18,
        skill = "ashlander_theology",
        description = "Gird yourself in mystic armors.",
        image = "Icons\\PRAY\\art\\red_mountain.dds",
        spellEffects = {
            {
                id = 3, --shield
                duration = 720,
                min = 10,
                max = 30,
            },
            {
                id = 48, --sound
                duration = 720,
                min = 10,
                max = 30,
            },
            {
                id = 59, --telekinesis 
                duration = 720,
                min = 5,
                max = 15,
            }
        },
        text = "Rise from darkness, Red Mountain!\nSpread your dark clouds and green vapors!\nBirth earthquakes, shatter stones!\nFeed the winds with fire!\nFlay the tents of the tribes from the land!\nFeed the burned earth with our souls!\n\nYet never shall you have your rule over me."
    },
}

this.sixthHousePrayers = {
    {
        name = "Form of the Dreamer",
        id = "sixthHouse_prayer_6",
        handler = "Sixth House Prayers",
        skillReq = 15,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned? Together we shall speak for the Law and the Land, and shall drive the mongrel dogs of the Empire from Morrowind.\nCome to me, through fire and war. I welcome you.\nWelcome, Moon-and-Star. I have prepared a place for you.",
        image = "Icons\\PRAY\\art\\dagoth6.dds",
        skillProgress = 200,
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 6, --personality
                duration = 720,
                min = 60,
                max = 66,
            },
            {
                id = 79, --fortifyAttribute
                attribute = 6, --strength
                duration = 720,
                min = 60,
                max = 66,
            },
            {
                id = 3, --shield
                duration = 720,
                min = 60,
                max = 66,
            },
            {
                id = 4, --fireShield
                duration = 720,
                min = 60,
                max = 66,
            },
            {
                id = 98, --resistNormalWeapons
                duration = 720,
                min = 60,
                max = 66,
            },
        },
        text = "He is the Lord, and Father of the Mountain.\nHe wakes, and the land wakes with him.\nAll the land, and all of its people, shall rise from sleep, and sweep the land clean of the n'wah.\nWhy have you denied him?\nAs Lord Dagoth has said. All shall greet him as flesh, or as dust.\nIt is the Hour of Wakening. He comes forth in his glory, and his people shall rejoice, and his enemies shall scatter like dust."
    }
}

this.miscPrayers = {
    {
        name = "The Gray Maybe",
        id = "luck_prayer",
        handler = "Miscellaneous Prayers",
        skillReq = 5,
        skill = "divine_theology",
        description = "See what luck the day will bring.",
        skillProgress = 0,
        prayerDuration = 5,
        image = "Icons\\PRAY\\art\\dice.dds",
        soundPath = "Fx\\magic\\mystC.wav",
        knowledgeRequirement = function()
            return true
        end,
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 7, --luck
                duration = 720,
                min = 0,
                max = 10,
            },
            {
                id = 17, --drainAttribute
                attribute = 7, --luck
                duration = 720,
                min = 0,
                max = 10,
            }
        },
        text = "Man or mer, things begin with the dualism of Anu and His Other.\nThese twin forces go by many names\n\nAnu-Padomay\nAnuiel-Sithis\nAk-El\nSatak-Akel\nIs-Is Not."
    },
}

return this
