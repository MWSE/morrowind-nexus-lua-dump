local this = {}

local function getConfig()
    return mwse.loadConfig("character_beliefs") or {}
end

local function saveConfig(newConfig)
    mwse.saveConfig("character_beliefs", newConfig)
end

--AKATOSH
this.akatosh = {
    id = "akatosh",
    name = "Akatosh",
    description = (
        "Dragon God of Time - is the chief deity of the Nine Divines and one of two deities found in every Tamrielic religion. He is generally considered to be the first of the Gods to form in the Beginning Place; after his establishment, other spirits found the process of being easier and the various pantheons of the world emerged. He is the ultimate God of the Cyrodilic Empire, where he embodies the qualities of endurance, invincibility, and everlasting legitimacy. \n\nAkatosh is usually venerated by Cyrodiils and Bretons. \n\nBonus to Endurance (+10) is bestowed upon followers of Akatosh."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 10
        })
    end,
}

--ALDUIN
this.alduin = {
    id = "alduin",
    name = "Alduin",
    description = (
        "World Eater - is the Nordic variation of Akatosh, and only superficially resembles his counterpart in the Nine Divines. Alduin's sobriquet, 'the world eater', comes from myths that depict him as the horrible, ravaging firestorm that destroyed the last world to begin this one. Nords therefore see the god of time as both creator and harbinger of the apocalypse. Many Nords however insist that the belief he is some sort of Nordic version of Akatosh is a false one perpetuated by foreigners who misunderstood Nordic oral traditions. \n\nAlduin is sometimes venerated by Nords. \n\nBonus to Maximum Magicka (10%) is bestowed upon followers of Alduin."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Alduin"
        }

    end
}

--AURI-EL
this.auriel = {
    id = "auriel", 
    name = "Auri-El", 
    description = (
        "King of the Aldmer - is the Elven Akatosh, the soul of Anui-El, who, in turn, is the soul of Anu the Everything. He is the chief of most Aldmeri pantheons. In his only known moment of weakness, he agreed to take his part in the creation of the mortal plane, that act which forever sundered the Elves from the spirit worlds of eternity. To make up for it, Auri-El led the original Aldmer against the armies of Lorkhan in mythic times, vanquishing that tyrant and establishing the first kingdoms of the Altmer, Altmora and Old Ehlnofey. He then ascended to heaven in full observance of his followers so that they might learn the steps needed to escape the mortal plane. \n\nAuri-El is usually venerated by Altmers and Bosmers. \n\nAbility to Reflect spells (10%) and ability to Resist Common Diseases (10%) is bestowed upon followers of Auri-El."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Auriel"
        }
    end
}

--ALKOSH
this.alkosh = {
    id = "alkosh",
    name = "Alkosh",
    description = (
        "Dragon King of Cats - Is Khajiiti variation on the Altmeri Auri-El, and thus an Akatosh-as-culture-hero. He enjoys immense popularity in Elsweyr's wasteland regions. He is depicted as a fearsome dragon, a creature the Khajiit say 'is just a real big cat'. It is said that Alkosh repelled an early Aldmeri pogrom of Pelinal Whitestrake during mythic times, by shouting the invader off the summit of Sunspire and out of Elsweyr, leaving behind a wound in the sky. \n\nAlkosh is usually venerated by Khajiits. \n\nBonus to Speed (+10) is bestowed upon followers of Alkosh."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 10
        })
    end
}

--ALL-MAKER
this.allmaker = {
    id = "allmaker",
    name = "The All-Maker",
    description = (
        "The All-Maker is a mysterious deity revered as the wellspring of creation. All life flows from the All-Maker like a great river, and, in time, this river flows back to its source. The spirits of dead creatures return to the All-Maker, who shapes new life and returns it to Mundus. Each life is a gift given in the great wisdom of the All-Maker, thus each one is very precious and sacred. The All-Maker favors those who hone their skills, and disfavors the greedy and lazy. 'Oneness' with the land is considered crucial to pleasing the All-Maker. Firewood is collected from dead trees. Hunting is for subsistence, not sport. The sanctity of life demands that violence only be used as a last resort. \n\nAll-Maker is venerated by the Skaal of Solstheim. \n\nBonuses to Personality (+10) and Luck (+10) are bestowed upon followers of the All-Maker, but they suffer penalties (-5) to fighting skills and have trouble with learning Destruction and Conjuration magic. "
    ),
    doOnce = function()
		local fightSkills = {
            tes3.skill.axe,
            tes3.skill.block,
            tes3.skill.bluntWeapon,
            tes3.skill.handToHand,
            tes3.skill.longBlade,
            tes3.skill.marksman,
            tes3.skill.shortBlade,
            tes3.skill.spear,
        }
        for _, skill in ipairs(fightSkills) do
            tes3.modStatistic({
                reference = tes3.player,
                skill = skill,
                value = -5
            })
        end
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = 10
        })
		tes3.setStatistic({
			reference = tes3.player,
			skill = tes3.skill.destruction,
			value = 0
		})
		tes3.setStatistic({
			reference = tes3.player,
			skill = tes3.skill.conjuration,
			value = 0
		})
    end,
}

--ADVERSARY
this.adversary = {
    id = "adversary",
    name = "The Adversary",
    description = (
        "The Greedy Man, Thartaag the World-Devourer - is an opponent to the All-Maker working to corrupt the dominion of the All-Maker. The Skaal believe the Adversary takes delight in tormenting and testing them. Daedra are presumably considered to be merely some of the many evil aspects of the Adversary. \n\nNothing is known about cult of the Adversary. \n\nBonuses to Destruction (+10), Conjuration (+10) and fighting skills (+5) are bestowed upon followers of the Adversary, but they suffer penalties to Personality (-15) and Luck (-15)."
    ),
    doOnce = function()
		local fightSkillsadv = {
            tes3.skill.axe,
            tes3.skill.block,
            tes3.skill.bluntWeapon,
            tes3.skill.handToHand,
            tes3.skill.longBlade,
            tes3.skill.marksman,
            tes3.skill.shortBlade,
            tes3.skill.spear,
        }
        for _, skill in ipairs(fightSkillsadv) do
            tes3.modStatistic({
                reference = tes3.player,
                skill = skill,
                value = 5
            })
        end
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -15
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = -15
        })
		tes3.modStatistic({
			reference = tes3.player,
			skill = tes3.skill.destruction,
			value = 10
		})
		tes3.modStatistic({
			reference = tes3.player,
			skill = tes3.skill.conjuration,
			value = 10
		})
    end,
}

--ALMALEXIA
this.almalexia = {
    id = "almalexia",
    name = "Almalexia",
    description = (
        "Mother of Morrowind - Most traces of Akatosh disappeared from ancient Chimer legends during their so-called 'exodus', primarily due to that god's association and esteem with the Altmeri. However, most aspects of Akatosh which seem so important to the mortal races, namely immortality, historicity, and genealogy, have conveniently resurfaced in Almalexia, the most popular of Morrowind's divine Tribunal. \n\nAlmalexia is usually venerated by Dunmers. \n\nBonus to Endurance (+5) and ability to Resist Paralysis (10%) is bestowed upon followers of Almalexia."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 5
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Almalexia"
        }
    end
}

