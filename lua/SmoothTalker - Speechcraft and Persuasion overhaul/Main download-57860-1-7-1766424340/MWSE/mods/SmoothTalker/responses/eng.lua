-- Response database for persuasion actions
-- Structure: action -> outcome -> category -> tier -> array of responses
-- Categories: generic, faction_*, race_*, class_* (extensible for future customization)

local responses = {
	admire = {
		success = {
			generic = {
				high = {
					"Why, thank you! I do try my best.",
					"I appreciate you noticing!",
					"That's very kind of you to say.",
					"Well, I do what I can.",
					"You're too generous!",
					"I'm glad you think so!",
					"What a kind thing to say!",
					"That means a lot, thank you.",
					"I'm honored you'd say that.",
					"It's nice to be appreciated!",
				},
				medium = {
					"Well... I suppose I do alright.",
					"I try, at least.",
					"Thanks, I guess.",
					"That's... good to hear.",
					"Hmm. I appreciate that.",
					"Well, thank you.",
					"I'll take it.",
					"Fair enough.",
					"I suppose so, yes.",
					"That's decent of you to say.",
				},
				low = {
					"I... well, I do my best, I suppose.",
					"Hmph. About time someone noticed.",
					"...If you say so.",
					"Well... I suppose that's true.",
					"Hmm. I guess.",
					"...Alright then.",
					"I suppose... yes.",
					"Well... thank you. I think.",
					"Hmph. I'll accept that.",
					"...Fair enough, I suppose.",
				}
			},
			-- Race: Dunmer
			race_dunmer = {
				high = {
					"Why, thank you, sera. The Three have blessed me, it's true.",
					"I do take pride in upholding our traditions.",
					"You're too kind. For an outlander.",
					"I appreciate that you recognize quality when you see it.",
					"Indeed. Our ways are superior, after all.",
					"A perceptive observation, sera.",
				},
				medium = {
					"Well... I suppose that's true enough.",
					"I do what I can, sera.",
					"Hmm. Perhaps you're not entirely blind.",
					"Fair enough, outlander.",
					"I'll accept that.",
					"You show some sense, at least.",
				},
				low = {
					"I... well, even outlanders can see the obvious, I suppose.",
					"Hmph. About time you noticed.",
					"...I'll accept that, fetcher.",
					"Well... I suppose that's accurate.",
					"Finally, some recognition.",
					"Hmph. I suppose so.",
				}
			},
			-- Race: Khajiit
			race_khajiit = {
				high = {
					"This one is grateful for such kind words!",
					"Ah, you make this one's heart warm, walker!",
					"May your roads lead to warm sands for such sweetness!",
					"This one does try! Thank you, friend!",
					"You honor this one greatly!",
					"This one's tail swells with pride!",
				},
				medium = {
					"This one appreciates the kind words.",
					"Warm sands, walker. This one thanks you.",
					"That is pleasant to hear.",
					"This one is glad you think so.",
					"This one accepts with gratitude.",
					"Kind of you to say, walker.",
				},
				low = {
					"Hmm. This one... supposes that's true.",
					"Well. This one will accept that.",
					"...If walker says so.",
					"This one... thanks you. Perhaps.",
					"This one is... flattered. Somewhat.",
					"Hmph. If you say so, walker.",
				}
			},
			-- Class: Guard
			class_guard = {
				high = {
					"Well... thank you, citizen. I do my best.",
					"That's kind of you. Not many appreciate what we do.",
					"I appreciate that. Really.",
					"That means something. Thank you.",
					"Good to hear, citizen. Good to hear.",
					"Thank you. Keeps the job worthwhile.",
				},
				medium = {
					"Citizen.",
					"Hmm. Thanks.",
					"Appreciated.",
					"Fair enough.",
					"Noted.",
					"I suppose. Carry on.",
				},
				low = {
					"I... well, I try, citizen.",
					"Hmm. If you say so. Move along.",
					"I suppose. Carry on.",
					"...Right. Move along, citizen.",
					"Well... thanks. I guess.",
					"Hmph. If you say so.",
				}
			},
			-- Class: Ordinator
			class_ordinator = {
				high = {
					"The Three guide my hand. I am but their instrument.",
					"I serve the Tribunal with all my being. Thank you.",
					"Such words honor the Temple I serve.",
					"The Tribunal is my strength. I am grateful.",
					"May the Three bless you for your kind words.",
				},
				medium = {
					"The Temple appreciates your respect.",
					"I do my duty. That is all.",
					"Hmm. Proceed.",
					"The Ordinators acknowledge this.",
					"Fair words, sera.",
				},
				low = {
					"I... serve the Three as best I can.",
					"The Tribunal expects much. I try.",
					"Hmph. Move along, outlander.",
					"I do what the Temple requires.",
					"...The Three guide me. Move along.",
				}
			},
			-- Faction: Imperial Legion
			faction_imperial_legion = {
				high = {
					"Thank you, citizen. The Legion trains us well.",
					"I appreciate that. We serve the Empire with honor.",
					"Kind words. The discipline of the Legion shows, I suppose.",
					"The Empire breeds excellence. Thank you.",
					"For the glory of the Empire. I'm honored.",
				},
				medium = {
					"Noted, citizen.",
					"I do my duty.",
					"Fair enough. Carry on.",
					"The Legion appreciates that.",
					"Acknowledged.",
				},
				low = {
					"I... suppose I do my job adequately.",
					"The Legion expects competence. I deliver.",
					"...Very well. Move along.",
					"Hmm. I do what's required.",
					"The Empire demands much. I try.",
				}
			},
			-- Faction: Thieves Guild
			faction_thieves_guild = {
				high = {
					"Heh, I do have my talents. Thanks for noticing.",
					"Well, the guild doesn't recruit amateurs. I do alright.",
				},
				medium = {
					"I suppose I'm decent at what I do.",
					"Takes one to know one, eh?",
				},
				low = {
					"I... well, I've got some skill, sure.",
					"Alright, alright. I'll take it.",
				}
			}
		},
		failure = {
			generic = {
				depleted = {
					"I've had enough of your words.",
					"Leave me be. I'm done listening to you.",
					"Not now. I need some time away from you.",
					"Enough! I don't want to hear from you anymore!",
					"Stop. Just... stop talking to me.",
					"I can't stand to hear another word from you.",
					"Go away. I'm done with this.",
					"That's it. I'm done listening.",
				},
				high = {
					"That's... rather overstated, don't you think?",
					"I'm not THAT impressive.",
					"Oh, come now. That's laying it on thick.",
					"Let's not get carried away here.",
					"Bit excessive, that.",
					"I appreciate the sentiment, but really...",
				},
				medium = {
					"I don't know about that.",
					"That seems a bit much.",
					"I wouldn't go that far.",
					"Hardly.",
					"That's debatable.",
					"Save your breath.",
				},
				low = {
					"Oh, please.",
					"I'm not an idiot.",
					"Do you think I'm stupid?",
					"That's absurd.",
					"What nonsense.",
					"Don't mock me.",
				}
			},
			-- Race: Dunmer
			race_dunmer = {
				high = {
					"For a Dunmer? Perhaps. For an outlander like you? Hardly.",
					"I'm well aware of my qualities, sera. No need to exaggerate.",
					"Flattery from an outlander? How... transparent.",
					"Such praise is more than you deserve to give, fetcher.",
				},
				medium = {
					"That's laying it on a bit thick, outlander.",
					"Careful now. I'm not THAT vain.",
					"A bit much, don't you think?",
					"Excessive, sera.",
				},
				low = {
					"Don't mock me, n'wah!",
					"Save your breath, fetcher!",
					"Are you mocking a Dunmer?!",
					"Enough of your s'wit nonsense!",
				}
			},
			-- Race: Khajiit
			race_khajiit = {
				high = {
					"This one knows such praise, but from you? This one doubts.",
					"Warm words, walker, but this one is not so easily swayed.",
					"Sweet words, but this one knows better.",
					"This one has heard such things before, walker.",
				},
				medium = {
					"This one has heard sweeter words before.",
					"Perhaps, but this one doubts your sincerity.",
					"Laying it on thick, walker.",
					"This one thinks you exaggerate.",
				},
				low = {
					"Bah! This one is no fool, walker.",
					"Do you take this one for a simpleton?",
					"Mock this one? Bad idea, walker.",
					"This one does not appreciate such mockery!",
				}
			},
			-- Class: Guard
			class_guard = {
				high = {
					"I'm just doing my job, citizen.",
					"That's... a bit much. I'm no hero.",
					"Easy now. I'm just a guard.",
					"Let's not exaggerate, citizen.",
				},
				medium = {
					"Move along, citizen.",
					"Hardly.",
					"Save it.",
					"Enough of that.",
				},
				low = {
					"Are you mocking me?",
					"Watch yourself, citizen.",
					"That's crossing a line.",
					"Don't test me.",
				}
			},
			-- Class: Ordinator
			class_ordinator = {
				high = {
					"The Three deserve such praise. Not I.",
					"I am but a humble servant of the Tribunal.",
					"Save such words for the Temple itself.",
					"The Tribunal is worthy. I am merely a tool.",
				},
				medium = {
					"Excessive, outlander.",
					"Keep such words for the Temple itself.",
					"Too much, sera.",
					"I am unworthy of such praise.",
				},
				low = {
					"Blasphemous exaggeration!",
					"Do not mock a servant of the Three!",
					"This borders on heresy!",
					"Silence your tongue!",
				}
			},
			-- Faction: Imperial Legion
			faction_imperial_legion = {
				high = {
					"The Legion doesn't need compliments, citizen. We need discipline.",
					"I serve the Empire. That's all that matters.",
					"Save such words for the brass.",
					"I'm a soldier, not a hero.",
				},
				medium = {
					"Save it for the recruiting officer.",
					"I'm not interested in praise.",
					"Enough, citizen.",
					"I do my duty. That's all.",
				},
				low = {
					"Don't waste my time.",
					"Enough. Dismissed.",
					"Move along.",
					"Stop wasting my time, citizen.",
				}
			}
		}
	},
	intimidate = {
		success = {
			generic = {
				high = {
					"Perhaps... we don't need to take this further.",
					"I'd rather avoid trouble.",
					"Very well. Let's not escalate this.",
					"Alright. I'll cooperate.",
					"No need for violence. I understand.",
					"Fine. I'll do what you want.",
				},
				medium = {
					"Alright, alright! Easy!",
					"Okay, I get it!",
					"Fine. I hear you.",
					"Okay, okay! I understand!",
					"No need to get rough!",
					"Alright! I'll cooperate!",
				},
				low = {
					"Fine! What do you want?!",
					"I... I'll do it!",
					"Alright! Just don't hurt me!",
					"Please! I'll cooperate!",
					"Mercy! I yield!",
					"Okay! Okay! Whatever you say!",
				}
			},
			-- Race: Dunmer
			race_dunmer = {
				high = {
					"Perhaps... it would be unwise to push this further.",
					"I... will not oppose you in this, sera.",
					"Very well. I see reason in backing down.",
					"Fine. I'll cooperate this once.",
				},
				medium = {
					"Very well. I'll comply.",
					"Alright, outlander. You win.",
					"Fine. I'll do as you ask.",
					"I yield. This time.",
				},
				low = {
					"Fine! What do you want from me?!",
					"I yield! Don't hurt me!",
					"Alright! Please! Mercy!",
					"I'll cooperate! Just... please!",
				}
			},
			-- Race: Khajiit
			race_khajiit = {
				high = {
					"This one thinks... yes, this one will cooperate.",
					"Perhaps it is better to avoid conflict, yes?",
					"This one sees wisdom in peace.",
					"Very well, walker. This one yields.",
				},
				medium = {
					"Alright, alright. This one will do as you ask.",
					"No need for violence. This one cooperates.",
					"Fine, fine. This one hears you.",
					"This one will comply, walker.",
				},
				low = {
					"Please! This one has kittens to feed!",
					"Mercy! This one will do anything you ask!",
					"Don't hurt this one! Please!",
					"This one yields! Mercy, walker!",
				}
			},
			-- Class: Guard
			class_guard = {
				high = {
					"Easy there, citizen. Let's keep this civil.",
					"No need for that. I'll... look the other way.",
					"Alright. I didn't see anything.",
					"We can work this out. No problem.",
				},
				medium = {
					"Alright! I get it!",
					"Fine, citizen. Fine.",
					"Okay! I'll cooperate!",
					"Easy! I understand!",
				},
				low = {
					"Fine! Just... just don't do anything crazy!",
					"Okay! I'll let it slide!",
					"Please! I'll look away!",
					"Don't hurt me! I'll cooperate!",
				}
			},
			-- Class: Ordinator
			class_ordinator = {
				high = {
					"The Temple... values peace. I will stand down.",
					"Very well. I will not interfere.",
					"The Three teach wisdom. I concede.",
					"Peace, then. The Temple permits this.",
				},
				medium = {
					"Very well. The Temple permits this.",
					"I... will allow it, sera.",
					"The Ordinators will overlook this.",
					"Fine. Go in peace.",
				},
				low = {
					"The Three teach mercy... I will spare you!",
					"...Fine. Go! Quickly!",
					"The Temple... yields. Go!",
					"Mercy! Leave now!",
				}
			},
			-- Faction: Imperial Legion
			faction_imperial_legion = {
				high = {
					"The Legion values pragmatism. I concede.",
					"Very well. I'll stand down.",
					"Discretion is wise. I'll cooperate.",
					"The Empire values reason. Fine.",
				},
				medium = {
					"Understood. I'll... overlook this.",
					"Fine, citizen.",
					"The Legion will permit this.",
					"Alright. I'll stand down.",
				},
				low = {
					"Fine! I'll cooperate!",
					"Alright! You win!",
					"Okay! I yield!",
					"Please! I'll let it go!",
				}
			}
		},
		failure = {
			generic = {
				depleted = {
					"I've heard enough from you!",
					"No. Leave me alone.",
					"Leave. Now.",
					"Get out!",
					"I'm done with you!",
					"Get out before I lose my temper!",
				},
				high = {
					"I'm not afraid of you.",
					"You don't scare me.",
					"I'm not backing down.",
					"I don't fear you.",
					"Go ahead. Try it.",
					"I'll take my chances.",
				},
				medium = {
					"That doesn't scare me.",
					"Is that all?",
					"I'm not intimidated.",
					"Really? That's it?",
					"I've faced worse.",
					"Try harder.",
				},
				low = {
					"Get out of my sight!",
					"How dare you!",
					"You'll regret this!",
					"Guards! GUARDS!",
					"You've made a terrible mistake!",
					"I'll have you arrested!",
				}
			},
			-- Race: Dunmer
			race_dunmer = {
				high = {
					"I'm a Dunmer in Morrowind. You have no power here.",
					"You forget where you are, outlander.",
					"This is MY land. Not yours.",
					"I fear no outlander.",
				},
				medium = {
					"Typical outlander. All noise.",
					"You think that frightens me?",
					"Weak threats from weak people.",
					"Pathetic, n'wah.",
				},
				low = {
					"Get out of Morrowind, n'wah!",
					"Touch me and die, s'wit!",
					"Try it, fetcher! I dare you!",
					"You'll regret those words!",
				}
			},
			-- Race: Khajiit
			race_khajiit = {
				high = {
					"This one does not fear you, walker.",
					"This one has survived far worse than you.",
					"This one has faced death before.",
					"Threats do not scare this one.",
				},
				medium = {
					"Empty words, walker.",
					"This one is unafraid.",
					"Meaningless threats.",
					"This one has heard worse.",
				},
				low = {
					"Try it, walker. See what happens!",
					"This one's claws are sharp!",
					"Come closer and find out!",
					"This one will fight back!",
				}
			},
			-- Class: Guard
			class_guard = {
				high = {
					"That's a crime, citizen. Watch yourself.",
					"Threatening a guard? You're in trouble now.",
					"You just made things worse for yourself.",
					"Bad move, citizen. Very bad move.",
				},
				medium = {
					"One more word and you're arrested.",
					"Don't push me, citizen.",
					"You're on thin ice.",
					"Watch it.",
				},
				low = {
					"That's it! Halt! Halt! Halt!",
					"You're under arrest!",
					"Stop right there!",
					"You're done, criminal!",
				}
			},
			-- Class: Ordinator
			class_ordinator = {
				high = {
					"The Three protect me. I fear nothing.",
					"You dare threaten a servant of the Tribunal? Fool.",
					"The Tribunal is my shield.",
					"I fear no mortal threat.",
				},
				medium = {
					"The Tribunal shields me from your threats.",
					"I am not afraid.",
					"Empty words before the Three.",
					"The Temple fears nothing.",
				},
				low = {
					"HERESY! You will die for this!",
					"The Temple will destroy you!",
					"The Three demand your death!",
					"Blasphemer! Face justice!",
				}
			},
			-- Faction: Imperial Legion
			faction_imperial_legion = {
				high = {
					"The Legion doesn't yield to threats, citizen.",
					"I've faced down Daedra. You're nothing.",
					"I'm a legionnaire. I fear no threats.",
					"The Empire doesn't negotiate with criminals.",
				},
				medium = {
					"Threatening a legionnaire? Bad idea.",
					"Watch yourself. That's a crime.",
					"You're making a mistake, citizen.",
					"The Legion doesn't back down.",
				},
				low = {
					"That's it. You're under arrest!",
					"You're going to the stockade!",
					"Stop right there!",
					"You just committed treason!",
				}
			}
		}
	},
	taunt = {
		success = {
			generic = {
				high = {
					"How dare you say that!",
					"You'll pay for those words!",
					"That's too far!",
					"You've gone too far!",
					"I won't tolerate this!",
					"You dare?!",
				},
				medium = {
					"Why you little...!",
					"That's it! I've had enough!",
					"I'll make you regret that!",
					"That does it!",
					"You're dead!",
					"You're asking for it!",
				},
				low = {
					"You want a fight?! You've got one!",
					"I'll kill you!",
					"Die!",
					"Face me!",
					"THAT'S IT!",
					"You're dead!",
				}
			},
			-- Race: Dunmer
			race_dunmer = {
				high = {
					"You dare say that to ME?! Prepare to die!",
					"Such insolence from an outlander! You die now!",
				},
				medium = {
					"That's it! I've had enough of you, outlander!",
					"Too far, n'wah! Too far!",
				},
				low = {
					"DIE, S'WIT!",
					"I'LL KILL YOU, N'WAH!",
				}
			},
			-- Race: Khajiit
			race_khajiit = {
				high = {
					"You dare say such things?! This one will claw you to pieces!",
					"Too much! This one will end you!",
				},
				medium = {
					"That is too far, walker! This one attacks!",
					"No more words! Claws speak now!",
				},
				low = {
					"This one will tear you apart!",
					"DIE!",
				}
			},
			-- Class: Guard
			class_guard = {
				high = {
					"That's assault on an officer! You're done!",
					"You just committed a crime, citizen!",
				},
				medium = {
					"That's it! You're under arrest!",
					"You've made a terrible mistake!",
				},
				low = {
					"HALT! HALT! HALT!",
					"DIE, SCUM!",
				}
			},
			-- Class: Ordinator
			class_ordinator = {
				high = {
					"Blasphemy! The Three will have your soul!",
					"You insult the Tribunal?! Death!",
				},
				medium = {
					"Heretic! Face divine wrath!",
					"The Temple will not stand for this!",
				},
				low = {
					"FOR THE TEMPLE!",
					"THE THREE DEMAND YOUR DEATH!",
				}
			},
			-- Faction: Imperial Legion
			faction_imperial_legion = {
				high = {
					"You insult the Empire?! Treason!",
					"That's sedition, citizen! Prepare to die!",
				},
				medium = {
					"That's treason! Face justice!",
					"The Legion will have your head!",
				},
				low = {
					"FOR THE EMPIRE!",
					"DEATH TO TRAITORS!",
				}
			}
		},
		failure = {
			generic = {
				depleted = {
					"Enough! I won't listen to another word!",
					"I'm done with you. Leave.",
					"Save your breath. I'm not interested.",
					"I'm finished here.",
					"Begone. You're wasting my time.",
					"Leave. Now.",
				},
				high = {
					"I've been called worse.",
					"That doesn't bother me.",
					"If you say so.",
					"Is that supposed to hurt?",
					"I've heard it all before.",
					"Amusing, but no.",
				},
				medium = {
					"And?",
					"So what?",
					"I don't care.",
					"Hardly.",
					"That's your opinion.",
					"Think what you like.",
				},
				low = {
					"Say that again and regret it.",
					"Get out of my sight.",
					"Leave before I lose my temper.",
					"You'll regret opening your mouth.",
					"Watch yourself.",
					"One more word...",
				}
			},
			-- Race: Dunmer
			race_dunmer = {
				high = {
					"I've heard worse from guar, outlander.",
					"Coming from the likes of you? I'll take it as a compliment.",
				},
				medium = {
					"Typical n'wah ignorance.",
					"Is that what passes for wit among outlanders?",
				},
				low = {
					"Begone, fetcher.",
					"Shut your mouth, s'wit.",
				}
			},
			-- Race: Khajiit
			race_khajiit = {
				high = {
					"This one has been called worse, walker.",
					"Such words do not trouble this one.",
				},
				medium = {
					"Hmm. This one is unimpressed.",
					"Your words are just noise, walker.",
				},
				low = {
					"Say that again, walker. This one dares you.",
					"Go away before claws teach you manners.",
				}
			},
			-- Class: Guard
			class_guard = {
				high = {
					"I've been called worse by better, citizen.",
					"Heard it all before. Move along.",
				},
				medium = {
					"Watch your tongue, citizen.",
					"Careful. That's bordering on a crime.",
				},
				low = {
					"One more word and you're arrested.",
					"Keep talking. See what happens.",
				}
			},
			-- Class: Ordinator
			class_ordinator = {
				high = {
					"The Three teach patience with fools.",
					"I am at peace with what I am.",
				},
				medium = {
					"Silence would better serve you, outlander.",
					"Careful. Such words approach heresy.",
				},
				low = {
					"One more word and the Temple will act.",
					"Leave. Now.",
				}
			},
			-- Faction: Imperial Legion
			faction_imperial_legion = {
				high = {
					"The Legion has heard worse from bandits.",
					"I've endured harsher words in the barracks.",
				},
				medium = {
					"Careful, citizen. That borders on sedition.",
					"Watch yourself.",
				},
				low = {
					"One more word and you're arrested.",
					"Keep talking, citizen. Please.",
				}
			}
		}
	},
	placate = {
		success = {
			generic = {
				high = {
					"You're right. I was being unreasonable.",
					"Alright. Let's forget this happened.",
					"I appreciate that. Thank you.",
					"Fair enough. I'll let it go.",
					"Very well. No hard feelings.",
					"Peace, then. I accept.",
				},
				medium = {
					"Fine. I'll let it go. This time.",
					"Alright, alright. I'll calm down.",
					"That's... fair, I suppose.",
					"Okay. We're good.",
					"Fair enough. I'll back off.",
					"Very well. Enough.",
				},
				low = {
					"...Fine. But I'm watching you.",
					"I'll back off... but this isn't forgotten.",
					"Lucky for you I'm feeling merciful.",
					"Hmph. Fine. This time.",
					"...I'll let it go. For now.",
					"Whatever. Just stay away from me.",
				}
			},
			-- Race: Dunmer
			race_dunmer = {
				high = {
					"Perhaps... that is fair, outlander.",
					"I will... accept that explanation. This time.",
				},
				medium = {
					"Very well. I will let this pass.",
					"Fine. I suppose that's reasonable, sera.",
				},
				low = {
					"Hmph. I suppose... that's acceptable.",
					"...Fine. But I won't forget this, outlander.",
				}
			},
			-- Race: Khajiit
			race_khajiit = {
				high = {
					"Ah... yes. This one understands now, walker.",
					"This one accepts. Peace between us.",
				},
				medium = {
					"Very well. This one will forgive.",
					"Alright. This one lets this pass.",
				},
				low = {
					"...Fine. This one relents.",
					"Hmph. This one accepts. But barely.",
				}
			},
			-- Class: Guard
			class_guard = {
				high = {
					"Alright, citizen. I'll overlook it this time.",
					"Fair enough. Keep the peace and we're fine.",
				},
				medium = {
					"Alright. I'll let this slide.",
					"Fine. But watch yourself.",
				},
				low = {
					"...This is your lucky day. Move along.",
					"Hmph. Fine. But I'm watching you, citizen.",
				}
			},
			-- Class: Ordinator
			class_ordinator = {
				high = {
					"The Three teach mercy. I will extend it.",
					"Very well. The Temple accepts. Go in peace.",
				},
				medium = {
					"The Ordinators will show clemency.",
					"The Three forgive... this time.",
				},
				low = {
					"...The Temple shows mercy. Do not abuse it.",
					"Hmph. The Three teach forgiveness. You are fortunate.",
				}
			},
			-- Faction: Imperial Legion
			faction_imperial_legion = {
				high = {
					"That's... reasonable. The Legion accepts.",
					"Fair enough. We'll stand down, citizen.",
				},
				medium = {
					"Acceptable. No bloodshed needed.",
					"The Legion can work with that.",
				},
				low = {
					"...Fine. But don't test us.",
					"This once. Don't make me regret this.",
				}
			}
		},
		failure = {
			generic = {
				depleted = {
					"I don't want to hear it!",
					"No! I'm done!",
					"Leave me be!",
					"It's too late for that!",
					"I won't hear another word!",
					"Enough!",
				},
				high = {
					"That doesn't help.",
					"I'm still angry.",
					"It's too late for that.",
					"No. I don't accept that.",
					"That changes nothing.",
					"We're past that point.",
				},
				medium = {
					"That's not enough.",
					"I'm not satisfied.",
					"Not good enough.",
					"That doesn't make it right.",
					"I don't believe you.",
					"Try harder.",
				},
				low = {
					"Don't you dare!",
					"That just makes me angrier!",
					"TOO LATE!",
					"It's beyond words now!",
					"No more talking!",
					"ENOUGH!",
				}
			},
			-- Race: Dunmer
			race_dunmer = {
				high = {
					"You've gone too far this time, outlander.",
					"It's too late for your smooth words.",
				},
				medium = {
					"No. This one won't stand.",
					"I'm past listening to you.",
				},
				low = {
					"Shut up, n'wah!",
					"Die, s'wit!",
				}
			},
			-- Race: Khajiit
			race_khajiit = {
				high = {
					"This one's anger burns too hot.",
					"It is too late, walker.",
				},
				medium = {
					"No. This one will not hear it.",
					"This one's patience is exhausted.",
				},
				low = {
					"Bah! Too late!",
					"Claws will answer you now!",
				}
			},
			-- Class: Guard
			class_guard = {
				high = {
					"It's past that point, citizen.",
					"You've crossed the line.",
				},
				medium = {
					"Too late. You're in trouble now.",
					"No. Face justice.",
				},
				low = {
					"Stop resisting!",
					"You're under arrest!",
				}
			},
			-- Class: Ordinator
			class_ordinator = {
				high = {
					"The damage is done.",
					"Your offense cannot be undone.",
				},
				medium = {
					"The Three demand justice.",
					"It is beyond mere words now.",
				},
				low = {
					"The Temple will be satisfied!",
					"Face judgment!",
				}
			},
			-- Faction: Imperial Legion
			faction_imperial_legion = {
				high = {
					"The line has been crossed, citizen.",
					"Too late for that.",
				},
				medium = {
					"You've made your choice.",
					"Justice must be served.",
				},
				low = {
					"Stand down!",
					"Face Imperial justice!",
				}
			}
		}
	},
	bond = {
		success = {
			generic = {
				high = {
					"You understand me in a way few others do.",
					"This means more to me than you know.",
					"I'm glad our paths have crossed.",
					"You're a true friend. Thank you.",
					"I value our connection deeply.",
					"It's rare to find someone like you.",
					"I'll remember this. Thank you.",
				},
				medium = {
					"I appreciate you taking the time to know me.",
					"That's... actually quite meaningful.",
					"I think we understand each other.",
					"This feels right, somehow.",
					"You're alright, you know that?",
					"I'm glad we've had this conversation.",
					"Thank you for listening.",
					"I don't often connect with people like this.",
					"That means something to me.",
					"I think we could be good friends.",
				},
				low = {
					"I... suppose that's nice to hear.",
					"Well... that's more than most people try.",
					"Hmm. Perhaps you're genuine.",
					"I'll... remember this.",
					"That's... actually kind of you.",
					"Well. I appreciate the effort, at least.",
					"I suppose... we have an understanding.",
					"...Thank you. I think.",
					"Fine. Maybe I've been too harsh.",
					"I... I'll give you a chance.",
				}
			},
			-- Race: Dunmer
			race_dunmer = {
				high = {
					"You honor me with your understanding, sera.",
					"The Three have brought us together for a reason.",
					"I see you truly respect our ways. That means everything.",
					"You've earned my trust, outlander. Few have.",
					"May the Three bless this bond between us.",
				},
				medium = {
					"You show more wisdom than most of your kind.",
					"I... appreciate this connection, sera.",
					"Perhaps I have judged you too harshly.",
					"You understand more than I expected.",
					"This is... acceptable. More than acceptable.",
					"I will remember your kindness, outlander.",
				},
				low = {
					"I... suppose not all outlanders are the same.",
					"Well. You've made an effort at least.",
					"Hmm. Perhaps there's hope for you yet.",
					"I'll... consider you differently now.",
					"Very well. I acknowledge this gesture.",
					"...The Three teach us to find worth in all. Perhaps I see it now.",
				}
			},
			-- Race: Khajiit
			race_khajiit = {
				high = {
					"This one's heart is warmed, friend! Truly!",
					"Walker, you have earned this one's loyalty!",
					"The moons shine brighter with friends like you!",
					"This one will never forget your kindness!",
					"May your roads always lead to warm sands, dear friend!",
					"This one considers you family now!",
				},
				medium = {
					"This one values what we share, walker.",
					"You are kind to this one. This one remembers.",
					"Warm sands and warmer hearts, yes?",
					"This one is pleased to call you friend.",
					"You have earned this one's respect, walker.",
					"This one will speak well of you!",
				},
				low = {
					"This one... this one appreciates this.",
					"Well. This one supposes you are trustworthy.",
					"Hmm. Perhaps this one has been too cautious.",
					"This one will... remember your kindness.",
					"...Thank you, walker. Truly.",
					"This one thinks... yes, we can be friends.",
				}
			},
			-- Class: Guard
			class_guard = {
				high = {
					"You know... I needed this. Thank you, friend.",
					"I won't forget this. You're a good person.",
					"If you ever need help, you can count on me.",
					"This job... it's nice to be reminded why it matters.",
					"You've made my day. Really.",
				},
				medium = {
					"That's... decent of you, citizen.",
					"I appreciate you taking the time.",
					"Not many people bother. Thank you.",
					"I'll remember this.",
					"You're alright. Really.",
					"Good to know there are people like you around.",
				},
				low = {
					"I... well, thanks. I guess.",
					"That's more than most people do.",
					"Alright. I appreciate the gesture.",
					"...Fair enough, citizen.",
					"I'll... keep this in mind.",
				}
			},
			-- Class: Ordinator
			class_ordinator = {
				high = {
					"The Three have guided you to me. I am grateful.",
					"Your understanding of the Temple's burden touches me, sera.",
					"May the Tribunal bless this bond we share.",
					"I will pray for you. You are a true friend to the Temple.",
					"The weight of service... you understand. Thank you.",
					"The Three smile upon connections like this.",
				},
				medium = {
					"The Temple appreciates those who truly understand.",
					"You show wisdom beyond most, sera.",
					"I will remember your words.",
					"The Ordinators value such understanding.",
					"This means more than you know.",
					"The Three teach us to recognize genuine faith. I see it in you.",
				},
				low = {
					"I... the Temple thanks you for your understanding.",
					"Perhaps... yes, perhaps there is worth in this.",
					"The Three teach us to seek connections. This is... good.",
					"I will remember this gesture, sera.",
					"...The Tribunal guides us. I see their hand in this.",
					"Hmm. You are more thoughtful than most.",
				}
			},
			-- Faction: Imperial Legion
			faction_imperial_legion = {
				high = {
					"The Empire needs more citizens like you.",
					"You understand what we fight for. That's rare.",
					"I'm proud to call you a friend of the Legion.",
					"Your support means everything to us. Thank you.",
					"The Legion remembers its friends. I won't forget this.",
					"This is why we serve. People like you.",
				},
				medium = {
					"The Legion values loyal citizens like you.",
					"I appreciate your understanding, citizen.",
					"Good to know we have support out here.",
					"I'll remember this.",
					"The Empire is stronger with people like you.",
					"Thank you for your support.",
				},
				low = {
					"I... well, the Legion thanks you.",
					"That's more support than we usually get.",
					"Hmm. I'll keep this in mind, citizen.",
					"...Appreciate the gesture.",
					"Perhaps I've been too cynical.",
					"Fair enough. Thank you.",
				}
			},
			-- Faction: Thieves Guild
			faction_thieves_guild = {
				high = {
					"You really get it, don't you? I can trust you.",
					"Hard to find genuine connections in this line of work. Thanks.",
					"You're one of the good ones. I mean that.",
				},
				medium = {
					"Alright, you've earned my respect.",
					"I appreciate that. Really.",
					"Not bad. I'll remember this.",
				},
				low = {
					"I... guess you're alright.",
					"Well. That's something.",
					"Fair enough. Thanks, I suppose.",
				}
			}
		},
		failure = {
			generic = {
				depleted = {
					"I can't do this anymore. Please leave.",
					"No. I need space from you.",
					"I'm done. Just... go.",
					"I can't trust you. Not anymore.",
					"Leave me alone. Please.",
					"This isn't working. Go away.",
				},
				high = {
					"That feels... forced. I'm sorry.",
					"I'm not ready for this level of connection.",
					"This is too much, too fast.",
					"I appreciate the attempt, but no.",
					"I need to keep my distance.",
					"Let's not get ahead of ourselves.",
				},
				medium = {
					"I don't know you well enough for that.",
					"That's... a bit much.",
					"I'm not comfortable with this.",
					"Let's keep things professional.",
					"I'd rather not.",
					"This doesn't feel right.",
				},
				low = {
					"Absolutely not.",
					"What do you think you're doing?",
					"How dare you presume!",
					"I don't trust you at all!",
					"Get away from me!",
					"You've got some nerve!",
				}
			},
			-- Race: Dunmer
			race_dunmer = {
				high = {
					"You are still an outlander. We can never truly bond.",
					"I appreciate the gesture, but our worlds are too different.",
					"The gap between us is too great, sera.",
					"I cannot give what you ask.",
				},
				medium = {
					"No, outlander. This is inappropriate.",
					"We are not so familiar, sera.",
					"You overstep your bounds.",
					"I prefer to keep distance from your kind.",
				},
				low = {
					"How dare you! I am not your friend, n'wah!",
					"Presumptuous fetcher!",
					"You think we could ever be equals?!",
					"Get away from me, s'wit!",
				}
			},
			-- Race: Khajiit
			race_khajiit = {
				high = {
					"This one... this one is not ready for such bonds.",
					"Too much, too fast, walker. This one is sorry.",
					"This one appreciates the thought, but cannot accept.",
					"The walls around this one's heart are there for a reason.",
				},
				medium = {
					"This one is not comfortable with this.",
					"No, walker. We barely know each other.",
					"This one prefers distance.",
					"Too familiar, walker. Too familiar.",
				},
				low = {
					"This one does not trust you! Leave!",
					"How dare you! Away!",
					"No! This one wants nothing from you!",
					"You presume too much!",
				}
			},
			-- Class: Guard
			class_guard = {
				high = {
					"I appreciate it, but I need to stay professional.",
					"Let's keep things proper, citizen.",
					"I'm on duty. This isn't appropriate.",
					"I can't get too close. Regulations.",
				},
				medium = {
					"Keep your distance, citizen.",
					"Let's keep this professional.",
					"No. That's not how this works.",
					"Move along.",
				},
				low = {
					"Back off! Now!",
					"That's harassment, citizen!",
					"You're crossing a line!",
					"Watch yourself!",
				}
			},
			-- Class: Ordinator
			class_ordinator = {
				high = {
					"I serve the Three. Personal bonds are secondary.",
					"The Temple demands distance. I'm sorry.",
					"My duty to the Tribunal comes first.",
					"I cannot give what you seek.",
				},
				medium = {
					"This is inappropriate, sera.",
					"The Ordinators maintain proper distance.",
					"I must decline.",
					"Keep your distance.",
				},
				low = {
					"You dare! I am a servant of the Tribunal!",
					"Blasphemous familiarity!",
					"Know your place!",
					"The Temple does not permit this!",
				}
			},
			-- Faction: Imperial Legion
			faction_imperial_legion = {
				high = {
					"I serve the Empire. Personal connections compromise that.",
					"I appreciate it, but duty comes first.",
					"The Legion requires professional distance.",
					"I can't, citizen. Regulations.",
				},
				medium = {
					"Keep it professional, citizen.",
					"No. That's not appropriate.",
					"I'm a soldier, not your friend.",
					"Move along.",
				},
				low = {
					"That's completely inappropriate!",
					"Back off, citizen!",
					"You're out of line!",
					"One more step and you're arrested!",
				}
			}
		}
	},
	bribe = {
		success = {
			generic = {
				small = {
					"Well... I suppose that's acceptable.",
					"Every bit helps.",
					"Hmm. Fair enough.",
					"I'll take it.",
					"That works.",
					"Acceptable.",
				},
				medium = {
					"Now we're talking!",
					"Your generosity is noted.",
					"Excellent! Much appreciated!",
					"Now that's reasonable!",
					"Very good!",
					"I appreciate this!",
				},
				large = {
					"My, my! You are quite generous!",
					"With gold like this, you've made a friend.",
					"Exceptional! Most generous!",
					"Such wealth! I'm overwhelmed!",
					"You're far too kind!",
					"Incredible generosity!",
				}
			},
			-- Race: Dunmer
			race_dunmer = {
				small = {
					"Hmm. A modest offering, outlander.",
					"I suppose... this is acceptable.",
				},
				medium = {
					"Well now. You show some understanding of our ways.",
					"Your generosity is noted, sera.",
				},
				large = {
					"Most generous! Perhaps you're not like other outlanders.",
					"Such wealth! You honor me, sera!",
				}
			},
			-- Race: Khajiit
			race_khajiit = {
				small = {
					"A fair exchange, walker. This one thanks you.",
					"Good coin. This one accepts.",
				},
				medium = {
					"Generous, walker! This one is pleased!",
					"Ah! This will buy much moon-sugar! Thank you!",
				},
				large = {
					"Such wealth! This one's eyes grow wide!",
					"By the moons! This one has never seen such gold!",
				}
			},
			-- Class: Guard
			class_guard = {
				small = {
					"I... I didn't see that. Move along, citizen.",
					"Hmm. I suppose I can overlook this... once.",
				},
				medium = {
					"Right then. Let's just forget this ever happened.",
					"I think we can come to an understanding here.",
				},
				large = {
					"Well now... I believe I need to patrol elsewhere. Good day, citizen.",
					"I... may have been mistaken about what I saw here.",
				}
			},
			-- Class: Ordinator
			class_ordinator = {
				small = {
					"The Temple... acknowledges your donation.",
					"A modest offering. The Three accept.",
				},
				medium = {
					"Your generosity to the Temple is noted.",
					"The Ordinators... appreciate your contribution.",
				},
				large = {
					"Such devotion! The Three smile upon you, sera.",
					"The Temple is most grateful for your... generous donation.",
				}
			},
			-- Faction: Imperial Legion
			faction_imperial_legion = {
				small = {
					"A... reasonable contribution to the Legion.",
					"The Empire acknowledges your support.",
				},
				medium = {
					"Excellent! The Legion appreciates loyal citizens.",
					"Your support of Imperial forces is noted.",
				},
				large = {
					"Exceptional generosity! The Empire has need of citizens like you!",
					"Such support! You are a true friend of the Legion!",
				}
			}
		},
		failure = {
			generic = {
				depleted = {
					"Keep your gold. I want nothing more from you.",
					"Your money won't change anything now.",
					"I'm done dealing with you, gold or no gold.",
					"Take your coin and leave.",
					"No amount of gold will fix this.",
					"I want nothing from you.",
				},
				small = {
					"Is this a joke?",
					"You insult me with this pittance.",
					"Are you serious?",
					"That's all?",
					"Pathetic.",
					"You think that's enough?",
				},
				medium = {
					"Not enough, I'm afraid.",
					"You'll need to do better than that.",
					"Insufficient.",
					"Not interested.",
					"Try harder.",
					"Not even close.",
				},
				large = {
					"I'm not for sale at any price.",
					"Keep your gold, I want nothing from you.",
					"I cannot be bought.",
					"No. Absolutely not.",
					"Take it back.",
					"My integrity isn't for sale.",
				}
			},
			-- Race: Dunmer
			race_dunmer = {
				small = {
					"Keep your coin, outlander.",
					"You think all Dunmer can be bought? Typical.",
				},
				medium = {
					"I'm not interested in your gold.",
					"Take your money and leave, n'wah.",
				},
				large = {
					"How dare you! I am not some corrupt outlander!",
					"Get that filth out of my sight!",
				}
			},
			-- Race: Khajiit
			race_khajiit = {
				small = {
					"This one is insulted by such a paltry sum.",
					"You think this one works for scraps?",
				},
				medium = {
					"Not enough, walker. This one has standards.",
					"This one is not so desperate.",
				},
				large = {
					"No, walker. This one cannot accept. It is wrong.",
					"This one's honor is not for sale.",
				}
			},
			-- Class: Guard
			class_guard = {
				small = {
					"That's... are you trying to bribe me? With THAT?",
					"Pathetic. Move along before I arrest you.",
				},
				medium = {
					"Put that away. I'm not corrupt... for that price at least.",
					"Nice try, but no. Move along.",
				},
				large = {
					"That's a serious bribe attempt! You're under arrest!",
					"Halt! You just committed a crime!",
				}
			},
			-- Class: Ordinator
			class_ordinator = {
				small = {
					"You dare insult the Temple with this pittance?",
					"The Ordinators are not swayed by petty coin.",
				},
				medium = {
					"The Temple's servants cannot be bought so cheaply.",
					"Take your coin. The Three are watching.",
				},
				large = {
					"HERESY! You attempt to corrupt a servant of the Tribunal?!",
					"Blasphemer! The Temple will hear of this!",
				}
			},
			-- Faction: Imperial Legion
			faction_imperial_legion = {
				small = {
					"That's bribery, citizen. And a pathetic attempt at that.",
					"You insult the Legion with this pittance.",
				},
				medium = {
					"Put that away before you make things worse for yourself.",
					"Attempting to bribe a legionnaire? That's a crime.",
				},
				large = {
					"You're under arrest for attempting to bribe an officer!",
					"That's it. I'm taking you in!",
				}
			}
		}
	}
}

