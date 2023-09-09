local this = {}

local skillModule = require("OtherSkills.skillModule")


-- use these pages to look up spell effects
-- https://mwse.github.io/MWSE/apis/tes3/?h=script#tes3applymagicsource
-- https://mwse.github.io/MWSE/references/magic-effects/
-- https://mwse.github.io/MWSE/references/attributes/
-- https://mwse.github.io/MWSE/references/skills/
-- https://mwse.github.io/MWSE/references/magic-effects-modded/

this.divineRituals = {
    {
        name = "Wings of Akatosh",
        id = "ritual_of_akatosh",
        handler = "Divine Rituals",
        skillReq = 20,
        skill = "divine_theology",
        description = "Venerate Akatosh for a blessing of flight.",
        prayerDuration = 30,
        image = "Icons\\PRAY\\art\\akatosh_gold.dds",
        materials = {
            { material = "candle", count = 5 },
        },
        spellEffects = {
            {
                id = 10, --levitate
                duration = 720,
                min = 10,
                max = 30,
            },
            {
                id = 83, --fortifySkill
                skill = 14, --mysticism,
                duration = 720,
                min = 10,
                max = 20,
            },
            {
                id = 79, --fortifyAttribute
                attribute = 4, --speed
                duration = 720,
                min = 10,
                max = 20,
            },
        },
        text = "We have suffered, and are diminished, for all time, but the mortal world we have made is glorious, filling our hearts and spirits with hope. Let us teach the Mortal Races to live well, to cherish beauty and honor, and to love one another as we love them.", --https://en.uesp.net/wiki/Morrowind:The_Monomyth
    },
    {
        name = "Rite of Arkay",
        id = "ritual_of_arkay",
        handler = "Divine Rituals",
        skillReq = 20,
        skill = "divine_theology",
        description = "Sanctify your body with an offering to Arkay",
        prayerDuration = 30,
        image = "Icons\\PRAY\\art\\arkay_gold.dds",
        materials = {
            { material = "pray_empty_soulgem", count = 3 },
            { material = "candle", count = 3 },
        },
        spellEffects = {
            {
                id = 42, --sanctuary
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 83, --fortifySkill
                skill = 17, --unarmored,
                duration = 720,
                min = 10,
                max = 20,
            },
            {
                id = 79, --fortifyAttribute
                attribute = 2, --willpower
                duration = 720,
                min = 10,
                max = 20,
            },
        },
        text = "Blessed are the Bonemen, for they serve without self in spirit forever.\nBlessed are the Mistmen, for they blend in the glory of the transcendent spirit.\nBlessed are the Wrathmen, for they render their rage unto the ages.\nBlessed are the Masters, for they bridge the past and span the future.", --https://en.uesp.net/wiki/Morrowind:Book_of_Life_and_Service
    },
    {
        name = "Brilliant Gem of Dibella",
        id = "ritual_of_dibella",
        handler = "Divine Rituals",
        skillReq = 20,
        skill = "divine_theology",
        description = "Adorn yourself in the dazzling glamour of Dibella",
        prayerDuration = 30,
        image = "Icons\\PRAY\\art\\dibella_gold.dds",
        materials = {
            { material = "gem", count = 1 },
        },
        spellEffects = {
            {
                id = 68, --reflect
                duration = 720,
                min = 1,
                max = 10,
            },
            {
                id = 83, --fortifySkill
                skill = 13, --conjuration,
                duration = 720,
                min = 10,
                max = 20,
            },
            {
                id = 79, --fortifyAttribute
                attribute = 6, --personality
                duration = 720,
                min = 10,
                max = 20,
            },
        },
        text = "Ah, but the Passion Dancer bids us remember that quality of love is of the essence, not quantity. If the dance transports us, what matter the number of dancers?", --https://en.uesp.net/wiki/Lore:Augustine_Viliane_Answers_Your_Questions
    },
    {
        name = "Secrets of Julianos",
        id = "ritual_of_julianos",
        handler = "Divine Rituals",
        skillReq = 20,
        skill = "divine_theology",
        description = "Offer a skull for the ",
        prayerDuration = 30,
        image = "Icons\\PRAY\\art\\julianos_gold.dds",
        materials = {
            { material = "skull", count = 1 },
            { material = "candle", count = 3 },
        },
        spellEffects = {
            {
                id = 39, --invisibility
                duration = 720,
            },
            {
                id = 83, --fortifySkill
                skill = 9, --enchant,
                duration = 720,
                min = 10,
                max = 20,
            },
            {
                id = 79, --fortifyAttribute
                attribute = 1, --intelligence
                duration = 720,
                min = 10,
                max = 20,
            },
        },
        text = "A simple spell cast once, no matter how skillfully and no matter how spectacularly, is ephemeral, of the present, what it is and no more", --https://en.uesp.net/wiki/Morrowind:Palla
    },
    {
        name = "Feather of Kynareth",
        id = "ritual_of_kynareth",
        handler = "Divine Rituals",
        skillReq = 20,
        skill = "divine_theology",
        description = "Offer a feather to soar upon the winds",
        prayerDuration = 30,
        image = "Icons\\PRAY\\art\\kynareth_gold.dds",
        materials = {
            { material = "pray_feather", count = 1 },
            { material = "candle", count = 3 },
        },
        spellEffects = {
            {
                id = 9, --jump
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 83, --fortifySkill
                skill = 8, --athletics,
                duration = 720,
                min = 10,
                max = 20,
            },
            {
                id = 79, --fortifyAttribute
                attribute = 3, --agility
                duration = 720,
                min = 10,
                max = 20,
            },
        },
        text = "Kynareth\nto you we give the sky\nfor what can fly higher than the wind?", --https://en.uesp.net/wiki/Lore:Words_of_Clan_Mother_Ahnissi
    },
    {
        name = "Mara's Blessed Cup",
        id = "ritual_of_mara",
        handler = "Divine Rituals",
        skillReq = 20,
        skill = "divine_theology",
        description = "Fill a cup with the healing waters of Mara",
        prayerDuration = 30,
        image = "Icons\\PRAY\\art\\mara_gold.dds",
        materials = {
            { material = "cup", count = 1 },
            { material = "restore_health_ingred", count = 5 },
        },
        spellEffects = {
            {
                id = 80, --fortifyHealth
                duration = 720,
                min = 10,
                max = 50,
            },
            {
                id = 83, --fortifySkill
                skill = 15, --restoration,
                duration = 720,
                min = 10,
                max = 20,
            },
            {
                id = 79, --fortifyAttribute
                attribute = 5, --endurance
                duration = 720,
                min = 10,
                max = 20,
            },
        },
        text = "The Goddess Mara recognized their true love and wept at their loss. Not having power over death, she could do nothing to save Shandar, but she knew that she could not let their love die. She reached down from the heavens and picked up Mara and Shandar in her arms, and placed them high in the heavens.", --https://en.uesp.net/wiki/Lore:Mara%27s_Tear
    },
    {
        name = "Mercy of Stendarr",
        id = "ritual_of_stendarr",
        handler = "Divine Rituals",
        skillReq = 20,
        skill = "divine_theology",
        description = "Transform a mace into the steadfast fist of Stendarr",
        prayerDuration = 30,
        image = "Icons\\PRAY\\art\\stendarr_gold.dds",
        materials = {
            { material = "pray_mace", count = 1 },
            { material = "candle", count = 1 },
        },
        spellEffects = {
            {
                id = 122, --boundMace
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 83, --fortifySkill
                skill = 4, --bluntWeapon,
                duration = 720,
                min = 10,
                max = 20,
            },
            {
                id = 79, --fortifyAttribute
                attribute = 0, --strenth
                duration = 720,
                min = 10,
                max = 20,
            },
        },
        text = "The castle would hold. No matter the forces, the walls of Cascabel Hall would never fail, but that was small consolation.",--https://en.uesp.net/wiki/Morrowind:The_Rear_Guard
    },
    {
        name = "Sword-Meeting of Talos",
        id = "ritual_of_talos",
        handler = "Divine Rituals",
        skillReq = 20,
        skill = "divine_theology",
        description = "Offer a sword to Talos for a combat blessing.",
        prayerDuration = 30,
        image = "Icons\\PRAY\\art\\talos_gold.dds",
        materials = {
            { material = "pray_longsword", count = 1 },
            { material = "candle", count = 1 },
        },
        spellEffects = {
            {
                id = 41, --light
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 83, --fortifySkill
                skill = 5, --longBlade,
                duration = 720,
                min = 10,
                max = 20,
            },
            {
                id = 117, --fortifyAttack
                duration = 720,
                min = 10,
                max = 20,
            }
        },
        text = "For thirty-eight years, the Emperor Tiber reigned supreme. It was a lawful, pious, and glorious age, when justice was known to one and all, from serf to sovereign. On Tiber's death, it rained for an entire fortnight as if the land of Tamriel itself was weeping.", --https://en.uesp.net/wiki/Lore:Brief_History_of_the_Empire_v_1
    },
    {
        name = "Investment of Zenithar",
        id = "ritual_of_zenithar",
        handler = "Divine Rituals",
        skillReq = 20,
        skill = "divine_theology",
        description = "Honor Zenithar with the fruits of your labor, and your hands and tongue will be blessed",
        prayerDuration = 30,
        image = "Icons\\PRAY\\art\\zenithar_gold.dds",
        materials = {
            { material = "pray_gold", count = 100 },
        },
        spellEffects = {
            {
                id = 59, --telekinesis
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 83, --fortifySkill
                skill = 25, --speechcraft,
                duration = 720,
                min = 10,
                max = 20,
            },
            {
                id = 79, --fortifyAttribute
                attribute = 7, --luck
                duration = 720,
                min = 10,
                max = 20,
            },
        },
        text = "Each of the Nine represents different aspects of life, and how it should be lived. But the simplest statement of our doctrines is -- help and protect one another. The stronger one is, the wealthier one is, the more one bears responsibility for helping and protecting others.", --https://en.uesp.net/wiki/Lore:For_my_Gods_and_Emperor
    },
}

