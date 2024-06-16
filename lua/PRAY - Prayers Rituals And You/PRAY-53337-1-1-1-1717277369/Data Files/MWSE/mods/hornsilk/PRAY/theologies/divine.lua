local this = {}

this.name = "divine_theology"
this.fullName = "Divine Theology"
this.specialization = tes3.specialization.magic
this.attribute = tes3.attribute.willpower
this.icon = "Icons\\PRAY\\divine.dds"
this.sound = "PRAY\\div_pray.wav"
this.description = (
    "The Divine Theology skill determines your knowledge of prayers and rituals of the Divines."
)

this.knowledgeRequirement = function()
    return tes3.getFaction("Imperial Cult").playerJoined
end

this.recipes = {
    {
        name = "Prayer of Akatosh",
        id = "prayer_of_akatosh",
        handler = "Divine Prayers",
        skillReq = 10,
        skill = "divine_theology",
        description = "Pray to Akatosh to fortify Speed\n\n     - Fortify Speed 5",
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
        description = "Pray to Arkay to fortify Willpower\n\n     - Fortify Willpower 5",
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
        description = "Pray to Dibella to fortify Personality\n\n     - Fortify Personality 5",
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
        description = "Pray to Julianos to fortify Intelligence\n\n     - Fortify Intelligence 5",
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
        description = "Pray to Kynareth to fortify Agility\n\n     - Fortify Agility 5",
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
        description = "Pray to Mara to fortify Endurance\n\n     - Fortify Endurance 5",
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
        description = "Pray to Stendarr to fortify Strength\n\n     - Fortify Strength 5",
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
        description = "Pray to Talos to fortify Attack\n\n     - Fortify Attack 5",
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
        description = "Pray to Zenithar to fortify Luck\n\n     - Fortify Luck 5",
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
    {
        name = "Wings of Akatosh",
        id = "ritual_of_akatosh",
        handler = "Divine Rituals",
        skillReq = 20,
        skill = "divine_theology",
        description = "Venerate Akatosh for a blessing of flight.\n\n    Levitate 10 - 30\n    Fortify Speed 10 - 20\n    Fortify Mysticism 10 - 20",
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
        description = "Sanctify your body with an offering to Arkay\n\n    Sanctuary 20\n    Fortify Willpower 10 - 20\n    Fortify Unarmored 10 - 20",
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
        description = "Adorn yourself in the dazzling glamour of Dibella\n\n    Reflect 1 - 10\n    Fortify Personality 10 - 20\n    Fortify Conjuration 10 - 20",
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
        description = "Offer a skull for the secrets of the contradiction\n\n    Invisibility\n    Fortify Intelligence 10 - 20\n    Fortify Enchant 10 - 20",
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
        description = "Offer a feather to soar upon the winds\n\n    Jump 20\n    Fortify Agility 10 - 20\n    Fortify Athletics 10 - 20",
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
        description = "Fill a cup with the healing waters of Mara\n\n    Fortify Health 10 - 50\n    Fortify Endurance 10 - 20\n    Fortify Restoration 10 - 20",
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
        description = "Transform a mace into the steadfast fist of Stendarr\n\n    Bound Mace\n    Fortify Strength 10 - 20\n    Fortify Blunt Weapon 10 - 20",
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
        description = "Offer a sword to Talos for a combat blessing\n\n    Light 20\n    Fortify Attack 10 - 20\n    Fortify Long Blade 10 - 20",
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
        description = "Honor Zenithar with the fruits of your labor, and your hands and tongue will be blessed\n\n    Telekinesis 20\n    Fortify Luck 10 - 20\n    Fortify Speechcraft 10 - 20",
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

return this