--ARKAY
this.arkay = {
    id = "arkay",
    name = "Arkay",
    description = (
        "Lord of the Wheel of Life - Arkay is a member of the Nine Divines pantheon, and popular elsewhere as well. Often more important in those cultures where his father, Akatosh, is either less related to time or where his time aspects are difficult to comprehend by the layman. He is the god of burials and funeral rites, and is sometimes associated with the seasons. His priests are staunch opponents of necromancy and all forms of the undead. It is said that Arkay did not exist before the world was created by the gods under Lorkhan's trickery. Therefore, he is sometimes called the Mortals' God. \n\nArkay is usually venerated by Cyrodiils, Bosmers and Bretons. \n\nBonus to Health (+10) is bestowed upon followers of Arkay, but they have trouble with learning Conjuration magic."
    ),
    doOnce = function()
		tes3.modStatistic{
			reference = tes3.player,
			name = 'health',
			value = 10
		}
		tes3.setStatistic({
			reference = tes3.player,
			skill = tes3.skill.conjuration,
			value = 0
		})
    end
}

--ORKEY
this.orkey = {
    id = "orkey",
    name = "Orkey",
    description = (
        "Old Knocker - Orkey is a loan-god of the Nords, who seem to have taken up his worship during Aldmeri rule of Atmora. He combines aspects of Arkay and Malacath. Nords believe they once lived as long as Elves until Orkey appeared; through heathen trickery, he fooled them into a bargain that 'bound them to the count of winters'. At one time, legends say, Nords only had a lifespan of six years due to Orkey's foul magic. Shor showed up, though, and, through unknown means, removed the curse, throwing most of it onto the nearby Orcs. \n\nOrkey is sometimes venerated by Nords. \n\nBonus to Strength (+5) and Health (+10) is bestowed upon followers of Orkey, but they suffer from Weakness to Frost (10%)"
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
        tes3.modStatistic{
			reference = tes3.player,
			name = 'health',
			value = 10
		}
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Orkey"
        }
    end
}

--XARXES
this.xarxes = {
    id = "xarxes",
    name = "Xarxes",
    description = (
        "Ageless One - God of ancestry and secret knowledge, Xarxes began as a scribe to Auri-El, and has kept track of all Aldmeri accomplishments, large and small, since the beginning of time. He created his wife, Oghma, from his favorite moments in history. \n\nXarxes is usually venerated by Altmers and Bosmers. \n\nBonus to Intelligence (+3), Strength (+1), Willpower (+1), Endurance (+1), Agility (+1), Speed (+1), Personality (+1) and Luck (+1) is bestowed upon followers of Xarxes."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 3
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 1
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = 1
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 1
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 1
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 1
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = 1
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = 1
        })
    end
}

--TUWHACCA
this.tuwhacca = {
    id = "tuwhacca",
    name = "Tu'whacca",
    description = (
        "Tricky God - Yokudan god of souls. Tu'whacca, before the creation of the world, was the god of Nobody Really Cares. When Ruptga undertook the creation of the Walkabout, Tu'whacca found a purpose; he became the caretaker of the Far Shores, and continues to help Redguards find their way into the afterlife. His cult is sometimes associated with Arkay in the more cosmopolitan regions of Hammerfell. \n\nTu'whacca is usually venerated by Redguards. \n\nBonus to Luck (+5) and Health (+5) is bestowed upon followers of Tu'whacca, but they have trouble with learning Conjuration magic."
    ),
    doOnce = function()
		tes3.setStatistic({
			reference = tes3.player,
			skill = tes3.skill.conjuration,
			value = 0
		})
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = 5
        })
        tes3.modStatistic{
			reference = tes3.player,
			name = 'health',
			value = 5
		}
    end
}

--AZURA
this.azura = {
    id = "azura",
    name = "Azura",
    description = (
        "Queen of Dawn and Dusk - is a Daedric Prince whose sphere is dawn and dusk—the magic in-between realms of twilight—as well as mystery and magic, fate and prophecy, and vanity and egotism. Azura is one of the few Daedra who maintains the appearance of being 'good' by mortal standards, and reportedly feels more concern for the well-being of her mortal subjects than other Daedric Princes. It is said she wants their love above all else, and for her worshippers to love themselves; it pains her when they do not. This attitude leads to an extremely devoted following. She is also one of the few Princes who constantly maintains a female image, and is perceived accordingly. \n\nAbility to see in the dark is bestowed upon followers of Azura." --Shame I don't know how to add bonuses only during Dawn and Dusk :(
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Azura"
        }
    end
}

--BAAN DAR
this.baandar = {
    id = "baandar",
    name = "Baan Dar",
    description = (
        "The Bandit God - a trickster spirit of thieves and beggars. Regarded as the Pariah, Baan Dar becomes the cleverness or desperate genius of the long-suffering Khajiit, whose last minute plans always upset the machinations of their enemies. \n\nBaan Dar is usually venerated by Khajiits and Bosmers. \n\nBonus to Intelligence (+5) and Luck (+5) is bestowed upon followers of Baan Dar."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = 5
        })
    end,
}

--BOETHIAH
this.boethiah = {
    id = "boethiah",
    name = "Boethiah",
    description = (
        "Prince of Plots - is a Daedric Prince who rules over deceit, conspiracy, secret plots of murder, assassination, treason, and unlawful overthrow of authority. This sphere is destructive in nature, and his destructiveness comes from inspiring the arms of mortal warriors. Worshippers are known to hold bloody competitions in Bher honor, battling—even killing—each other. Sometimes described as a male and commonly as a female, often within the same text. Boethiah is also known as the Anticipation of Almalexia. \n\nBonus to Long Blade (+20) is bestowed upon followers of Boethiah."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade,
            value = 20
        })
    end,
}

--CLAVICUS VILE
this.clavicusvile = {
    id = "clavicusvile",
    name = "Clavicus Vile",
    description = (
        "Prince of Trickery and Bargains - is a Daedric Prince whose sphere is the granting of power and wishes through ritual invocations and pacts. He is seen as one of the more 'sophisticated' of the Daedric Princes. Clavicus finds eternity to be 'boring', so he finds entertainment in watching mortals and occasionally meddling in their affairs. He has been known to be the patron to vampires, gracing them with social stature, reason and savvy, allowing them to not only live among regular mortals, but to hold powerful positions in society. However, not all of Vile's machinations are necessarily insidious; he has been known to reward those who, on his direction, eliminate threats to the general public, while still serving his own interests. \n\nBonus to Personality (+30) is bestowed upon followers of Clavicus Vile, but they suffer a penalty to Luck (-20)."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = 30
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = -20
        })
    end,
}

--DAGOTH UR
this.dagothur = {
    id = "dagothur",
    name = "Dagoth Ur",
    description = (
        "The Sharmat - is the Awakened Lord of the Sixth House, come to cast down false gods, drive foreigners from the land, and restore the ancient glory of Morrowind. He bids you come to Red Mountain. He would grant you counsel and power, if only you would pledge that friendship anew. The path to Red Mountain is long, and filled with danger, but if you are worthy, you will find there wisdom, and all the power you need to set the world aright. \n\nDagoth Ur is usually venerated by Dunmers. \n\nA gift of His Flesh which grants Ability to Resist Common and Blight Diseases (100%) together with Corprus upon consumption is given to followers of Dagoth Ur."
    ),
    doOnce = function()
        mwscript.addItem{
            reference = tes3.player, 
            item = "MTR_ByTheDivines_DagothUr"
        }
    end,
}

--DIAGNA
this.diagna = {
    id = "diagna",
    name = "Diagna",
    description = (
        "Orichalc God of the Sideways Blade - Hoary thuggish cult of the Redguards. Originated in Yokuda during the Twenty Seven Snake Folk Slaughter. Diagna was an avatar of the HoonDing that achieved permanence. He was instrumental to the defeat of the Sinistral Mer, as he brought orichalc weapons to the Yokudan people to win the fight. In Tamriel, he led a very tight knit group of followers against the Orcs of Orsinium during the height of their ancient power, but then faded into obscurity. \n\nDiagna is sometimes venerated by Redguards. \n\nBonus to Armorer (+20) is bestowed upon followers of Diagna."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer,
            value = 20
        })
    end,
}

