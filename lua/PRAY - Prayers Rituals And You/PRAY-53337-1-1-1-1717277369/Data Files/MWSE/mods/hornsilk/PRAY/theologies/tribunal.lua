local this = {}

this.name = "tribunal_theology"
this.fullName = "Tribunal Theology"
this.specialization = tes3.specialization.magic
this.attribute = tes3.attribute.intelligence
this.icon = "Icons\\PRAY\\almsivi.dds"
this.sound = "PRAY\\tri_pray.wav"
this.description = (
    "The Tribunal Theology skill determines your knowledge of traditional prayers and rituals of the Tribunal Temple."
)

this.knowledgeRequirement = function()
    return tes3.getFaction("Temple").playerJoined
end

this.recipes = {
    {
        name = "Restoration of Saint Meris",
        id = "restore_attributes",
        handler = "Tribunal Prayers",
        skillReq = 25,
        skill = "tribunal_theology",
        description = "Pray to Saint Meris to restore all of your attribues\n\n    Restore Strength\n    Restore Intelligence\n    Restore Willpower\n    Restore Agility\n    Restore Speed\n    Restore Endurance\n    Restore Personality\n    Restore Luck",
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
        description = "Restore the skills of the Warrior\n\n    Restore Block\n    Restore Armorer\n    Restore Medium Armor\n    Restore Heavy Armor\n    Restore Blunt Weapon\n    Restore Long Blade\n    Restore Axe\n    Restore Spear",
        image = "Icons\\PRAY\\art\\alma_resto.dds",
        spellEffects = {
            {
                id = 78, --restoreSkill
                skill = 0,
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
                skill = 2,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 3,
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
                skill = 6,
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
        },
        text = "The Mother is active and clawed like a nix-hound, yet she is the holiest of those that reclaim their days.\n\nThe ending of the words is ALMSIVI." -- https://en.uesp.net/wiki/Morrowind:The_36_Lessons_of_Vivec
    },
    {
        name = "Restoration of the Thief",
        id = "restore_stealth_skills", --except for hand-to-hand bc only space for 8
        handler = "Tribunal Prayers",
        skillReq = 25,
        skill = "tribunal_theology",
        description = "Restore the skills of the Thief\n\n    Restore Security\n    Restore Sneak\n    Restore Acrobatics\n    Restore Light Armor\n    Restore Short Blade\n    Restore Marksman\n    Restore Mercantile\n    Restore Speechcraft",
        image = "Icons\\PRAY\\art\\vivec_resto.dds",
        spellEffects = {
            {
                id = 78, --restoreSkill
                skill = 18,
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
                skill = 22,
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
        },
        text = "The Son is myself, Vehk, and I am unto three, six, nine, and the rest that come after, glorious and sympathetic, without borders, utmost in the perfections of this world and the others, sword and symbol, pale like gold.\n\nThe ending of the words is ALMSIVI." -- https://en.uesp.net/wiki/Morrowind:The_36_Lessons_of_Vivec
    },
    {
        name = "Restoration of the Mage",
        id = "restore_magic_skills", --except for unarmored bc only 8
        handler = "Tribunal Prayers",
        skillReq = 25,
        skill = "tribunal_theology",
        description = "Restore the skills of the Mage\n\n    Restore Enchant\n    Restore Destruction\n    Restore Alteration\n    Restore Illusion\n    Restore Conjuration\n    Restore Mysticism\n    Restore Restoration\n    Restore Alchemy",
        image = "Icons\\PRAY\\art\\sotha_resto.dds",
        spellEffects = {
            {
                id = 78, --restoreSkill
                skill = 9,
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
                skill = 11,
                duration = 1,
                min = 100,
                max = 100,
            },
            {
                id = 78, --restoreSkill
                skill = 12,
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
            {
                id = 78, --restoreSkill
                skill = 16,
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
        description = "Restore the skills of the Wanderer, unarmed and unarmored, who walks the ashlands\n\n    Restore Athletics\n    Restore Unarmored\n    Restore Hand-to-Hand",
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
        description = "Assume the aspect of Vivec\n\n    Fortify Personality 20\n    Fortify Spear 20\n    Lightning Shield 20 - 30\n    Bound Spear\n    Reflect 5",
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
        description = "Assume the aspect of Sotha Sil\n\n    Fortify Intelligence 20\n    Fortify Mysticism 20\n    Frost Shield 20 - 30\n    Bound Cuirass\n    Spell Absorption 20",
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
        description = "Assume the aspect of Almalexia\n\n    Fortify Speed 20\n    Fortify Axe 20\n    Fire Shield 20 - 30\n    Bound Helm\n    Fortify Attack 20",
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
    {
        name = "Prostration Towards Vivec",
        id = "vivec_donation_ritual",
        handler = "Tribunal Rituals",
        skillReq = 10,
        skill = "tribunal_theology",
        description = "Pray to the Child of Verse and Memory\n\n    Fortify Fatigue 5 - 10",
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
        description = "Pray to Mother Morrowind\n\n    Fortify Health 5 - 10",
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
        description = "Pray to the Father of Mysteries\n\n    Fortify Magicka 5 - 10",
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
        name = "Saint Aralor's Intervention",
        id = "aralor_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Aralor.\n\n    Cure Common Disease\n    Fortify Personality 5 - 15",
        image = "Icons\\PRAY\\art\\aralor.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 6, --personality
                duration = 720,
                min = 5,
                max = 15,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn self-respect and respect for others, follow Saint Aralor the Penitent, Patron of Tanners and Miners. This foul criminal repented his sins and traveled a circuit of the great pilgrimages on his knees."
    },
    {
        name = "Saint Delyn's Shield",
        id = "delyn_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Delyn\n\n    Cure Common Disease\n    Resist Blight Disease 10 - 50",
        image = "Icons\\PRAY\\art\\delyn.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 95, --resistBlightDisease
                duration = 720,
                min = 10,
                max = 30,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn benevolence, follow Saint Delyn the Wise, Patron of Potters and Glassmakers. Saint Delyn was head of House Indoril, a skilled lawyer, and author of many learned treatises on Tribunal law and custom."
    },
    {
        name = "Saint Felms's Glory",
        id = "felms_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Felms\n\n    Cure Common Disease\n    Fortify Restoration 5 - 15",
        image = "Icons\\PRAY\\art\\felms.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 83, --fortifySkill 
                skill = 15, --restoration
                duration = 720,
                min = 5,
                max = 15,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn fierce justice, follow Saint Felms the Bold, Patron of Butchers and Fishmongers. This brave warlord slew the Nord invaders and drove them from our lands. He could neither read nor write, receiving inspiration directly from the lips of Almsivi."
    },
    {
        name = "Saint Llothis's Rock",
        id = "llothis_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Llothis\n\n    Cure Common Disease\n    Fortify Willpower 5 - 15",
        image = "Icons\\PRAY\\art\\llothis.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 2, --willpower
                duration = 720,
                min = 5,
                max = 15,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn reverence, follow Saint Llothis the Pious, Patron of Tailors and Dyers. Contemporary and companion of the Tribunal, and the best-loved Alma Rula of the Tribunal Temple, he formulated the central rituals and principles of the New Temple Faith. Saint Llothis is the symbolic mortal bridge between the gods and the faithful, and the archetypal priest."
    },
    {
        name = "Saint Meris's Warding",
        id = "meris_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Meris\n\n    Cure Common Disease\n    Resist Corprus Disease 20 - 50",
        image = "Icons\\PRAY\\art\\meris.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 96, --resistCorprusDisease
                duration = 720,
                min = 20,
                max = 60,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn the love of peace, follow Saint Meris the Peacemaker, Patron of Farmers and Laborers. As a little girl, Saint Meris showed healing gifts, and trained as a Healer. She ended a long and bloody House War, intervening on the battlefield in her white robe to heal warriors and spellcrafters without regard to faction."
    },
    {
        name = "Saint Nerevar's Spirit",
        id = "nerevar_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Nerevar\n\n    Cure Common Disease\n    Fortify Fatigue 20 - 60",
        image = "Icons\\PRAY\\art\\nerevar.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 82, --fortifyFatigue
                duration = 720,
                min = 20,
                max = 60,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn valor, follow St. Nerevar the Captain, patron of Warriors and Statesmen. Lord Nerevar helped to unite the barbarian Dunmer tribes into a great nation, culminating in his martyrdom when leading the Dunmer to victory against the evil Dwemer and the traitorous House Dagoth in the Battle of Red Mountain."
    },
    {
        name = "Saint Olms's Benediction",
        id = "olms_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Olms\n\n    Cure Common Disease\n    Resist Common Disease 20 - 60",
        image = "Icons\\PRAY\\art\\olms.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 94, --resistCommonDisease
                duration = 720,
                min = 20,
                max = 60,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn the rule of law and justice, follow Saint Olms the Just, Patron of Chandlers and Clerks. Founder of the Ordinators, Saint Olms conceived and articulated the fundamental principles of testing, ordeal, and repentance."
    },
    {
        name = "Saint Rilms's Grace",
        id = "rilm_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Rilms\n\n    Cure Common Disease\n    Fortify Endurance 5 - 15",
        image = "Icons\\PRAY\\art\\rilms.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 79, --fortifyAttribute
                attribute = 5, --endurance
                duration = 720,
                min = 5,
                max = 15,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn generosity, follow Saint Rilms the Barefooted, Patron of Pilgrims and Beggars. Saint Rilms gave away her shoes, then dressed and appeared as a beggar to better acquaint herself with the poor."
    },
    {
        name = "Saint Roris's Bloom",
        id = "roris_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Roris\n\n    Cure Common Disease\n    Fortify Health 5 - 15",
        image = "Icons\\PRAY\\art\\roris.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 80, --fortifyHealth
                duration = 720,
                min = 5,
                max = 15,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn pride of race and tribe, follow Saint Roris the Martyr, Patron of Furnishers and Caravaners. Captured by Argonians just before the Arnesian War, Roris proudly refused to renounce the Tribunal faith, and withstood the cruel tortures of Argonian sorcerers. Vengeance and justice for the martyred Saint Roris was the rallying cry of the Arnesian War."
    },
    {
        name = "Saint Seryn's Shield",
        id = "seryn_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Seryn\n\n    Cure Common Disease\n    Resist Poison 20 - 60",
        image = "Icons\\PRAY\\art\\seryn.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 97, --resistPoison
                duration = 720,
                min = 20,
                max = 60,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn mercy and its fruits, follow Saint Seryn the Merciful, Patron of Brewers, Bakers, Distillers. This pure virgin of modest aspect could heal all diseases at the price of taking the disease upon herself. Tough-minded and fearless, she took on the burdens of others, and bore those burdens to an honored old age."
    },
    {
        name = "Saint Veloth's Indwelling",
        id = "veloth_ritual",
        handler = "Tribunal Rituals",
        skillReq = 20,
        skill = "tribunal_theology",
        description = "Purge yourself of disease and study the virtures of Saint Veloth\n\n    Cure Common Disease\n    Fortify Magicka 10 - 30",
        image = "Icons\\PRAY\\art\\veloth.dds",
        materials = { { material = "candle", count = 1 } },
        spellEffects = {
            {
                id = 81, --fortifyMagicka
                duration = 720,
                min = 10,
                max = 30,
            },
            {
                id = 69, --cureCommonDisease
            },
        },
        text = "If you would learn daring, follow Saint Veloth the Pilgrim, Patron of Outcasts and Spiritual Seekers. Saint Veloth, prophet and mystic, led the Dunmer out of the decadent home country of the Summerset Isles and into the promised land of Morrowind. Saint Veloth also taught the difference between the Good and Bad Daedra, and won the aid of the Good Daedra for his people while teaching how to carefully negotiate with the Bad Daedra."
    },
}

return this
