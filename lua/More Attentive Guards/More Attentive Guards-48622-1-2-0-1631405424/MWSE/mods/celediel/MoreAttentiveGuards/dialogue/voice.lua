--[[
				{ file = "file path relative to Data Files\Sound", subtitle = "what it says" },
]]

local voices = {
    argonian = {
        female = {
            ["sneaking"] = {
                { file = "vo\\a\\f\\Hlo_AF000a.mp3", subtitle = "What?" },
                { file = "vo\\a\\f\\Idl_AF007.mp3", subtitle = "What was that?" },
                { file = "vo\\a\\f\\Idl_AF001.mp3", subtitle = "Sniff." },
                { file = "vo\\a\\f\\Hlo_AF107.mp3", subtitle = "Your crimes are known to us." },
                { file = "vo\\a\\f\\Hlo_AF106.mp3", subtitle = "You make a name for yourself, criminal." },
                { file = "vo\\a\\f\\Hlo_AF040.mp3", subtitle = "Is there nothing for you to do?" },
                { file = "vo\\a\\f\\Hlo_AF027.mp3", subtitle = "Must you make a pest of yourself?" }
            },
            ["stop_sneaking"] = {
                { file = "vo\\a\\f\\Srv_AF003.mp3", subtitle = "You should leave." },
                { file = "vo\\a\\f\\Srv_AF012.mp3", subtitle = "Leave! Before I eat it!" },
                { file = "vo\\a\\f\\Srv_AF010.mp3", subtitle = "It should go away and die!" },
                { file = "vo\\a\\f\\Hlo_AF000c.mp3", subtitle = "Humph." },
                { file = "vo\\a\\f\\Hlo_AF000b.mp3", subtitle = "Humph." },
                { file = "vo\\a\\f\\Thf_AF003.mp3", subtitle = "Hiss." },
                { file = "vo\\a\\f\\Hlo_AF000e.mp3", subtitle = "Get out of here!" }
            },
            ["stop_following"] = {
                { file = "vo\\a\\f\\Hlo_AF019.mp3", subtitle = "You hardly seem worth the trouble, criminal." },
                { file = "vo\\a\\f\\Hlo_AF000b.mp3", subtitle = "Humph." },
                { file = "vo\\a\\f\\Hlo_AF000c.mp3", subtitle = "Humph." },
                { file = "vo\\a\\f\\Hlo_AF000d.mp3", subtitle = "I won't waste my time on the likes of you." },
                { file = "vo\\a\\f\\Hlo_AF000e.mp3", subtitle = "Get out of here!" },
                { file = "vo\\a\\f\\Thf_AF003.mp3", subtitle = "Hiss." }
            },
            ["join_combat"] = {
                { file = "vo\\a\\f\\Hlo_AF017.mp3", subtitle = "Your life is mine!" },
                { file = "vo\\a\\f\\Hlo_AF014.mp3", subtitle = "Kill it!" },
                { file = "vo\\a\\f\\Hlo_AF014.mp3", subtitle = "Rip it apart!" },
                { file = "vo\\a\\f\\Hlo_AF012.mp3", subtitle = "Bleed!" },
                { file = "vo\\a\\f\\Atk_AF010.mp3", subtitle = "Hahahaha." }
            }
        },
        male = {
            ["sneaking"] = {
                { file = "vo\\a\\m\\Flw_AM001.mp3", subtitle = "Where are you going?" },
                { file = "vo\\a\\m\\Thf_AM005.mp3", subtitle = "I see you!" },
                { file = "vo\\a\\m\\Hlo_AM106.mp3", subtitle = "You make a name for yourself, criminal." },
                { file = "vo\\a\\m\\Hlo_AM107.mp3", subtitle = "Your crimes are known to us." },
                { file = "vo\\a\\m\\Hlo_AM056.mp3", subtitle = "Sniff. This scent is new." },
                { file = "vo\\a\\m\\Hlo_AM040.mp3", subtitle = "Is there nothing for you to do?" },
                { file = "vo\\a\\m\\Hlo_AM027.mp3", subtitle = "Must you make a pest of yourself?" }
            },
            ["stop_sneaking"] = {
                { file = "vo\\a\\m\\Srv_AM012.mp3", subtitle = "Leave! Before I eat it!" },
                { file = "vo\\a\\m\\Srv_AM009.mp3", subtitle = "It should go away and die!" },
                { file = "vo\\a\\m\\Hlo_AM046.mp3", subtitle = "Crime doesn't suit you, friend." },
                { file = "vo\\a\\m\\Hlo_AM022.mp3", subtitle = "Be gone!" }
            },
            ["stop_following"] = {
                { file = "vo\\a\\m\\Hlo_AM019.mp3", subtitle = "You hardly seem worth the trouble, criminal." },
                { file = "vo\\a\\m\\Hlo_AM018.mp3", subtitle = "Get away, criminal." },
                { file = "vo\\a\\m\\Hlo_AM022.mp3", subtitle = "Be gone!" }
            },
            ["join_combat"] = {
                { file = "vo\\a\\m\\bAtk_AM002.mp3", subtitle = "Your head will be my new trophy!" },
                { file = "vo\\a\\m\\bAtk_AM005.mp3", subtitle = "Your cursed bloodline ends here!" },
                { file = "vo\\a\\m\\Atk_AM010.mp3", subtitle = "Bash!" },
                { file = "vo\\a\\m\\Atk_AM011.mp3", subtitle = "Kill!" },
                { file = "vo\\a\\m\\Atk_AM012.mp3", subtitle = "It will die!" },
                { file = "vo\\a\\m\\Atk_AM013.mp3", subtitle = "Suffer!" },
                { file = "vo\\a\\m\\Atk_AM014.mp3", subtitle = "Die!" }
            }
        }
    },
    breton = {
        female = {
            ["sneaking"] = {
                { file = "vo\\b\\f\\Srv_BF006.mp3", subtitle = "I don't like you here, outlander." },
                { file = "vo\\b\\f\\Hlo_BF026.mp3", subtitle = "Well, this should be interesting." },
                { file = "vo\\b\\f\\Hlo_BF106.mp3", subtitle = "You would be wise to give up crime. It doesn't suit you." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\b\\f\\Srv_BF024.mp3", subtitle = "Do not waste my time." },
                { file = "vo\\b\\f\\Idl_BF001.mp3", subtitle = "What was that about?" },
                { file = "vo\\b\\f\\Hlo_BF017.mp3", subtitle = "What a revolting display." },
                { file = "vo\\b\\f\\Hlo_BF000b.mp3", subtitle = "Humph." },
                { file = "vo\\b\\f\\Hlo_BF000c.mp3", subtitle = "Humph." }
            },
            ["stop_following"] = {
                { file = "vo\\b\\f\\Srv_BF024.mp3", subtitle = "Do not waste my time." },
                { file = "vo\\b\\f\\Srv_BF003.mp3", subtitle = "You are repulsive, please go away." },
                { file = "vo\\b\\f\\Hlo_BF025.mp3", subtitle = "No, I don't have time for you." },
                { file = "vo\\b\\f\\Hlo_BF001.mp3", subtitle = "I think you should go elsewhere." },
                { file = "vo\\b\\f\\Hlo_BF056.mp3", subtitle = "I am busy, so, if you will excuse me." }
            },
            ["join_combat"] = {
                { file = "vo\\b\\f\\Atk_BF013.mp3", subtitle = "I should have killed you sooner!" },
                { file = "vo\\b\\f\\Atk_BF009.mp3", subtitle = "Soon you'll be reduced to dust!" },
                { file = "vo\\b\\f\\Atk_BF006.mp3", subtitle = "Death awaits you!" },
                { file = "vo\\b\\f\\Atk_BF004.mp3", subtitle = "You'll be dead soon!" },
                { file = "vo\\b\\f\\Atk_BF008.mp3", subtitle = "You should have run while you had a chance!" }
            }
        },
        male = {
            ["sneaking"] = {
                { file = "vo\\b\\m\\Flw_BM001.mp3", subtitle = "Where are you going?" },
                { file = "vo\\b\\m\\Hlo_BM105.mp3", subtitle = "You'd be wise to stay out of trouble, friend." },
                { file = "vo\\b\\m\\Hlo_BM106.mp3", subtitle = "You would be wise to give up crime. It doesn't suit you." },
                { file = "vo\\b\\m\\Srv_BM006.mp3", subtitle = "I'm watching you." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\b\\m\\Hlo_BM025.mp3", subtitle = "I don't have time for you." },
                { file = "vo\\b\\m\\Srv_BM012.mp3", subtitle = "Do not waste my time." },
                { file = "vo\\b\\m\\Hlo_BM017.mp3", subtitle = "What a revolting display." },
                { file = "vo\\b\\m\\Hlo_BM000b.mp3", subtitle = "Humph." },
                { file = "vo\\b\\m\\Hlo_BM000c.mp3", subtitle = "Humph." }
            },
            ["stop_following"] = {
                { file = "vo\\b\\m\\Hlo_BM029.mp3", subtitle = "This is becoming most unpleasant." },
                { file = "vo\\b\\m\\Hlo_BM028.mp3", subtitle = "You are beginning to annoy me." },
                { file = "vo\\b\\m\\Hlo_BM025.mp3", subtitle = "I don't have time for you." },
                { file = "vo\\b\\m\\Srv_BM012.mp3", subtitle = "Do not waste my time." },
                { file = "vo\\b\\m\\Srv_BM003.mp3", subtitle = "You are repulsive. Please, go away." }
            },
            ["join_combat"] = {
                { file = "vo\\b\\m\\CrAtk_BM005.mp3", subtitle = "Die!" },
                { file = "vo\\b\\m\\Atk_BM013.mp3", subtitle = "I should have killed you sooner!" },
                { file = "vo\\b\\m\\Atk_BM009.mp3", subtitle = "Soon you'll be reduced to dust!" },
                { file = "vo\\b\\m\\Atk_BM006.mp3", subtitle = "Death awaits you!" },
                { file = "vo\\b\\m\\Atk_BM004.mp3", subtitle = "You'll be dead soon!" }
            }
        }
    },
    ["dark elf"] = {
        female = {
            ["sneaking"] = {
                { file = "vo\\d\\f\\Hlo_DF165.mp3", subtitle = "There are better ways than theft to earn a coin, outlander." },
                { file = "vo\\d\\f\\Hlo_DF164.mp3", subtitle = "I find your crimes distasteful, outlander. Perhaps you should leave." },
                { file = "vo\\d\\f\\tHlo_DF009.mp3", subtitle = "Who do you think you are?" }
            },
            ["stop_sneaking"] = {
                { file = "vo\\d\\f\\Srv_DF045.mp3", subtitle = "Do not waste my time." },
                { file = "vo\\d\\f\\Hlo_DF037.mp3", subtitle = "Annoying outlanders." },
                { file = "vo\\d\\f\\Hlo_DF035.mp3", subtitle = "Keep moving, scum." },
                { file = "vo\\d\\f\\tIdl_DF015.mp3", subtitle = "Damn foreigners..." }
            },
            ["stop_following"] = {
                { file = "vo\\d\\f\\Srv_DF033.mp3", subtitle = "I find you foul and disgusting. Leave now." },
                { file = "vo\\d\\f\\Srv_DF045.mp3", subtitle = "Do not waste my time." },
                { file = "vo\\d\\f\\Hlo_DF094.mp3", subtitle = "I've got better things to do, so, if you don't mind, let's move this along." },
                { file = "vo\\d\\f\\Hlo_DF046.mp3", subtitle = "If you'll excuse me, I don't have time for you right now. Or ever." },
                { file = "vo\\d\\f\\Hlo_DF045.mp3", subtitle = "I'm late for an appointment. Hopefully somewhere away from you." },
                { file = "vo\\d\\f\\Hlo_DF037.mp3", subtitle = "Annoying outlanders." }
            },
            ["join_combat"] = {
                { file = "vo\\d\\f\\Atk_DF002.mp3", subtitle = "Your life's end is approaching." },
                { file = "vo\\d\\f\\Atk_DF001.mp3", subtitle = "Now you die." },
                { file = "vo\\d\\f\\Atk_DF005.mp3", subtitle = "This is the end of you, s'wit." },
                { file = "vo\\d\\f\\Atk_DF008.mp3", subtitle = "You will suffer greatly!" },
                { file = "vo\\d\\f\\Atk_DF003.mp3", subtitle = "Die, fetcher." },
                { file = "vo\\d\\f\\Atk_DF004.mp3", subtitle = "You n'wah!" },
                { file = "vo\\d\\f\\Hlo_DF027.mp3", subtitle = "Filthy s'wit!" },
                { file = "vo\\d\\f\\Atk_DF013.mp3", subtitle = "Surrender your life to me and I will end your pain!" },
                { file = "vo\\d\\f\\bAtk_DF002.mp3", subtitle = "Your head will be my new trophy!" },
                { file = "vo\\d\\f\\bAtk_DF004.mp3", subtitle = "I've fought guars more ferocious than you!" },
                { file = "vo\\d\\f\\bAtk_DF005.mp3", subtitle = "Your cursed bloodline ends here!" }
            }
        },
        male = {
            ["sneaking"] = {
                { file = "vo\\d\\m\\Flw_DM001.mp3", subtitle = "Where are you going?" },
                { file = "vo\\d\\m\\Idl_DM007.mp3", subtitle = "What was that?" },
                { file = "vo\\d\\m\\Hlo_DM165.mp3", subtitle = "There are better ways than theft to earn a coin, outlander." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\d\\m\\Hlo_DM021.mp3", subtitle = "Bothersome creature." },
                { file = "vo\\d\\m\\Hlo_DM001.mp3", subtitle = "Go away." },
                { file = "vo\\d\\m\\Hlo_DM000b.mp3", subtitle = "Humph." },
                { file = "vo\\d\\m\\Hlo_DM000c.mp3", subtitle = "Hmmph." }
            },
            ["stop_following"] = {
                { file = "vo\\d\\m\\Hlo_DM111.mp3", subtitle = "Move along, outlander." },
                { file = "vo\\d\\m\\Hlo_DM035.mp3", subtitle = "Keep moving, scum." },
                { file = "vo\\d\\m\\Hlo_DM021.mp3", subtitle = "Bothersome creature." },
                { file = "vo\\d\\m\\Hlo_DM000b.mp3", subtitle = "Humph." },
                { file = "vo\\d\\m\\Hlo_DM000c.mp3", subtitle = "Hmmph." }
            },
            ["join_combat"] = {
                { file = "vo\\d\\m\\CrAtk_AM005.mp3", subtitle = "Die!" },
                { file = "vo\\d\\m\\CrAtk_AM005.mp3", subtitle = "Die!" },
                { file = "vo\\d\\m\\Atk_DM005.mp3", subtitle = "This is the end of you, s'wit." },
                { file = "vo\\d\\m\\Atk_DM002.mp3", subtitle = "Your life's end is approaching." },
                { file = "vo\\d\\m\\Atk_DM001.mp3", subtitle = "Now you die." }
            }
        }
    },
    ["high elf"] = {
        female = {
            ["sneaking"] = {
                { file = "vo\\h\\f\\Srv_HF012.mp3", subtitle = "If you don't leave now you will wish you had." },
                { file = "vo\\h\\f\\Hlo_HF106.mp3", subtitle = "I won't tolerate any thievery if that's what you're thinking." },
                { file = "vo\\h\\f\\Hlo_HF047.mp3", subtitle = "Keep your hands where I can see them, thief." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\h\\f\\Srv_HF003.mp3", subtitle = "Don't waste my time." },
                { file = "vo\\h\\f\\Hlo_HF000b.mp3", subtitle = "Hmph!" },
                { file = "vo\\h\\f\\Hlo_HF000c.mp3", subtitle = "Hmph!" },
                { file = "vo\\h\\f\\Hlo_HF000e.mp3", subtitle = "Get out of here." }
            },
            ["stop_following"] = {
                { file = "vo\\h\\f\\Hlo_HF059.mp3", subtitle = "My patience is limited." },
                { file = "vo\\h\\f\\Hlo_HF028.mp3", subtitle = "You creatures are all the same." },
                { file = "vo\\h\\f\\Hlo_HF000d.mp3", subtitle = "Clearly, you are an idiot." },
                { file = "vo\\h\\f\\Hlo_HF001.mp3", subtitle = "I haven't any time for you now." },
                { file = "vo\\h\\f\\Hlo_HF000e.mp3", subtitle = "Get out of here." },
                { file = "vo\\h\\f\\Idl_HF002.mp3", subtitle = "If that creature visits again, I think I'll have choice words to say." }
            },
            ["join_combat"] = {
                { file = "vo\\h\\f\\CrAtk_HF005.mp3", subtitle = "Die!" },
                { file = "vo\\h\\f\\Atk_HF013.mp3", subtitle = "You'll soon be nothing more than a bad memory!" },
                { file = "vo\\h\\f\\Atk_HF014.mp3", subtitle = "I shall enjoy watching you take your last breath." },
                { file = "vo\\h\\f\\Atk_HF012.mp3", subtitle = "Embrace your demise!" }
            }
        },
        male = {
            ["sneaking"] = {
                { file = "vo\\h\\m\\Hlo_HM106.mp3", subtitle = "I won't tolerate any thievery if that's what you're thinking." },
                { file = "vo\\h\\m\\Hlo_HM047.mp3", subtitle = "Keep your hands where I can see them, thief." },
                { file = "vo\\h\\m\\Srv_HM012.mp3", subtitle = "If I see you shoplift, you will pay with your life!" },
                { file = "vo\\h\\m\\Hlo_HM089.mp3", subtitle = "Do you want something?" }
            },
            ["stop_sneaking"] = {
                { file = "vo\\h\\m\\Hlo_HM028.mp3", subtitle = "You creatures are all the same." },
                { file = "vo\\h\\m\\Srv_HM003.mp3", subtitle = "Don't waste my time." },
                { file = "vo\\h\\m\\Srv_HM006.mp3", subtitle = "You try my patience." },
                { file = "vo\\h\\m\\Hlo_HM000c.mp3", subtitle = "Humph!" }
            },
            ["stop_following"] = {
                { file = "vo\\h\\m\\Hlo_HM059.mp3", subtitle = "My patience is limited." },
                { file = "vo\\h\\m\\Srv_HM006.mp3", subtitle = "You try my patience." },
                { file = "vo\\h\\m\\Hlo_HM001.mp3", subtitle = "I haven't any time for you now." },
                { file = "vo\\h\\m\\Hlo_HM000d.mp3", subtitle = "I won't waste my time on the likes of you!" },
                { file = "vo\\h\\m\\Hlo_HM000c.mp3", subtitle = "Humph!" }
            },
            ["join_combat"] = {
                { file = "vo\\h\\m\\Atk_HM014.mp3", subtitle = "I shall enjoy watching you take your last breath." },
                { file = "vo\\h\\m\\Atk_HM013.mp3", subtitle = "You'll soon be nothing more than a bad memory!" },
                { file = "vo\\h\\m\\Atk_HM012.mp3", subtitle = "Embrace your demise!" },
                { file = "vo\\h\\m\\Atk_HM007.mp3", subtitle = "You will die in disgrace." }
            }
        }
    },
    imperial = {
        female = {
            ["sneaking"] = {
                { file = "vo\\i\\f\\Srv_IF009.mp3", subtitle = "I've got my eye on you." },
                { file = "vo\\i\\f\\Hlo_IF128.mp3", subtitle = "Stay out of trouble and you'll have none from me." },
                { file = "vo\\i\\f\\Hlo_IF057.mp3", subtitle = "Stay out of trouble, and you won't get hurt." },
                { file = "vo\\i\\f\\Hlo_IF071.mp3", subtitle = "Watch your step." },
                { file = "vo\\i\\f\\Hlo_IF070.mp3", subtitle = "Don't try anything funny." },
                { file = "vo\\i\\f\\Hlo_IF007.mp3", subtitle = "Are you here to start trouble, or are you just stupid?" },
                { file = "vo\\i\\f\\tHlo_IF003.mp3", subtitle = "Crime doesn't pay." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\i\\f\\Hlo_IF011.mp3", subtitle = "So tiresome." },
                { file = "vo\\i\\f\\Idl_IF002.mp3", subtitle = "I don't know if I like this." },
                { file = "vo\\i\\f\\Hlo_IF006.mp3", subtitle = "What a pathetic excuse for a criminal." }
            },
            ["stop_following"] = {
                { file = "vo\\i\\f\\Srv_IF021.mp3", subtitle = "I think we're done here. Please leave." },
                { file = "vo\\i\\f\\Hlo_IF011.mp3", subtitle = "So tiresome." },
                { file = "vo\\i\\f\\Hlo_IF006.mp3", subtitle = "What a pathetic excuse for a criminal." },
                { file = "vo\\i\\f\\Hlo_IF000d.mp3", subtitle = "I wouldn't waste my time on the likes of you!" },
                { file = "vo\\i\\f\\bIdl_IF003.mp3", subtitle = "My mother warned me about mooks like you." },
                { file = "vo\\i\\f\\bIdl_IF013.mp3", subtitle = "[Wide yawn.]" }
            },
            ["join_combat"] = {
                { file = "vo\\i\\f\\Atk_IF010.mp3", subtitle = "Die, scoundrel!" },
                { file = "vo\\i\\f\\Atk_IF014.mp3", subtitle = "This is pointless, give in!" },
                { file = "vo\\i\\f\\Atk_IF005.mp3", subtitle = "You won't escape me that easily!" },
                { file = "vo\\i\\f\\bAtk_IF005.mp3", subtitle = "Your head will be my new trophy!" },
                { file = "vo\\i\\f\\bAtk_IF008.mp3", subtitle = "Your cursed bloodline ends here!" }
            }
        },
        male = {
            ["sneaking"] = {
                { file = "vo\\i\\m\\Hlo_IM007.mp3", subtitle = "Are you here to start trouble, or are you just stupid?" },
                { file = "vo\\i\\m\\Flw_IM001.mp3", subtitle = "Where are you going?" },
                { file = "vo\\i\\m\\Hlo_IM057.mp3", subtitle = "Stay out of trouble and you won't get hurt." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\i\\m\\bIdl_IM028.mp3", subtitle = "Just as well..." },
                { file = "vo\\i\\m\\Hlo_IM000e.mp3", subtitle = "Get out of here." },
                { file = "vo\\i\\m\\Srv_IM027.mp3", subtitle = "You are a nuisance to me. Please leave." }
            },
            ["stop_following"] = {
                { file = "vo\\i\\m\\Hlo_IM000e.mp3", subtitle = "Get out of here." },
                { file = "vo\\i\\m\\Srv_IM027.mp3", subtitle = "You are a nuisance to me. Please leave." },
                { file = "vo\\i\\m\\Hlo_IM006.mp3", subtitle = "What a pathetic excuse for a criminal!" }
            },
            ["join_combat"] = {
                { file = "vo\\i\\m\\Atk_IM009.mp3", subtitle = "Die, scoundrel!" },
                { file = "vo\\i\\m\\CrAtk_IM005.mp3", subtitle = "Die!" },
                { file = "vo\\i\\m\\Atk_IM010.mp3", subtitle = "You're hardly a match for me!" },
                { file = "vo\\i\\m\\Atk_IM007.mp3", subtitle = "Let's see what you're made of!" },
                { file = "vo\\i\\m\\Hlo_IM004.mp3", subtitle = "Since you're already on death's door, may I open it for you?" },
                { file = "vo\\i\\m\\Hlo_IM018.mp3", subtitle = "You're a disgrace to the Empire." },
                { file = "vo\\i\\m\\Hlo_IM000d.mp3", subtitle = "You're about to find more trouble than you can possibly imagine." }
            }
        }
    },
    khajiit = {
        female = {
            ["sneaking"] = {
                { file = "vo\\k\\f\\Hlo_KF106.mp3", subtitle = "You are too easily caught." },
                { file = "vo\\k\\f\\Hlo_KF041.mp3", subtitle = "Why is it here?" },
                { file = "vo\\k\\f\\Hlo_KF019.mp3", subtitle = "You are trouble. Khajiit know this." },
                { file = "vo\\k\\f\\Hlo_KF017.mp3", subtitle = "Does it want to feel Khajiiti claws?" }
            },
            ["stop_sneaking"] = {
                { file = "vo\\k\\f\\Hlo_KF016.mp3", subtitle = "Disgusting thing. Leave now." },
                { file = "vo\\k\\f\\Hlo_KF053.mp3", subtitle = "You do not please us." },
                { file = "vo\\k\\f\\Hlo_KF021.mp3", subtitle = "It will leave. Now." },
                { file = "vo\\k\\f\\Hlo_KF000b.mp3", subtitle = "Hmmph!" },
                { file = "vo\\k\\f\\Hlo_KF000c.mp3", subtitle = "Grrfph!" }
            },
            ["stop_following"] = {
                { file = "vo\\k\\f\\Srv_KF009.mp3", subtitle = "Annoying creature! It should go away." },
                { file = "vo\\k\\f\\Hlo_KF016.mp3", subtitle = "Disgusting thing. Leave now." },
                { file = "vo\\k\\f\\Hlo_KF000d.mp3", subtitle = "I won't waste my time on the likes of you." },
                { file = "vo\\k\\f\\Hlo_KF026.mp3", subtitle = "So little manners, so little time." }
            },
            ["join_combat"] = {
                { file = "vo\\k\\f\\Atk_KF014.mp3", subtitle = "This one is no more." },
                { file = "vo\\k\\f\\Atk_KF015.mp3", subtitle = "This one is no more." },
                { file = "vo\\k\\f\\CrAtk_KF005.mp3", subtitle = "Die!" },
                { file = "vo\\k\\f\\Atk_KF010.mp3", subtitle = "So small and tasty. I will enjoy eating you." },
                { file = "vo\\k\\f\\Fle_KF004.mp3", subtitle = "You had your chance!" }
            }
        },
        male = {
            ["sneaking"] = {
                { file = "vo\\k\\m\\Hlo_KM041.mp3", subtitle = "Why is it here?" },
                { file = "vo\\k\\m\\Hlo_KM106.mp3", subtitle = "You are too easily caught." },
                { file = "vo\\k\\m\\Hlo_KM019.mp3", subtitle = "You are trouble. Khajiit know this." },
                { file = "vo\\k\\m\\Hlo_KM017.mp3", subtitle = "Does it want to feel Khajiiti claws?" }
            },
            ["stop_sneaking"] = {
                { file = "vo\\k\\m\\Srv_KM006.mp3", subtitle = "This one should leave." },
                { file = "vo\\k\\m\\Hlo_KM053.mp3", subtitle = "You do not please us." },
                { file = "vo\\k\\m\\Hlo_KM021.mp3", subtitle = "It will leave. Now." },
                { file = "vo\\k\\m\\Hlo_KM016.mp3", subtitle = "Disgusting thing. Leave now." }
            },
            ["stop_following"] = {
                { file = "vo\\k\\m\\Hlo_KM022.mp3", subtitle = "Go away! Do not come back!" },
                { file = "vo\\k\\m\\Hlo_KM053.mp3", subtitle = "You do not please us." },
                { file = "vo\\k\\m\\Hlo_KM016.mp3", subtitle = "Disgusting thing. Leave now." },
                { file = "vo\\k\\m\\Hlo_KM026.mp3", subtitle = "So little manners, so little time." }
            },
            ["join_combat"] = {
                { file = "vo\\k\\m\\Atk_KM014.mp3", subtitle = "This one is no more." },
                { file = "vo\\k\\m\\Atk_KM015.mp3", subtitle = "This one is no more!" },
                { file = "vo\\k\\m\\Atk_KM010.mp3", subtitle = "So small and tasty. I will enjoy eating you." },
                { file = "vo\\k\\m\\bAtk_KM004.mp3", subtitle = "I’ve fought guars more ferocious than you!" }
            }
        }
    },
    nord = {
        female = {
            ["sneaking"] = {
                { file = "vo\\n\\f\\Hlo_NF106.mp3", subtitle = "Hmm. You're not here to start trouble, are you?" },
                { file = "vo\\n\\f\\Hlo_NF087.mp3", subtitle = "What's this all about?" },
                { file = "vo\\n\\f\\Hlo_NF059.mp3", subtitle = "You like to walk a fine line, don't you?" },
                { file = "vo\\n\\f\\Hlo_NF047.mp3", subtitle = "I've got no patience for petty criminals. Move on." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\n\\f\\Srv_NF009.mp3", subtitle = "You must be joking! Go away!" },
                { file = "vo\\n\\f\\Hlo_NF077.mp3", subtitle = "On your way." },
                { file = "vo\\n\\f\\Hlo_NF030.mp3", subtitle = "I think you should keep walking." },
                { file = "vo\\n\\f\\Hlo_NF022.mp3", subtitle = "Get out of here before you get hurt." }
            },
            ["stop_following"] = {
                { file = "vo\\n\\f\\Hlo_NF055.mp3", subtitle = "By the gods! You tourists are a nuisance!" },
                { file = "vo\\n\\f\\Hlo_NF022.mp3", subtitle = "Get out of here before you get hurt." },
                { file = "vo\\n\\f\\Hlo_NF000d.mp3", subtitle = "I won't waste my time on the likes of you." },
                { file = "vo\\n\\f\\bIdl_NF021.mp3", subtitle = "[Wide yawn.]" }
            },
            ["join_combat"] = {
                { file = "vo\\n\\f\\CrAtk_NF005.mp3", subtitle = "Die!" },
                { file = "vo\\n\\f\\Atk_NF015.mp3", subtitle = "Face death!" },
                { file = "vo\\n\\f\\Atk_NF007.mp3", subtitle = "I will bathe in your blood." },
                { file = "vo\\n\\f\\Atk_NF004.mp3", subtitle = "Fool!" },
                { file = "vo\\n\\f\\bAtk_NF002.mp3", subtitle = "Your cursed bloodline ends here!" }
            }
        },
        male = {
            ["sneaking"] = {
                { file = "vo\\n\\m\\Hlo_NM106.mp3", subtitle = "Hello. Hmm. You're not here to start trouble, are you?" },
                { file = "vo\\n\\m\\Hlo_NM087.mp3", subtitle = "What's this all about?" },
                { file = "vo\\n\\m\\Hlo_NM059.mp3", subtitle = "You like to dance close to the fire, don't you?" },
                { file = "vo\\n\\m\\Hlo_NM047.mp3", subtitle = "I've got no patience for petty criminals. Move on." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\n\\m\\Hlo_NM077.mp3", subtitle = "On your way." },
                { file = "vo\\n\\m\\Hlo_NM017.mp3", subtitle = "You must be joking." },
                { file = "vo\\n\\m\\Hlo_NM022.mp3", subtitle = "Get out of here, before you get hurt!" },
                { file = "vo\\n\\m\\Hlo_NM022.mp3", subtitle = "Get out of here, before you get hurt!" }
            },
            ["stop_following"] = {
                { file = "vo\\n\\m\\Hlo_NM055.mp3", subtitle = "By the gods! You tourists are a nuisance!" },
                { file = "vo\\n\\m\\Hlo_NM022.mp3", subtitle = "Get out of here before you get hurt." },
                { file = "vo\\n\\m\\Srv_NM003.mp3", subtitle = "Do not waste my time!" },
                { file = "vo\\n\\m\\bIdl_NM016.mp3", subtitle = "[Wide yawn.]" }
            },
            ["join_combat"] = {
                { file = "vo\\n\\m\\Atk_NM020.mp3", subtitle = "It will be your blood here, not mine!" },
                { file = "vo\\n\\m\\Atk_NM007.mp3", subtitle = "I will bathe in your blood." },
                { file = "vo\\n\\m\\Atk_NM004.mp3", subtitle = "Fool!" },
                { file = "vo\\n\\m\\bAtk_NM002.mp3", subtitle = "Your cursed bloodline ends here!" }
            }
        }
    },
    orc = {
        female = {
            ["sneaking"] = {
                { file = "vo\\o\\f\\Hlo_OF018.mp3", subtitle = "We cut off the hand that steals. Know this, thief." },
                { file = "vo\\o\\f\\Hlo_OF106.mp3", subtitle = "I know of your taste for crime. Be warned." },
                { file = "vo\\o\\f\\Hlo_OF044.mp3", subtitle = "What are you supposed to be?" },
                { file = "vo\\o\\f\\Idl_OF009.mp3", subtitle = "Finally something interesting." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\o\\f\\Srv_OF003.mp3", subtitle = "Get out! You'll give this place a bad name." },
                { file = "vo\\o\\f\\Hlo_OF056.mp3", subtitle = "Do not waste my time." },
                { file = "vo\\o\\f\\Hlo_OF023.mp3", subtitle = "I haven't time for fools." },
                { file = "vo\\o\\f\\Hlo_OF026.mp3", subtitle = "So annoying." }
            },
            ["stop_following"] = {
                { file = "vo\\o\\f\\Hlo_OF056.mp3", subtitle = "Do not waste my time." },
                { file = "vo\\o\\f\\Hlo_OF026.mp3", subtitle = "So annoying." },
                { file = "vo\\o\\f\\Hlo_OF025.mp3", subtitle = "You're hardly worth my time." },
                { file = "vo\\o\\f\\Hlo_OF023.mp3", subtitle = "I haven't time for fools." }
            },
            ["join_combat"] = {
                { file = "vo\\o\\f\\CrAtk_OF005.mp3", subtitle = "Die!" },
                { file = "vo\\o\\f\\Atk_OF015.mp3", subtitle = "Our blood is made for fighting!" },
                { file = "vo\\o\\f\\Atk_OF005.mp3", subtitle = "Now you die." },
                { file = "vo\\o\\f\\Atk_OF003.mp3", subtitle = "No surrender! No mercy!" }
            }
        },
        male = {
            ["sneaking"] = {
                { file = "vo\\o\\m\\Hlo_OM018.mp3", subtitle = "We cut of the hand that steals. Know this, thief." },
                { file = "vo\\o\\m\\Hlo_OM106.mp3", subtitle = "I know of your taste for crime. Be warned." },
                { file = "vo\\o\\m\\Hlo_OM055.mp3", subtitle = "What are you doing?" },
                { file = "vo\\o\\m\\Hlo_OM024.mp3", subtitle = "Do you seek a fight with me? If not, leave." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\o\\m\\Srv_OM006.mp3", subtitle = "Bother me again and I'll rip your arm off." },
                { file = "vo\\o\\m\\Hlo_OM056.mp3", subtitle = "Do not waste my time." },
                { file = "vo\\o\\m\\Hlo_OM026.mp3", subtitle = "Annoying creature." },
                { file = "vo\\o\\m\\Hlo_OM023.mp3", subtitle = "I haven't time for fools." }
            },
            ["stop_following"] = {
                { file = "vo\\o\\m\\Srv_OM006.mp3", subtitle = "Bother me again and I'll rip your arm off." },
                { file = "vo\\o\\m\\Hlo_OM056.mp3", subtitle = "Do not waste my time." },
                { file = "vo\\o\\m\\Hlo_OM025.mp3", subtitle = "You're hardly worth my time." },
                { file = "vo\\o\\m\\Hlo_OM023.mp3", subtitle = "I haven't time for fools." }
            },
            ["join_combat"] = {
                { file = "vo\\o\\m\\CrAtk_OM005.mp3", subtitle = "Die!" },
                { file = "vo\\o\\m\\Atk_OM015.mp3", subtitle = "Our blood is made for fighting!" },
                { file = "vo\\o\\m\\Atk_OM011.mp3", subtitle = "I will kill you quickly." },
                { file = "vo\\o\\m\\Atk_OM013.mp3", subtitle = "Your bones will be my dinner." }
            }
        }
    },
    redguard = {
        female = {
            ["sneaking"] = {
                { file = "vo\\r\\f\\Hlo_RF118.mp3", subtitle = "Well, what have we here?" },
                { file = "vo\\r\\f\\Hlo_RF106.mp3", subtitle = "You might consider a less hazardous profession, thief." },
                { file = "vo\\r\\f\\Hlo_RF055.mp3", subtitle = "There's something not right about you. Maybe you should go." },
                { file = "vo\\r\\f\\Hlo_RF054.mp3", subtitle = "How do I know you're not up to something devious?" },
                { file = "vo\\r\\f\\Hlo_RF024.mp3", subtitle = "If you're looking for trouble, you're getting very warm." },
                { file = "vo\\r\\f\\Thf_RF001.mp3", subtitle = "Not on my watch, thief." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\r\\f\\Hlo_RF027.mp3", subtitle = "Keep walking." },
                { file = "vo\\r\\f\\Hlo_RF022.mp3", subtitle = "Get lost." },
                { file = "vo\\r\\f\\Hlo_RF001.mp3", subtitle = "I think it would be best if you leave. Now." },
                { file = "vo\\r\\f\\Hlo_RF000b.mp3", subtitle = "Humph." }
            },
            ["stop_following"] = {
                { file = "vo\\r\\f\\Hlo_RF046.mp3", subtitle = "I don't want any part of this. Whatever it is." },
                { file = "vo\\r\\f\\Hlo_RF000b.mp3", subtitle = "Humph." },
                { file = "vo\\r\\f\\Hlo_RF000d.mp3", subtitle = "I won't waste my time on the likes of you." },
                { file = "vo\\r\\f\\Atk_RF004.mp3", subtitle = "Stupid fetcher!" }
            },
            ["join_combat"] = {
                { file = "vo\\r\\f\\CrAtk_RF005.mp3", subtitle = "Die!" },
                { file = "vo\\r\\f\\Atk_RF010.mp3", subtitle = "You'll be dead soon." },
                { file = "vo\\r\\f\\Atk_RF014.mp3", subtitle = "Run or die!" },
                { file = "vo\\r\\f\\Atk_RF007.mp3", subtitle = "Run while you can." }
            }
        },
        male = {
            ["sneaking"] = {
                { file = "vo\\r\\m\\Hlo_RM118.mp3", subtitle = "Well, what have we here?" },
                { file = "vo\\r\\m\\Hlo_RM106.mp3", subtitle = "You might consider a less hazardous profession, thief." },
                { file = "vo\\r\\m\\Hlo_RM055.mp3", subtitle = "There's something not right about you. Maybe you should go." },
                { file = "vo\\r\\m\\Hlo_RM054.mp3", subtitle = "How do I know you're not up to something devious?" },
                { file = "vo\\r\\m\\Hlo_RM024.mp3", subtitle = "If you're looking for trouble, you're getting very warm." },
                { file = "vo\\r\\m\\Thf_RM001.mp3", subtitle = "Not on my watch, thief." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\r\\m\\Hlo_RM027.mp3", subtitle = "Keep walking." },
                { file = "vo\\r\\m\\Hlo_RM022.mp3", subtitle = "Get lost." },
                { file = "vo\\r\\m\\Hlo_RM001.mp3", subtitle = "I think it would be best if you leave. Now." },
                { file = "vo\\r\\m\\Fle_RM002.mp3", subtitle = "We're done here." }
            },
            ["stop_following"] = {
                { file = "vo\\r\\m\\Hlo_RM046.mp3", subtitle = "I don't want any part of this. Whatever it is." },
                { file = "vo\\r\\m\\Hlo_RM044.mp3", subtitle = "Stop wasting my time with your foolishness!" },
                { file = "vo\\r\\m\\Hlo_RM022.mp3", subtitle = "Get lost." },
                { file = "vo\\r\\m\\Srv_RM003.mp3", subtitle = "It ... should leave!" }
            },
            ["join_combat"] = {
                { file = "vo\\r\\m\\Atk_RM016.mp3", subtitle = "I hope you suffer!" },
                { file = "vo\\r\\m\\Atk_RM010.mp3", subtitle = "You'll be dead soon." },
                { file = "vo\\r\\m\\Atk_RM014.mp3", subtitle = "Here it comes!" },
                { file = "vo\\r\\m\\Atk_RM007.mp3", subtitle = "Run while you can." }
            }
        }
    },
    ["wood elf"] = {
        female = {
            ["sneaking"] = {
                { file = "vo\\w\\f\\Hlo_WF106.mp3", subtitle = "Criminals should dealt with harshly, don't you think?" },
                { file = "vo\\w\\f\\Hlo_WF083.mp3", subtitle = "What is this about?" },
                { file = "vo\\w\\f\\Hlo_WF024.mp3", subtitle = "You'll get more than you bargained for from me." },
                { file = "vo\\w\\f\\Hlo_WF000d.mp3", subtitle = "You don't want to see me angry." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\w\\f\\Hlo_WF025.mp3", subtitle = "I really don't want you around here." },
                { file = "vo\\w\\f\\Hlo_WF023.mp3", subtitle = "Useless tourists." },
                { file = "vo\\w\\f\\Hlo_WF028.mp3", subtitle = "I don't like you much, stranger." },
                { file = "vo\\w\\f\\Hlo_WF019.mp3", subtitle = "You're a disgrace." }
            },
            ["stop_following"] = {
                { file = "vo\\w\\f\\Srv_WF009.mp3", subtitle = "You offend me!" },
                { file = "vo\\w\\f\\Atk_WF002.mp3", subtitle = "Fetcher!" },
                { file = "vo\\w\\f\\Hlo_WF055.mp3", subtitle = "Too much trouble. Must be going now." },
                { file = "vo\\w\\f\\Hlo_WF054.mp3", subtitle = "I'm sure this is important, but I really must go." }
            },
            ["join_combat"] = {
                { file = "vo\\w\\f\\CrAtk_WF005.mp3", subtitle = "Die!" },
                { file = "vo\\w\\f\\Atk_WF001.mp3", subtitle = "Now you're going to get it." },
                { file = "vo\\w\\f\\Atk_WF009.mp3", subtitle = "One of us will die here and it won't be me." },
                { file = "vo\\w\\f\\Atk_WF008.mp3", subtitle = "Run while you can." }
            }
        },
        male = {
            ["sneaking"] = {
                { file = "vo\\w\\m\\Hlo_WM106.mp3", subtitle = "Criminals should dealt with harshly, don't you think?" },
                { file = "vo\\w\\m\\Hlo_WM083.mp3", subtitle = "What is this about?" },
                { file = "vo\\w\\m\\Hlo_WM024.mp3", subtitle = "You'll get more than you bargained for from me." },
                { file = "vo\\w\\m\\Hlo_WM046.mp3", subtitle = "The laws are harsh for thieves. Including yourself." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\w\\m\\Hlo_WM025.mp3", subtitle = "I really don't want you around here." },
                { file = "vo\\w\\m\\Hlo_WM023.mp3", subtitle = "Useless tourists." },
                { file = "vo\\w\\m\\Hlo_WM028.mp3", subtitle = "I don't like you much." },
                { file = "vo\\w\\m\\Hlo_WM019.mp3", subtitle = "You're a disgrace." }
            },
            ["stop_following"] = {
                { file = "vo\\w\\m\\Hlo_WM027.mp3", subtitle = "Can't you find someone else to bother?" },
                { file = "vo\\w\\m\\Atk_WM002.mp3", subtitle = "Fetcher!" },
                { file = "vo\\w\\m\\Hlo_WM055.mp3", subtitle = "Too much trouble. Must be going now." },
                { file = "vo\\w\\m\\Hlo_WM054.mp3", subtitle = "I'm sure this is important, but I really must go." }
            },
            ["join_combat"] = {
                { file = "vo\\w\\m\\Atk_WM003.mp3", subtitle = "You don't deserve to live." },
                { file = "vo\\w\\m\\Atk_WM001.mp3", subtitle = "Now you're going to get it." },
                { file = "vo\\w\\m\\Atk_WM009.mp3", subtitle = "One of us will die here and it won't be me." },
                { file = "vo\\w\\m\\Atk_WM008.mp3", subtitle = "Run while you can." }
            }
        }
    },
    ordinator = {
        male = {
            ["sneaking"] = {
                { file = "vo\\ord\\Hlo_ORM008.mp3", subtitle = "Watch yourself. We'll have no trouble here." },
                { file = "vo\\ord\\Hlo_ORM004.mp3", subtitle = "If you're here for trouble, you'll get more than you bargained for." },
                { file = "vo\\ord\\Hlo_ORM003.mp3", subtitle = "We're watching you. Scum." }
            },
            ["stop_sneaking"] = {
                { file = "vo\\ord\\Hlo_ORM001.mp3", subtitle = "Grrrr." },
                { file = "vo\\ord\\Hlo_ORM009.mp3", subtitle = "Go on about your business." },
                { file = "vo\\ord\\Hlo_ORM007.mp3", subtitle = "Keep moving." },
                { file = "vo\\ord\\Hlo_ORM011.mp3", subtitle = "Move along." }
            },
            ["stop_following"] = {
                { file = "vo\\ord\\Hlo_ORM011.mp3", subtitle = "Move along." },
                { file = "vo\\ord\\Hlo_ORM009.mp3", subtitle = "Go on about your business." },
                { file = "vo\\ord\\Hlo_ORM007.mp3", subtitle = "Keep moving." },
                { file = "vo\\ord\\Hlo_ORM002.mp3", subtitle = "Go. Now." }
            },
            ["join_combat"] = {
                { file = "vo\\ord\\Atk_ORM002.mp3", subtitle = "Fool!" },
                { file = "vo\\ord\\Atk_ORM003.mp3", subtitle = "You have sealed your fate!" },
                { file = "vo\\ord\\Atk_ORM004.mp3", subtitle = "You cannot escape the righteous!" },
                { file = "vo\\ord\\Atk_ORM005.mp3", subtitle = "You will pay with your blood!" },
                { file = "vo\\ord\\Atk_ORM001.mp3", subtitle = "May our Lords be merciful!" }
            }
        }
    }
}

-- TR voices
voices["t_els_cathay"] = voices.khajiit
voices["t_els_cathay-raht"] = voices.khajiit
voices["t_els_ohmes"] = voices.khajiit
voices["t_els_ohmes-raht"] = voices.khajiit
voices["t_els_suthay"] = voices.khajiit
voices["t_sky_reachman"] = voices.breton -- todo: combine Nord + Breton -- actually that would be weird so I guess this is fine
voices["t_pya_seaelf"] = voices["high elf"] -- todo: something better

return voices