--DIBELLA
this.dibella = {
    id = "dibella",
    name = "Dibella",
    description = (
        "Goddess of Beauty - Popular god of the Nine Divines. In Cyrodiil, she has nearly a dozen different cults, some devoted to women, some to artists and aesthetics, and others to erotic instruction. \n\nDibella is usually venerated by Cyrodiils, Nords and Bretons. \n\nBonus to Personality (+5) and Agility (+5) is bestowed upon followers of Dibella."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 5
        })
    end,
}

--HERMAEUS MORA
this.hermaeusmora = {
    id = "hermaeusmora",
    name = "Hermaeus Mora",
    description = (
        "Demon of Knowledge -  is a Daedric Prince whose sphere is forbidden knowledge and the 'scrying of the tides of Fate, of the past and future as read in the stars and heavens, and in whose dominion are the treasures of knowledge and memory'. Mora has been called the wisest of the Daedric Princes, with a mind as old as Tamriel and a body of slime, though he describes himself as 'The riddle unsolveable. The door unopenable. The book unreadable. The question unanswerable.' Unlike most Princes, Hermaeus Mora does not take on a humanoid form, manifesting instead as varied, grotesque assemblages of eyes, tentacles, and claws, or a featureless purple vortex known as the Wretched Abyss. He is also known as Herma-Mora, The Woodland Man - Ancient Atmoran demon who, at one time, nearly seduced the Nords into becoming Aldmer. Most Ysgramor myths are about escaping the wiles of old Herma-Mora. He is vaguely related to the cult origins of the Morag Tong - Foresters Guild, if only by association with Mephala. \n\nBonus to Intelligence (+20) is bestowed upon followers of Hermaeus Mora, but they suffer from worse vision (Blind 20%)."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 20
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_HermaeusMora"
        }
    end,
}

--HIRCINE
this.hircine = {
    id = "hircine",
    name = "Hircine",
    description = (
        "The Huntsman - is a Daedric Prince whose sphere is the Hunt, the Sport of Daedra, the Great Game, the Chase. During the Dawn Era, before Y'ffre stabilized the forms of most creatures, life was stuck in a primal chaos, ever shapeshifting state called the Ooze. Some cultures, such as that of the Khajiit, credit Hircine as being responsible for this Shapelessness, and the Bosmer people believe that Hircine wishes to return to this state of chaos. Indeed, many of the curses he has unleashed on Tamriel share this theme, these therianthropic diseases which transform mortals into were-creatures. Whilst Nirn's inhabitants may see these creatures as nothing more than abominations, Hircine views them as his children, and is a guardian to them. \n\nAbility to Detect Animals is bestowed upon followers of Hircine."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Hircine"
        }
    end,
}

--HOONDING
this.hoonding = {
    id = "hoonding",
    name = "HoonDing",
    description = (
        "The Make Way God - Yokudan spirit of 'perseverance over infidels'. The HoonDing has historically materialized whenever the Redguards need to 'make way' for their people. In Tamrielic history this has only happened three times -- twice in the first era during the Ra Gada invasion and once during the Tiber War. In this last incarnation, the HoonDing was said to have been either a sword or a crown, or both. \n\nHoonDing is usually venerated by Redguards. \n\nBonus to Attack (+10) is bestowed upon followers of HoonDing."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_HoonDing"
        }
    end,
}

--JULIANOS
this.julianos = {
    id = "julianos",
    name = "Julianos",
    description = (
        "God of Wisdom and Logic - Often associated with Jhunal, the Nordic father of language and mathematics, Julianos is the Cyrodilic god of literature, law, history, and contradiction. Monastic orders founded by Tiber Septim and dedicated to Julianos are the keepers of the Elder Scrolls. \n\nJulianos is usually venerated by Cyrodiils and Bretons. \n\nBonus to Enchant (+10) and Alchemy (+10) is bestowed upon followers of Julianos."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant,
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy,
            value = 10
        })
    end,
}

--JHUNAL
this.jhunal = {
    id = "jhunal",
    name = "Jhunal",
    description = (
        "Rune God - The Nordic god of hermetic orders, father of language and mathematics. After falling out of favor with the rest of that pantheon, he became Julianos of the Nine Divines. He is absent in modern Skyrim mythology. \n\nJhunal is sometimes venerated by Nords. \n\nBonus to Enchant (+20) and Alchemy (+20) is bestowed upon followers of Jhunal, but they suffer penalty to Personality (-10)"
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant,
            value = 20
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy,
            value = 20
        })
    end,
}

--JYGGALAG
this.jyggalag = {
    id = "jyggalag",
    name = "Jyggalag",
    description = (
        "Prince of Order - is a Daedric Prince whose sphere represents logical order and deduction; his great library once contained a logical prediction of every detail of the world and of every action that would ever take place on Mundus or Oblivion, long before they actually happened. Until the Third Era, the Prince was virtually unknown in Tamriel beyond his name, having been cursed in antiquity to become the Prince of Madness, Sheogorath. \n\nAbility to Restore Health is bestowed upon followers of Jyggalag, but they are cursed with Silence."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Jyggalag"
        }
    end,
}

--KYNARETH
this.kynareth = {
    id = "kynareth",
    name = "Kynareth",
    description = (
        "Goddess of Air - Kynareth is a member of the Nine Divines, the strongest of the Sky spirits. In some legends, she is the first to agree to Lorkhan's plan to invent the mortal plane, and provides the space for its creation in the void. She is also associated with rain, a phenomenon said not to occur before the removal of Lorkhan's divine spark. \n\nKynareth is usually venerated by Cyrodiils and Bretons. \n\nBonus to Speed (+5) and Agility (+5) is bestowed upon followers of Kynareth."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 5
        })
    end,
}

--KYNE
this.kyne = {
    id = "kyne",
    name = "Kyne",
    description = (
        "Kiss At the End - Nordic Goddess of the Storm. Widow of Shor and favored god of warriors. She is often called the Mother of Men. Her daughters taught the first Nords the use of the thu'um, or Storm Voice. \n\nKyne is usually venerated by Nords. \n\nBonus to Speed (+10) is bestowed upon followers of Kyne."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 10
        })
    end,
}

--KHENARTHI
this.khenarthi = {
    id = "khenarthi",
    name = "Khenarthi",
    description = (
        "God of Winds - is the Khajiiti god of weather and the sky, and the most powerful of the Sky spirits. When a Khajiit dies, it is Khenarthi who guides their soul either to Azurah for judgment, or to Llesw'er, the Sands Behind the Stars. And it is Khenarthi's clarion call that will summon the 'eternal united spirit of all Khajiit' to defend creation at the end of time. \n\nBonus to Agility (+10) is bestowed upon followers of Khenarthi."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 10
        })
    end,
}

--JODE and JONE
this.jodejone = {
    id = "jodejone",
    name = "Jode and Jone",
    description = (
        "Big Moon God and Little Moon God - Aldmeri gods of the Big Moon and the Little Moon. Also called Masser or Mara's Tear and Secunda or Stendarr's Sorrow. In Khajiti religion, Jode and Jone are aspects of the Lunar Lattice, or ja-Kha'jay. Together, the moons represent duality, fate, and luck. \n\nJode and Jone are usually venerated by Bosmers and Khajiits. \n\nBonus to Luck (+10) is bestowed upon followers of Jode and Jone."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = 10
        })
    end,
}

