local messages = {}

messages.potion = "A concoction has found its way into your inventory."
messages.ingredient = "A distinct ingredient has made its way into your collection."
messages.scroll = "A written enchantment now resides within your possession."

messages.healedVital = "A revitalizing surge courses through your veins."
messages.damagedVital = "Your vital energies falter."

messages.spellFeather = "A weightless sensation envelops you."
messages.spellBurden = "The weight upon your shoulders increases."

messages.unlocked = "The lock gives in and dissipates."
messages.lockedLess = "The lock's defenses falter."
messages.lockedMore = "The lock's resistance intensifies."

messages.bountyMore = "Your reputation as a troublemaker spreads."
messages.bountyLess = "The weight of your transgressions lessens."
messages.bountyTeleport = "You find yourself in a new location, where a Guild comrade can help with your bounty."

messages.templeTeleport = "Almsivi's touch guides your steps to a nearby temple."
messages.cultTeleport = "By the will of the Divines, a shrine opens its doors to you."

messages.diseaseCured = "As you breathe in the fresh air, the taint of your illness is banished."
messages.blightCured = "An aura of purification surrounds you, dispelling the blight's corruption."

messages.diseaseContracted = "Your body betrays you as it succumbs to the grasp of a relentless sickness."
messages.blightContracted = "The tendrils of the Blight slither through your veins."

messages.spellPoison = "Poisonous fumes envelop you."
messages.poisonCured = "The magical aura surrounding you acts as a potent antidote."

messages.underwaterBoon = "The aquatic realm becomes your domain."

messages.teleportOutside = "You find yourself whisked away from the chaos of battle."

messages.calmHostiles = "A tranquil hush settles upon your foes."
messages.frenzyHostiles = "The minds of your foes are engulfed in frenzied turmoil."

messages.sanctuary = "You are enveloped in a sanctuary of tranquility, guarded against the onslaught of adversity."
messages.chameleon = "Your presence becomes elusive, merging effortlessly into the tapestry of the world."
messages.invisibility = "A shroud of unseen energies cloaks your form, rendering you invisible to the world."

messages.disintegrateArmor = "Your armor suffers severe damage, its protective properties weakened."
messages.disintegrateWeapon = "Your weapon sustains significant damage, its effectiveness compromised."

messages.killHostiles = "Through mystical ways, your adversaries drop to the ground before you."
messages.damageHostiles = "Your foes vital energy crumbles as they weaken."

messages.luckIncreased = "Fortune smiles upon you, bestowing an increase in luck."

messages.scribSummoned = "A friendly scrib appears, scuttling about with curiosity and a hint of mischief."
messages.scribSummonedHostile = "Beware! A colossal scrib emerges, ready to unleash its fury."

messages.teleportRandom = "You find yourself in a completely new location."

messages.aleaInactive = "Alepsychon seems drained of any magical essence."

messages.luckyContainer = "You have a feeling you will find something interesting soon..."
messages.luckyContainerOpened = "There it is!"

messages.alchemyBoon = "Your alchemical prowess surges, empowering your concoctions."
messages.alchemyFail = "Your alchemical knowledge falters, hindering your potion-making abilities."

messages.personalityBoon = "A radiant charm envelops you, enhancing your charisma."
messages.personalityFail = "A cloud of negativity engulfs your presence, eroding your charm."

messages.barterBoon = "Your knack for commerce grows, enhancing your mercantile skill."
messages.barterFail = "Misfortune befalls your trade ventures, lowering your mercantile skill."

messages.flungedAir =  "You find yourself flunged high up into the air."
messages.flungedOutside = "You are magically teleported outside."

messages.preventEquip = function(item) return string.format("Whoops! Your lack of coordination causes %s to slip through your fingers.", item) end
messages.clumsy = "You can't seem to shake off the aura of clumsiness that surrounds you."

messages.flies = "A vexing buzzing fills the air, as if a thousand flies have taken residence all around you."

return messages