this.tribunalRituals = {
    {
        name = "Prostration Towards Vivec",
        id = "vivec_donation_ritual",
        handler = "Tribunal Rituals",
        skillReq = 10,
        skill = "tribunal_theology",
        description = "Pray to the Child of Verse and Memory",
        image = "Icons\\PRAY\\V.dds",
        materials = { { material = "pray_gold", count = 50 } },
        spellEffects = {
            {
                id = 82, --fortifyFatigue
                duration = 720,
                min = 5,
                max = 10,
            },
        },
        text = "Learn by serving.\nBlessed Almsivi, Mercy, Mastery, Mystery."--https://en.uesp.net/wiki/Morrowind:The_Book_of_Dawn_and_Dusk
    },
    {
        name = "Prostration Towards Almalexia",
        id = "alma_donation_ritual",
        handler = "Tribunal Rituals",
        skillReq = 10,
        skill = "tribunal_theology",
        description = "Pray to Mother Morrowind",
        image = "Icons\\PRAY\\A.dds",
        materials = { { material = "pray_gold", count = 50 } },
        spellEffects = {
            {
                id = 80, --fortifyHealth
                duration = 720,
                min = 5,
                max = 10,
            },
        },
        text = "From the heart, the light; from the head, the law.\nBlessed Almsivi, Mercy, Mastery, Mystery."--https://en.uesp.net/wiki/Morrowind:The_Book_of_Dawn_and_Dusk
    },
    {
        name = "Prostration Towards Sotha Sil",
        id = "sotha_donation_ritual",
        handler = "Tribunal Rituals",
        skillReq = 10,
        skill = "tribunal_theology",
        description = "Pray to the Father of Mysteries",
        image = "Icons\\PRAY\\S.dds",
        materials = { { material = "pray_gold", count = 50 } },
        spellEffects = {
            {
                id = 81, --fortifyMagicka
                duration = 720,
                min = 5,
                max = 10,
            },
        },
        text = "Refuse neither brother nor ghost.\nBlessed Almsivi, Mercy, Mastery, Mystery." --https://en.uesp.net/wiki/Morrowind:The_Book_of_Dawn_and_Dusk
    },
    {
        name = "Rite of Saint Aralor's Intervention",
        id = "aralor_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Aralor",
        image = "Icons\\PRAY\\art\\aralor.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 6, --personality
                duration = 720,
                min = 5,
                max = 5,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn self-respect and respect for others, follow Saint Aralor the Penitent, Patron of Tanners and Miners. This foul criminal repented his sins and traveled a circuit of the great pilgrimages on his knees."
    },
    {
        name = "Rite of Saint Delyn's Shield",
        id = "delyn_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Delyn",
        image = "Icons\\PRAY\\art\\delyn.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 95, --resistBlightDisease
                duration = 720,
                min = 10,
                max = 10,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn benevolence, follow Saint Delyn the Wise, Patron of Potters and Glassmakers. Saint Delyn was head of House Indoril, a skilled lawyer, and author of many learned treatises on Tribunal law and custom."
    },
    {
        name = "Rite of Saint Felms's Glory",
        id = "felms_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Felms",
        image = "Icons\\PRAY\\art\\felms.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 83, --fortifySkill 
                skill = 15, --restoration
                duration = 720,
                min = 5,
                max = 5,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn fierce justice, follow Saint Felms the Bold, Patron of Butchers and Fishmongers. This brave warlord slew the Nord invaders and drove them from our lands. He could neither read nor write, receiving inspiration directly from the lips of Almsivi."
    },
    {
        name = "Rite of Saint Llothis's Rock",
        id = "llothis_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Llothis",
        image = "Icons\\PRAY\\art\\llothis.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 2, --willpower
                duration = 720,
                min = 5,
                max = 5,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn reverence, follow Saint Llothis the Pious, Patron of Tailors and Dyers. Contemporary and companion of the Tribunal, and the best-loved Alma Rula of the Tribunal Temple, he formulated the central rituals and principles of the New Temple Faith. Saint Llothis is the symbolic mortal bridge between the gods and the faithful, and the archetypal priest."
    },
    {
        name = "Rite of Saint Meris's Warding",
        id = "meris_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Meris",
        image = "Icons\\PRAY\\art\\meris.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 96, --resistCorprusDisease
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn the love of peace, follow Saint Meris the Peacemaker, Patron of Farmers and Laborers. As a little girl, Saint Meris showed healing gifts, and trained as a Healer. She ended a long and bloody House War, intervening on the battlefield in her white robe to heal warriors and spellcrafters without regard to faction."
    },
    {
        name = "Rite of Saint Nerevar's Spirit",
        id = "nerevar_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Nerevar",
        image = "Icons\\PRAY\\art\\nerevar.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 82, --fortifyFatigue
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn valor, follow St. Nerevar the Captain, patron of Warriors and Statesmen. Lord Nerevar helped to unite the barbarian Dunmer tribes into a great nation, culminating in his martyrdom when leading the Dunmer to victory against the evil Dwemer and the traitorous House Dagoth in the Battle of Red Mountain."
    },
    {
        name = "Rite of Saint Olms's Benediction",
        id = "olms_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Olms",
        image = "Icons\\PRAY\\art\\olms.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 94, --resistCommonDisease
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn the rule of law and justice, follow Saint Olms the Just, Patron of Chandlers and Clerks. Founder of the Ordinators, Saint Olms conceived and articulated the fundamental principles of testing, ordeal, and repentance."
    },
    {
        name = "Rite of Saint Rilms's Grace",
        id = "rilm_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Rilms",
        image = "Icons\\PRAY\\art\\rilms.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 5, --endurance
                duration = 720,
                min = 5,
                max = 5,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn generosity, follow Saint Rilms the Barefooted, Patron of Pilgrims and Beggars. Saint Rilms gave away her shoes, then dressed and appeared as a beggar to better acquaint herself with the poor."
    },
    {
        name = "Rite of Saint Roris's Bloom",
        id = "roris_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Roris",
        image = "Icons\\PRAY\\art\\roris.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 80, --fortifyHealth
                duration = 720,
                min = 5,
                max = 5,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn pride of race and tribe, follow Saint Roris the Martyr, Patron of Furnishers and Caravaners. Captured by Argonians just before the Arnesian War, Roris proudly refused to renounce the Tribunal faith, and withstood the cruel tortures of Argonian sorcerers. Vengeance and justice for the martyred Saint Roris was the rallying cry of the Arnesian War."
    },
    {
        name = "Rite of Saint Seryn's Shield",
        id = "seryn_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Seryn",
        image = "Icons\\PRAY\\art\\seryn.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 97, --resistPoison
                duration = 720,
                min = 20,
                max = 20,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn mercy and its fruits, follow Saint Seryn the Merciful, Patron of Brewers, Bakers, Distillers. This pure virgin of modest aspect could heal all diseases at the price of taking the disease upon herself. Tough-minded and fearless, she took on the burdens of others, and bore those burdens to an honored old age."
    },
    {
        name = "Rite of Saint Veloth's Indwelling",
        id = "veloth_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Veloth",
        image = "Icons\\PRAY\\art\\veloth.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 81, --fortifyMagicka
                duration = 720,
                min = 10,
                max = 10,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn daring, follow Saint Veloth the Pilgrim, Patron of Outcasts and Spiritual Seekers. Saint Veloth, prophet and mystic, led the Dunmer out of the decadent home country of the Summerset Isles and into the promised land of Morrowind. Saint Veloth also taught the difference between the Good and Bad Daedra, and won the aid of the Good Daedra for his people while teaching how to carefully negotiate with the Bad Daedra."
    },
}