--TAVA
this.tava = {
    id = "tava",
    name = "Tava",
    description = (
        "Bird God - Yokudan spirit of the air. Tava is most famous for leading the Yokudans to the isle of Herne after the destruction of their homeland. She has since become assimilated into the mythology of Kynareth. She is still very popular in Hammerfell among sailors, and her shrines can be found in most port cities. \n\nTava is usually venerated by Redguards. \n\nBonus to Speed (+5) and Fatigue (+5) is bestowed upon followers of Tava."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 5
        })
        tes3.modStatistic{
			reference = tes3.player,
			name = 'fatigue',
			value = 5
		}
    end,
}

--LEKI
this.leki = {
    id = "leki",
    name = "Leki",
    description = (
        "Saint of the Spirit Sword - Goddess daughter of Ruptga, Leki is the goddess of aberrant swordsmanship. The Na-Totambu of Yokuda warred to a standstill during the mythic era to decide who would lead the charge against the Sinistral Mer. Their swordmasters, though, were so skilled in the Best Known Cuts as to be matched evenly. Leki introduced the Ephemeral Feint. Afterwards, a victor emerged and the war with the Aldmer began. \n\nLeki is usually venerated by Redguards. \n\nBonus to Long Blade (+10) and Luck (+5) is bestowed upon followers of Leki."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade,
            value = 10
        })
    end,
}

--SHEZARR
this.shezarr = {
    id = "shezarr",
    name = "Shezarr",
    description = (
        "God of Man - Cyrodilic version of Lorkhan, whose importance suffers when Akatosh comes to the fore of Imperial religion. Shezarr was the spirit behind all human undertaking, especially against Aldmeri aggression. He is sometimes associated with the founding of the first Cyrodilic battlemages. In the present age of racial tolerance, Shezarr is all but forgotten. \n\nShezarr is sometimes venerated by Cyrodiils. \n\nBonus to Attack (+5) and Luck (+5) is bestowed upon followers of Shezarr."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = 5
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Shezarr"
        }
    end,
}

--SHOR
this.shor = {
    id = "shor",
    name = "Shor",
    description = (
        "God of the Underworld - Nordic version of Lorkhan, who takes sides with Men after the creation of the world. Foreign gods conspire against him and bring about his defeat, dooming him to the underworld. Atmoran myths depict him as a bloodthirsty warrior king who leads the Nords to victory over their Aldmeri oppressors time and again. Before his doom, Shor was the chief of the gods. \n\nShor is usually venerated by Nords. \n\nBonus to Attack (+5) and Strength (+5) is bestowed upon followers of Shor."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Shor"
        }
    end,
}

--SHEOR
this.sheor = {
    id = "sheor",
    name = "Sheor",
    description = (
        "Bad Man - In Bretony, the Bad Man is the source of all strife. He seems to have started as the god of crop failure, but most modern theologians agree that he is a demonized version of the Nordic Shor, born during the dark years after the fall of Saarthal. \n\nSheor is sometimes venerated by Bretons. \n\nBonus to Attack (+5) and Strength (+10) is bestowed upon followers of Sheor, but they suffer penalty to Luck (-5)"
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = -5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 10
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Sheor"
        }
    end,
}

--SEP
this.sep = {
    id = "sep",
    name = "Sep",
    description = (
        "The Snake - Yokudan version of Lorkhan. Sep is born when Ruptga creates someone to help him regulate the spirit trade. Sep, though, is driven crazy by the hunger of Satakal, and he convinces some of the gods to help him make an easier alternative to the Walkabout. This, of course, is the world as we know it, and the spirits who followed Sep become trapped here, to live out their lives as mortals. Sep is punished by Ruptga for his transgressions, but his hunger lives on as a void in the stars, a 'non-space' that tries to upset mortal entry into the Far Shores. \n\nSep is sometimes venerated by Redguard. \n\nAbility to Resist Poison (20%) is bestowed upon followers of Sep."
    ),
    doOnce = function()
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Sep"
        }
    end,
}

--LORKHAN
this.lorkhan = {
    id = "lorkhan",
    name = "Lorkhan",
    description = (
        "The Missing God - This Creator-Trickster-Tester deity is in every Tamrielic mythic tradition. His most popular name is the Aldmeri 'Lorkhan', or Doom Drum. He convinced or contrived the Original Spirits to bring about the creation of the mortal plane, upsetting the status quo -- much like his father Padomay had introduced instability into the universe in the Beginning Place. After the world is materialized, Lorkhan is separated from his divine center, sometimes involuntarily, and wanders the creation of the et'Ada. He and his metaphysical placement in the 'scheme of things' is interpreted a variety of ways. In Morrowind, for example, he is a being related to the Psijiic Endeavor, a process by which mortals are charged with transcending the gods that created them. To the High Elves, he is the most unholy of all higher powers, as he forever broke their connection to the spirit plane. In the legends, he is almost always an enemy of the Aldmer and, therefore, a hero of early Mankind. Khajiits know him as Lorkhaj. \n\nBonus to Maximum Magicka (10%) is bestowed upon followers of Lorkhan." --I really run out of ideas here, sorry :( Actually I kinda like it, you get bonus to magicka because of proximity to Heart of Lorkhan + it's kinda funny how Alduin (Destroyer) and Lorkhan (Creator) have the same bonus.
    ),
    doOnce = function()
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Lorkhan"
        }
    end,
}

--ANUIEL
this.anuiel = {
    id = "anuiel",
    name = "Anui-El",
    description = (
        "Soul of Anu - Anui-El is seen as Order, the Everlasting Ineffable Light, and is dichotomically opposed to Sithis, who represents Chaos, the Corrupting Inexpressible Action.\n\nAnui-El is a part of Altmer tradition. \n\nAbility to Resist Frost, Fire and Shock (10%) is bestowed upon followers of Anuiel, but they find it almost impossible to cast Alteration spells."
    ),
    doOnce = function()
        tes3.setStatistic({
			reference = tes3.player,
			skill = tes3.skill.alteration,
			value = 0
		})
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Anuiel"
        }
    end
}

--MAGNUS
this.magnus = {
    id = "magnus",
    name = "Magnus",
    description = (
        "The God of Sorcery - Magnus withdrew from the creation of the world at the last second, though it cost him dearly. What is left of him on the world is felt and controlled by mortals as magic. One story says that, while the idea was thought up by Lorkhan, it was Magnus who created the schematics and diagrams needed to construct the mortal plane. He is sometimes represented by an astrolabe, a telescope, or, more commonly, a staff. Cyrodilic legends say he can inhabit the bodies of powerful magicians and lend them his power. Associated with Zurin Arctus, the Underking. Known to Khajiits as Magrus. \n\nMagnus is usually venerated by Altmers, Bretons and Khajiits. \n\nAbility of Spell Absorption (10%) is bestowed upon followers of Magnus."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Magnus"
        }
    end,
}

--MALACATH
this.malacath = {
    id = "malacath",
    name = "Malacath",
    description = (
        "God of Curses - is a Daedric Prince whose sphere is 'the patronage of the spurned and ostracized, the keeper of the Sworn Oath, and the Bloody Curse', as well as conflict, battle, broken promises, and anguish. Malacath has been described as a 'weak but vengeful' Daedra, and he fittingly is not recognized as a Daedra Lord by his peers. The Prince rules over a realm of Oblivion known as the Ashpit. Malacath was created when Boethiah ate the Altmeri ancestor spirit, Trinimac, although Malacath himself says that this tale is far too 'literal minded'. Additionally, Trinimac's most devout Elven followers were transformed into the Orsimer. However, some Orsimer cling to the belief that Trinimac still exists and Malacath is a separate entity. Goblinkind worships the 'Blue God', whom they venerate with sacred idols of Malacath, painted blue. Associated with Horde King Malooc, an enemy god of the Ra Gada. \n\nMalacath is usually venerated by Orsimers. \n\nBonus to Strength (+10) is bestowed upon followers of Malacath."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 10
        })
    end,
}