-- API for other mods to register additional responses
local M = {}

-- Store the responses table
M.responses = responses

-- Register a single response to a specific category
-- @param action: "admire", "intimidate", "taunt", "placate", or "bribe"
-- @param outcome: "success" or "failure"
-- @param category: "generic", "faction_<id>", "race_<id>", or "class_<id>"
-- @param tier: "high", "medium", "low" (for success/failure) or "small", "medium", "large" (for bribe)
-- @param response: string - the response text to add
function M.registerResponse(action, outcome, category, tier, response)
	-- Validate inputs
	if not responses[action] then
		mwse.log("[SmoothTalker] Invalid action: %s", action)
		return false
	end

	if not responses[action][outcome] then
		mwse.log("[SmoothTalker] Invalid outcome: %s", outcome)
		return false
	end

	-- Create category if it doesn't exist
	if not responses[action][outcome][category] then
		responses[action][outcome][category] = {}
	end

	-- Create tier if it doesn't exist
	if not responses[action][outcome][category][tier] then
		responses[action][outcome][category][tier] = {}
	end

	-- Add the response
	table.insert(responses[action][outcome][category][tier], response)
	mwse.log("[SmoothTalker] Registered response for %s/%s/%s/%s", action, outcome, category, tier)
	return true
end

-- Batch register multiple responses
-- @param responseData: table with structure matching the responses table
-- Example: { admire = { success = { faction_mycustomfaction = { high = {...}, medium = {...} } } } }
function M.registerResponses(responseData)
	for action, outcomes in pairs(responseData) do
		for outcome, categories in pairs(outcomes) do
			for category, tiers in pairs(categories) do
				for tier, responseList in pairs(tiers) do
					for _, response in ipairs(responseList) do
						M.registerResponse(action, outcome, category, tier, response)
					end
				end
			end
		end
	end
	mwse.log("[SmoothTalker] Batch registered responses")
end

return M