this.ashlanderRituals = {
    {
        name = "Invocation of Alandro Sul",
        id = "alandro_sul",
        handler = "Ashlander Rituals",
        skillReq = 20,
        skill = "ashlander_theology",
        description = "Commune with the whispers of Alandro Sul's spirit.",
        prayerDuration = 30,
        image = "Icons\\PRAY\\art\\alandro_sul.dds",
        materials = {
            { material = "pray_ashlander_cuirass", count = 1},
            { material = "ashlander_lit", count = 1},
            { material = "candle", count = 5 },
        },
        spellEffects = {
            {
                id = 47, --blind
                duration = 720,
                min = 100,
                max = 100,
            },
            {
                id = 42, --sanctuary
                duration = 720,
                min = 100,
                max = 100,
            },
            {
                id = 64, --detectAnimal
                duration = 720,
                min = 100,
                max = 100,
            },
            {
                id = 65, --detectEnchantment
                duration = 720,
                min = 100,
                max = 100,
            },
            {
                id = 66, --detectKey
                duration = 720,
                min = 100,
                max = 100,
            },
            -- {
            --     id = 336, --detectDaedra (Enhanced Detection)
            --     duration = 720,
            --     min = 100,
            --     max = 100,
            -- },
            -- {
            --     id = 338, --detectHumanoid (Enhanced Detection)
            --     duration = 720,
            --     min = 100,
            --     max = 100,
            -- },
            -- {
            --     id = 340, --detectUndead (Enhanced Detection)
            --     duration = 720,
            --     min = 100,
            --     max = 100,
            -- },
        },
        text = "When earth is sundered, and skies choked black\nAnd sleepers serve the seven curses\nTo the hearth there comes a stranger,\nJourneyed far 'neath moon and star",
    }
}