--TRINIMAC
this.trinimac = {
    id = "trinimac",
    name = "Trinimac",
    description = (
        "Strong god of the early Aldmer, in some places more popular than Auri-El. He was a warrior spirit of the original Elven tribes that led armies against the Men. Boethiah is said to have assumed his shape (in some stories, he even eats Trinimac) so that he could convince a throng of Aldmer to listen to him, which led to their eventual Chimeri conversion. He vanishes from the mythic stage after this, to return as the dread Malacath. \n\nTrinimac is usually venerated by Orsimers. \n\nBonus to Endurance (+10) is bestowed upon followers of Trinimac."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 10
        })
    end,
}

--MAULOCH
this.mauloch = {
    id = "mauloch",
    name = "Mauloch",
    description = (
        "Mountain Fart - enemy god of the Nords and an Orcish god of the Velothi Mountains, Mauloch troubled the heirs of King Harald for a long time. Fled east after his defeat at the Battle of Dragon Wall, circa 1E 660. His rage was said to fill the sky with his sulfurous hatred, later called the 'Year of Winter in Summer', referring to the famed eruption of Red Mountain. The 'Myth of Mauloch' a little-known legend which says, in part, that the Orcs had been nomads for two hundred years before the first founding of Orsinium. \n\nMauloch is sometimes venerated by Orsimers. \n\nBonus to Strength (+5) and Endurance (+5) is bestowed upon followers of Mauloch."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
    end,
}

--MARA
this.mara = {
    id = "mara",
    name = "Mara",
    description = (
        "Goddess of Love - Nearly universal goddess. Origins started in mythic times as a fertility goddess. In Skyrim, Mara is a handmaiden of Kyne. In the Empire, she is Mother-Goddess. She is sometimes associated with Nir of the 'Anuad', the female principle of the cosmos that gave birth to creation. Depending on the religion, she is either married to Akatosh or Lorkhan, or the concubine of both. \n\nMara is usually venerated by Cyrodiils, Nords, Altmers, Bosmers, Khajiits and Bretons. \n\nBonus to Willpower (+5) and Restoration (+10) is bestowed upon followers of Mara."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.restoration,
            value = 10
        })
    end,
}

--MORWHA
this.morwha = {
    id = "morwha",
    name = "Morwha",
    description = (
        "Teat God - Yokudan fertility goddess. Fundamental deity in the Yokudan pantheon, and the favorite of Ruptga's wives. Still worshipped in various areas of Hammerfell, including Stros M'kai. Morwha is always portrayed as four-armed, so that she can 'grab more husbands'. \n\nMorwha is usually venerated by Redguards. \n\nBonus to Agility (+5) and Restoration (+10) is bestowed upon followers of Morwha."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.restoration,
            value = 10
        })
    end,
}

--MEHRUNES DAGON
this.mehrunesdagon = {
    id = "mehrunesdagon",
    name = "Mehrunes Dagon",
    description = (
        "God of Destruction - is the Daedric Prince of Destruction, Change, Revolution, Energy, and Ambition. He is associated with natural dangers like fire, earthquakes, and floods. Dagon is an especially important deity in Morrowind, where he represents its near-inhospitable terrain as one of the Four Corners of the House of Troubles. In most cultures, though, Dagon is merely a god of bloodshed and betrayal. \n\nBonus to Destruction (+10), Illusion (+5) and Alteration (+5) is bestowed upon followers of Mehrunes Dagon."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.destruction,
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion,
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alteration,
            value = 5
        })
    end,
}

--MEPHALA
this.mephala = {
    id = "mephala",
    name = "Mephala",
    description = (
        "Webspinner - is a Daedric Prince whose sphere is obscured to mortals, also known as the Anticipation of Vivec. Unlike many other Daedric Princes, Mephala appears as either male or female depending on whom the Daedric Prince wishes to ensnare. Mephala's only consistent theme seems to be interference in the affairs of mortals for amusement. Mephala's sphere seems to indicate a careful plan carried out through executions, each life a portion of a massive web. Mephala sees the affairs of mortals as a weave; pull but one thread and the whole thing unravels. The Dunmer associate Mephala with more simple concepts—lies, sex, and murder. Mephala directly helped to found the infamous cult of the Morag Tong, and they claim to murder for the daedra's glory. Some scholars also argue that when the Morag Tong was banished from the rest of Tamriel, they were allowed to continue to operate in Morrowind when they replaced their worship of Mephala with that of Vivec. As a reaction to this, the Dark Brotherhood was formed, being led by the mysterious Night Mother, who some insist is just another form of Mephala. \n\nBonus to Mysticism (+5), Illusion (+5), Sneak (+5) and Short Blade (+5) is bestowed upon followers of Mephala."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion,
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism,
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak,
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.shortBlade,
            value = 5
        })
    end,
}

--MERIDIA
this.meridia = {
    id = "meridia",
    name = "Meridia",
    description = (
        "Lady of Light - is a Daedric Prince, associated with the energies of living things. Meridia has a great and everlasting hatred for the undead and will greatly reward any who eliminate them from the world. Meridia is one of the few Daedric Princes who is usually not considered to be wholly evil. However, she is referred to as the Lady of Greed in the Iliac Bay area, and is known to collect human specimens. \n\nBonus to Illusion (+10) and Restoration (+10) is bestowed upon followers of Meridia, but they have troubles with learning Conjuration magic."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion,
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.restoration,
            value = 10
        })
		tes3.setStatistic({
			reference = tes3.player,
			skill = tes3.skill.conjuration,
			value = 0
		})
    end,
}

--MOLAG BAL
this.molagbal = {
    id = "molagbal",
    name = "Molag Bal",
    description = (
        "God of Schemes - is the Daedric Prince whose sphere is the domination and enslavement of mortals. His main desire is to harvest the souls of mortals and to bring them within his sway by spreading seeds of strife and discord in the mortal realms. To this end, he obsessively collects a great number of soul gems, and has even dragged pieces of Nirn into his realm to satisfy his insatiable desire for conquest. The more souls he collects, the more he wants. Molag Bal values patience and cunning. He does not hesitate to deceive those he deals with, and is capable of waiting exceedingly long periods of time to carry out the schemes he prepares. He also takes great pleasure in the suffering of mortals, and often has them tortured for his amusement. The Prince has a penchance for necromancy, often employing the use of the risen dead and forcing his followers to serve beyond the grave. He is intimately familiar with death and is capable of preserving live mortals for extended periods of time to prolong their suffering. \n\nBonus to Mysticism (+5), Conjuration (+5) and Blunt Weapon (+10) is bestowed upon followers of Molag Bal."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.bluntWeapon,
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism,
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration,
            value = 5
        })
    end,
}

--MORIHAUS
this.morihaus = {
    id = "morihaus",
    name = "Morihaus",
    description = (
        "First Breath of Man - Ancient cultural hero god of the Cyro-Nordics. Legend portrays him as the Taker of the Citadel, an act of mythic times that established Human control over the Valley Heartland. He is often associated with the Nordic powers of thu'um, and therefore with Kynareth. \n\nMorihaus is sometimes venerated by Cyrodiils. \n\nAbility to Resist Magicka (10%) is bestowed upon followers of Morihaus."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Morihaus"
        }
    end,
}

--NAMIRA
this.namira = {
    id = "namira",
    name = "Namira",
    description = (
        "Lady of Decay - is a Daedric Prince whose sphere is the ancient Darkness. She is known as the Spirit Daedra, ruler of sundry dark and shadowy spirits, and is often associated with spiders, insects, slugs, and other repulsive creatures which inspire mortals with an instinctive revulsion. Namira also appears to be associated with beggars and the beggaring gifts of disease, pity, and disregard. Namira and her shadowy endeavors are often recognized to bear some association with eternity. \n\nAbility to Reflect Spells (15%) is bestowed upon followers of Namira, but they suffer from Weakness to Common Diseases (10%) and Blind (20%)"
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Namira"
        }
    end,
}

--NOCTURNAL
this.nocturnal = {
    id = "nocturnal",
    name = "Nocturnal",
    description = (
        "Night Mistress - is a Daedric Prince, or 'Daedric Princess', whose sphere is the night and darkness. She is associated with, and often depicted alongside, jet-black ravens and crows, which are said to have the power of speech. \n\nBonus to Illusion (+10) and Security (+10) is bestowed upon followers of Nocturnal."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion,
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security,
            value = 10
        })
    end,
}

--ONSI
this.onsi = {
    id = "onsi",
    name = "Onsi",
    description = (
        "Boneshaver - Notable warrior god of the Yokudan Ra Gada, Onsi taught Mankind how to pull their knives into swords. \n\nOnsi is usually venerated by Redguards. \n\nBonus to Armorer (+10) and Long Blade (+10) is bestowed upon followers of Onsi."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer,
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade,
            value = 10
        })
    end,
}

--ANU and PADOMAY
this.anu = {
    id = "anupadomay",
    name = "Anu and Padomay",
    description = (
        "Anu The Everything and Padomay The Darkness - Anu is thought to be the quintessential form of Stasis, the anthropomorphization of one of the two primal forces. Anu is known to Redguards as Satak and to Khajiits as Ahnurr. Padomay is the quintessential form of change, the personification of the primordial force of chaos and change who dwells in the Void. Padomay is known to Redguards as Akel and to Khajiits as Fadomai. \n\nAnu and Padomay aren't actively worshiped. \n\nBonus to Luck (+10) is bestowed upon followers of Anu and Padomay."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = 10
        })
    end
}

--SITHIS
this.sithis = {
    id = "sithis",
    name = "Sithis",
    description = (
        "Sithis is a representation of the one primordial state of chaos. Sithis is most often associated with the Dark Brotherhood, an assassin organization dedicated to his worship. He is often associated with serpent-like imagery, and small aspects of Sithis have even been known to reveal themselves in the form of ghostly serpents. \n\nSithis is usually venerated by members of Dark Brotherhood. \n\nBonus to Short Blade (+10) and Sneak (+10) is bestowed upon followers of Sithis."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak,
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.shortBlade,
            value = 10
        })
    end,
}

--PERYITE
this.peryite = {
    id = "peryite",
    name = "Peryite",
    description = (
        "Taskmaster - is Daedric Prince whose sphere of influence includes tasks, natural order, and pestilence. Although he is typically depicted as a green four-legged dragon, Peryite is considered one of the weakest of the Princes. \n\nBonus to Health (+50) is bestowed upon followers of Peryite, but they suffer from Weakness to Common Diseases (200%) and Blight Diseases (100%)."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Peryite"
        }
		tes3.modStatistic{
			reference = tes3.player,
			name = 'health',
			value = 50
		}
    end,
}

--PHYNASTER
this.phynaster = {
    id = "phynaster",
    name = "Phynaster",
    description = (
        "The Guardian - Hero-god of the Summerset Isles, who taught the Altmer how to naturally live another hundred years by using a shorter walking stride. \n\nPhynaster is usually venerated by Altmers and Bretons. \n\nBonus to Health (+10) and Ability to Resist Poison (20%) is bestowed upon followers of Phynaster, but they suffer penalty to Speed (-10)"
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = -10
        })
        tes3.modStatistic{
			reference = tes3.player,
			name = 'health',
			value = 10
		}
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Phynaster"
        }
    end
}

--RAJHIN
this.rajhin = {
    id = "rajhin",
    name = "Rajhin",
    description = (
        "Footpad - Thief god of the Khajiiti, who grew up in the Black Kiergo section of Senchal. The most famous burglar in Elsweyr's history, Rajhin is said to have stolen a tattoo from the neck of Empress Kintyra as she slept. \n\nRajhin is usually venerated by Khajiits. \n\nBonus to Sneak (+5) and Security (+15) is bestowed upon followers of Rajhin."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak,
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security,
            value = 15
        })
    end,
}

--REMAN
this.reman = {
    id = "reman",
    name = "Reman",
    description = (
        "The Cyrodiil - Culture god-hero of the Second Empire, Reman was the greatest hero of the Akaviri Trouble. Indeed, he convinced the invaders to help him build his own empire, and conquered all of Tamriel except for Morrowind. He instituted the rites of becoming Emperor, which included the ritual geas to the Amulet of Kings, a soulgem of immense power. His Dynasty was ended by the Dunmeri Morag Tong at the end of the first era. \n\nReman is sometimes venerated by Cyrodiils. \n\nBonus to Personality (+10) is bestowed upon followers of Reman."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = 10
        })
    end,
}

--RIDDLE'THAR
this.riddlethar = {
    id = "riddlethar",
    name = "Riddle'Thar",
    description = (
        "Two-Moons Dance - The cosmic order deity of the Khajiiti, the Riddle'Thar was revealed to Elsweyr by the prophet Rid-Thar-ri'Datta, the Mane. The Riddle'Thar is more a set of guidelines by which to live than a single entity, but some of his avatars like to appear as humble messengers of the gods. Also known as the Sugar God. \n\nRiddle'Thar is usually venerated by Khajiits. \n\nBonus to weaponless combat (+20) is bestowed upon followers of Riddle'Thar."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.handToHand,
            value = 20
        })
    end,
}

--RUPTGA
this.ruptga = {
    id = "ruptga",
    name = "Ruptga",
    description = (
        "Tall Papa - Chief deity of the Yokudan pantheon. Ruptga, was the first god to figure out how to survive the Hunger of Satakal. Following his lead, the other gods learned the 'Walkabout', or a process by which they can persist beyond one lifetime. Tall Papa set the stars in the sky to show lesser spirits how to do this, too. When there were too many spirits to keep track of, though, Ruptga created a helper out the dead skin of past worlds, Sep, who later creates the world of mortals. \n\nRuptga is usually venerated by Redguards. \n\nBonus to Endurance (+20) is bestowed upon followers of Ruptga, but they suffer penalty to Luck (-10)"
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 20
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = -10
        })
    end,
}

--SANGUINE
this.sanguine = {
    id = "sanguine",
    name = "Sanguine",
    description = (
        "Sanguine is a Daedric Prince whose sphere is hedonistic revelry, debauchery, and passionate indulgences of darker natures. He is thought to control thousands of realms. \n\nBonus to Personality (+10) and Conjuration (+20) is bestowed upon followers of Sanguine, but they suffer penalty to Intelligence (-10)"
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration,
            value = 20
        })
    end,
}