this.sixthHouseRituals = {
    {
        name = "First Word of the Dreamer",
        id = "sixthHouse_ritual_1",
        handler = "Sixth House Rituals",
        skillReq = 10,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned?",
        image = "Icons\\PRAY\\art\\dagoth1.dds",
        skillProgress = 200,
        materials = {
            { material = "ash_statue", count = 1 }
        },
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A2_2_6thHouse" } > 41 and skillModule.getSkill('sixthHouse').value < 11
        end,
        spellEffects = {
            {
                id = 17, --drainAttribute
                attribute = 6, --personality
                duration = 720,
                min = 10,
                max = 10,
            },
        },
        text = "He is the Lord, and Father of the Mountain."
    },
    {
        name = "Second Word of the Dreamer",
        id = "sixthHouse_ritual_2",
        handler = "Sixth House Rituals",
        skillReq = 11,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned?",
        image = "Icons\\PRAY\\art\\dagoth2.dds",
        skillProgress = 200,
        materials = {
            { material = "ash_statue", count = 1 },
            { material = "corprusmeat", count = 3 },
        },
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A2_2_6thHouse" } > 41 and skillModule.getSkill('sixthHouse').value < 12
        end,
        spellEffects = {
            {
                id = 17, --drainAttribute
                attribute = 6, --personality
                duration = 720,
                min = 20,
                max = 20,
            },
        },
        text = "He is the Lord, and Father of the Mountain.\nHe wakes, and the land wakes with him."
    },
    {
        name = "Third Word of the Dreamer",
        id = "sixthHouse_ritual_3",
        handler = "Sixth House Rituals",
        skillReq = 12,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned? Together we shall speak for the Law and the Land, and shall drive the mongrel dogs of the Empire from Morrowind.",
        image = "Icons\\PRAY\\art\\dagoth3.dds",
        skillProgress = 200,
        materials = {
            { material = "ash_statue", count = 2 },
            { material = "corprusmeat", count = 5 },
        },
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A2_2_6thHouse" } > 41 and skillModule.getSkill('sixthHouse').value < 13
        end,
        spellEffects = {
            {
                id = 17, --drainAttribute
                attribute = 6, --personality
                duration = 720,
                min = 30,
                max = 30,
            },
        },
        text = "He is the Lord, and Father of the Mountain.\nHe wakes, and the land wakes with him.\nAll the land, and all of its people, shall rise from sleep, and sweep the land clean of the n'wah."
    },
    {
        name = "Forth Word of the Dreamer",
        id = "sixthHouse_ritual_4",
        handler = "Sixth House Rituals",
        skillReq = 13,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned? Together we shall speak for the Law and the Land, and shall drive the mongrel dogs of the Empire from Morrowind.",
        image = "Icons\\PRAY\\art\\dagoth4.dds",
        skillProgress = 200,
        materials = {
            { material = "ash_statue", count = 3 },
            { material = "corprusmeat", count = 11 },
        },
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A2_2_6thHouse" } > 41 and skillModule.getSkill('sixthHouse').value < 14
        end,
        spellEffects = {
            {
                id = 17, --drainAttribute
                attribute = 6, --personality
                duration = 720,
                min = 40,
                max = 40,
            },
        },
        text = "He is the Lord, and Father of the Mountain.\nHe wakes, and the land wakes with him.\nAll the land, and all of its people, shall rise from sleep, and sweep the land clean of the n'wah.\nWhy have you denied him?"
    },
    {
        name = "Fifth Word of the Dreamer",
        id = "sixthHouse_ritual_5",
        handler = "Sixth House Rituals",
        skillReq = 14,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned? Together we shall speak for the Law and the Land, and shall drive the mongrel dogs of the Empire from Morrowind.\nCome to me, through fire and war. I welcome you.",
        image = "Icons\\PRAY\\art\\dagoth5.dds",
        skillProgress = 200,
        materials = {
            { material = "ash_statue", count = 4 },
            { material = "corprusmeat", count = 19 },
        },
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A2_2_6thHouse" } > 41 and skillModule.getSkill('sixthHouse').value < 15
        end,
        spellEffects = {
            {
                id = 17, --drainAttribute
                attribute = 6, --personality
                duration = 720,
                min = 50,
                max = 50,
            },
        },
        text = "He is the Lord, and Father of the Mountain.\nHe wakes, and the land wakes with him.\nAll the land, and all of its people, shall rise from sleep, and sweep the land clean of the n'wah.\nWhy have you denied him?\nAs Lord Dagoth has said. All shall greet him as flesh, or as dust."
    },
    {
        name = "Final Word of the Dreamer",
        id = "sixthHouse_ritual_6",
        handler = "Sixth House Rituals",
        skillReq = 15,
        skill = "sixth_house_theology",
        description = "How will you honor the Sixth House, the tribe unmourned? Together we shall speak for the Law and the Land, and shall drive the mongrel dogs of the Empire from Morrowind.\nCome to me, through fire and war. I welcome you.\nWelcome, Moon-and-Star. I have prepared a place for you.",
        image = "Icons\\PRAY\\art\\dagoth6.dds",
        skillProgress = 200,
        materials = {
            { material = "ash_statue", count = 6 },
            { material = "corprusmeat", count = 36 },
            { material = "pray_6th_house", count = 1 },
        },   
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A2_2_6thHouse" } >= 11 and skillModule.getSkill('sixthHouse').value < 16
        end,
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
    },
}