--SATAKAL
this.satakal = {
    id = "satakal",
    name = "Satakal",
    description = (
        "The Worldskin - Yokudan god of everything. A fusion of the concepts of Anu and Padomay. Basically, Satakal is much like the Nordic Alduin, who destroys one world to begin the next. In Yokudan mythology, Satakal had done (and still does) this many times over, a cycle which prompted the birth of spirits that could survive the transition. These spirits ultimately become the Yokudan pantheon. Popular god of the Alik'r nomads. \n\nSatakal is usually venerated by Redguards. \n\nBonus to Fatigue (+20) is bestowed upon followers of Satakal." --Run out of ideas completely
    ),
    doOnce = function()
        tes3.modStatistic{
			reference = tes3.player,
			name = 'fatigue',
			value = 20
		}
    end,
}

--SHEOGORATH
this.sheogorath = {
    id = "sheogorath",
    name = "Sheogorath",
    description = (
        "The Mad God - is the Daedric Prince of Madness, Fourth Corner of the House of Troubles, the Skooma Cat, Lord of the Never-There, and Sovereign of the Shivering Isles. His realm has also been called the Madhouse. It's believed that those who go there lose their sanity forever. Of course, only the Mad God himself may decide who has the privilege to enter. The Golden Saints, or Aureals, and Dark Seducers, or Mazken, are his servants. The Mad God typically manifests on Nirn as a seemingly harmless, well-dressed man often carrying a cane, a guise so prevalent it has actually been coined 'Gentleman With a Cane'. 'Fearful obeisance' of Sheogorath is widespread in Tamriel, and he plays an important part in Dunmeri religious practice. \n\nBonus to Maximum Magicka (+20%) and random Attributes is bestowed upon followers of Sheogorath, but they suffer from Madness and penalty to random Attributes."
    ),
    doOnce = function()
		local madC = math.random(-5, 5)
		local madM = math.random(-5, 5)
		local madT = math.random(-5, 5)
		local madB = math.random(-5, 5)
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = (madC - madB)
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = (-madC - madC)
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = (madM + madM)
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = (-madM + madB)
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = (madT + madC)
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = (-madT - madT)
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = (madB + madT)
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = (-madB - madM)
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Sheogorath"
        }
    end,
}

--SOTHA SIL
this.sothasil = {
    id = "sothasil",
    name = "Sotha Sil",
    description = (
        "Mystery of Morrowind - God of the Dunmer, Sotha Sil is the least known of the divine Tribunal. He is said to be reshaping the world from his hidden, Clockwork City. \n\nSotha Sil is usually venerated by Dunmers. \n\nBonus to Intelligence (+5) and Enchant (+10) is bestowed upon followers of Sotha Sil."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant,
            value = 10
        })
    end
}

--STENDARR
this.stendarr = {
    id = "stendarr",
    name = "Stendarr",
    description = (
        "God of Mercy - God of the Nine Divines, Stendarr has evolved from his Nordic origins into a deity of compassion or, sometimes, righteous rule. He is said to have accompanied Tiber Septim in his later years. In early Altmeri legends, Stendarr is the apologist of Men. \n\nStendarr is usually venerated by Cyrodiils, Bretons, Altmers and Bosmers. \n\nBonus to Endurance (+5), Block (+5) and Blunt Weapon (+5) is bestowed upon followers of Stendarr."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.block,
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.bluntWeapon,
            value = 5
        })
    end,
}

--S'RENDARR
this.srendarr = {
    id = "srendarr",
    name = "S'rendarr",
    description = (
        "The Runt - S'rendarr is Khajiiti god of mercy, compassion, charity, and justice. \n\nS'rendarr is usually venerated by Khajiits. \n\nBonus to Unarmored (+10) and Personality (+5) is bestowed upon followers of S'rendarr."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.unarmored,
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = 5
        })
    end,
}

--STUHN
this.stuhn = {
    id = "stuhn",
    name = "Stuhn",
    description = (
        "God of Ransom - Nordic precursor to Stendarr, brother of Tsun. Shield-thane of Shor, Stuhn was a warrior god that fought against the Aldmeri pantheon. He showed Men how to take, and the benefits of taking, prisoners of war. \n\nStuhn is usually venerated by Nords. \n\nBonus to Strength (+5) and Speeechraft (+10) is bestowed upon followers of Stuhn."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft,
            value = 10
        })
    end,
}

--SYRABANE
this.syrabane = {
    id = "syrabane",
    name = "Syrabane",
    description = (
        "Warlock's God - An Aldmeri god-ancestor of magic, Syrabane aided Bendu Olo in the Fall of the Sload. Through judicious use of his magical ring, Syrabane saved many from the scourge of the Thrassian Plague. He is also called the Apprentices' God, for he is a favorite of the younger members of the Mages Guild. \n\nSyrabane is usually venerated by Altmers. \n\nBonus to Speed (+5) and Enchant (+10) is bestowed upon followers of Syrabane."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant,
            value = 10
        })
    end,
}

--TALOS
this.talos = {
    id = "talos",
    name = "Talos",
    description = (
        "The Dragonborn - Heir to the Seat of Sundered Kings, Tiber Septim is the most important hero-god of Mankind. He conquered all of Tamriel and ushered in the Third Era. Also called Ysmir, 'Dragon of the North'. He withstood the power of the Greybeards' voices long enough to hear their prophecy. Later, many Nords could not look on him without seeing a dragon. \n\nTalos is usually venerated by Cyrodiils and Nords. \n\nBonus to Endurance (+5) and Attack (+5) is bestowed upon followers of Talos."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 5
        })
		mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Talos"
        }
    end,
}

--VAERMINA
this.vaermina = {
    id = "vaermina",
    name = "Vaermina",
    description = (
        "Prince of Dreams and Nightmares - is a Daedric Prince whose sphere is the realm of dreams and nightmares, and from whose realm evil omens issue forth. She is considered one of the more 'demonic' Daedra, in that she is destructive for the sake of causing destruction; her method being 'torture'. Vaermina's plane of Oblivion is Quagmire, described by observers as a 'nightmarish land'. It is said Vaermina hungers for the memories of mortals, collecting them from her citadel at the center of the realm, and leaves behind 'visions of horror and despair'. It is not known what Vaermina does with these memories, but it is assumed to be malevolent. \n\nBonus to Illusion (+10) and Alchemy (+10) is bestowed upon followers of Vaermina."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.illusion,
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy,
            value = 10
        })
    end,
}

--VIVEC
this.vivec = {
    id = "vivec",
    name = "Vivec",
    description = (
        "Master of Morrowind - is the Guardian Warrior-Poet God-King of the holy land of Vvardenfell, and ever-vigilant protector from the dark gods of the Red Mountain, the gate to hell. \n\nVivec is usually venerated by Dunmers. \n\nBonus to Attack (+5) and Luck (+5) is bestowed upon followers of Vivec."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = 5
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Vivec"
        }
    end
}

--Y'FFRE
this.yffre = {
    id = "yffre",
    name = "Y'ffre",
    description = (
        "God of the Forest - Most important deity of the Bosmeri pantheon. While Auri-El Time Dragon might be the king of the gods, the Bosmer revere Y'ffre as the spirit of 'the now'. According to the Wood Elves, after the creation of the mortal plane everything was in chaos. The first mortals were turning into plants and animals and back again. Then Y'ffre transformed himself into the first of the Ehlnofey, or 'Earth Bones'. After these laws of nature were established, mortals had a semblance of safety in the new world, because they could finally understand it. Y'ffre is sometimes called the Storyteller, for the lessons he taught the first Bosmer. Some Bosmer still possess the knowledge of the chaos times, which they can use to great effect. \n\nY'ffre is usually venerated by Bosmers, Altmers and Bretons. \n\nAbility to Resist Poison (20%) and Resist Common Diseases (25%) is bestowed upon followers of Y'ffre."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Yffre"
        }
    end,
}

--Y'FFER
this.yffer = {
    id = "yffer",
    name = "Y'ffer",
    description = (
        "The Elden Shaper - is the Khajiiti analogue of Y'ffre, and one of the Bastard Sons of Ahnurr. He was said to be 'wise and kind', and created the first flower in order to convince Nirni to be his mate. Y'ffer made the forest people Elves always and never beasts. And Y'ffer named them Bosmer. And from that moment they were no longer in the same litter as the Khajiit. \n\nY'ffer is sometimes venerated by Khajiits. \n\nBonus to Intelligence (+5) and Personality (+5) is bestowed upon followers of Y'ffer."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = 5
        })
    end,
}

--ZENITHAR
this.zenithar = {
    id = "zenithar",
    name = "Zenithar",
    description = (
        "God of Work and Commerce - Member of the Nine Divines, Zenithar is understandably associated with Z'en. In the Empire, however, he is a far more cultivated god of merchants and middle nobility. His worshippers say, despite his mysterious origins, Zenithar is the god 'that will always win'. \n\nZenithar is usually venerated by Cyrodiils and Bretons. \n\nBonus to Mercantile (+20) is bestowed upon followers of Zenithar."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile,
            value = 20
        })
    end,
}

--TSUN
this.tsun = {
    id = "tsun",
    name = "Tsun",
    description = (
        "God of Trials against Adversity - He died defending Shor from foreign gods. Tsun and his brother Stuhn were both Shield-thanes of Shor. He currently guards the Whalebone Bridge to the Hall of Valor of Sovngarde. At Shor's bidding, he has taken on the role of the master of trials, asking new arrivals to the utopia to prove their strength in combat against him before they can enter the Hall. \n\nTsun is usually venerated by Nords. \n\nBonus to Endurance (+5) and Axe (+10) is bestowed upon followers of Tsun."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.axe,
            value = 10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 5
        })
    end,
}

--Z'EN
this.zen = {
    id = "zen",
    name = "Z'en",
    description = (
        "God of Toil - Bosmeri god of payment in kind. Studies indicate origins in both Argonian and Akaviri mythologies, perhaps introduced into Valenwood by Kothringi sailors. Ostensibly an agriculture deity, Z'en sometimes proves to be an entity of a much higher cosmic order. His worship has all but died out shortly after the Knahaten Flu. \n\nZ'en is sometimes venerated by Bosmers and Argonians. \n\nBonus to Endurance (+5), Speechcraft (+5) and Alchemy (+10) is bestowed upon followers of Z'en."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft,
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alchemy,
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance, 
            value = 5
        })
    end,
}

--ZEHT
this.zeht = {
    id = "zeht",
    name = "Zeht",
    description = (
        "God of Farms - Yokudan god of agriculture. Renounced his father after the world was created, which is why Ruptga makes it so hard to grow food. \n\nZeht is usually venerated by Redguards. \n\nAbility to Resist Poison (10%), Resist Common Diseases (10%) and Bonus to Strength (+5) is bestowed upon followers of Zeht."
    ),
    doOnce = function()
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "MTR_ByTheDivines_Zeht"
        }
		tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
    end,
}

--GOD OF WORMS
this.godofworms = {
    id = "godofworms",
    name = "God of Worms",
    description = (
        "Mannimarco, an Altmer lich, is the leader of the Order of the Black Worm and an enemy of the Mages Guild. He is described as 'world's first of the undying liches', despite the fact that there had been many immortal liches before him. \n\nGod of Worms is sometimes venerated by Necromancers. \n\nBonus to Conjuration (+30) is bestowed upon followers of God of Worms, but they suffer a penalty to Personality (-5)."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration,
            value = 30
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
    end,
}

--EBONARM
this.ebonarm = {
    id = "ebonarm",
    name = "Ebonarm",
    description = (
        "The God of War - is companion and protector of all warriors. He is said to ride a golden stallion named War Master, and is accompanied by a pair of huge Ravens. Ebonarm's name refers to the Ebony sword fused to his right arm, a result of the wounds he suffered in titanic battles of the past, and he is never seen without a full suit of ebony armor. He is described as bearded, tall and muscular, and as having flowing reddish blonde hair and steel blue eyes. Emblazoned on his ebony tower shield is the symbol of a red rose, a flower known for blooming on battlefields where he appears. According to legend, he appears on the field of battle to reconcile opposing sides and prevent bloodshed. He's an enemy of all Daedric Princes except Sheogorath aswell as Stendarr and Mages Guild. \n\nEbonarm is sometimes venerated by members of Fighters Guild. \n\nBonus to Strength (+5) and Speechcraft (+10) is bestowed upon followers of Ebonarm."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft,
            value = 10
        })
    end,
}

--THE HIST
this.thehist = {
    id = "thehist",
    name = "The Hist",
    description = (
        "The Hist are a species of giant spore trees growing in the innermost swamps of Black Marsh. Argonians are known to have deep connections with the Hist, calling themselves 'people of the root', and licking the leaking sap of their trunks in religious rites. Others claim the trees are, in fact, a sentient race, more ancient than all the races of man and mer. \n\nThe Hist are usually venerated by Argonians. \n\nBonus to Alteration (+5), Mysticism (+5), Spear (+5) and Unarmored (+5) is bestowed upon followers of the Hist."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.alteration,
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mysticism,
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear,
            value = 5
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.unarmored,
            value = 5
        })
    end,
}

--THE OLD WAYS
this.theoldways = {
    id = "theoldways",
    name = "The Old Ways",
    description = (
        "Student of The Old Ways recognizes that so-called gods are no more than the spirits of superior men and women whose power and passion granted them great influence in the afterworld. Faithful to The Old Ways know it is essential always to remember the spiritual world while keeping eyes open in the physical one. A student of The Old Ways may indeed ally himself to a lord -- but it is a risky relationship. Individuals following The Old Ways are sometimes euphemistically called worshippers of The Gods of Reason and Logic. \n\nBonus to Intelligence (+20) is bestowed upon followers of The Old Ways, but they suffer penalty to Personality (-5) and Luck (-5)"
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = 20
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.luck, 
            value = -5
        })
    end,
}

--IDEAL MASTERS
this.idealmasters = {
    id = "idealmasters",
    name = "Ideal Masters",
    description = (
        "Ideal Masters are the malevolent beings that rule the realm of Oblivion known as the Soul Cairn. Typically, they do not physically manifest themselves in the realm, instead preferring a type of omnipresence; however, Ideal Masters have been known to take the form resembling a soul gem, which can be used as a conduit through which the individual can communicate or drain the life essence of an approaching mortal. The Ideal Masters eternally seek souls to bring to the realm, where they become eternally trapped. The Masters view this as peaceful eternal life, although the undead who reside there view it as a curse. Individual Masters have names, so exalted that they cannot be spoken. They call themselves the Makers of the Soul Cairn, and were once mortals themselves. \n\nBonus to Enchant (+10) and Conjuration (+10) is bestowed upon followers of Ideal Masters."
    ),
    doOnce = function()
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant,
            value = 10
        })
		tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.conjuration,
            value = 10
        })
    end,
}

-- Here could be "gods" from earlier games like Arius, Ius, Notorgo, Druagaa, Ephen, Jhim Sei, Shagrath, Sai, etc.,
-- but most of them lack any information about them and adding only few selected ones would be counterproductive. All or none. :)

return this