this.miscRituals = {
    {
        name = "Caius's 'Ritual'",
        id = "caius_skooma",
        handler = "Miscellaneous Rituals",
        skillReq = 5,
        skill = "divine_theology",
        description = "Caius taught me a 'ritual'.",
        image = "Icons\\PRAY\\art\\caius_skooma.dds",
        knowledgeRequirement = function()
            return tes3.getJournalIndex{ id = "A1_1_FindSpymaster" } >= 11
        end,
        soundPath = "Fx\\envrn\\undrwatr.wav",
        skillProgress = 0,
        materials = {
            { material = "skooma_pipe", count = 1},
            { material = "pray_moon_sugar", count = 1},
        },
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 0, --strength
                duration = 720,
                min = 20,
                max = 30,
            },
            {
                id = 79, --fortifyAttribute
                attribute = 4, --speed
                duration = 720,
                min = 20,
                max = 30,
            },
            {
                id = 17, --drainAttribute
                attribute = 1, --intelligence
                duration = 720,
                min = 20,
                max = 30,
            },
            {
                id = 17, --drainAttribute
                attribute = 3, --agility
                duration = 720,
                min = 20,
                max = 30,
            },
            {
               id = 43, --nightEye
               duration = 720,
               min = 0,
               max = 50,
            },
            {
               id = 47, --blind
               duration = 720,
               min = 0,
               max = 50,
            },
        },
        text = "'I'm just an old man with a skooma problem.' ~ Caius Cosades",
    }
}

return this
