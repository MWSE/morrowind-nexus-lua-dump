local this = {}

---@enum KoiKoi.SoundEffectId
this.se = {
    dealCard = 1,
    putDeck = 2,
    pickCard = 3,
    putCard = 4,
    flipCard = 5,
}
---@enum KoiKoi.VoiceId
this.voice = {
    continue = 1,  -- koi-koi
    finish = 2,    -- shobu
    loseRound = 3, -- negative
    winGame = 4,   -- positive
    think = 5,
    remind = 6,
}

---@enum KoiKoi.MusicId
this.music = {
    win = 1,
    lose = 2,
}

---@class KoiKoi.MusicData
---@field path string

-- I'd like to treat it as an SE, but so far I can't.
---@type {[KoiKoi.MusicId] : KoiKoi.MusicData}
this.musicData = {
    [this.music.win] = { path = "Special/MW_Triumph.mp3" },
    [this.music.lose] = { path = "Special/MW_Death.mp3" },
}

---@class KoiKoi.SoundData
---@field soundPath string[]?
---@field sound string? fallback
---@field volume number? normalzied value

---@type {[KoiKoi.SoundEffectId] : KoiKoi.SoundData}
this.soundData = {
    [this.se.dealCard] = { sound = "book page2", soundPath = { "Fx\\Hanafuda\\soundeffect-lab_deal1.wav" } },
    [this.se.putDeck] = { sound = "book close", soundPath = { "Fx\\Hanafuda\\soundeffect-lab_pick1.wav" } },
    [this.se.pickCard] = { sound = "book page", soundPath = { "Fx\\Hanafuda\\on-jin_pick1.wav", "Fx\\Hanafuda\\on-jin_pick2.wav" }, volume = 0.8 },
    [this.se.putCard] = { sound = "book page2", soundPath = { "Fx\\Hanafuda\\soundeffect-lab_put1.wav", "Fx\\Hanafuda\\springin_put1.wav" } },
    [this.se.flipCard] = { sound = "book page", soundPath = { "Fx\\Hanafuda\\soundeffect-lab_flip1.wav", "Fx\\Hanafuda\\springin_flip1.wav" } },
}

-- TODO It would be nice to be able to assign unused assets. This is only for assets that are referenced by esm.
-- Structures that can distinguish the gender, race, outlander, etc. of the other party are complex and are avoided.
-- Maybe we should have 2 levels, depending on disposition.
-- Thieves (Thf_) and crime alerts could be useful if the cheat feature could be.
-- Servants (Srv_) have been excluded because they may have a different tone of speech even if it is textually appropriate.
---@type {[string] : {[string]: {[KoiKoi.VoiceId] : string[] } } } race, sex, VoiceId, file excluding directory
this.voiceData = {
    ["argonian"] = {
        ["f"] = {
            [this.voice.continue] = {
                "vo\\a\\f\\Hlo_AF011.mp3", --	I will gladly add to your wounds if you do not leave.
                "vo\\a\\f\\Hlo_AF021.mp3", --	Hisses
                "vo\\a\\f\\Hlo_AF022.mp3", --	Hissss!
                "vo\\a\\f\\Hlo_AF053.mp3",	--	The prey approaches.
                "vo\\a\\f\\Hlo_AF059.mp3",	--	The prey approaches.
                "vo\\a\\f\\Hlo_AF114.mp3", --	Please, go ahead. Speak.
            },
            [this.voice.finish] = {
                "vo\\a\\f\\Atk_AF017.mp3", --	Your life is mine!
                "vo\\a\\f\\Hlo_AF043.mp3",	--	You waste my time with your foolishness.
                "vo\\a\\f\\Hlo_AF047.mp3", --	You look unwell.
                "vo\\a\\f\\Hlo_AF048.mp3", --	It looks unwell, unhealthy...
                "vo\\a\\f\\Hlo_AF049.mp3", --	Death is upon you.
                "vo\\a\\f\\Hlo_AF057.mp3", --	Fresh game.
                "vo\\a\\f\\Hlo_AF079.mp3", --	It looks unwell, unhealthy...
                "vo\\a\\f\\Hlo_AF104.mp3", --	It looks unwell, unhealthy...
                -- "vo\\a\\f\\Hlo_AF131.mp3", --	You are unwell, friend.
            },
            [this.voice.loseRound] = {
                "vo\\a\\f\\Fle_AF002.mp3", --	Stop!
                -- "vo\\a\\f\\Fle_AF003.mp3", --	Go away!
                "vo\\a\\f\\Fle_AF004.mp3", --	No more!
                "vo\\a\\f\\Fle_AF005.mp3", --	Make it stop!
                "vo\\a\\f\\Hit_AF001.mp3",	--	Ungh!
                "vo\\a\\f\\Hit_AF002.mp3", --	Arrgh.
                "vo\\a\\f\\Hit_AF004.mp3", --	Groan.
                "vo\\a\\f\\Hit_AF005.mp3", --	Groan.
                "vo\\a\\f\\Hit_AF006.mp3", --	Groan.
                "vo\\a\\f\\Hit_AF007.mp3", --	Groan.
                "vo\\a\\f\\Hit_AF008.mp3", --	Grunt.
                "vo\\a\\f\\Hit_AF009.mp3", --	Grunt.
                "vo\\a\\f\\Hit_AF010.mp3", --	Grunt.
                "vo\\a\\f\\Hit_AF011.mp3", --	Grunt.
                "vo\\a\\f\\Hit_AF012.mp3", --	Grunt.
                "vo\\a\\f\\Hit_AF014.mp3", --	Hiss.
                -- "vo\\a\\f\\Hlo_AF024.mp3",	--	Return to me no more.
                "vo\\a\\f\\Hlo_AF025.mp3", --	Unwelcome it is.
                -- "vo\\a\\f\\Hlo_AF026.mp3", --	Don't bother me.
                -- "vo\\a\\f\\Hlo_AF028.mp3", --	Leave me.
                -- "vo\\a\\f\\Hlo_AF029.mp3", --	Go away, wretch.
            },
            [this.voice.winGame] = {
                "vo\\a\\f\\Hlo_AF071.mp3", --	Excuse me, sera.
                "vo\\a\\f\\Hlo_AF085.mp3", --	Be well, traveller.
                "vo\\a\\f\\Hlo_AF108.mp3", --	Your bidding, muthsera?
                "vo\\a\\f\\Hlo_AF135.mp3", --	Blessed we are.
                "vo\\a\\f\\Hlo_AF136.mp3", --	This is an honor for me.
            },
            [this.voice.think] = {
                "vo\\a\\f\\Hlo_AF000a.mp3", --	What?
                "vo\\a\\f\\Hlo_AF000b.mp3", --	Humph.
                "vo\\a\\f\\Hlo_AF000c.mp3", --	Humph.
                "vo\\a\\f\\Hlo_AF087.mp3",  --	Ah, yes. What is it?
                "vo\\a\\f\\Hlo_AF134.mp3",  --	What is this one before me?
                "vo\\a\\f\\Hlo_AF139.mp3",  --	Hisses
                "vo\\a\\f\\Idl_AF001.mp3",  --	Sniff.
                "vo\\a\\f\\Idl_AF002.mp3",  --	No. That's not it.
                "vo\\a\\f\\Idl_AF007.mp3",  --	What was that?
            },
            [this.voice.remind] = {
                "vo\\a\\f\\Hlo_AF040.mp3", --	Is there nothing for you to do?
                "vo\\a\\f\\Hlo_AF052.mp3", --	Questions?
                "vo\\a\\f\\Hlo_AF082.mp3", --	Friend?
                "vo\\a\\f\\Hlo_AF083.mp3", --	Yes?
                "vo\\a\\f\\Hlo_AF109.mp3", --	Share your thoughts.
                "vo\\a\\f\\Hlo_AF111.mp3", --	It wants something. What does it ask?
                -- "vo\\a\\f\\Hlo_AF132.mp3",	--	We work hard for you. Ease your burden.
                "vo\\a\\f\\Idl_AF008.mp3", --	Click, click, click.
            },
        },
        ["m"] = {
            [this.voice.continue] = {
                "vo\\a\\m\\Atk_AM012.mp3",	--	It will die!
                "vo\\a\\m\\Atk_AM015.mp3",	--	To the gods with you!
                "vo\\a\\m\\Hlo_AM011.mp3",	--	I will gladly add to your wounds if you do not leave.
                "vo\\a\\m\\Hlo_AM021.mp3",	--	Hiss!
                "vo\\a\\m\\Hlo_AM053.mp3",  --	The prey approaches.
                "vo\\a\\m\\Hlo_AM059.mp3",  --	The prey approaches.
                "vo\\a\\m\\Hlo_AM088.mp3",  --	Go ahead, speak.
                "vo\\a\\m\\Hlo_AM114.mp3",  --	Please, go ahead. Speak.
            },
            [this.voice.finish] = {
                "vo\\a\\m\\Atk_AM009.mp3",	--	A small trophy for my young!
                "vo\\a\\m\\Atk_AM010.mp3",	--	Bash!
                "vo\\a\\m\\Atk_AM013.mp3",	--	Suffer!
                "vo\\a\\m\\Atk_AM014.mp3",	--	Die!
                "vo\\a\\m\\Hlo_AM042.mp3",	--	You bother us. Do not waste our time.
                "vo\\a\\m\\Hlo_AM047.mp3",	--	You look unwell.
                "vo\\a\\m\\Hlo_AM048.mp3",  --	It looks unwell, unhealthy...
                "vo\\a\\m\\Hlo_AM049.mp3",  --	Death is upon you.
                "vo\\a\\m\\Hlo_AM057.mp3",  --	Fresh game.
                "vo\\a\\m\\Hlo_AM079.mp3",  --	It looks unwell, unhealthy...
                "vo\\a\\m\\Hlo_AM104.mp3",  --	It looks unwell, unhealthy...
            },
            [this.voice.loseRound] = {
                "vo\\a\\m\\Fle_AM001.mp3",	--	Stop! Help!
                "vo\\a\\m\\Fle_AM002.mp3",	--	Help us!
                -- "vo\\a\\m\\Fle_AM003.mp3",	--	Go away!
                "vo\\a\\m\\Fle_AM004.mp3",	--	No more!
                "vo\\a\\m\\Fle_AM005.mp3",	--	No!
                "vo\\a\\m\\Hit_AM001.mp3",	--	AAAIIEE!
                "vo\\a\\m\\Hit_AM002.mp3",	--	Arrhgh!
                "vo\\a\\m\\Hit_AM004.mp3",	--	Groan!
                "vo\\a\\m\\Hit_AM005.mp3",	--	Groan!
                "vo\\a\\m\\Hit_AM006.mp3",	--	Groan!
                "vo\\a\\m\\Hit_AM007.mp3",	--	Groan!
                "vo\\a\\m\\Hit_AM008.mp3",	--	Grunt!
                "vo\\a\\m\\Hit_AM009.mp3",	--	Grunt!
                "vo\\a\\m\\Hit_AM010.mp3",	--	Grunt!
                "vo\\a\\m\\Hit_AM012.mp3",	--	Grunt!
                "vo\\a\\m\\Hit_AM013.mp3",	--	Hiss!
                "vo\\a\\m\\Hit_AM014.mp3",	--	Hiss!
                "vo\\a\\m\\Hit_AM015.mp3",	--	Hiss!
                "vo\\a\\m\\Hit_AM016.mp3",	--	Arrgh!
                "vo\\a\\m\\Hlo_AM022.mp3",	--	Be gone!
                -- "vo\\a\\m\\Hlo_AM024.mp3",	--	Return to me no more.
                "vo\\a\\m\\Hlo_AM025.mp3",	--	Unwelcome it is.
                -- "vo\\a\\m\\Hlo_AM026.mp3",	--	Don't bother me.
                -- "vo\\a\\m\\Hlo_AM028.mp3",	--	Leave me.
                -- "vo\\a\\m\\Hlo_AM029.mp3",	--	Go away, stranger.
            },
            [this.voice.winGame] = {
                "vo\\a\\m\\Hlo_AM135.mp3",  --	Blessed we are.
                "vo\\a\\m\\Hlo_AM136.mp3",  --	This is an honor for me.
                "vo\\a\\m\\Hlo_AM071.mp3",  --	Excuse me, saer.
                "vo\\a\\m\\Hlo_AM085.mp3",  --	Be well, traveller.
                "vo\\a\\m\\Hlo_AM108.mp3",  --	Your bidding, Muthsera?
            },
            [this.voice.think] = {
                "vo\\a\\m\\Hlo_AM000a.mp3",	--	Growl!
                "vo\\a\\m\\Hlo_AM000b.mp3",	--	Humph.
                "vo\\a\\m\\Hlo_AM000c.mp3",	--	Grunt.
                "vo\\a\\m\\Hlo_AM000d.mp3",	--	Pest!
                "vo\\a\\m\\Hlo_AM000e.mp3",	--	Enough!
                "vo\\a\\m\\Idl_AM001.mp3",  --	Grunt.
                "vo\\a\\m\\Idl_AM003.mp3",  --	So much to remember.
                "vo\\a\\m\\Idl_AM008.mp3",  --	Grunt. Grunt. Grunt. Grunt. Grunt.
            },
            [this.voice.remind] = {
                "vo\\a\\m\\Hlo_AM040.mp3",	--	Is there nothing for you to do?
                "vo\\a\\m\\Hlo_AM052.mp3",  --	Questions?
                "vo\\a\\m\\Hlo_AM061.mp3",  --	Questions?
                "vo\\a\\m\\Hlo_AM082.mp3",  --	Friend?
                "vo\\a\\m\\Hlo_AM083.mp3",  --	Yes?
                "vo\\a\\m\\Hlo_AM087.mp3",  --	Ah, yes. What is it, Muthsera?
                "vo\\a\\m\\Hlo_AM089.mp3",  --	What is it? What do you want?
                "vo\\a\\m\\Hlo_AM109.mp3",  --	Share your thoughts, friend.
                "vo\\a\\m\\Hlo_AM111.mp3",  --	It wants something. What does it ask?
                -- "vo\\a\\m\\Hlo_AM132.mp3",  --	We work hard for you. Ease your burden.
                "vo\\a\\m\\Hlo_AM139.mp3",  --	Hiss!
                "vo\\a\\m\\Idl_AM002.mp3",  --	Small fork on outside, or is it inside....
            },
        },
    },
    ["breton"] = {
        ["f"] = {
            [this.voice.continue] = {
                "vo\\b\\f\\Atk_BF004.mp3",	--	You'll be dead soon!
                "vo\\b\\f\\Atk_BF006.mp3",	--	Death awaits you!
                "vo\\b\\f\\Atk_BF007.mp3",	--	Not long now!
                "vo\\b\\f\\Atk_BF009.mp3",	--	Soon you'll be reduced to dust!
                "vo\\b\\f\\Atk_BF010.mp3",	--	Come on, fight!
                "vo\\b\\f\\Hlo_BF086.mp3",	--	Go ahead, I'm listening.
                "vo\\b\\f\\Hlo_BF088.mp3",	--	I'm listening, please, go ahead.
                -- "vo\\b\\f\\Hlo_BF134.mp3",	--	Go ahead, please. Tell me about yourself.
                -- "vo\\b\\f\\Hlo_BF136.mp3",	--	I must say, I find you most interesting right now. Please, go ahead.
            },
            [this.voice.finish] = {
                "vo\\b\\f\\Atk_BF001.mp3",	--	Ha-ha!
                "vo\\b\\f\\Atk_BF002.mp3",	--	Ha!
                "vo\\b\\f\\Atk_BF003.mp3",	--	I have you!
                "vo\\b\\f\\Atk_BF005.mp3",	--	Your skills fail you!
                "vo\\b\\f\\Atk_BF008.mp3",	--	You should have run while you had a chance!
                "vo\\b\\f\\Atk_BF012.mp3",	--	My victory is at hand!
                "vo\\b\\f\\Atk_BF014.mp3",	--	To the death!
            },
            [this.voice.loseRound] = {
                "vo\\b\\f\\Fle_BF001.mp3",	--	You'll get yours!
                "vo\\b\\f\\Fle_BF002.mp3",	--	Help!
                "vo\\b\\f\\Fle_BF003.mp3",	--	Hey, leave me alone! I give up!
                "vo\\b\\f\\Fle_BF004.mp3",	--	I've had enough of this! I hope you get eaten by a kagouti!
                -- "vo\\b\\f\\Fle_BF005.mp3",	--	Go away!
                "vo\\b\\f\\Hit_BF001.mp3",	--	AAAIIEE.
                "vo\\b\\f\\Hit_BF002.mp3",	--	Oomph!
                "vo\\b\\f\\Hit_BF003.mp3",	--	Ack!
                "vo\\b\\f\\Hit_BF004.mp3",	--	Groan.
                "vo\\b\\f\\Hit_BF005.mp3",	--	Groan.
                "vo\\b\\f\\Hit_BF006.mp3",	--	Groan.
                "vo\\b\\f\\Hit_BF007.mp3",	--	Groan.
                "vo\\b\\f\\Hit_BF008.mp3",	--	Grunt.
                "vo\\b\\f\\Hit_BF009.mp3",	--	Grunt.
                "vo\\b\\f\\Hit_BF010.mp3",	--	Grunt.
                "vo\\b\\f\\Hit_BF011.mp3",	--	Grunt.
                "vo\\b\\f\\Hit_BF012.mp3",	--	Grunt.
                "vo\\b\\f\\Hit_BF013.mp3",	--	Hiss.
                "vo\\b\\f\\Hit_BF014.mp3",	--	Hiss.
                "vo\\b\\f\\Hit_BF015.mp3",	--	Hiss.
                -- "vo\\b\\f\\Hlo_BF000e.mp3",	--	Get out of here!
                "vo\\b\\f\\Hlo_BF014.mp3",	--	You're positively revolting.
                "vo\\b\\f\\Hlo_BF022.mp3",	--	This is most unsettling. Leave me.
            },
            [this.voice.winGame] = {
                "vo\\b\\f\\Hlo_BF000d.mp3",	--	I won't waste my time on the likes of you.
                "vo\\b\\f\\Hlo_BF001.mp3",	--	I think you should go elsewhere.
                "vo\\b\\f\\Hlo_BF011.mp3",	--	Whatever trouble you've gotten yourself into, you'll have to deal with it yourself.
                "vo\\b\\f\\Hlo_BF025.mp3",	--	No, I don't have time for you.
                "vo\\b\\f\\Hlo_BF116.mp3",	--	To what do I owe this pleasure?
                "vo\\b\\f\\Hlo_BF118.mp3",	--	My pleasure, truly.
            },
            [this.voice.think] = {
                "vo\\b\\f\\Hlo_BF000a.mp3",	--	What?
                "vo\\b\\f\\Hlo_BF000b.mp3",	--	Hmmph!
                "vo\\b\\f\\Hlo_BF000c.mp3",	--	Hmmph!
                "vo\\b\\f\\Hlo_BF026.mp3",	--	Well, this should be interesting.
                "vo\\b\\f\\Hlo_BF074.mp3",	--	What brings you out in this mess?
                "vo\\b\\f\\Hlo_BF084.mp3",	--	Yes, what is it?
                "vo\\b\\f\\Hlo_BF087.mp3",	--	I suppose I have a moment. What is it?
                "vo\\b\\f\\Idl_BF001.mp3",	--	What was that about?
                "vo\\b\\f\\Idl_BF003.mp3",	--	What was I thinking?
                "vo\\b\\f\\Idl_BF004.mp3",	--	Dirt, dirt, dirt, dirt, dirt. Everywhere dirt.
                "vo\\b\\f\\Idl_BF005.mp3",	--	Who put that there?
                "vo\\b\\f\\Idl_BF006.mp3",	--	Whistle.
                "vo\\b\\f\\Idl_BF007.mp3",	--	Cough.
                "vo\\b\\f\\Idl_BF008.mp3",	--	Clears throat.
                "vo\\b\\f\\Idl_BF009.mp3",	--	Sniff.
            },
            [this.voice.remind] = {
                "vo\\b\\f\\Hlo_BF027.mp3",	--	Don't press your luck.
                -- "vo\\b\\f\\Hlo_BF030.mp3",	--	Be quick about this or find someone else to talk to.
                "vo\\b\\f\\Hlo_BF041.mp3",	--	What say you?
                "vo\\b\\f\\Hlo_BF054.mp3",	--	I haven't much time, so be quick about this.
                "vo\\b\\f\\Hlo_BF055.mp3",	--	I hope this won't take long.
                -- "vo\\b\\f\\Hlo_BF056.mp3",	--	I am busy, so, if you will excuse me.
                "vo\\b\\f\\Hlo_BF058.mp3",	--	So what do you want?
                "vo\\b\\f\\Hlo_BF061.mp3",	--	Yes?
                -- "vo\\b\\f\\Hlo_BF089.mp3",	--	May I help you?
                "vo\\b\\f\\Hlo_BF090.mp3",	--	Do you need something?
                "vo\\b\\f\\Hlo_BF091.mp3",	--	Is there something I can do for you?
                -- "vo\\b\\f\\Hlo_BF109.mp3",	--	What can I do for you, friend?
                -- "vo\\b\\f\\Hlo_BF113.mp3",	--	What can I help you with?
                "vo\\b\\f\\Hlo_BF114.mp3",	--	How fair thee, friend?
                -- "vo\\b\\f\\Hlo_BF115.mp3",	--	Should you need something, I will be happy to oblige.
                -- "vo\\b\\f\\Hlo_BF135.mp3",	--	Share your thoughts, friend, I enjoy the company.
            },
        },
        ["m"] = {
            [this.voice.continue] = {
                "vo\\b\\m\\Atk_BM004.mp3",	--	You'll be dead soon!
                "vo\\b\\m\\Atk_BM006.mp3",	--	Death awaits you!
                "vo\\b\\m\\Atk_BM007.mp3",	--	Not long now!
                "vo\\b\\m\\Atk_BM009.mp3",	--	Soon you'll be reduced to dust!
                "vo\\b\\m\\Atk_BM010.mp3",	--	Come on, fight!
                "vo\\b\\m\\Hlo_BM086.mp3",	--	Go ahead, I'm listening.
                "vo\\b\\m\\Hlo_BM088.mp3",	--	I'm listening, please, go ahead.
                -- "vo\\b\\m\\Hlo_BM134.mp3",	--	I must say, I find you most interesting right now. Please, go ahead.
                -- "vo\\b\\m\\Hlo_BM136.mp3",	--	I must say, I find you most interesting right now. Please, go ahead.
            },
            [this.voice.finish] = {
                "vo\\b\\m\\Atk_BM001.mp3",	--	Ha-ha!
                "vo\\b\\m\\Atk_BM002.mp3",	--	Ha!
                "vo\\b\\m\\Atk_BM003.mp3",	--	I have you!
                "vo\\b\\m\\Atk_BM005.mp3",	--	Your skills fail you!
                "vo\\b\\m\\Atk_BM008.mp3",	--	You should have run while you had a chance!
                "vo\\b\\m\\Atk_BM012.mp3",	--	My victory is at hand!
                "vo\\b\\m\\Atk_BM014.mp3",	--	To the death!
                -- "vo\\b\\m\\CrAtk_BM001.mp3",	--	Arrgh!
                -- "vo\\b\\m\\CrAtk_BM002.mp3",	--	Rarrh!
                -- "vo\\b\\m\\CrAtk_BM003.mp3",	--	Huhh!
                -- "vo\\b\\m\\CrAtk_BM004.mp3",	--	Ha!
                -- "vo\\b\\m\\CrAtk_BM005.mp3",	--	Die!
                "vo\\b\\m\\Idl_BM005.mp3",	--	I shouldn't have pushed so hard.
            },
            [this.voice.loseRound] = {
                "vo\\b\\m\\Fle_BM001.mp3",	--	You've won this time, but you'll get yours!
                "vo\\b\\m\\Fle_BM002.mp3",	--	Help!
                "vo\\b\\m\\Fle_BM003.mp3",	--	Leave me alone!
                "vo\\b\\m\\Fle_BM004.mp3",	--	Not today.
                -- "vo\\b\\m\\Fle_BM005.mp3",	--	I have no more quarrel with you. Go away!
                "vo\\b\\m\\Hit_BM001.mp3",	--	AAAIIEE.
                "vo\\b\\m\\Hit_BM002.mp3",	--	Umph!
                "vo\\b\\m\\Hit_BM004.mp3",	--	Ow!
                "vo\\b\\m\\Hit_BM005.mp3",	--	Arghph!
                "vo\\b\\m\\Hit_BM006.mp3",	--	Ungh!
                "vo\\b\\m\\Hit_BM007.mp3",	--	Hungh!
                "vo\\b\\m\\Hit_BM008.mp3",	--	Gulp!
                "vo\\b\\m\\Hit_BM009.mp3",	--	Aaghph!
                "vo\\b\\m\\Hit_BM010.mp3",	--	Ungh!
                "vo\\b\\m\\Hit_BM011.mp3",	--	Ooof!
                "vo\\b\\m\\Hit_BM012.mp3",	--	Aaahgh!
                "vo\\b\\m\\Hit_BM013.mp3",	--	Unulph!
                "vo\\b\\m\\Hit_BM014.mp3",	--	Ungh!
                "vo\\b\\m\\Hit_BM015.mp3",	--	Wheeze!
                -- "vo\\b\\m\\Hlo_BM000e.mp3",	--	Get out of here!
                "vo\\b\\m\\Hlo_BM014.mp3",	--	You're positively revolting.
                "vo\\b\\m\\Hlo_BM022.mp3",	--	This is most unsettling. Leave me.
            },
            [this.voice.winGame] = {
                "vo\\b\\m\\Hlo_BM000d.mp3",	--	I won't waste my time on the likes of you!
                "vo\\b\\m\\Hlo_BM001.mp3",	--	I think you should go elsewhere.
                "vo\\b\\m\\Hlo_BM011.mp3",	--	Whatever trouble you've gotten yourself into, you'll have to deal with it yourself.
                "vo\\b\\m\\Hlo_BM025.mp3",	--	I don't have time for you.
                "vo\\b\\m\\Hlo_BM116.mp3",	--	To what do I owe this pleasure?
            },
            [this.voice.think] = {
                "vo\\b\\m\\Hlo_BM000a.mp3",	--	What?!
                "vo\\b\\m\\Hlo_BM000b.mp3",	--	Humph.
                "vo\\b\\m\\Hlo_BM000c.mp3",	--	Humph.
                "vo\\b\\m\\Hlo_BM026.mp3",	--	This should be interesting.
                "vo\\b\\m\\Hlo_BM058.mp3",	--	What's this then?
                "vo\\b\\m\\Hlo_BM059.mp3",	--	What's this about?
                "vo\\b\\m\\Hlo_BM060.mp3",	--	What's this regarding?
                "vo\\b\\m\\Idl_BM004.mp3",	--	Dirt, dirt, dirt, dirt, dirt. Everywhere dirt.
                "vo\\b\\m\\Idl_BM006.mp3",	--	Whistle.
                "vo\\b\\m\\Idl_BM007.mp3",	--	Humm.
                "vo\\b\\m\\Idl_BM008.mp3",	--	Clears throat.
                "vo\\b\\m\\Idl_BM009.mp3",	--	Sniff.
            },
            [this.voice.remind] = {
                "vo\\b\\m\\Hlo_BM027.mp3",	--	Don't press your luck.
                -- "vo\\b\\m\\Hlo_BM030.mp3",	--	Be quick about this or find someone else to talk to.
                "vo\\b\\m\\Hlo_BM041.mp3",	--	What say you?
                "vo\\b\\m\\Hlo_BM054.mp3",	--	I haven't much time, so be quick about this.
                "vo\\b\\m\\Hlo_BM055.mp3",	--	I hope this won't take long.
                -- "vo\\b\\m\\Hlo_BM056.mp3",	--	I am busy, so, if you will excuse me.
                "vo\\b\\m\\Hlo_BM057.mp3",	--	What do you want?
                "vo\\b\\m\\Hlo_BM061.mp3",	--	Yes, friend?
                "vo\\b\\m\\Hlo_BM083.mp3",	--	All right, I'm listening.
                "vo\\b\\m\\Hlo_BM087.mp3",	--	I suppose I have a moment. What is it?
                -- "vo\\b\\m\\Hlo_BM089.mp3",	--	May I help you?
                "vo\\b\\m\\Hlo_BM090.mp3",	--	Do you need something?
                "vo\\b\\m\\Hlo_BM091.mp3",	--	Is there something I can do for you?
                -- "vo\\b\\m\\Hlo_BM108.mp3",	--	What can I do for you, friend?
                "vo\\b\\m\\Hlo_BM109.mp3",	--	Tidings and good wishes to you.
                -- "vo\\b\\m\\Hlo_BM113.mp3",	--	What can I help you with?
                "vo\\b\\m\\Hlo_BM114.mp3",	--	How fair thee, friend?
                -- "vo\\b\\m\\Hlo_BM115.mp3",	--	Should you need something, I would be happy to oblige.
                -- "vo\\b\\m\\Hlo_BM135.mp3",	--	Well, I find myself in pleasant company. Please, share your thoughts.
                -- "vo\\b\\m\\Hlo_BM137.mp3",	--	Well, I find myself in pleasant company. Please, share your thoughts.
                "vo\\b\\m\\Idl_BM001.mp3",	--	Do I drop the sweetroll or hand it over and come back later? Dunno....
                "vo\\b\\m\\Idl_BM002.mp3",	--	The blue plates are nice, but the brown ones seem to last longer.
                "vo\\b\\m\\Idl_BM003.mp3",	--	I think that tavern girl was looking at me. How can I tell her I'm not interested?
            },
        },
    },
    ["dark elf"] = {
        ["f"] = {
            [this.voice.continue] = {
                "vo\\d\\f\\Atk_DF002.mp3",	--	Your life's end is approaching.
                "vo\\d\\f\\Atk_DF008.mp3",	--	You will suffer greatly!
                "vo\\d\\f\\Atk_DF009.mp3",	--	There is no escape!
                "vo\\d\\f\\Atk_DF010.mp3",	--	Your pain is nearing an end!
                "vo\\d\\f\\Atk_DF012.mp3",	--	You will die!
                "vo\\d\\f\\Atk_DF013.mp3",	--	Surrender your life to me and I will end your pain!
                "vo\\d\\f\\bAtk_DF003.mp3",	--	I've got a bone for you. Come and get it!
                "vo\\d\\f\\Fle_DF001.mp3",	--	This will not go unnoticed, you will be disgraced for this.
                "vo\\d\\f\\Hlo_DF025.mp3",	--	Go now.
                "vo\\d\\f\\Hlo_DF031.mp3",	--	Not today.
                "vo\\d\\f\\Hlo_DF036.mp3",	--	There's no time for talk now. Go.
                "vo\\d\\f\\Hlo_DF084.mp3",	--	Go ahead.
                -- "vo\\d\\f\\Hlo_DF092.mp3",	--	Come on, I haven't got all day to stand around and talk to you.
                "vo\\d\\f\\Hlo_DF123.mp3",	--	I'm listening. Go ahead.
                "vo\\d\\f\\Hlo_DF184.mp3",	--	Go ahead, I'm listening.
                "vo\\d\\f\\tHlo_DF159.mp3",	--	It's fine with me. Go ahead.
                "vo\\d\\f\\tHlo_DF160.mp3",	--	Go ahead. I'm waiting.
                -- "vo\\d\\f\\tHlo_DF171.mp3",	--	Go on. I can't stop you.
            },
            [this.voice.finish] = {
                "vo\\d\\f\\Atk_DF001.mp3",	--	Now you die.
                "vo\\d\\f\\Atk_DF003.mp3",	--	Die, fetcher.
                "vo\\d\\f\\Atk_DF004.mp3",	--	You n'wah!
                "vo\\d\\f\\Atk_DF005.mp3",	--	This is the end of you, s'wit.
                "vo\\d\\f\\Atk_DF011.mp3",	--	I have you!
                "vo\\d\\f\\bAtk_DF002.mp3",	--	Your head will be my new trophy!
                -- "vo\\d\\f\\CrAtk_DF001.mp3",	--	Arrgh!
                -- "vo\\d\\f\\CrAtk_DF002.mp3",	--	Rarrgh!
                -- "vo\\d\\f\\CrAtk_DF003.mp3",	--	Hurrrgh!
                -- "vo\\d\\f\\CrAtk_DF004.mp3",	--	Ha!
                -- "vo\\d\\f\\CrAtk_DF005.mp3",	--	Die!
                "vo\\d\\f\\Hlo_DF172.mp3",	--	Three blessings, sera.
                "vo\\d\\f\\Hlo_DF195.mp3",	--	We are blessed. Truly blessed. This is an honor.
                "vo\\d\\f\\tHlo_DF017.mp3",	--	Walk in the light, in the spirits' names.
                "vo\\d\\f\\tHlo_DF040.mp3",	--	I smell your blood, mortal.
                "vo\\d\\f\\tHlo_DF071.mp3",	--	Seven virtues, sera.
                "vo\\d\\f\\tHlo_DF075.mp3",	--	Out of our mouths, truth, sera.
                "vo\\d\\f\\tIdl_DF007.mp3",	--	No chance. None.
            },
            [this.voice.loseRound] = {
                -- "vo\\d\\f\\bFle_DF003.mp3",	--	Go away! I don't have any treats!
                "vo\\d\\f\\Fle_DF003.mp3",	--	I can't take anymore!
                "vo\\d\\f\\Fle_DF004.mp3",	--	Let me live!
                "vo\\d\\f\\Fle_DF005.mp3",	--	This fight is over!
                "vo\\d\\f\\Hit_DF001.mp3",	--	Arrgh.
                "vo\\d\\f\\Hit_DF002.mp3",	--	Eeek
                "vo\\d\\f\\Hit_DF003.mp3",	--	Ooph!
                "vo\\d\\f\\Hit_DF003.mp3",	--	Oooff.
                "vo\\d\\f\\Hit_DF004.mp3",	--	Ughn
                "vo\\d\\f\\Hit_DF005.mp3",	--	Stoopid.
                "vo\\d\\f\\Hit_DF006.mp3",	--	AIIEEE.
                -- "vo\\d\\f\\Hit_DF007.mp3",	--	Groan. (missing)
                "vo\\d\\f\\Hit_DF008.mp3",	--	Groan.
                "vo\\d\\f\\Hit_DF009.mp3",	--	Ungh!
                "vo\\d\\f\\Hit_DF009.mp3",	--	Groan.
                "vo\\d\\f\\Hit_DF010.mp3",	--	Grunt.
                "vo\\d\\f\\Hit_DF011.mp3",	--	Grunt.
                "vo\\d\\f\\Hit_DF012.mp3",	--	Groan.
                "vo\\d\\f\\Hit_DF013.mp3",	--	Growl.
                "vo\\d\\f\\Hit_DF014.mp3",	--	Gasp.
                -- "vo\\d\\f\\Hlo_DF000e.mp3",	--	Get out of here!
                -- "vo\\d\\f\\Hlo_DF001.mp3",	--	Go away.
                "vo\\d\\f\\Hlo_DF017.mp3",	--	I am not amused.
                "vo\\d\\f\\Hlo_DF029.mp3",	--	How rude!
                -- "vo\\d\\f\\Hlo_DF033.mp3",	--	Leave me.
                "vo\\d\\f\\Hlo_DF040.mp3",	--	I can already tell I'm not going to like this.
                -- "vo\\d\\f\\Hlo_DF041.mp3",	--	Oh, come on. Leave me alone.
                -- "vo\\d\\f\\Hlo_DF072.mp3",	--	Say what you want or go away.
                "vo\\d\\f\\Hlo_DF107.mp3",	--	We are punished by the gods. The wind is our suffering.
                -- "vo\\d\\f\\tHlo_DF007.mp3",	--	Get OUT! Now!
                "vo\\d\\f\\tHlo_DF033.mp3",	--	So much for THAT problem....
                -- "vo\\d\\f\\tHlo_DF034.mp3",	--	You BEAST! Get out of here!
                "vo\\d\\f\\tHlo_DF062.mp3",	--	Mind your tongue, sera.
                "vo\\d\\f\\tHlo_DF088.mp3",	--	It's terrible. Terrible. I'm so worried....
            },
            [this.voice.winGame] = {
                "vo\\d\\f\\bAtk_DF004.mp3",	--	I've fought guars more ferocious than you!
                "vo\\d\\f\\Hlo_DF000d.mp3",	--	I don't waste my time on the likes of you!
                "vo\\d\\f\\Hlo_DF022.mp3",	--	You waste your time. Go away.
                "vo\\d\\f\\Hlo_DF023.mp3",	--	You must be joking. Bother someone else.
                "vo\\d\\f\\Hlo_DF046.mp3",	--	If you'll excuse me, I don't have time for you right now. Or ever.
                "vo\\d\\f\\Hlo_DF077.mp3",	--	Spit it out or hit the road.
                "vo\\d\\f\\Hlo_DF219.mp3",	--	I'm very happy to make your acquaintance.
                "vo\\d\\f\\Hlo_DF222.mp3",	--	I don't know where to begin. It is such an honor to meet you.
                "vo\\d\\f\\Hlo_DF223.mp3",	--	It's so good to meet you.
                "vo\\d\\f\\tHlo_DF031.mp3",	--	You were very brave.
                "vo\\d\\f\\tHlo_DF045.mp3",	--	Respect is repaid, sera.
                "vo\\d\\f\\tHlo_DF046.mp3",	--	Your words are your measure, sera.
                "vo\\d\\f\\tHlo_DF047.mp3",	--	Blessings upon your house, sera.
                "vo\\d\\f\\tHlo_DF064.mp3",	--	I'll thank you to be brief, sera.
                "vo\\d\\f\\tHlo_DF065.mp3",	--	Life is a burden. Bear it with honor.
                "vo\\d\\f\\tHlo_DF067.mp3",	--	Forget tomorrow. If you are right, act today.
                "vo\\d\\f\\tHlo_DF069.mp3",	--	Do what is right, and all else shall follow.
                "vo\\d\\f\\tHlo_DF072.mp3",	--	Show respect, sera.
                "vo\\d\\f\\tHlo_DF073.mp3",	--	Gods grant you justice, sera.
                "vo\\d\\f\\tHlo_DF074.mp3",	--	I'll judge your words fairly, sera.
                "vo\\d\\f\\tHlo_DF076.mp3",	--	Walk in mercy, sera.
                "vo\\d\\f\\tHlo_DF078.mp3",	--	A pure reputation is wealth enough for me, sera.
                "vo\\d\\f\\tHlo_DF085.mp3",	--	Take care, stranger.
            },
            [this.voice.think] = {
                "vo\\d\\f\\bIdl_DF013.mp3",	--	*Pfbbbbbbbt*
                "vo\\d\\f\\bIdl_DF014.mp3",	--	Oh, not AGAIN!
                "vo\\d\\f\\Hlo_DF000a.mp3",	--	What?
                "vo\\d\\f\\Hlo_DF000b.mp3",	--	Humph!
                "vo\\d\\f\\Hlo_DF000c.mp3",	--	Groan.
                "vo\\d\\f\\Hlo_DF047.mp3",	--	What now?
                "vo\\d\\f\\Hlo_DF075.mp3",	--	No. I don't think so.
                "vo\\d\\f\\Hlo_DF079.mp3",	--	What now?
                "vo\\d\\f\\Hlo_DF080.mp3",	--	This better be important.
                "vo\\d\\f\\tHlo_DF041.mp3",	--	So much to do, so little time....
                "vo\\d\\f\\tHlo_DF027.mp3",	--	Excuse me, please.
                "vo\\d\\f\\tHlo_DF161.mp3",	--	Excuse me. Did you say something?
                "vo\\d\\f\\tHlo_DF162.mp3",	--	Excuse me. I was just thinking...
                "vo\\d\\f\\tIdl_DF012.mp3",	--	Gods, that itches.
            },
            [this.voice.remind] = {
                "vo\\d\\f\\bIdl_DF003.mp3",	--	An untidy tale comes to a sorry end.
                "vo\\d\\f\\bIdl_DF004.mp3",	--	Ah... ah... AH... CHOOOO!
                "vo\\d\\f\\bIdl_DF015.mp3",	--	[Wide yawn.]
                -- "vo\\d\\f\\Hlo_DF035.mp3",	--	Keep moving, scum.
                "vo\\d\\f\\Hlo_DF070.mp3",	--	Do you want something?
                "vo\\d\\f\\Hlo_DF074.mp3",	--	Whatever you're looking for, I'm sure I don't know how to find it.
                "vo\\d\\f\\Hlo_DF085.mp3",	--	What do you want?
                "vo\\d\\f\\Hlo_DF090.mp3",	--	My time is precious, so make it quick.
                "vo\\d\\f\\Hlo_DF091.mp3",	--	I'm waiting.
                "vo\\d\\f\\Hlo_DF095.mp3",	--	Let's hear it.
                "vo\\d\\f\\Hlo_DF096.mp3",	--	What is it, sera?
                "vo\\d\\f\\Hlo_DF119.mp3",	--	Muthsera?
                "vo\\d\\f\\Hlo_DF126.mp3",	--	What is this about?
                "vo\\d\\f\\Hlo_DF127.mp3",	--	Can we hurry this up?
                "vo\\d\\f\\Hlo_DF129.mp3",	--	What do you want?
                -- "vo\\d\\f\\Hlo_DF145.mp3",	--	May I help you?
                "vo\\d\\f\\Hlo_DF147.mp3",	--	Is there something you need?
                -- "vo\\d\\f\\Hlo_DF148.mp3",	--	Is there something I can do for you?
                -- "vo\\d\\f\\Hlo_DF179.mp3",	--	Tell me what you want.
                -- "vo\\d\\f\\Hlo_DF193.mp3",	--	Is there something I can do for you?
                "vo\\d\\f\\Idl_DF001.mp3",	--	Cough.
                "vo\\d\\f\\Idl_DF002.mp3",	--	Sniff.
                "vo\\d\\f\\Idl_DF003.mp3",	--	Sigh.
                "vo\\d\\f\\Idl_DF004.mp3",	--	Grumbling.
                -- "vo\\d\\f\\tHlo_DF018.mp3",	--	What do you want?
                -- "vo\\d\\f\\tHlo_DF020.mp3",	--	What do you want with me?
                "vo\\d\\f\\tHlo_DF036.mp3",	--	Well? What's going on?
                -- "vo\\d\\f\\tHlo_DF044.mp3",	--	Do you have a question for me, sera?
                "vo\\d\\f\\tHlo_DF079.mp3",	--	Be quick, and I shall serve you, sera.
                "vo\\d\\f\\tHlo_DF151.mp3",	--	I'm not busy now. What do you need?
                "vo\\d\\f\\tHlo_DF153.mp3",	--	Happy to help. What's your problem?
                "vo\\d\\f\\tHlo_DF155.mp3",	--	Whatever you want... within reason.
                "vo\\d\\f\\tHlo_DF157.mp3",	--	Yes?
                "vo\\d\\f\\tHlo_DF165.mp3",	--	What is it now?
                "vo\\d\\f\\tHlo_DF167.mp3",	--	Will this take long?
                "vo\\d\\f\\tHlo_DF169.mp3",	--	Well?
                "vo\\d\\f\\tHlo_DF170.mp3",	--	So? You want something?
                "vo\\d\\f\\tHlo_DF172.mp3",	--	If you insist...
            },
        },
        ["m"] = {
            [this.voice.continue] = {
                "vo\\d\\m\\Atk_DM002.mp3",	--	Your life's end is approaching.
                "vo\\d\\m\\Atk_DM007.mp3",	--	You will suffer greatly.
                "vo\\d\\m\\Atk_DM008.mp3",	--	There is no escape.
                "vo\\d\\m\\Atk_DM009.mp3",	--	Your pain is nearing an end.
                "vo\\d\\m\\Atk_DM011.mp3",	--	You will die.
                "vo\\d\\m\\Atk_DM012.mp3",	--	Surrender your life to me and I will end your pain!
                "vo\\d\\m\\bAtk_DM003.mp3",	--	I've got a bone for you. Come and get it!
                "vo\\d\\m\\Fle_DM001.mp3",	--	This will not go unnoticed!
                "vo\\d\\m\\Hlo_DM025.mp3",	--	Go now.
                "vo\\d\\m\\Hlo_DM031.mp3",	--	Not today.
                "vo\\d\\m\\Hlo_DM084.mp3",	--	Go ahead.
                "vo\\d\\m\\Hlo_DM094.mp3",	--	I've got better things to do, so, if you don't mind, let's move this along.
                "vo\\d\\m\\Hlo_DM123.mp3",	--	I'm listening. Go ahead.
                "vo\\d\\m\\Hlo_DM184.mp3",	--	Go ahead, I'm listening.
                "vo\\d\\m\\tHlo_DM032.mp3",	--	Carry on. I'm listening.
                "vo\\d\\m\\tHlo_DM058.mp3",	--	Could it get any worse?
                "vo\\d\\m\\tHlo_DM069.mp3",	--	Welcome to MY world, where we do things MY way.
                "vo\\d\\m\\tHlo_DM083.mp3",	--	Show respect, sera.
                "vo\\d\\m\\tHlo_DM187.mp3",	--	It's fine with me. Go ahead.
                "vo\\d\\m\\tHlo_DM188.mp3",	--	Go ahead. I'm waiting.
                -- "vo\\d\\m\\tHlo_DM199.mp3",	--	Go on. I can't stop you.
                "vo\\d\\m\\tIdl_DM002.mp3",	--	Try me, and you'll regret it.
            },
            [this.voice.finish] = {
                "vo\\d\\m\\Atk_DM001.mp3",	--	Now you die.
                "vo\\d\\m\\Atk_DM003.mp3",	--	Die, fetcher.
                "vo\\d\\m\\Atk_DM004.mp3",	--	You n'wah!
                "vo\\d\\m\\Atk_DM005.mp3",	--	This is the end of you, s'wit.
                -- "vo\\d\\m\\Atk_DM006.mp3",	--	ARRRR!
                "vo\\d\\m\\Atk_DM010.mp3",	--	I have you.
                "vo\\d\\m\\Atk_DM013.mp3",	--	You're beaten.
                "vo\\d\\m\\Atk_DM014.mp3",	--	Your wounds are great!
                "vo\\d\\m\\bAtk_DM002.mp3",	--	Your head will be my new trophy!
                -- "vo\\d\\m\\CrAtk_AM001.mp3",	--	Arrgh!
                -- "vo\\d\\m\\CrAtk_AM002.mp3",	--	Hrarh!
                -- "vo\\d\\m\\CrAtk_AM003.mp3",	--	Hungh!
                -- "vo\\d\\m\\CrAtk_AM004.mp3",	--	Ha!
                -- "vo\\d\\m\\CrAtk_AM005.mp3",	--	Die!
                "vo\\d\\m\\Hlo_DM172.mp3",	--	Three blessings, sera.
                "vo\\d\\m\\Hlo_DM195.mp3",	--	We are blessed. Truly blessed. This is an honor.
                "vo\\d\\m\\tHlo_DM023.mp3",	--	We are in your debt, sera.
                "vo\\d\\m\\tHlo_DM027.mp3",	--	We are pleased to see you, sera.
                "vo\\d\\m\\tHlo_DM028.mp3",	--	Welcome, sera.
                "vo\\d\\m\\tHlo_DM035.mp3",	--	What are YOU staring at?
                "vo\\d\\m\\tHlo_DM041.mp3",	--	Look on me, and despair!
                "vo\\d\\m\\tHlo_DM060.mp3",	--	It's never easy, is it?
                "vo\\d\\m\\tHlo_DM064.mp3",	--	We print the truth -- the straight truth.
                "vo\\d\\m\\tHlo_DM074.mp3",	--	Justice never sleeps.
                "vo\\d\\m\\tHlo_DM080.mp3",	--	Do what is right, and all else shall follow.
                "vo\\d\\m\\tHlo_DM084.mp3",	--	Gods grant you justice, sera.
                "vo\\d\\m\\tIdl_DM004.mp3",	--	Trust in Gods and Justice.
            },
            [this.voice.loseRound] = {
                -- "vo\\d\\m\\bFle_DM003.mp3",	--	Go away! I don't have any treats!
                "vo\\d\\m\\bHlo_DM004.mp3",	--	Uh... there's a perfectly good explanation for this, I assure you...
                "vo\\d\\m\\bIdl_DM002.mp3",	--	The sun shines every day in hell.
                "vo\\d\\m\\Fle_DM003.mp3",	--	I cannot take anymore!
                "vo\\d\\m\\Fle_DM004.mp3",	--	Let me live!
                "vo\\d\\m\\Fle_DM005.mp3",	--	You will be disgraced for this!
                "vo\\d\\m\\Hit_DM001.mp3",	--	Arrgh.
                "vo\\d\\m\\Hit_DM002.mp3",	--	Umph!
                "vo\\d\\m\\Hit_DM003.mp3",	--	Omph!
                "vo\\d\\m\\Hit_DM004.mp3",	--	Ughn
                "vo\\d\\m\\Hit_DM005.mp3",	--	Grunt.
                "vo\\d\\m\\Hit_DM006.mp3",	--	Argh!
                "vo\\d\\m\\Hit_DM007.mp3",	--	Grunt!
                "vo\\d\\m\\Hit_DM008.mp3",	--	Grunt!
                "vo\\d\\m\\Hit_DM009.mp3",	--	Groan!
                "vo\\d\\m\\Hit_DM010.mp3",	--	Umph!
                "vo\\d\\m\\Hit_DM011.mp3",	--	Ungh!
                "vo\\d\\m\\Hit_DM012.mp3",	--	Ugh!
                "vo\\d\\m\\Hit_DM013.mp3",	--	Unngh!
                "vo\\d\\m\\Hit_DM014.mp3",	--	Ungh!
                "vo\\d\\m\\Hlo_DM000e.mp3",	--	That is quite enough!
                -- "vo\\d\\m\\Hlo_DM001.mp3",	--	Go away.
                "vo\\d\\m\\Hlo_DM017.mp3",	--	I am not amused.
                -- "vo\\d\\m\\Hlo_DM026.mp3",	--	What, n'wah?
                "vo\\d\\m\\Hlo_DM029.mp3",	--	How rude!
                -- "vo\\d\\m\\Hlo_DM030.mp3",	--	Must you be so annoying? Go away.
                -- "vo\\d\\m\\Hlo_DM033.mp3",	--	Leave me.
                -- "vo\\d\\m\\Hlo_DM041.mp3",	--	Oh, come on. Leave me alone.
                -- "vo\\d\\m\\Hlo_DM072.mp3",	--	Say what you want or go away.
                "vo\\d\\m\\Hlo_DM107.mp3",	--	We are punished by the gods. The wind is our suffering.
                "vo\\d\\m\\tHlo_DM008.mp3",	--	Well, well, well. Aren't YOU the tasty little morsel?
                "vo\\d\\m\\tHlo_DM043.mp3",	--	Mind your tongue, sera.
                -- "vo\\d\\m\\tHlo_DM049.mp3",	--	Scram, f'lah.
                "vo\\d\\m\\tHlo_DM071.mp3",	--	Yes? W-w-what? What do you w-w-want?
                "vo\\d\\m\\tHlo_DM072.mp3",	--	Oh, dear. Oh, m-m-my. Goddess protect me.
            },
            [this.voice.winGame] = {
                "vo\\d\\m\\bAtk_DM004.mp3",	--	I've fought guars more ferocious than you!
                --"vo\\d\\m\\bIdl_DM001.mp3",	--	The best swimmers are soonest drowned. (missing)
                "vo\\d\\m\\Hlo_DM023.mp3",	--	You must be joking. Bother someone else.
                "vo\\d\\m\\Hlo_DM022.mp3",	--	You waste your time. Go away.
                "vo\\d\\m\\Hlo_DM024.mp3",	--	Whatever it is, I'm not interested.
                "vo\\d\\m\\Hlo_DM046.mp3",	--	If you'll excuse me, I don't have time for you right now. Or ever.
                "vo\\d\\m\\Hlo_DM077.mp3",	--	Spit it out or hit the road.
                "vo\\d\\m\\Hlo_DM216.mp3",	--	This one honors us. Please, speak.
                "vo\\d\\m\\Hlo_DM219.mp3",	--	I'm very happy to make your acquaintance.
                "vo\\d\\m\\Hlo_DM222.mp3",	--	I don't know where to begin. It is such an honor to meet you.
                "vo\\d\\m\\Hlo_DM223.mp3",	--	It's so good to meet you.
                "vo\\d\\m\\tHlo_DM001.mp3",	--	Peace! Now I must be silent, and join my ancestors.
                "vo\\d\\m\\tHlo_DM006.mp3",	--	With the right deal, we all profit.
                "vo\\d\\m\\tHlo_DM007.mp3",	--	Hey there, sport. What's the word?
                "vo\\d\\m\\tHlo_DM026.mp3",	--	Your reputation does you honor, sera.
                "vo\\d\\m\\tHlo_DM045.mp3",	--	I'll thank you to be brief, sera.
                "vo\\d\\m\\tHlo_DM057.mp3",	--	Not bad for an amateur.
                "vo\\d\\m\\tHlo_DM059.mp3",	--	Relax. You'll be fine.
                "vo\\d\\m\\tHlo_DM063.mp3",	--	I'll thank you to be brief, sera.
                "vo\\d\\m\\tHlo_DM076.mp3",	--	Life is a burden. Bear it with honor.
                "vo\\d\\m\\tHlo_DM077.mp3",	--	Honor is food and drink for the soul.
                "vo\\d\\m\\tHlo_DM078.mp3",	--	Forget tomorrow. If you are right, act today.
                "vo\\d\\m\\tHlo_DM082.mp3",	--	Seven virtues, sera.
                "vo\\d\\m\\tHlo_DM086.mp3",	--	Out of our mouths, truth, sera.
                "vo\\d\\m\\tHlo_DM087.mp3",	--	Walk in mercy, sera.
                "vo\\d\\m\\tHlo_DM089.mp3",	--	A pure reputation is wealth enough for me, sera.
                "vo\\d\\m\\tHlo_DM097.mp3",	--	Respect is repaid, sera.
                "vo\\d\\m\\tHlo_DM099.mp3",	--	Blessings upon your house, sera.
                "vo\\d\\m\\tHlo_DM113.mp3",	--	I'll thank you to be brief, sera.
            },
            [this.voice.think] = {
                "vo\\d\\m\\bHlo_DM006.mp3",	--	Here to choose from our incredibly limited selection? What'll it be?
                "vo\\d\\m\\bHlo_DM007.mp3",	--	So old.... So weary.
                "vo\\d\\m\\bIdl_DM004.mp3",	--	Uh-oh!
                "vo\\d\\m\\bIdl_DM005.mp3",	--	Please, not again....
                "vo\\d\\m\\bIdl_DM006.mp3",	--	How'd that get there?
                "vo\\d\\m\\bIdl_DM012.mp3",	--	*Pfbbbbbbbt*
                "vo\\d\\m\\bIdl_DM013.mp3",	--	Oh, not AGAIN!
                "vo\\d\\m\\Hlo_DM000b.mp3",	--	Humph.
                "vo\\d\\m\\Hlo_DM000c.mp3",	--	Hmmph.
                "vo\\d\\m\\Hlo_DM040.mp3",	--	I can already tell I'm not going to like this.
                "vo\\d\\m\\Hlo_DM075.mp3",	--	No. I don't think so.
                "vo\\d\\m\\Hlo_DM079.mp3",	--	What now?
                "vo\\d\\m\\Hlo_DM080.mp3",	--	This better be important.
                "vo\\d\\m\\Idl_DM007.mp3",	--	What was that?
                "vo\\d\\m\\Idl_DM008.mp3",	--	Probably nothing.
                "vo\\d\\m\\tHlo_DM010.mp3",	--	Take care, stranger.
                "vo\\d\\m\\tHlo_DM031.mp3",	--	Yes, I've been around, I can tell you. Been there done that....
                "vo\\d\\m\\tHlo_DM052.mp3",	--	Sorry. Not interested.
                "vo\\d\\m\\tHlo_DM073.mp3",	--	What is it now? Must we go on?
                "vo\\d\\m\\tHlo_DM116.mp3",	--	Gods' grief! What next?
                "vo\\d\\m\\tHlo_DM189.mp3",	--	Excuse me. Did you say something?
                "vo\\d\\m\\tHlo_DM190.mp3",	--	Excuse me. I was just thinking...
                "vo\\d\\m\\tIdl_DM003.mp3",	--	A hard judge, but fair.
                "vo\\d\\m\\tIdl_DM006.mp3",	--	What are you gawking at?
                "vo\\d\\m\\tIdl_DM008.mp3",	--	Must be going crazy, talking to myself like this...
                "vo\\d\\m\\tIdl_DM019.mp3",	--	[Laughter]
            },
            [this.voice.remind] = {
                "vo\\d\\m\\bIdl_DM003.mp3",	--	Ah... ah... AH... CHOOOO!
                "vo\\d\\m\\bIdl_DM007.mp3",	--	Well, if it bothers you so much, just don't look at it, all right?
                "vo\\d\\m\\bIdl_DM014.mp3",	--	[Wide yawn.]
                -- "vo\\d\\m\\Hlo_DM035.mp3",	--	Keep moving, scum.
                "vo\\d\\m\\Hlo_DM047.mp3",	--	What now?
                "vo\\d\\m\\Hlo_DM070.mp3",	--	Do you want something?
                "vo\\d\\m\\Hlo_DM074.mp3",	--	Whatever you're looking for, I'm sure I don't know how to find it.
                "vo\\d\\m\\Hlo_DM085.mp3",	--	What do you want?
                -- "vo\\d\\m\\Hlo_DM090.mp3",	--	My time is precious, so make it quick.
                "vo\\d\\m\\Hlo_DM091.mp3",	--	I'm waiting.
                "vo\\d\\m\\Hlo_DM096.mp3",	--	What is it, sera?
                "vo\\d\\m\\Hlo_DM119.mp3",	--	Muthsera?
                "vo\\d\\m\\Hlo_DM126.mp3",	--	What is this about?
                "vo\\d\\m\\Hlo_DM127.mp3",	--	Can we hurry this up?
                "vo\\d\\m\\Hlo_DM129.mp3",	--	What do you want?
                -- "vo\\d\\m\\Hlo_DM145.mp3",	--	May I help you?
                "vo\\d\\m\\Hlo_DM147.mp3",	--	Is there something you need?
                -- "vo\\d\\m\\Hlo_DM148.mp3",	--	Is there something I can do for you?
                "vo\\d\\m\\Hlo_DM179.mp3",	--	Tell me what you want.
                -- "vo\\d\\m\\Hlo_DM193.mp3",	--	Is there something I can do for you?
                "vo\\d\\m\\Idl_DM001.mp3",	--	Cough.
                "vo\\d\\m\\Idl_DM002.mp3",	--	Sniff.
                "vo\\d\\m\\Idl_DM003.mp3",	--	Sigh.
                "vo\\d\\m\\Idl_DM004.mp3",	--	Grumbling.
                -- "vo\\d\\m\\tHlo_DM090.mp3",	--	Be quick, and I shall serve you, sera.
                "vo\\d\\m\\tHlo_DM179.mp3",	--	I'm not busy now. What do you need?
                -- "vo\\d\\m\\tHlo_DM181.mp3",	--	Happy to help. What's your problem?
                "vo\\d\\m\\tHlo_DM183.mp3",	--	Whatever you want... within reason.
                "vo\\d\\m\\tHlo_DM185.mp3",	--	Yes?
                "vo\\d\\m\\tHlo_DM193.mp3",	--	What is it now?
                "vo\\d\\m\\tHlo_DM195.mp3",	--	Will this take long?
                "vo\\d\\m\\tHlo_DM197.mp3",	--	Well?
                "vo\\d\\m\\tHlo_DM198.mp3",	--	So? You want something?
                "vo\\d\\m\\tHlo_DM200.mp3",	--	If you insist...
                "vo\\d\\m\\tIdl_DM007.mp3",	--	Do I care?
                "vo\\d\\m\\tIdl_DM018.mp3",	--	Ahh... ahh... CHUE!
                "vo\\d\\m\\tIdl_DM021.mp3",	--	Woo-hoo-hoo-hoo!
                "vo\\d\\m\\tIdl_DM022.mp3",	--	Dah-da-dah-de-dah-de-dah.
            },
        },
    },
    ["high elf"] = {
        ["f"] = {
            [this.voice.continue] = {
                "vo\\h\\f\\Atk_HF007.mp3",	--	You will die in disgrace.
                "vo\\h\\f\\Atk_HF013.mp3",	--	You'll soon be nothing more than a bad memory!
                "vo\\h\\f\\Atk_HF014.mp3",	--	I shall enjoy watching you take your last breath.
                "vo\\h\\f\\Hlo_HF013.mp3",	--	There are other places to die. I suggest you find one.
                "vo\\h\\f\\Hlo_HF040.mp3",	--	Identify yourself.
                "vo\\h\\f\\Hlo_HF056.mp3",	--	Identify yourself.
                "vo\\h\\f\\Hlo_HF110.mp3",	--	All right, I'm intrigued. Go ahead.
                "vo\\h\\f\\Hlo_HF111.mp3",	--	This is unexpected, but not unwelcome. Please go ahead.
            },
            [this.voice.finish] = {
                "vo\\h\\f\\Atk_HF011.mp3",	--	It's over for you!
                "vo\\h\\f\\Atk_HF012.mp3",	--	Embrace your demise!
                "vo\\h\\f\\Atk_HF015.mp3",	--	Your end is here!
                "vo\\h\\f\\Fle_HF004.mp3",	--	You had your chance!
                "vo\\h\\f\\Hlo_HF012.mp3",	--	You look fairly beaten. Care for more?
                "vo\\h\\f\\Hlo_HF029.mp3",	--	Spare me the formalities and get to the point.
                "vo\\h\\f\\Hlo_HF041.mp3",	--	Hail.
                "vo\\h\\f\\Hlo_HF049.mp3",	--	Trouble seems to have found you and given you a good kicking.
                "vo\\h\\f\\Hlo_HF092.mp3",	--	Hail.
            },
            [this.voice.loseRound] = {
                "vo\\h\\f\\Fle_HF003.mp3",	--	I give up!
                "vo\\h\\f\\Fle_HF005.mp3",	--	No!
                "vo\\h\\f\\Hit_HF001.mp3",	--	AAAIIEE.
                "vo\\h\\f\\Hit_HF002.mp3",	--	Arrgh.
                "vo\\h\\f\\Hit_HF003.mp3",	--	Fetcher!
                "vo\\h\\f\\Hit_HF004.mp3",	--	Groan.
                "vo\\h\\f\\Hit_HF005.mp3",	--	Groan.
                "vo\\h\\f\\Hit_HF006.mp3",	--	Ungh!
                "vo\\h\\f\\Hit_HF007.mp3",	--	Groan.
                "vo\\h\\f\\Hit_HF008.mp3",	--	Grunt.
                "vo\\h\\f\\Hit_HF009.mp3",	--	Grunt.
                "vo\\h\\f\\Hit_HF010.mp3",	--	Grunt.
                "vo\\h\\f\\Hit_HF011.mp3",	--	Grunt.
                "vo\\h\\f\\Hit_HF012.mp3",	--	Grunt.
                "vo\\h\\f\\Hit_HF013.mp3",	--	Hiss.
                "vo\\h\\f\\Hit_HF014.mp3",	--	Ungh!
                "vo\\h\\f\\Hit_HF015.mp3",	--	Hiss.
                -- "vo\\h\\f\\Hlo_HF000e.mp3",	--	Get out of here!
                "vo\\h\\f\\Hlo_HF019.mp3",	--	I sense great hostility -- mine.
                "vo\\h\\f\\Hlo_HF027.mp3",	--	You again. How tiresome.
                "vo\\h\\f\\Idl_HF001.mp3",	--	The indignity of it all.
            },
            [this.voice.winGame] = {
                "vo\\h\\f\\Hlo_HF000d.mp3",	--	Clearly, you are an idiot.
                "vo\\h\\f\\Hlo_HF001.mp3",	--	I haven't any time for you now.
                "vo\\h\\f\\Hlo_HF055.mp3",	--	You will address me with respect.
                "vo\\h\\f\\Hlo_HF117.mp3",	--	Ah, there's an intelligent face.
                "vo\\h\\f\\Hlo_HF134.mp3",	--	An honor to be sure.
                "vo\\h\\f\\Hlo_HF135.mp3",	--	How delightful! Welcome.
            },
            [this.voice.think] = {
                "vo\\h\\f\\Hlo_HF000a.mp3",	--	What?
                "vo\\h\\f\\Hlo_HF000b.mp3",	--	Hmph!
                "vo\\h\\f\\Hlo_HF000c.mp3",	--	Hmph!
                "vo\\h\\f\\Hlo_HF024.mp3",	--	Do you mind?
                "vo\\h\\f\\Hlo_HF025.mp3",	--	This better be good.
                "vo\\h\\f\\Hlo_HF026.mp3",	--	This is an unwelcome surprise.
                "vo\\h\\f\\Hlo_HF085.mp3",	--	I suppose I could spare a moment or two.
                "vo\\h\\f\\Hlo_HF109.mp3",	--	Well, what have we here? Interesting.
            },
            [this.voice.remind] = {
                -- "vo\\h\\f\\Hlo_HF054.mp3",	--	Is it necessary that you speak with ME?
                "vo\\h\\f\\Hlo_HF057.mp3",	--	You have something to say to me?
                "vo\\h\\f\\Hlo_HF059.mp3",	--	My patience is limited.
                "vo\\h\\f\\Hlo_HF060.mp3",	--	Can we hurry this along?
                -- "vo\\h\\f\\Hlo_HF061.mp3",	--	What assistance do you need?
                "vo\\h\\f\\Hlo_HF082.mp3",	--	Any time now.
                "vo\\h\\f\\Hlo_HF083.mp3",	--	You have my attention.
                "vo\\h\\f\\Hlo_HF089.mp3",	--	Do you want something?
                "vo\\h\\f\\Idl_HF006.mp3",	--	Whistle.
                "vo\\h\\f\\Idl_HF007.mp3",	--	Humm.
                "vo\\h\\f\\Idl_HF008.mp3",	--	Cough.
            },
        },
        ["m"] = {
            [this.voice.continue] = {
                "vo\\h\\m\\Atk_HM001.mp3",	--	This will be the end of you!
                "vo\\h\\m\\Atk_HM003.mp3",	--	Prepare to die!
                "vo\\h\\m\\Atk_HM005.mp3",	--	You haven't a chance against me!
                "vo\\h\\m\\Atk_HM006.mp3",	--	Your suffering will be great!
                "vo\\h\\m\\Atk_HM007.mp3",	--	You will die in disgrace.
                "vo\\h\\m\\Atk_HM013.mp3",	--	You'll soon be nothing more than a bad memory!
                "vo\\h\\m\\Hlo_HM040.mp3",	--	Identify yourself.
                "vo\\h\\m\\Hlo_HM056.mp3",	--	Identify yourself.
                "vo\\h\\m\\Hlo_HM110.mp3",	--	All right, I'm intrigued. Go ahead.
                "vo\\h\\m\\Hlo_HM111.mp3",	--	This is unexpected, but not unwelcome. Please go ahead.
            },
            [this.voice.finish] = {
                "vo\\h\\m\\Atk_HM002.mp3",	--	Your moment is at an end!
                "vo\\h\\m\\Atk_HM008.mp3",	--	You're defeated, give up.
                "vo\\h\\m\\Atk_HM009.mp3",	--	HUHHH.
                "vo\\h\\m\\Atk_HM010.mp3",	--	AAAAAAYYYY.
                "vo\\h\\m\\Atk_HM011.mp3",	--	It's over for you!
                "vo\\h\\m\\Atk_HM012.mp3",	--	Embrace your demise!
                "vo\\h\\m\\Atk_HM014.mp3",	--	I shall enjoy watching you take your last breath.
                "vo\\h\\m\\Atk_HM015.mp3",	--	Your end is here!
                -- "vo\\h\\m\\CrAtk_HM001.mp3",	--	Arrrgh!
                -- "vo\\h\\m\\CrAtk_HM002.mp3",	--	Hurrrhhh!
                -- "vo\\h\\m\\CrAtk_HM003.mp3",	--	Hurrragh!
                -- "vo\\h\\m\\CrAtk_HM004.mp3",	--	Hah!
                -- "vo\\h\\m\\CrAtk_HM005.mp3",	--	Die!
                "vo\\h\\m\\Hlo_HM012.mp3",	--	You look fairly beaten. Care for more?
                "vo\\h\\m\\Hlo_HM029.mp3",	--	Spare me the formalities and get to the point.
                "vo\\h\\m\\Hlo_HM041.mp3",	--	Hail.
                "vo\\h\\m\\Hlo_HM092.mp3",	--	Hail.
            },
            [this.voice.loseRound] = {
                "vo\\h\\m\\Fle_HM003.mp3",	--	I give up! Let me live!
                "vo\\h\\m\\Fle_HM004.mp3",	--	You had your chance!
                "vo\\h\\m\\Fle_HM005.mp3",	--	Don't kill me!
                "vo\\h\\m\\Hit_HM001.mp3",	--	Arrgh!
                "vo\\h\\m\\Hit_HM002.mp3",	--	Upmph!
                "vo\\h\\m\\Hit_HM003.mp3",	--	Ungh!
                "vo\\h\\m\\Hit_HM004.mp3",	--	Groan.
                "vo\\h\\m\\Hit_HM005.mp3",	--	Upmph!
                "vo\\h\\m\\Hit_HM006.mp3",	--	Argh!
                "vo\\h\\m\\Hit_HM007.mp3",	--	Ungh!
                "vo\\h\\m\\Hit_HM008.mp3",	--	Ungh!
                "vo\\h\\m\\Hit_HM009.mp3",	--	Ommph!
                "vo\\h\\m\\Hit_HM010.mp3",	--	Aughph!
                "vo\\h\\m\\Hit_HM011.mp3",	--	Grunt!
                "vo\\h\\m\\Hit_HM012.mp3",	--	Umph!
                "vo\\h\\m\\Hit_HM013.mp3",	--	Humph!
                "vo\\h\\m\\Hit_HM015.mp3",	--	Unghaaaah!
                -- "vo\\h\\m\\Hlo_HM000e.mp3",	--	Get out of here!
                "vo\\h\\m\\Hlo_HM019.mp3",	--	I sense great hostility -- mine.
                "vo\\h\\m\\Hlo_HM027.mp3",	--	You again. How tiresome.
            },
            [this.voice.winGame] = {
                "vo\\h\\m\\Hlo_HM001.mp3",	--	I haven't any time for you now.
                "vo\\h\\m\\Hlo_HM049.mp3",	--	Trouble seems to have found you and given you a good kicking.
                "vo\\h\\m\\Hlo_HM055.mp3",	--	You will address me with respect.
                "vo\\h\\m\\Hlo_HM104.mp3",	--	How tragic, you're barely standing.
                "vo\\h\\m\\Hlo_HM117.mp3",	--	Ah, there's an intelligent face.
                "vo\\h\\m\\Hlo_HM130.mp3",	--	How tragic, friend! You're barely standing.
                "vo\\h\\m\\Hlo_HM134.mp3",	--	An honor to be sure.
                "vo\\h\\m\\Hlo_HM135.mp3",	--	How delightful! Welcome.
            },
            [this.voice.think] = {
                "vo\\h\\m\\Hlo_HM000a.mp3",	--	What?!
                "vo\\h\\m\\Hlo_HM000b.mp3",	--	Humph!
                "vo\\h\\m\\Hlo_HM000c.mp3",	--	Humph!
                "vo\\h\\m\\Hlo_HM024.mp3",	--	Do you mind?
                "vo\\h\\m\\Hlo_HM025.mp3",	--	This better be good.
                "vo\\h\\m\\Hlo_HM026.mp3",	--	This is an unwelcome surprise.
                "vo\\h\\m\\Hlo_HM085.mp3",	--	I suppose I could spare a moment or two.
                "vo\\h\\m\\Hlo_HM109.mp3",	--	Well, what have we here? Interesting.
            },
            [this.voice.remind] = {
                -- "vo\\h\\m\\Hlo_HM000d.mp3",	--	I won't waste my time on the likes of you!
                "vo\\h\\m\\Hlo_HM057.mp3",	--	You have something to say to me?
                "vo\\h\\m\\Hlo_HM059.mp3",	--	My patience is limited.
                "vo\\h\\m\\Hlo_HM060.mp3",	--	Can we hurry this along?
                "vo\\h\\m\\Hlo_HM061.mp3",	--	What assistance do you need?
                "vo\\h\\m\\Hlo_HM082.mp3",	--	Any time now.
                "vo\\h\\m\\Hlo_HM083.mp3",	--	You have my attention.
                "vo\\h\\m\\Hlo_HM089.mp3",	--	Do you want something?
                "vo\\h\\m\\Hlo_HM103.mp3",	--	What happened to you?
                -- "vo\\h\\m\\Hlo_HM114.mp3",	--	You've piqued my interest. Please, share your thoughts.
                "vo\\h\\m\\Hlo_HM129.mp3",	--	Oh, my good friend. What happened to you?
                "vo\\h\\m\\Idl_HM006.mp3",	--	Whistle.
                "vo\\h\\m\\Idl_HM007.mp3",	--	Humm.
                "vo\\h\\m\\Idl_HM008.mp3",	--	Clearing throat.
                "vo\\h\\m\\Idl_HM009.mp3",	--	Sniff.
            },
        },
    },
    ["imperial"] = {
        ["f"] = {
            [this.voice.continue] = {
                "vo\\i\\f\\Atk_IF005.mp3",	--	You won't escape me that easily!
                "vo\\i\\f\\Atk_IF014.mp3",	--	This is pointless, give in!
                "vo\\i\\f\\bAtk_IF006.mp3",	--	I've got a bone for you. Come and get it!
                "vo\\i\\f\\Hlo_IF036.mp3",	--	Let's get this over with quickly.
                "vo\\i\\f\\Hlo_IF037.mp3",	--	I only have a few moments.
                "vo\\i\\f\\Hlo_IF039.mp3",	--	Come on. I haven't got all day you know.
                "vo\\i\\f\\Hlo_IF063.mp3",	--	Go ahead, stranger.
                "vo\\i\\f\\Hlo_IF100.mp3",	--	Move along.
                "vo\\i\\f\\Hlo_IF116.mp3",	--	Keep moving.
                "vo\\i\\f\\Hlo_IF118.mp3",	--	Go ahead.
                "vo\\i\\f\\Hlo_IF147.mp3",	--	I'm all yours, please go ahead.
                -- "vo\\i\\f\\Hlo_IF161.mp3",	--	With pleasure, please, go ahead. I'm all ears.
                "vo\\i\\f\\tHlo_IF095.mp3",	--	It's fine with me. Go ahead.
                "vo\\i\\f\\tHlo_IF096.mp3",	--	Go ahead. I'm waiting.
            },
            [this.voice.finish] = {
                "vo\\i\\f\\Atk_IF001.mp3",	--	I've trifled with you long enough.
                "vo\\i\\f\\Atk_IF003.mp3",	--	Take that!
                "vo\\i\\f\\Atk_IF006.mp3",	--	I have you!
                "vo\\i\\f\\Atk_IF012.mp3",	--	You've lost this round!
                "vo\\i\\f\\Atk_IF013.mp3",	--	You're not even trying!
                "vo\\i\\f\\Atk_IF015.mp3",	--	No one can match me!
                "vo\\i\\f\\bAtk_IF005.mp3",	--	Your head will be my new trophy!
                "vo\\i\\f\\Hlo_IF065.mp3",	--	Hail.
                "vo\\i\\f\\tHlo_IF004.mp3",	--	For King and Emperor.
            },
            [this.voice.loseRound] = {
                -- "vo\\i\\f\\bFle_IF003.mp3",	--	Go away! I don't have any treats!
                -- "vo\\i\\f\\Fle_IF002.mp3",	--	I'm getting out of here!
                "vo\\i\\f\\Fle_IF003.mp3",	--	No!
                "vo\\i\\f\\Fle_IF005.mp3",	--	Help!
                "vo\\i\\f\\Hit_IF001.mp3",	--	AAAIIEE.
                "vo\\i\\f\\Hit_IF002.mp3",	--	Arrgh.
                "vo\\i\\f\\Hit_IF003.mp3",	--	Arrgh!
                "vo\\i\\f\\Hit_IF004.mp3",	--	Groan.
                "vo\\i\\f\\Hit_IF005.mp3",	--	Ungh!
                "vo\\i\\f\\Hit_IF006.mp3",	--	Groan.
                "vo\\i\\f\\Hit_IF007.mp3",	--	Groan.
                "vo\\i\\f\\Hit_IF008.mp3",	--	Grunt.
                "vo\\i\\f\\Hit_IF009.mp3",	--	Grunt.
                "vo\\i\\f\\Hit_IF010.mp3",	--	Grunt.
                "vo\\i\\f\\Hit_IF011.mp3",	--	Grunt.
                "vo\\i\\f\\Hit_IF012.mp3",	--	Grunt.
                "vo\\i\\f\\Hit_IF013.mp3",	--	Hiss.
                "vo\\i\\f\\Hit_IF014.mp3",	--	Hiss.
                "vo\\i\\f\\Hit_IF015.mp3",	--	Hiss.
                -- "vo\\i\\f\\Hlo_IF000e.mp3",	--	Get out of here!
                "vo\\i\\f\\Hlo_IF012.mp3",	--	Don't bother me.
                -- "vo\\i\\f\\Hlo_IF028.mp3",	--	Go away.
                "vo\\i\\f\\Hlo_IF032.mp3",	--	What? Why do you disturb me?
                "vo\\i\\f\\tIdl_IF006.mp3",	--	[Long sigh.] Mother said there'd be days like this.
                "vo\\i\\f\\tIdl_IF009.mp3",	--	Don't look at me! I didn't do it....
            },
            [this.voice.winGame] = {
                "vo\\i\\f\\bHlo_IF005.mp3",	--	Be strong, my friend. You will persevere.
                "vo\\i\\f\\bIdl_IF006.mp3",	--	No. Not in a million years.
                "vo\\i\\f\\Hlo_IF000d.mp3",	--	I wouldn't waste my time on the likes of you!
                "vo\\i\\f\\Hlo_IF003.mp3",	--	You don't look so good. Well done.
                "vo\\i\\f\\Hlo_IF020.mp3",	--	Go complain elsewhere.
                "vo\\i\\f\\Hlo_IF107.mp3",	--	This is truly an honor.
                "vo\\i\\f\\tHlo_IF101.mp3",	--	Zenithar's fortune to you.
                "vo\\i\\f\\tHlo_IF102.mp3",	--	Today and tomorrow, good luck.
            },
            [this.voice.think] = {
                "vo\\i\\f\\bIdl_IF012.mp3",	--	Oh, not AGAIN!
                "vo\\i\\f\\Hlo_IF000a.mp3",	--	What!?
                "vo\\i\\f\\Hlo_IF000b.mp3",	--	Ugh!
                "vo\\i\\f\\Hlo_IF000c.mp3",	--	Uggh!
                "vo\\i\\f\\Hlo_IF010.mp3",	--	I don't think so.
                "vo\\i\\f\\Hlo_IF011.mp3",	--	So tiresome.
                "vo\\i\\f\\Hlo_IF060.mp3",	--	What's this about?
                "vo\\i\\f\\Hlo_IF075.mp3",	--	What brings you out in this mess?
                "vo\\i\\f\\Hlo_IF115.mp3",	--	What is this regarding?
                "vo\\i\\f\\Idl_IF001.mp3",	--	What was that?
                "vo\\i\\f\\Idl_IF002.mp3",	--	I don't know if I like this.
                "vo\\i\\f\\tHlo_IF097.mp3",	--	Excuse me. Did you say something?
                "vo\\i\\f\\tHlo_IF098.mp3",	--	Excuse me. I was just thinking...
                "vo\\i\\f\\tIdl_IF011.mp3",	--	If it's not one thing, it's another...
            },
            [this.voice.remind] = {
                "vo\\i\\f\\bIdl_IF005.mp3",	--	Ah... ah... AH... CHOOOO!
                "vo\\i\\f\\bIdl_IF011.mp3",	--	*Pfbbbbbbbt*
                "vo\\i\\f\\bIdl_IF013.mp3",	--	[Wide yawn.]
                "vo\\i\\f\\Hlo_IF002.mp3",	--	Looks like you've already got some of what's coming to you.
                "vo\\i\\f\\Hlo_IF030.mp3",	--	What?
                "vo\\i\\f\\Hlo_IF059.mp3",	--	Alright, I'll listen, but hurry up.
                "vo\\i\\f\\Hlo_IF061.mp3",	--	Anytime now.
                "vo\\i\\f\\Hlo_IF064.mp3",	--	Yes, friend?
                "vo\\i\\f\\Hlo_IF070.mp3",	--	Don't try anything funny.
                "vo\\i\\f\\Hlo_IF087.mp3",	--	I'm listening.
                "vo\\i\\f\\Hlo_IF088.mp3",	--	Yes?
                "vo\\i\\f\\Hlo_IF090.mp3",	--	You want something?
                "vo\\i\\f\\Hlo_IF106.mp3",	--	At ease.
                -- "vo\\i\\f\\Hlo_IF117.mp3",	--	How can I help you?
                "vo\\i\\f\\Hlo_IF120.mp3",	--	Do you want something from me?
                -- "vo\\i\\f\\Hlo_IF149.mp3",	--	If I can be of any assistance, I'll be happy to help.
                -- "vo\\i\\f\\Hlo_IF172.mp3",	--	The pleasure is mine. What may I do for you?
                "vo\\i\\f\\Idl_IF004.mp3",	--	Whistle.
                "vo\\i\\f\\Idl_IF005.mp3",	--	Sniff.
                "vo\\i\\f\\Idl_IF006.mp3",	--	Cough.
                "vo\\i\\f\\Idl_IF007.mp3",	--	Clearing throat.
                "vo\\i\\f\\Idl_IF008.mp3",	--	Humming.
                "vo\\i\\f\\Idl_IF009.mp3",	--	Strange.
                "vo\\i\\f\\tHlo_IF087.mp3",	--	Happy to help. What's your problem?
                "vo\\i\\f\\tHlo_IF089.mp3",	--	Whatever you want... within reason.
                "vo\\i\\f\\tHlo_IF094.mp3",	--	Yes?
                "vo\\i\\f\\tHlo_IF105.mp3",	--	What is it now?
                "vo\\i\\f\\tHlo_IF107.mp3",	--	Will this take long?
                "vo\\i\\f\\tHlo_IF109.mp3",	--	Well?
                "vo\\i\\f\\tHlo_IF110.mp3",	--	So? You want something?
                "vo\\i\\f\\tHlo_IF111.mp3",	--	Go on. I can't stop you.
                "vo\\i\\f\\tHlo_IF112.mp3",	--	If you insist...
                "vo\\i\\f\\tIdl_IF010.mp3",	--	[Singing to self....] 'Mama's little baby likes scumble, scumble....'
            },
        },
        ["m"] = {
            [this.voice.continue] = {
                "vo\\i\\m\\Atk_IM004.mp3",	--	You won't escape me that easily!
                "vo\\i\\m\\Atk_IM007.mp3",	--	Let's see what you're made of!
                "vo\\i\\m\\Atk_IM008.mp3",	--	Surrender now and I might let you live!
                "vo\\i\\m\\Atk_IM012.mp3",	--	This is pointless, give in!
                "vo\\i\\m\\Atk_IM013.mp3",	--	Come on! Fight!
                "vo\\i\\m\\Atk_IM014.mp3",	--	I will enjoy this!
                "vo\\i\\m\\bAtk_IM006.mp3",	--	I've got a bone for you. Come and get it!
                "vo\\i\\m\\bHlo_IM043.mp3",	--	One hand washes the other.
                "vo\\i\\m\\Hlo_IM000d.mp3",	--	You're about to find more trouble than you can possibly imagine.
                "vo\\i\\m\\Hlo_IM036.mp3",	--	Let's get this over with quickly.
                "vo\\i\\m\\Hlo_IM063.mp3",	--	Go ahead, stranger.
                "vo\\i\\m\\Hlo_IM116.mp3",	--	Keep moving.
                "vo\\i\\m\\Hlo_IM118.mp3",	--	Go ahead.
                "vo\\i\\m\\Hlo_IM147.mp3",	--	I'm all yours. Please, go ahead.
                -- "vo\\i\\m\\Hlo_IM161.mp3",	--	With pleasure, please, go ahead. I'm all ears.
                "vo\\i\\m\\tHlo_IM099.mp3",	--	It's fine with me. Go ahead.
                "vo\\i\\m\\tHlo_IM100.mp3",	--	Go ahead. I'm waiting.
                "vo\\i\\m\\tHlo_IM115.mp3",	--	Go on. I can't stop you.
            },
            [this.voice.finish] = {
                "vo\\i\\m\\Atk_IM001.mp3",	--	I've trifled with you long enough.
                "vo\\i\\m\\Atk_IM002.mp3",	--	Ha-Ha!
                "vo\\i\\m\\Atk_IM003.mp3",	--	Take that!
                "vo\\i\\m\\Atk_IM005.mp3",	--	I have you!
                "vo\\i\\m\\Atk_IM006.mp3",	--	You're mine!
                "vo\\i\\m\\Atk_IM010.mp3",	--	You're hardly a match for me!
                "vo\\i\\m\\Atk_IM011.mp3",	--	You make this too easy!
                "vo\\i\\m\\bAtk_IM005.mp3",	--	Your head will be my new trophy!
                -- "vo\\i\\m\\CrAtk_IM001.mp3",	--	Hurrgh!
                -- "vo\\i\\m\\CrAtk_IM002.mp3",	--	Hurrargh!
                -- "vo\\i\\m\\CrAtk_IM003.mp3",	--	Urrragh!
                -- "vo\\i\\m\\CrAtk_IM004.mp3",	--	Ha!
                -- "vo\\i\\m\\CrAtk_IM005.mp3",	--	Die!
                "vo\\i\\m\\Hlo_IM065.mp3",	--	Hail.
                "vo\\i\\m\\tHlo_IM016.mp3",	--	Glory and honor, Emperor and Empire
                "vo\\i\\m\\tHlo_IM018.mp3",	--	For King and Emperor.
                "vo\\i\\m\\tIdl_IM002.mp3",	--	Hard times, and well-deserved.
            },
            [this.voice.loseRound] = {
                -- "vo\\i\\m\\bFle_IM003.mp3",	--	Go away! I don't have any treats!
                "vo\\i\\m\\bHlo_IM006.mp3",	--	Stuck here. Forever. I'll die.
                "vo\\i\\m\\bHlo_IM023a.mp3",	--	I got nothing more to say.
                "vo\\i\\m\\bIdl_IM024.mp3",	--	Just another of life's little disappointments...
                "vo\\i\\m\\bIdl_IM032.mp3",	--	What a life.
                -- "vo\\i\\m\\Fle_IM002.mp3",	--	I'm getting out of here!
                "vo\\i\\m\\Fle_IM003.mp3",	--	No!
                "vo\\i\\m\\Hit_IM001.mp3",	--	Uggh
                "vo\\i\\m\\Hit_IM002.mp3",	--	Wuggh
                "vo\\i\\m\\Hit_IM003.mp3",	--	Hungh!
                "vo\\i\\m\\Hit_IM004.mp3",	--	Huhhah.
                "vo\\i\\m\\Hit_IM005.mp3",	--	Hughah.
                "vo\\i\\m\\Hit_IM006.mp3",	--	Arrgh!
                "vo\\i\\m\\Hit_IM007.mp3",	--	Ungh!
                "vo\\i\\m\\Hit_IM008.mp3",	--	Ugharrrh.
                "vo\\i\\m\\Hit_IM009.mp3",	--	Humphf.
                "vo\\i\\m\\Hit_IM010.mp3",	--	Umphf.
                -- "vo\\i\\m\\Hlo_IM000e.mp3",	--	Get out of here!
                "vo\\i\\m\\Hlo_IM011.mp3",	--	So tiresome.
                "vo\\i\\m\\Hlo_IM012.mp3",	--	Don't bother me.
                -- "vo\\i\\m\\Hlo_IM028.mp3",	--	Go away.
                "vo\\i\\m\\Hlo_IM032.mp3",	--	What? Why do you disturb me?
                "vo\\i\\m\\tHlo_IM006.mp3",	--	This is too much excitement for me!
                "vo\\i\\m\\tHlo_IM015.mp3",	--	Must you? This is SO tiresome....
            },
            [this.voice.winGame] = {
                "vo\\i\\m\\bHlo_IM001.mp3",	--	Be strong, my friend. You will persevere.
                "vo\\i\\m\\bHlo_IM026.mp3",	--	Decisions are good. But good decisions are better.
                "vo\\i\\m\\bHlo_IM029.mp3",	--	YOU'RE not the problem. You're doing fine... thank the Gods.
                "vo\\i\\m\\bHlo_IM033.mp3",	--	You're a lifesaver.
                "vo\\i\\m\\bHlo_IM034.mp3",	--	Don't know what I'd do without you.
                "vo\\i\\m\\bHlo_IM039.mp3",	--	Don't bother me with trivial details. Know what's important, and do it right the first time.
                "vo\\i\\m\\Hlo_IM002.mp3",	--	Looks like you've already got some of what you have coming to you.
                "vo\\i\\m\\Hlo_IM003.mp3",	--	You don't look so good. Well done!
                "vo\\i\\m\\Hlo_IM057.mp3",	--	Stay out of trouble and you won't get hurt.
                "vo\\i\\m\\tHlo_IM004.mp3",	--	Zenithar's fortune to you.
                "vo\\i\\m\\tHlo_IM008.mp3",	--	The King's health to you, sera.
                "vo\\i\\m\\tHlo_IM009.mp3",	--	Long live the King.
                "vo\\i\\m\\tHlo_IM096.mp3",	--	The King's health to you, sera.
                "vo\\i\\m\\tHlo_IM097.mp3",	--	Long live the King.
                "vo\\i\\m\\tHlo_IM103.mp3",	--	Peace of the Nine to you.
                "vo\\i\\m\\tHlo_IM104.mp3",	--	Nine good days to you, sera.
                "vo\\i\\m\\tHlo_IM105.mp3",	--	Mara's mercy on you.
            },
            [this.voice.think] = {
                "vo\\i\\m\\bHlo_IM008.mp3",	--	What is it you want?
                "vo\\i\\m\\bHlo_IM015.mp3",	--	What is it?
                "vo\\i\\m\\bHlo_IM028.mp3",	--	It's always something, isn't it?
                "vo\\i\\m\\bHlo_IM030.mp3",	--	What next?
                "vo\\i\\m\\bHlo_IM041.mp3",	--	Time is money. Let's get moving here.
                "vo\\i\\m\\bIdl_IM017.mp3",	--	Oh, not AGAIN!
                "vo\\i\\m\\bIdl_IM019.mp3",	--	If it's not one thing, it's another.
                "vo\\i\\m\\bIdl_IM020.mp3",	--	Well, it couldn't get worse... Could it?
                "vo\\i\\m\\bIdl_IM021.mp3",	--	Once more, with feeling...
                "vo\\i\\m\\bIdl_IM025.mp3",	--	Uh-huh.
                "vo\\i\\m\\bIdl_IM026.mp3",	--	Right.
                "vo\\i\\m\\bIdl_IM027.mp3",	--	No point worrying about it.
                "vo\\i\\m\\bIdl_IM028.mp3",	--	Just as well...
                "vo\\i\\m\\bIdl_IM029.mp3",	--	Could be worse. Probably will be.
                "vo\\i\\m\\bIdl_IM033.mp3",	--	It's hard, but it's fair.
                "vo\\i\\m\\bIdl_IM034.mp3",	--	Oh, brother... not again....
                "vo\\i\\m\\Hlo_IM000a.mp3",	--	What?!
                "vo\\i\\m\\Hlo_IM000b.mp3",	--	Humphf.
                "vo\\i\\m\\Hlo_IM000c.mp3",	--	Humph.
                "vo\\i\\m\\Hlo_IM010.mp3",	--	I don't think so.
                "vo\\i\\m\\Hlo_IM060.mp3",	--	What's this about?
                "vo\\i\\m\\Hlo_IM115.mp3",	--	What is this regarding?
                "vo\\i\\m\\Hlo_IM122.mp3",	--	What say you?
                "vo\\i\\m\\tHlo_IM101.mp3",	--	Excuse me. Did you say something?
                "vo\\i\\m\\tHlo_IM102.mp3",	--	Excuse me. I was just thinking...
                "vo\\i\\m\\tHlo_IM109.mp3",	--	What is it now?
            },
            [this.voice.remind] = {
                "vo\\i\\m\\bHlo_IM022.mp3",	--	Yes? Did you want something?
                "vo\\i\\m\\bHlo_IM036.mp3",	--	About time.
                "vo\\i\\m\\bIdl_IM002.mp3",	--	Ah... ah... AH... CHOOOO!
                "vo\\i\\m\\bIdl_IM009.mp3",	--	Ummm... pudding!
                "vo\\i\\m\\bIdl_IM018.mp3",	--	[Wide yawn.]
                "vo\\i\\m\\bIdl_IM037.mp3",	--	Look, don't tell me about YOUR problems....
                "vo\\i\\m\\Hlo_IM030.mp3",	--	What?
                "vo\\i\\m\\Hlo_IM037.mp3",	--	I only have a few moments.
                "vo\\i\\m\\Hlo_IM039.mp3",	--	Come on. I haven't got all day you know.
                "vo\\i\\m\\Hlo_IM059.mp3",	--	Alright, I'll listen, but hurry up.
                "vo\\i\\m\\Hlo_IM061.mp3",	--	Anytime now.
                "vo\\i\\m\\Hlo_IM064.mp3",	--	Yes?
                "vo\\i\\m\\Hlo_IM088.mp3",	--	Yes?
                "vo\\i\\m\\Hlo_IM090.mp3",	--	You want something, friend?
                -- "vo\\i\\m\\Hlo_IM117.mp3",	--	How can I help you?
                "vo\\i\\m\\Hlo_IM120.mp3",	--	Do you want something from me?
                -- "vo\\i\\m\\Hlo_IM149.mp3",	--	If I can be of any assistance, I'll be happy to help.
                -- "vo\\i\\m\\Hlo_IM172.mp3",	--	The pleasure is mine. What may I do for you?
                "vo\\i\\m\\Idl_IM001.mp3",	--	Sniff.
                "vo\\i\\m\\Idl_IM002.mp3",	--	Sniff, sniff.
                "vo\\i\\m\\Idl_IM004.mp3",	--	Clears throat.
                "vo\\i\\m\\Idl_IM005.mp3",	--	Hmmm.
                "vo\\i\\m\\Idl_IM006.mp3",	--	Whistles.
                "vo\\i\\m\\Idl_IM008.mp3",	--	What was that?
                "vo\\i\\m\\Idl_IM009.mp3",	--	Clears throat.
                "vo\\i\\m\\tHlo_IM089.mp3",	--	I'm not busy now. What do you need?
                -- "vo\\i\\m\\tHlo_IM091.mp3",	--	Happy to help. What's your problem?
                "vo\\i\\m\\tHlo_IM093.mp3",	--	Whatever you want... within reason.
                "vo\\i\\m\\tHlo_IM098.mp3",	--	Yes?
                "vo\\i\\m\\tHlo_IM111.mp3",	--	Will this take long?
                "vo\\i\\m\\tHlo_IM113.mp3",	--	Well?
                "vo\\i\\m\\tHlo_IM114.mp3",	--	So? You want something?
                "vo\\i\\m\\tHlo_IM116.mp3",	--	If you insist...
                "vo\\i\\m\\tIdl_IM008.mp3",	--	Clears throat.
                "vo\\i\\m\\tIdl_IM011.mp3",	--	[Whistles]
                "vo\\i\\m\\tIdl_IM012.mp3",	--	You're imagining things.
            },
        },
    },
    ["khajiit"] = {
        ["f"] = {
            [this.voice.continue] = {
                "vo\\k\\f\\Atk_KF010.mp3",	--	So small and tasty. I will enjoy eating you.
                "vo\\k\\f\\Hlo_KF055.mp3",	--	Speak now or leave now.
                "vo\\k\\f\\Hlo_KF093.mp3",	--	Not to be afraid of this one.
                "vo\\k\\f\\Hlo_KF116.mp3",	--	Swift hunting, friend.
                "vo\\k\\f\\Idl_KF001.mp3",	--	Sweet Skooma.
                "vo\\k\\f\\Idl_KF009.mp3",	--	Sweet moon sugar.
            },
            [this.voice.finish] = {
                "vo\\k\\f\\Atk_KF001.mp3",	--	Growl!
                "vo\\k\\f\\Atk_KF005.mp3",	--	Growl!
                "vo\\k\\f\\Atk_KF006.mp3",	--	Growl!
                "vo\\k\\f\\Atk_KF007.mp3",	--	Growl!
                "vo\\k\\f\\Atk_KF012.mp3",	--	Growl!
                "vo\\k\\f\\Atk_KF013.mp3",	--	Growl!
                "vo\\k\\f\\Atk_KF014.mp3",	--	This one is no more!
                "vo\\k\\f\\Hlo_KF091.mp3",	--	Some sugar for you, friend?
                "vo\\k\\f\\Hlo_KF133.mp3",	--	Our sugar is yours, friend.
            },
            [this.voice.loseRound] = {
                "vo\\k\\f\\Fle_KF003.mp3",	--	I give up! Let me live!
                "vo\\k\\f\\Fle_KF004.mp3",	--	You had your chance!
                "vo\\k\\f\\Hit_KF001.mp3",	--	AAAIIEE.
                "vo\\k\\f\\Hit_KF002.mp3",	--	Arrgh.
                "vo\\k\\f\\Hit_KF003.mp3",	--	Fetcher!
                "vo\\k\\f\\Hit_KF004.mp3",	--	Urggh!
                "vo\\k\\f\\Hit_KF005.mp3",	--	Groan.
                "vo\\k\\f\\Hit_KF006.mp3",	--	Urgh!
                "vo\\k\\f\\Hit_KF007.mp3",	--	Groan.
                "vo\\k\\f\\Hit_KF008.mp3",	--	Grunt.
                "vo\\k\\f\\Hit_KF009.mp3",	--	Grunt.
                "vo\\k\\f\\Hit_KF010.mp3",	--	Grunt.
                "vo\\k\\f\\Hit_KF011.mp3",	--	Grunt.
                "vo\\k\\f\\Hit_KF012.mp3",	--	Grunt.
                "vo\\k\\f\\Hit_KF013.mp3",	--	Hiss.
                "vo\\k\\f\\Hit_KF014.mp3",	--	Hiss.
                "vo\\k\\f\\Hit_KF015.mp3",	--	Hiss.
                "vo\\k\\f\\Hlo_KF023.mp3",	--	Do not bother us.
                "vo\\k\\f\\Hlo_KF026.mp3",	--	So little manners. So little time.
                -- "vo\\k\\f\\Hlo_KF029.mp3",	--	Go away.
                "vo\\k\\f\\Hlo_KF053.mp3",	--	You do not please us.
            },
            [this.voice.winGame] = {
                "vo\\k\\f\\Hlo_KF000d.mp3",	--	I won't waste my time on the likes of you.
                "vo\\k\\f\\Hlo_KF005.mp3",	--	Let me stuff your shirt for you.
                "vo\\k\\f\\Hlo_KF011.mp3",	--	You show your weakness, prey.
                "vo\\k\\f\\Hlo_KF014.mp3",	--	Wealth? Fame? What good are these?
                "vo\\k\\f\\Hlo_KF017.mp3",	--	Does it want to feel Khajiti claws?
                "vo\\k\\f\\Hlo_KF087.mp3",	--	Good hunting.
                "vo\\k\\f\\Hlo_KF131.mp3",	--	A night's rest and you'll be good as new.
                "vo\\k\\f\\Hlo_KF136.mp3",	--	Good friend. This is an honor.
            },
            [this.voice.think] = {
                "vo\\k\\f\\Hlo_KF000a.mp3",	--	What?!
                "vo\\k\\f\\Hlo_KF000b.mp3",	--	Hmmph!
                "vo\\k\\f\\Hlo_KF000c.mp3",	--	Grrfph!
                "vo\\k\\f\\Hlo_KF028.mp3",	--	Khajiit has nothing to say to you.
                "vo\\k\\f\\Hlo_KF060.mp3",	--	Khajiit has no words for you.
                "vo\\k\\f\\Hlo_KF071.mp3",	--	Khajiit better than lizard. We work hard. No steal. Make you happy.
                "vo\\k\\f\\Hlo_KF114.mp3",	--	What is it, friend?
                "vo\\k\\f\\Idl_KF005.mp3",	--	What was that?
                "vo\\k\\f\\Idl_KF008.mp3",	--	There is much to learn.
            },
            [this.voice.remind] = {
                "vo\\k\\f\\Hlo_KF042.mp3",	--	You do not share.
                "vo\\k\\f\\Hlo_KF056.mp3",	--	You want something?
                "vo\\k\\f\\Hlo_KF059.mp3",	--	Khajiit has no time for you.
                "vo\\k\\f\\Hlo_KF061.mp3",	--	What do you need?
                "vo\\k\\f\\Hlo_KF082.mp3",	--	What Khajiit do for you?
                "vo\\k\\f\\Hlo_KF084.mp3",	--	What do you want?
                "vo\\k\\f\\Hlo_KF086.mp3",	--	Friend.
                "vo\\k\\f\\Hlo_KF088.mp3",	--	Sera?
                "vo\\k\\f\\Hlo_KF089.mp3",	--	Muthsera?
                "vo\\k\\f\\Hlo_KF109.mp3",	--	Friend?
                "vo\\k\\f\\Hlo_KF115.mp3",	--	What can Khajiit do for you?
                "vo\\k\\f\\Hlo_KF139.mp3",	--	Growls
                "vo\\k\\f\\Idl_KF002.mp3",	--	Purr.
                "vo\\k\\f\\Idl_KF003.mp3",	--	Var var var.
                "vo\\k\\f\\Idl_KF004.mp3",	--	Sniff.
            },
        },
        ["m"] = {
            [this.voice.continue] = {
                "vo\\k\\m\\Atk_KM010.mp3",	--	So small and tasty. I will enjoy eating you.
                "vo\\k\\m\\bAtk_KM003.mp3",	--	I've got a bone for you. Come and get it!
                "vo\\k\\m\\Hlo_KM055.mp3",	--	Speak now or leave now.
                "vo\\k\\m\\Hlo_KM093.mp3",	--	Not to be afraid of this one.
                "vo\\k\\m\\Idl_KM001.mp3",	--	Sweet Skooma.
                "vo\\k\\m\\Idl_KM009.mp3",	--	Sweet moon sugar.
            },
            [this.voice.finish] = {
                "vo\\k\\m\\Atk_KM001.mp3",	--	Growl!
                "vo\\k\\m\\Atk_KM005.mp3",	--	Growl!
                "vo\\k\\m\\Atk_KM006.mp3",	--	Growl!
                "vo\\k\\m\\Atk_KM007.mp3",	--	Growl!
                "vo\\k\\m\\Atk_KM012.mp3",	--	Growl!
                "vo\\k\\m\\Atk_KM013.mp3",	--	Growl!
                "vo\\k\\m\\Atk_KM015.mp3",	--	This one is no more!
                "vo\\k\\m\\bAtk_KM002.mp3",	--	Your head will be my new trophy!
                -- "vo\\k\\m\\CrAtk_KM001.mp3",	--	Rrrarrwlll!
                "vo\\k\\m\\Hlo_KM091.mp3",	--	Some sugar for you, friend?
                "vo\\k\\m\\Hlo_KM133.mp3",	--	Our sugar is yours, friend.
            },
            [this.voice.loseRound] = {
                "vo\\k\\m\\Fle_KM003.mp3",	--	I give up! Let me live!
                "vo\\k\\m\\Fle_KM004.mp3",	--	You had your chance!
                "vo\\k\\m\\Hit_KM001.mp3",	--	AAAIIEE.
                "vo\\k\\m\\Hit_KM002.mp3",	--	Arrgh.
                "vo\\k\\m\\Hit_KM003.mp3",	--	Hugnh!
                "vo\\k\\m\\Hit_KM004.mp3",	--	Groan.
                "vo\\k\\m\\Hit_KM005.mp3",	--	Grarrgh!
                "vo\\k\\m\\Hit_KM006.mp3",	--	Growwl!
                "vo\\k\\m\\Hit_KM007.mp3",	--	Groan.
                "vo\\k\\m\\Hit_KM008.mp3",	--	Grunt.
                "vo\\k\\m\\Hit_KM009.mp3",	--	Grunt.
                "vo\\k\\m\\Hit_KM010.mp3",	--	Rarrgh!
                "vo\\k\\m\\Hit_KM011.mp3",	--	Grunt.
                "vo\\k\\m\\Hit_KM012.mp3",	--	Grunt.
                "vo\\k\\m\\Hit_KM013.mp3",	--	Hiss.
                "vo\\k\\m\\Hit_KM014.mp3",	--	Hiss.
                "vo\\k\\m\\Hlo_KM023.mp3",	--	Do not bother us!
                "vo\\k\\m\\Hlo_KM026.mp3",	--	So little manners, so little time.
                -- "vo\\k\\m\\Hlo_KM029.mp3",	--	Go away.
                "vo\\k\\m\\Hlo_KM053.mp3",	--	You do not please us.
            },
            [this.voice.winGame] = {
                "vo\\k\\m\\Hlo_KM005.mp3",	--	Let me stuff your shirt for you.
                "vo\\k\\m\\Hlo_KM011.mp3",	--	You show your weakness, prey.
                "vo\\k\\m\\Hlo_KM014.mp3",	--	Wealth? Fame? What good are these?
                "vo\\k\\m\\Hlo_KM017.mp3",	--	Does it want to feel Khajiiti claws?
                "vo\\k\\m\\Hlo_KM087.mp3",	--	Good hunting.
                "vo\\k\\m\\Hlo_KM116.mp3",	--	Swift hunting, friend.
                "vo\\k\\m\\Hlo_KM131.mp3",	--	A night's rest and you'll be good as new.
                "vo\\k\\m\\Hlo_KM136.mp3",	--	Good friend, this is an honor.
            },
            [this.voice.think] = {
                "vo\\k\\m\\Hlo_KM028.mp3",	--	Khajiit has nothing to say to you.
                "vo\\k\\m\\Hlo_KM060.mp3",	--	Khajiit has no words for you.
                "vo\\k\\m\\Hlo_KM071.mp3",	--	Khajiit better than lizard. We work hard. No steal. Make you happy.
                "vo\\k\\m\\Hlo_KM114.mp3",	--	What is it, friend?
                "vo\\k\\m\\Idl_KM005.mp3",	--	What was that?
                "vo\\k\\m\\Idl_KM006.mp3",	--	I heard something.
                "vo\\k\\m\\Idl_KM008.mp3",	--	There is much to learn.
            },
            [this.voice.remind] = {
                "vo\\k\\m\\Hlo_KM042.mp3",	--	You do not share.
                "vo\\k\\m\\Hlo_KM056.mp3",	--	You want something?
                "vo\\k\\m\\Hlo_KM059.mp3",	--	Khajiit has no time for you.
                "vo\\k\\m\\Hlo_KM061.mp3",	--	What do you need?
                "vo\\k\\m\\Hlo_KM082.mp3",	--	What Khajiit do for you?
                "vo\\k\\m\\Hlo_KM084.mp3",	--	What do you want?
                "vo\\k\\m\\Hlo_KM086.mp3",	--	Friend?
                "vo\\k\\m\\Hlo_KM088.mp3",	--	Sera?
                "vo\\k\\m\\Hlo_KM089.mp3",	--	Muthsera?
                "vo\\k\\m\\Hlo_KM109.mp3",	--	Friend?
                "vo\\k\\m\\Hlo_KM115.mp3",	--	What can Khajiit do for you?
                "vo\\k\\m\\Hlo_KM139.mp3",	--	Grrrowl!
                "vo\\k\\m\\Idl_KM002.mp3",	--	Purrs.
                "vo\\k\\m\\Idl_KM003.mp3",	--	Var var var.
                "vo\\k\\m\\Idl_KM004.mp3",	--	Sniff.
            },
        },
    },
    ["nord"] = {
        ["f"] = {
            [this.voice.continue] = {
                "vo\\n\\f\\Atk_NF001.mp3",	--	You will die where you stand!
                "vo\\n\\f\\Atk_NF007.mp3",	--	I will bathe in your blood.
                "vo\\n\\f\\Atk_NF008.mp3",	--	Now this is fighting!
                "vo\\n\\f\\Atk_NF010.mp3",	--	How does it feel to know death is near?
                "vo\\n\\f\\Atk_NF014.mp3",	--	Come on, fight!
                "vo\\n\\f\\bAtk_NF006.mp3",	--	I've got a bone for you. Come and get it!
                "vo\\n\\f\\Fle_NF001.mp3",	--	Not today.
                "vo\\n\\f\\Hlo_NF060.mp3",	--	Don't press your luck. You're on your honor.
                "vo\\n\\f\\Hlo_NF061.mp3",	--	Come on then, say something or move on.
                "vo\\n\\f\\Hlo_NF084.mp3",	--	Head on.
                "vo\\n\\f\\Hlo_NF090.mp3",	--	You've got the better of me. So go ahead.
                "vo\\n\\f\\Hlo_NF111.mp3",	--	I'm ready for anything. Go ahead.
            },
            [this.voice.finish] = {
                "vo\\n\\f\\Atk_NF002.mp3",	--	ARRRR!
                "vo\\n\\f\\Atk_NF003.mp3",	--	HAAAA!
                "vo\\n\\f\\Atk_NF004.mp3",	--	Fool!
                "vo\\n\\f\\Atk_NF005.mp3",	--	Give in! You're dead already!
                "vo\\n\\f\\Atk_NF006.mp3",	--	You should've picked an easier opponent!
                "vo\\n\\f\\Atk_NF012.mp3",	--	This is too easy!
                "vo\\n\\f\\Atk_NF013.mp3",	--	Ungh! You call this fighting?
                "vo\\n\\f\\Atk_NF015.mp3",	--	Face death!
                "vo\\n\\f\\bAtk_NF005.mp3",	--	Your head will be my new trophy!
                "vo\\n\\f\\Hlo_NF078.mp3",	--	Hail.
                "vo\\n\\f\\Hlo_NF092.mp3",	--	Hail.
            },
            [this.voice.loseRound] = {
                -- "vo\\n\\f\\bFle_NF003.mp3",	--	Go away! I don't have any treats!
                "vo\\n\\f\\Fle_NF002.mp3",	--	You've won this round.
                "vo\\n\\f\\Hit_NF001.mp3",	--	Arrgh.
                "vo\\n\\f\\Hit_NF002.mp3",	--	Umpfh
                "vo\\n\\f\\Hit_NF003.mp3",	--	Ungh.
                "vo\\n\\f\\Hit_NF004.mp3",	--	Grunt.
                "vo\\n\\f\\Hit_NF005.mp3",	--	Engh!
                "vo\\n\\f\\Hit_NF006.mp3",	--	Growl.
                "vo\\n\\f\\Hit_NF007.mp3",	--	Cough
                "vo\\n\\f\\Hit_NF008.mp3",	--	Gasp.
                "vo\\n\\f\\Hit_NF009.mp3",	--	Scream.
                "vo\\n\\f\\Hit_NF010.mp3",	--	Ungh!
                "vo\\n\\f\\Hit_NF011.mp3",	--	Grunt.
                "vo\\n\\f\\Hit_NF012.mp3",	--	Groan.
                "vo\\n\\f\\Hit_NF013.mp3",	--	Growl.
                "vo\\n\\f\\Hit_NF014.mp3",	--	Gasp.
                "vo\\n\\f\\Hit_NF015.mp3",	--	Scream.
                "vo\\n\\f\\Hlo_NF017.mp3",	--	You must be joking.
                "vo\\n\\f\\Hlo_NF021.mp3",	--	I've had enough of you.
                "vo\\n\\f\\Hlo_NF023.mp3",	--	You must be joking.
                "vo\\n\\f\\Hlo_NF024.mp3",	--	Bother me again, and you might live to regret it.
                "vo\\n\\f\\Hlo_NF028.mp3",	--	I don't think I want you around anymore.
                "vo\\n\\f\\Idl_NF009.mp3",	--	Ugh! Disgusting!
            },
            [this.voice.winGame] = {
                "vo\\n\\f\\Fle_NF004.mp3",	--	End your fight, I'm leaving.
                "vo\\n\\f\\Hlo_NF000d.mp3",	--	I won't waste my time on the likes of you.
                "vo\\n\\f\\Hlo_NF022.mp3",	--	Get out of here before you get hurt.
                "vo\\n\\f\\Hlo_NF082.mp3",	--	May the wind be on your back.
                "vo\\n\\f\\Hlo_NF112.mp3",	--	That's how I like it, bold and direct! Come, I like you.
                "vo\\n\\f\\Hlo_NF136.mp3",	--	Ah, you bring good fortune with you. Welcome.
                "vo\\n\\f\\Hlo_NF137.mp3",	--	You choose you share your time to me? You humble me.
            },
            [this.voice.think] = {
                "vo\\n\\f\\bIdl_NF012.mp3",	--	Moody? Not really. I'm always this way.
                "vo\\n\\f\\bIdl_NF020.mp3",	--	Oh, not AGAIN!
                "vo\\n\\f\\Hlo_NF000a.mp3",	--	What?
                "vo\\n\\f\\Hlo_NF000b.mp3",	--	Hmph!
                "vo\\n\\f\\Hlo_NF000c.mp3",	--	Hmph!
                "vo\\n\\f\\Hlo_NF041.mp3",	--	Now what?
                "vo\\n\\f\\Hlo_NF042.mp3",	--	Look sharp.
                "vo\\n\\f\\Hlo_NF058.mp3",	--	What say you?
                "vo\\n\\f\\Hlo_NF087.mp3",	--	What's this all about?
            },
            [this.voice.remind] = {
                "vo\\n\\f\\bIdl_NF013.mp3",	--	Ah... ah... AH... CHOOOO!
                "vo\\n\\f\\bIdl_NF019.mp3",	--	*Pfbbbbbbbt*
                -- "vo\\n\\f\\bIdl_NF021.mp3",	--	[Wide yawn.] (missing)
                "vo\\n\\f\\Hlo_NF088.mp3",	--	I take it you want something. Well, what is it?
                "vo\\n\\f\\Hlo_NF089.mp3",	--	Today's your lucky day, so let's hear it.
                "vo\\n\\f\\Hlo_NF091.mp3",	--	Ho! What's your pleasure?
                "vo\\n\\f\\Idl_NF005.mp3",	--	Sniff.
                "vo\\n\\f\\Idl_NF006.mp3",	--	Humms.
                "vo\\n\\f\\Idl_NF007.mp3",	--	Cough.
                "vo\\n\\f\\Idl_NF008.mp3",	--	Whistle
            },
        },
        ["m"] = {
            [this.voice.continue] = {
                "vo\\n\\m\\Atk_NM001.mp3",	--	You will die where you stand!
                "vo\\n\\m\\Atk_NM007.mp3",	--	I will bathe in your blood.
                "vo\\n\\m\\Atk_NM008.mp3",	--	Now this is fighting!
                "vo\\n\\m\\Atk_NM010.mp3",	--	How does it feel to know death is near?
                "vo\\n\\m\\Atk_NM020.mp3",	--	It will be your blood here, not mine!
                "vo\\n\\m\\bAtk_NM006.mp3",	--	I've got a bone for you. Come and get it!
                "vo\\n\\m\\Fle_NM001.mp3",	--	Not today.
                "vo\\n\\m\\Hlo_NM060.mp3",	--	You're on your honor. Don't press your luck.
                "vo\\n\\m\\Hlo_NM061.mp3",	--	Come on then, say something or move on.
                "vo\\n\\m\\Hlo_NM084.mp3",	--	Head on.
                "vo\\n\\m\\Hlo_NM090.mp3",	--	You've got the better of me. So go ahead.
                "vo\\n\\m\\Hlo_NM111.mp3",	--	I'm ready for anything. Go ahead.
            },
            [this.voice.finish] = {
                "vo\\n\\m\\Atk_NM002.mp3",	--	ARRRR!
                "vo\\n\\m\\Atk_NM003.mp3",	--	HAAAA!
                "vo\\n\\m\\Atk_NM004.mp3",	--	Fool!
                "vo\\n\\m\\Atk_NM005.mp3",	--	Give in! You're dead already!
                "vo\\n\\m\\Atk_NM006.mp3",	--	You should've picked an easier opponent!
                "vo\\n\\m\\Atk_NM009.mp3",	--	You're bested!
                "vo\\n\\m\\Atk_NM011.mp3",	--	You're growing weak!
                "vo\\n\\m\\Atk_NM013.mp3",	--	This is too easy!
                "vo\\n\\m\\bAtk_NM005.mp3",	--	Your head will be my new trophy!
                "vo\\n\\m\\bHlo_NM012.mp3",	--	To Sovngarde!
                "vo\\n\\m\\bHlo_NM012.mp3",	--	To Sovngarde!
                "vo\\n\\m\\Hlo_NM078.mp3",	--	Hail.
                "vo\\n\\m\\Hlo_NM092.mp3",	--	Hail.
            },
            [this.voice.loseRound] = {
                -- "vo\\n\\m\\bFle_NM003.mp3",	--	Go away! I don't have any treats!
                "vo\\n\\m\\bIdl_NM028.mp3",	--	What a life.
                "vo\\n\\m\\Fle_NM002.mp3",	--	You've won this round.
                "vo\\n\\m\\Hit_NM001.mp3",	--	Arrgh.
                "vo\\n\\m\\Hit_NM002.mp3",	--	Umpfh
                "vo\\n\\m\\Hit_NM003.mp3",	--	Ungh!
                "vo\\n\\m\\Hit_NM004.mp3",	--	Hungh!
                "vo\\n\\m\\Hit_NM005.mp3",	--	Groan.
                "vo\\n\\m\\Hit_NM006.mp3",	--	Growl.
                "vo\\n\\m\\Hit_NM007.mp3",	--	Cough
                "vo\\n\\m\\Hit_NM008.mp3",	--	Gasp.
                "vo\\n\\m\\Hit_NM009.mp3",	--	Arrgh!
                "vo\\n\\m\\Hit_NM010.mp3",	--	Yell.
                "vo\\n\\m\\Hit_NM011.mp3",	--	Grunt.
                "vo\\n\\m\\Hit_NM012.mp3",	--	Groan.
                "vo\\n\\m\\Hit_NM013.mp3",	--	Growl.
                "vo\\n\\m\\Hit_NM014.mp3",	--	Gasp.
                "vo\\n\\m\\Hlo_NM017.mp3",	--	You must be joking.
                "vo\\n\\m\\Hlo_NM021.mp3",	--	I've had enough of you.
                "vo\\n\\m\\Hlo_NM023.mp3",	--	You must be joking.
                "vo\\n\\m\\Hlo_NM024.mp3",	--	Bother me again, and you might live to regret it.
            },
            [this.voice.winGame] = {
                "vo\\n\\m\\bHlo_NM015.mp3",	--	Keep your distance, friend, if you want to keep your head.
                "vo\\n\\m\\bHlo_NM036.mp3",	--	I have nothing to say. My time is done.
                "vo\\n\\m\\Fle_NM004.mp3",	--	End your fight, I'm leaving.
                "vo\\n\\m\\Hlo_NM022.mp3",	--	Get out of here, before you get hurt!
                "vo\\n\\m\\Hlo_NM082.mp3",	--	May the wind be on your back.
                "vo\\n\\m\\Hlo_NM112.mp3",	--	That's how I like it, bold and direct! Come, I like you.
                "vo\\n\\m\\Hlo_NM136.mp3",	--	Ah, you bring good fortune with you. Welcome.
            },
            [this.voice.think] = {
                "vo\\n\\m\\bIdl_NM015.mp3",	--	Oh, not AGAIN!
                "vo\\n\\m\\bIdl_NM021.mp3",	--	Uh-huh.
                "vo\\n\\m\\bIdl_NM022.mp3",	--	Right.
                "vo\\n\\m\\bIdl_NM023.mp3",	--	No point worrying about it.
                "vo\\n\\m\\bIdl_NM024.mp3",	--	Just as well...
                "vo\\n\\m\\bIdl_NM025.mp3",	--	Could be worse. Probably will be.
                "vo\\n\\m\\Hlo_NM041.mp3",	--	Now what?
                "vo\\n\\m\\Hlo_NM042.mp3",	--	Look sharp.
                "vo\\n\\m\\Hlo_NM058.mp3",	--	What say you?
                "vo\\n\\m\\Hlo_NM087.mp3",	--	What's this all about?
                "vo\\n\\m\\Hlo_NM137.mp3",	--	You choose to share your time to me? You humble me.
            },
            [this.voice.remind] = {
                "vo\\n\\m\\bHlo_NM062.mp3",	--	What is it, friend?
                "vo\\n\\m\\bHlo_NM066.mp3",	--	Let's get a move on.
                "vo\\n\\m\\bHlo_NM071.mp3",	--	Let us fight through to the end.
                "vo\\n\\m\\bIdl_NM004.mp3",	--	Ah... ah... AH... CHOOOO!
                "vo\\n\\m\\bIdl_NM014.mp3",	--	*Pfbbbbbbbt*
                "vo\\n\\m\\bIdl_NM016.mp3",	--	[Wide yawn.]
                "vo\\n\\m\\bIdl_NM033.mp3",	--	Look, don't tell me about YOUR problems....
                "vo\\n\\m\\Hlo_NM088.mp3",	--	I take it you want something. Well, what is it?
                "vo\\n\\m\\Hlo_NM089.mp3",	--	Today's your lucky day, so let's hear it.
                "vo\\n\\m\\Idl_NM002.mp3",	--	Cough.
                "vo\\n\\m\\Idl_NM003.mp3",	--	Sniff.
                "vo\\n\\m\\Idl_NM004.mp3",	--	Cough.
                "vo\\n\\m\\Idl_NM005.mp3",	--	Whistle.
                "vo\\n\\m\\Idl_NM006.mp3",	--	Humm.
                "vo\\n\\m\\Idl_NM007.mp3",	--	Cough.
                "vo\\n\\m\\Idl_NM008.mp3",	--	Whistle.
                "vo\\n\\m\\Idl_NM009.mp3",	--	Humm.
            },
        },
    },
    ["orc"] = {
        ["f"] = {
            [this.voice.continue] = {
                "vo\\o\\f\\Atk_OF001.mp3",	--	You will die here.
                "vo\\o\\f\\Atk_OF010.mp3",	--	Escape while you can.
                "vo\\o\\f\\Atk_OF013.mp3",	--	You will bring me great honor.
                "vo\\o\\f\\Hlo_OF077.mp3",	--	Move on.
            },
            [this.voice.finish] = {
                "vo\\o\\f\\Atk_OF002.mp3",	--	Die with honor, coward!
                "vo\\o\\f\\Atk_OF003.mp3",	--	No surrender! No mercy!
                "vo\\o\\f\\Atk_OF004.mp3",	--	Give up.
                "vo\\o\\f\\Atk_OF005.mp3",	--	Now you die.
                "vo\\o\\f\\Atk_OF006.mp3",	--	You grow weak.
                "vo\\o\\f\\Atk_OF007.mp3",	--	Weakling!
                "vo\\o\\f\\Atk_OF008.mp3",	--	Coward!
                "vo\\o\\f\\Atk_OF009.mp3",	--	You fight like a child!
                "vo\\o\\f\\Atk_OF014.mp3",	--	You are a fool to fight me.
                "vo\\o\\f\\Atk_OF015.mp3",	--	Our blood is made for fighting!
                "vo\\o\\f\\Idl_OF001.mp3",	--	An oath is an oath.
            },
            [this.voice.loseRound] = {
                "vo\\o\\f\\Fle_OF001.mp3",	--	This one is too strong for me.
                "vo\\o\\f\\Fle_OF002.mp3",	--	Help.
                "vo\\o\\f\\Fle_OF003.mp3",	--	This fight is over.
                "vo\\o\\f\\Fle_OF004.mp3",	--	I have no more quarrel with you.
                "vo\\o\\f\\Fle_OF005.mp3",	--	I have no more quarrel with you.
                "vo\\o\\f\\Hit_OF001.mp3",	--	AAAIIEE.
                "vo\\o\\f\\Hit_OF002.mp3",	--	Arrgh.
                "vo\\o\\f\\Hit_OF003.mp3",	--	Fetcher!
                "vo\\o\\f\\Hit_OF004.mp3",	--	Groan.
                "vo\\o\\f\\Hit_OF005.mp3",	--	AAAIIEE.
                "vo\\o\\f\\Hit_OF006.mp3",	--	AAAIIEE.
                "vo\\o\\f\\Hit_OF007.mp3",	--	Arrgh.
                "vo\\o\\f\\Hit_OF008.mp3",	--	Ughn!
                "vo\\o\\f\\Hit_OF009.mp3",	--	Groan.
                "vo\\o\\f\\Hit_OF010.mp3",	--	Groan.
                "vo\\o\\f\\Hit_OF011.mp3",	--	Arrgh!
                "vo\\o\\f\\Hit_OF012.mp3",	--	Groan.
                "vo\\o\\f\\Hit_OF013.mp3",	--	Grunt.
                "vo\\o\\f\\Hit_OF014.mp3",	--	Ungh!
                "vo\\o\\f\\Hit_OF014.mp3",	--	Grunt.
                "vo\\o\\f\\Hit_OF015.mp3",	--	Grunt.
                -- "vo\\o\\f\\Hlo_OF000e.mp3",	--	Get out of here!
                "vo\\o\\f\\Hlo_OF001.mp3",	--	Anger me further and I will be forced to take action.
                "vo\\o\\f\\Hlo_OF019.mp3",	--	You prey on the weak. There is no honor in this.
                "vo\\o\\f\\Hlo_OF026.mp3",	--	So annoying.
                "vo\\o\\f\\Hlo_OF047.mp3",	--	You prey on the weak. There is no honor in this.
            },
            [this.voice.winGame] = {
                "vo\\o\\f\\Hlo_OF023.mp3",	--	I haven't time for fools.
                "vo\\o\\f\\Hlo_OF025.mp3",	--	You're hardly worth my time.
                "vo\\o\\f\\Hlo_OF041.mp3",	--	You have much to learn.
                "vo\\o\\f\\Hlo_OF056.mp3",	--	Do not waste my time.
                "vo\\o\\f\\Hlo_OF083.mp3",	--	Strength is a virtue, friend. Welcome
                "vo\\o\\f\\Hlo_OF084.mp3",	--	May your battles show only victory, friend.
                "vo\\o\\f\\Hlo_OF110.mp3",	--	You're not what I expected. You've earned my trust.
                "vo\\o\\f\\Hlo_OF112.mp3",	--	Hail. May your adventures be great.
                "vo\\o\\f\\Hlo_OF135.mp3",	--	A sincere welcome to you. May you be forever blessed.
                "vo\\o\\f\\Idl_OF007.mp3",	--	Need to practice more.
            },
            [this.voice.think] = {
                "vo\\o\\f\\Hlo_OF000a.mp3",	--	What?!
                "vo\\o\\f\\Hlo_OF000b.mp3",	--	Humph!
                "vo\\o\\f\\Hlo_OF000c.mp3",	--	Hmph!
                "vo\\o\\f\\Idl_OF009.mp3",	--	Finally something interesting.
                "vo\\o\\f\\Hlo_OF028.mp3",	--	What now?
                "vo\\o\\f\\Hlo_OF029.mp3",	--	What?
                "vo\\o\\f\\Hlo_OF109.mp3",	--	You need not be afraid. Only fools earn my anger.
                "vo\\o\\f\\Hlo_OF078.mp3",	--	Yes, what is it?
            },
            [this.voice.remind] = {
                "vo\\o\\f\\Hlo_OF031.mp3",	--	Sera?
                "vo\\o\\f\\Hlo_OF044.mp3",	--	What are you supposed to be?
                "vo\\o\\f\\Hlo_OF055.mp3",	--	What are you doing?
                "vo\\o\\f\\Hlo_OF057.mp3",	--	Say your needs.
                "vo\\o\\f\\Hlo_OF059.mp3",	--	Say your words.
                "vo\\o\\f\\Hlo_OF060.mp3",	--	Yes?
                "vo\\o\\f\\Hlo_OF087.mp3",	--	Your actions show promise. What do you want?
                "vo\\o\\f\\Hlo_OF091.mp3",	--	Friend.
                "vo\\o\\f\\Hlo_OF108.mp3",	--	My attention is yours.
                -- "vo\\o\\f\\Hlo_OF114.mp3",	--	How can I help you, friend?
                -- "vo\\o\\f\\Hlo_OF134.mp3",	--	I am honored. Truly. How may I help you?
                "vo\\o\\f\\Idl_OF003.mp3",	--	Clears throat.
                "vo\\o\\f\\Idl_OF004.mp3",	--	Cough.
                "vo\\o\\f\\Idl_OF005.mp3",	--	Sniff.
                "vo\\o\\f\\Idl_OF006.mp3",	--	Cough.
            },
        },
        ["m"] = {
            [this.voice.continue] = {
                "vo\\o\\m\\Atk_OM001.mp3",	--	You will die here.
                "vo\\o\\m\\Atk_OM010.mp3",	--	Escape while you can.
                "vo\\o\\m\\Atk_OM012.mp3",	--	You will bring me great honor.
                "vo\\o\\m\\Hlo_OM000d.mp3",	--	You seek to challenge me?
                "vo\\o\\m\\Hlo_OM077.mp3",	--	Move on.
            },
            [this.voice.finish] = {
                "vo\\o\\m\\Atk_OM002.mp3",	--	Arrrgh.
                "vo\\o\\m\\Atk_OM003.mp3",	--	Grunt.
                "vo\\o\\m\\Atk_OM004.mp3",	--	Give up.
                "vo\\o\\m\\Atk_OM005.mp3",	--	Now you die.
                "vo\\o\\m\\Atk_OM006.mp3",	--	You grow weak.
                "vo\\o\\m\\Atk_OM007.mp3",	--	Weakling!
                "vo\\o\\m\\Atk_OM008.mp3",	--	Coward!
                "vo\\o\\m\\Atk_OM009.mp3",	--	You fight like a child!
                "vo\\o\\m\\Atk_OM014.mp3",	--	You are a fool to fight me!
                "vo\\o\\m\\Hlo_OM133.mp3",	--	Put that away!
            },
            [this.voice.loseRound] = {
                "vo\\o\\m\\Fle_OM001.mp3",	--	This one is too strong for me!
                "vo\\o\\m\\Fle_OM002.mp3",	--	Help!
                "vo\\o\\m\\Fle_OM003.mp3",	--	This fight is over!
                "vo\\o\\m\\Fle_OM004.mp3",	--	I have no more quarrel with you.
                "vo\\o\\m\\Fle_OM005.mp3",	--	I have no more quarrel with you.
                "vo\\o\\m\\Hit_OM001.mp3",	--	AAAIIEE.
                "vo\\o\\m\\Hit_OM002.mp3",	--	Arrgh.
                "vo\\o\\m\\Hit_OM003.mp3",	--	Groan!
                "vo\\o\\m\\Hit_OM004.mp3",	--	Groan.
                "vo\\o\\m\\Hit_OM005.mp3",	--	AAAIIEE.
                "vo\\o\\m\\Hit_OM006.mp3",	--	AAAIIEE.
                "vo\\o\\m\\Hit_OM007.mp3",	--	Arrgh.
                "vo\\o\\m\\Hit_OM008.mp3",	--	Arrgh!
                "vo\\o\\m\\Hit_OM008.mp3",	--	Arrgh!
                "vo\\o\\m\\Hit_OM009.mp3",	--	Fetcher.
                "vo\\o\\m\\Hit_OM010.mp3",	--	Groan.
                "vo\\o\\m\\Hit_OM011.mp3",	--	Hurmph!
                "vo\\o\\m\\Hit_OM012.mp3",	--	Hargh!
                "vo\\o\\m\\Hit_OM013.mp3",	--	Hurragh!
                "vo\\o\\m\\Hit_OM014.mp3",	--	Grunt.
                "vo\\o\\m\\Hit_OM015.mp3",	--	Hurgh!
                "vo\\o\\m\\Hit_OM015.mp3",	--	Grunt.
                "vo\\o\\m\\Hlo_OM000e.mp3",	--	Do not toy with me!
                "vo\\o\\m\\Hlo_OM001.mp3",	--	Anger me further, and I will be forced to take action.
                "vo\\o\\m\\Hlo_OM022.mp3",	--	By what right do you disturb me?
            },
            [this.voice.winGame] = {
                "vo\\o\\m\\Hlo_OM023.mp3",	--	I haven't time for fools.
                "vo\\o\\m\\Hlo_OM025.mp3",	--	You're hardly worth my time.
                "vo\\o\\m\\Hlo_OM041.mp3",	--	You have much to learn.
                "vo\\o\\m\\Hlo_OM083.mp3",	--	Fight well.
                "vo\\o\\m\\Hlo_OM084.mp3",	--	May your kills be quick and many.
                "vo\\o\\m\\Hlo_OM110.mp3",	--	You're not what I expected. You've earned my trust.
                "vo\\o\\m\\Hlo_OM112.mp3",	--	Hail. May your adventures be great.
                "vo\\o\\m\\Hlo_OM135.mp3",	--	A sincere welcome to you. May you be forever blessed.
                "vo\\o\\m\\Hlo_OM137.mp3",	--	You have great understanding. Welcome.
            },
            [this.voice.think] = {
                "vo\\o\\m\\Hlo_OM000.mp3",	--	Growl!
                "vo\\o\\m\\Hlo_OM000a.mp3",	--	Grrrrrr.
                "vo\\o\\m\\Hlo_OM000b.mp3",	--	Humph.
                "vo\\o\\m\\Hlo_OM000c.mp3",	--	Humph.
                "vo\\o\\m\\Hlo_OM028.mp3",	--	What now?
                "vo\\o\\m\\Hlo_OM029.mp3",	--	What?
                "vo\\o\\m\\Hlo_OM109.mp3",	--	You need not be afraid. My anger is reserved for the foolish.
                "vo\\o\\m\\Hlo_OM117.mp3",	--	This one interests me.
                "vo\\o\\m\\Idl_OM001.mp3",	--	There it is again.
                "vo\\o\\m\\Idl_OM002.mp3",	--	What was that?
            },
            [this.voice.remind] = {
                "vo\\o\\m\\Hlo_OM031.mp3",	--	Sera?
                "vo\\o\\m\\Hlo_OM053.mp3",	--	Hurry up, before I change my mind.
                "vo\\o\\m\\Hlo_OM055.mp3",	--	What are you doing?
                "vo\\o\\m\\Hlo_OM056.mp3",	--	Do not waste my time.
                "vo\\o\\m\\Hlo_OM057.mp3",	--	Say your needs.
                "vo\\o\\m\\Hlo_OM059.mp3",	--	Say your words.
                "vo\\o\\m\\Hlo_OM060.mp3",	--	Yes?
                "vo\\o\\m\\Hlo_OM078.mp3",	--	Yes, what is it?
                "vo\\o\\m\\Hlo_OM087.mp3",	--	Your actions show promise. What do you want?
                "vo\\o\\m\\Hlo_OM091.mp3",	--	Friend.
                -- "vo\\o\\m\\Hlo_OM114.mp3",	--	How can I help you, friend?
                -- "vo\\o\\m\\Hlo_OM134.mp3",	--	I am honored. Truly. How may I help you?
                "vo\\o\\m\\Hlo_OM136.mp3",	--	I feel I can truly share with you, without fear.
                "vo\\o\\m\\Idl_OM003.mp3",	--	Growl.
                "vo\\o\\m\\Idl_OM004.mp3",	--	Hmmm.
                "vo\\o\\m\\Idl_OM005.mp3",	--	Sniff.
                "vo\\o\\m\\Idl_OM006.mp3",	--	Cough.
                "vo\\o\\m\\Idl_OM007.mp3",	--	Clearing throat.
                "vo\\o\\m\\Idl_OM009.mp3",	--	Probably nothing.
            },
        },
    },
    ["redguard"] = {
        ["f"] = {
            [this.voice.continue] = {
                "vo\\r\\f\\Atk_RF006.mp3",	--	I'm not giving up that easily.
                "vo\\r\\f\\Atk_RF007.mp3",	--	Run while you can.
                "vo\\r\\f\\Atk_RF009.mp3",	--	Hold still!
                "vo\\r\\f\\Atk_RF010.mp3",	--	You'll be dead soon.
                "vo\\r\\f\\Atk_RF012.mp3",	--	Am I good or what?
                "vo\\r\\f\\Atk_RF013.mp3",	--	I'll make this quick.
                "vo\\r\\f\\Atk_RF014.mp3",	--	Run or die!
                "vo\\r\\f\\Hlo_RF025.mp3",	--	Watch it.
                "vo\\r\\f\\Hlo_RF028.mp3",	--	Nothing's keeping you here. So move on.
                "vo\\r\\f\\Hlo_RF077.mp3",	--	All right. Go ahead.
                "vo\\r\\f\\Hlo_RF078.mp3",	--	Well, I'm listening. So go ahead.
            },
            [this.voice.finish] = {
                "vo\\r\\f\\Atk_RF002.mp3",	--	Huh!
                "vo\\r\\f\\Atk_RF003.mp3",	--	Errgh!
                "vo\\r\\f\\Atk_RF004.mp3",	--	Stupid fetcher!
                "vo\\r\\f\\Atk_RF005.mp3",	--	I have the upper hand!
                "vo\\r\\f\\Atk_RF008.mp3",	--	You're beaten!
                "vo\\r\\f\\Atk_RF015.mp3",	--	Here it comes!
                "vo\\r\\f\\Hlo_RF092.mp3",	--	Hail.
                "vo\\r\\f\\Idl_RF003.mp3",	--	I can't believe it. Pfft.
            },
            [this.voice.loseRound] = {
                "vo\\r\\f\\Fle_RF001.mp3",	--	Not this time.
                "vo\\r\\f\\Fle_RF002.mp3",	--	We're done here!
                "vo\\r\\f\\Fle_RF003.mp3",	--	I'll be back, and you'll be dead!
                "vo\\r\\f\\Fle_RF004.mp3",	--	Not today!
                -- "vo\\r\\f\\Fle_RF005.mp3",	--	Get away from me!
                "vo\\r\\f\\Hit_RF001.mp3",	--	Arrgh.
                "vo\\r\\f\\Hit_RF002.mp3",	--	Umpfh
                "vo\\r\\f\\Hit_RF003.mp3",	--	Ungh!
                "vo\\r\\f\\Hit_RF004.mp3",	--	Grunt.
                "vo\\r\\f\\Hit_RF005.mp3",	--	Ungh!
                "vo\\r\\f\\Hit_RF006.mp3",	--	Growl.
                "vo\\r\\f\\Hit_RF008.mp3",	--	Ungh!
                "vo\\r\\f\\Hit_RF009.mp3",	--	Ungh!
                "vo\\r\\f\\Hit_RF010.mp3",	--	Ungh!
                "vo\\r\\f\\Hit_RF011.mp3",	--	Grunt!
                "vo\\r\\f\\Hit_RF012.mp3",	--	Groan.
                "vo\\r\\f\\Hit_RF013.mp3",	--	Growl.
                "vo\\r\\f\\Hit_RF014.mp3",	--	Gasp.
                -- "vo\\r\\f\\Hlo_RF000e.mp3",	--	Get out of here!
                "vo\\r\\f\\Hlo_RF021.mp3",	--	I don't think so.
            },
            [this.voice.winGame] = {
                "vo\\r\\f\\Hlo_RF000d.mp3",	--	I won't waste my time on the likes of you.
                "vo\\r\\f\\Hlo_RF001.mp3",	--	I think it would be best if you leave. Now.
                "vo\\r\\f\\Hlo_RF042.mp3",	--	Now what did I do to deserve this honor?
                "vo\\r\\f\\Hlo_RF115.mp3",	--	I think you're going to fit right in here, friend. You've won me over.
                "vo\\r\\f\\Hlo_RF116.mp3",	--	May each day greet you warmly, friend.
                "vo\\r\\f\\Hlo_RF117.mp3",	--	This is a pleasant surprise. Greetings, friend.
                "vo\\r\\f\\Hlo_RF135.mp3",	--	The pleasure is all mine.
                "vo\\r\\f\\Hlo_RF136.mp3",	--	What did I do to deserve this honor?
            },
            [this.voice.think] = {
                "vo\\r\\f\\Hlo_RF000a.mp3",	--	What?
                "vo\\r\\f\\Hlo_RF000b.mp3",	--	Humph.
                "vo\\r\\f\\Hlo_RF000c.mp3",	--	Humph.
                "vo\\r\\f\\Hlo_RF054.mp3",	--	How do I know you're not up to something devious?
                "vo\\r\\f\\Hlo_RF090.mp3",	--	So, what's this about?
                "vo\\r\\f\\Idl_RF002.mp3",	--	What was that?
            },
            [this.voice.remind] = {
                "vo\\r\\f\\Hlo_RF058.mp3",	--	So what do you want?
                "vo\\r\\f\\Hlo_RF059.mp3",	--	Anytime you're ready. Just don't keep me waiting.
                "vo\\r\\f\\Hlo_RF062.mp3",	--	I think I could spare a few minutes.
                "vo\\r\\f\\Hlo_RF087.mp3",	--	Anything I can do for you?
                -- "vo\\r\\f\\Hlo_RF089.mp3",	--	Can I help you out? Do you need something?
                "vo\\r\\f\\Hlo_RF109.mp3",	--	Anytime, friend. I'm right here.
                "vo\\r\\f\\Idl_RF004.mp3",	--	Humming.
                "vo\\r\\f\\Idl_RF005.mp3",	--	Cough.
                "vo\\r\\f\\Idl_RF009.mp3",	--	Whistling.
            },
        },
        ["m"] = {
            [this.voice.continue] = {
                "vo\\r\\m\\Atk_RM004.mp3",	--	Today will be your last!
                "vo\\r\\m\\Atk_RM006.mp3",	--	I'm not giving up that easily.
                "vo\\r\\m\\Atk_RM007.mp3",	--	Run while you can.
                "vo\\r\\m\\Atk_RM009.mp3",	--	Hold still!
                "vo\\r\\m\\Atk_RM010.mp3",	--	You'll be dead soon.
                "vo\\r\\m\\Fle_RM004.mp3",	--	Not today!
                "vo\\r\\m\\Hlo_RM025.mp3",	--	Watch it.
                "vo\\r\\m\\Hlo_RM028.mp3",	--	Nothing's keeping you here. So move on.
                "vo\\r\\m\\Hlo_RM078.mp3",	--	Come on. What's the good word?
            },
            [this.voice.finish] = {
                "vo\\r\\m\\Atk_RM001.mp3",	--	It's about time I had some fun!
                "vo\\r\\m\\Atk_RM002.mp3",	--	No mercy!
                "vo\\r\\m\\Atk_RM003.mp3",	--	I'm going to enjoy this!
                "vo\\r\\m\\Atk_RM005.mp3",	--	I have the upper hand!
                "vo\\r\\m\\Atk_RM008.mp3",	--	You're beaten!
                "vo\\r\\m\\Atk_RM011.mp3",	--	You're starting to fail.
                "vo\\r\\m\\Atk_RM012.mp3",	--	Am I good or what?
                "vo\\r\\m\\Atk_RM013.mp3",	--	I'll make this quick.
                "vo\\r\\m\\Atk_RM014.mp3",	--	Here it comes!
                -- "vo\\r\\m\\CrAtk_RM001.mp3",	--	Rarrgh!
                -- "vo\\r\\m\\CrAtk_RM002.mp3",	--	Ha!
                -- "vo\\r\\m\\CrAtk_RM003.mp3",	--	Haha!
                -- "vo\\r\\m\\CrAtk_RM004.mp3",	--	Die!
                "vo\\r\\m\\Hlo_RM092.mp3",	--	Hail.
            },
            [this.voice.loseRound] = {
                "vo\\r\\m\\Fle_RM001.mp3",	--	Not this time.
                "vo\\r\\m\\Fle_RM002.mp3",	--	We're done here!
                "vo\\r\\m\\Fle_RM003.mp3",	--	I'll be back, and you'll be dead!
                -- "vo\\r\\m\\Fle_RM005.mp3",	--	Get away from me!
                "vo\\r\\m\\Hit_RM001.mp3",	--	Arrgh.
                "vo\\r\\m\\Hit_RM002.mp3",	--	Urgh!
                "vo\\r\\m\\Hit_RM003.mp3",	--	Ungh.
                "vo\\r\\m\\Hit_RM004.mp3",	--	Ungh!
                "vo\\r\\m\\Hit_RM005.mp3",	--	Groan.
                "vo\\r\\m\\Hit_RM006.mp3",	--	Growl.
                "vo\\r\\m\\Hit_RM007.mp3",	--	Cough
                "vo\\r\\m\\Hit_RM008.mp3",	--	Gasp.
                "vo\\r\\m\\Hit_RM009.mp3",	--	Arrgh!
                "vo\\r\\m\\Hit_RM009.mp3",	--	Scream.
                "vo\\r\\m\\Hit_RM010.mp3",	--	Yell.
                "vo\\r\\m\\Hit_RM011.mp3",	--	Grunt.
                "vo\\r\\m\\Hit_RM012.mp3",	--	Groan.
                "vo\\r\\m\\Hit_RM013.mp3",	--	Growl.
                "vo\\r\\m\\Hit_RM014.mp3",	--	Gasp.
                "vo\\r\\m\\Hit_RM015.mp3",	--	Scream.
                -- "vo\\r\\m\\Hlo_RM042.mp3",	--	Not now. Go away.
            },
            [this.voice.winGame] = {
                "vo\\r\\m\\Hlo_RM001.mp3",	--	I think it would be best if you leave, now!
                -- "vo\\r\\m\\Hlo_RM044.mp3",	--	Stop wasting my time with your foolishness!
                -- "vo\\r\\m\\Hlo_RM046.mp3",	--	I don't want any part of this. Whatever it is.
                "vo\\r\\m\\Hlo_RM116.mp3",	--	May each day greet you warmly, friend.
                "vo\\r\\m\\Hlo_RM117.mp3",	--	This is a pleasant surprise. Greetings, friend.
                "vo\\r\\m\\Hlo_RM133.mp3",	--	It's probably a bad idea to walk around like that.
                "vo\\r\\m\\Hlo_RM134.mp3",	--	I like what I see.
                "vo\\r\\m\\Hlo_RM135.mp3",	--	The pleasure is all mine.
                "vo\\r\\m\\Hlo_RM136.mp3",	--	What did I do to deserve this honor?
                "vo\\r\\m\\Idl_RM001.mp3",	--	So I said. Where's the money in that?
            },
            [this.voice.think] = {
                "vo\\r\\m\\Hlo_RM021.mp3",	--	I don't think so.
                "vo\\r\\m\\Hlo_RM090.mp3",	--	So, what's this about?
                "vo\\r\\m\\Hlo_RM115.mp3",	--	You've won me over.
                "vo\\r\\m\\Hlo_RM118.mp3",	--	Well, what have we here?
            },
            [this.voice.remind] = {
                "vo\\r\\m\\Hlo_RM058.mp3",	--	So what do you want?
                "vo\\r\\m\\Hlo_RM059.mp3",	--	Anytime you're ready. Just don't keep me waiting.
                "vo\\r\\m\\Hlo_RM062.mp3",	--	I think I could spare a few minutes.
                "vo\\r\\m\\Hlo_RM080.mp3",	--	What happened to you?
                "vo\\r\\m\\Hlo_RM087.mp3",	--	Anything I can do for you?
                -- "vo\\r\\m\\Hlo_RM089.mp3",	--	Can I help you out? Do you need something?
                "vo\\r\\m\\Hlo_RM109.mp3",	--	Anytime, friend. I'm right here.
                "vo\\r\\m\\Hlo_RM111.mp3",	--	You seem to be doing all right for yourself. What can I do for you?
                -- "vo\\r\\m\\Hlo_RM114.mp3",	--	Can I do anything to help?
                "vo\\r\\m\\Idl_RM008.mp3",	--	Sniff.
                "vo\\r\\m\\Idl_RM009.mp3",	--	Cough.
            },
        },
    },
    ["wood elf"] = {
        ["f"] = {
            [this.voice.continue] = {
                "vo\\w\\f\\Atk_WF004.mp3",	--	This is going to be fun.
                "vo\\w\\f\\Atk_WF008.mp3",	--	Run while you can.
                "vo\\w\\f\\Atk_WF009.mp3",	--	One of us will die here and it won't be me.
                "vo\\w\\f\\Atk_WF012.mp3",	--	You should run now.
                "vo\\w\\f\\Atk_WF013.mp3",	--	I'll see you dead.
                "vo\\w\\f\\Hlo_WF062.mp3",	--	Go ahead.
                "vo\\w\\f\\Hlo_WF077.mp3",	--	Go ahead.
                "vo\\w\\f\\Hlo_WF089.mp3",	--	Interesting, go on.
                "vo\\w\\f\\Hlo_WF131.mp3",	--	And what have we here? Please. Go ahead.
            },
            [this.voice.finish] = {
                "vo\\w\\f\\Atk_WF001.mp3",	--	Now you're going to get it.
                "vo\\w\\f\\Atk_WF003.mp3",	--	You don't deserve to live.
                "vo\\w\\f\\Atk_WF006.mp3",	--	You chose the wrong Bosmer to mess with.
                "vo\\w\\f\\Atk_WF007.mp3",	--	You can't escape me.
                "vo\\w\\f\\Atk_WF010.mp3",	--	This is too easy.
                "vo\\w\\f\\Atk_WF011.mp3",	--	Fight, coward!
                "vo\\w\\f\\Atk_WF014.mp3",	--	You're growing weaker!
                "vo\\w\\f\\Hlo_WF132.mp3",	--	Hail, friend.
            },
            [this.voice.loseRound] = {
                "vo\\w\\f\\Fle_WF001.mp3",	--	There will be vengeance! This is not the last of this!
                "vo\\w\\f\\Fle_WF002.mp3",	--	When we meet again, you will die!
                -- "vo\\w\\f\\Fle_WF003.mp3",	--	Get away I do not wish to fight!
                "vo\\w\\f\\Fle_WF004.mp3",	--	I will deny you your victory and the spoils!
                "vo\\w\\f\\Fle_WF005.mp3",	--	Aaaagh!
                "vo\\w\\f\\Hit_WF001.mp3",	--	Arrgh!
                "vo\\w\\f\\Hit_WF002.mp3",	--	Eeek
                "vo\\w\\f\\Hit_WF003.mp3",	--	Oooff.
                "vo\\w\\f\\Hit_WF004.mp3",	--	Ughn
                "vo\\w\\f\\Hit_WF005.mp3",	--	Stoopid.
                "vo\\w\\f\\Hit_WF006.mp3",	--	AIIEEE.
                "vo\\w\\f\\Hit_WF007.mp3",	--	Groan.
                "vo\\w\\f\\Hit_WF008.mp3",	--	Groan.
                "vo\\w\\f\\Hit_WF009.mp3",	--	Ungh!
                "vo\\w\\f\\Hit_WF009.mp3",	--	Groan.
                "vo\\w\\f\\Hit_WF010.mp3",	--	Grunt.
                "vo\\w\\f\\Hit_WF011.mp3",	--	Grunt.
                "vo\\w\\f\\Hit_WF012.mp3",	--	Groan.
                "vo\\w\\f\\Hit_WF013.mp3",	--	Growl.
                "vo\\w\\f\\Hit_WF014.mp3",	--	Gasp.
                "vo\\w\\f\\Hit_WF015.mp3",	--	Scream.
                "vo\\w\\f\\Hlo_WF000d.mp3",	--	You don't want to see me angry.
                -- "vo\\w\\f\\Hlo_WF000e.mp3",	--	Get out of here!
                "vo\\w\\f\\Hlo_WF025.mp3",	--	I really don't want you around here.
                "vo\\w\\f\\Hlo_WF026.mp3",	--	Don't bother me.
                -- "vo\\w\\f\\Hlo_WF138.mp3",	--	Aargh! Go away!
            },
            [this.voice.winGame] = {
                "vo\\w\\f\\Hlo_WF001.mp3",	--	Go back where you came from.
                "vo\\w\\f\\Hlo_WF022.mp3",	--	Can't you see I wish to be left alone!
                "vo\\w\\f\\Hlo_WF114.mp3",	--	Three blessings friend.
                "vo\\w\\f\\Hlo_WF135.mp3",	--	I have a feeling you and I are about to become very close.
                "vo\\w\\f\\Hlo_WF136.mp3",	--	This is a wondrous encounter. Welcome.
            },
            [this.voice.think] = {
                "vo\\w\\f\\Hlo_WF000a.mp3",	--	What?
                "vo\\w\\f\\Hlo_WF000b.mp3",	--	Hmmph!
                "vo\\w\\f\\Hlo_WF000c.mp3",	--	Grrrr.
                "vo\\w\\f\\Hlo_WF053.mp3",	--	I couldn't possibly. Too busy.
                "vo\\w\\f\\Hlo_WF057.mp3",	--	This better be important.
                "vo\\w\\f\\Hlo_WF083.mp3",	--	What is this about?
                "vo\\w\\f\\Idl_WF006.mp3",	--	I thought I heard something?
                "vo\\w\\f\\Idl_WF007.mp3",	--	Hmm. Probably nothing.
                "vo\\w\\f\\Idl_WF008.mp3",	--	Now where did I put that?
                "vo\\w\\f\\Idl_WF009.mp3",	--	What was that?
            },
            [this.voice.remind] = {
                -- "vo\\w\\f\\Hlo_WF024.mp3",	--	You'll get more than you bargained for from me.
                -- "vo\\w\\f\\Hlo_WF058.mp3",	--	I really don't have time for this, so make it quick.
                "vo\\w\\f\\Hlo_WF059.mp3",	--	Hurry this up, will you?
                "vo\\w\\f\\Hlo_WF061.mp3",	--	If I can help I will, but don't take too much time.
                "vo\\w\\f\\Hlo_WF085.mp3",	--	I don't know if I can help you, but I'll try.
                "vo\\w\\f\\Hlo_WF086.mp3",	--	Do you want something from me?
                -- "vo\\w\\f\\Hlo_WF087.mp3",	--	How may I help you?
                "vo\\w\\f\\Hlo_WF090.mp3",	--	How do you do?
                "vo\\w\\f\\Hlo_WF091.mp3",	--	What can I do for you?
                "vo\\w\\f\\Hlo_WF108.mp3",	--	Yes?
                -- "vo\\w\\f\\Hlo_WF109.mp3",	--	Of course. What may I do for you?
                "vo\\w\\f\\Hlo_WF110.mp3",	--	Yes, stranger?
                -- "vo\\w\\f\\Hlo_WF115.mp3",	--	How can I help? I'll do what I can.
                -- "vo\\w\\f\\Hlo_WF137.mp3",	--	If there is anything I can do, I am humbly at your service.
                "vo\\w\\f\\Idl_WF001.mp3",	--	Sniff.
                "vo\\w\\f\\Idl_WF002.mp3",	--	Cough.
                "vo\\w\\f\\Idl_WF003.mp3",	--	Sigh.
                "vo\\w\\f\\Idl_WF004.mp3",	--	Whistle.
                "vo\\w\\f\\Idl_WF005.mp3",	--	Humm.
            },
        },
        ["m"] = {
            [this.voice.continue] = {
                "vo\\w\\m\\Atk_WM004.mp3",	--	This is going to be fun.
                "vo\\w\\m\\Atk_WM008.mp3",	--	Run while you can.
                "vo\\w\\m\\Atk_WM012.mp3",	--	You should run now.
                "vo\\w\\m\\Atk_WM013.mp3",	--	I'll see you dead.
                "vo\\w\\m\\Fle_WM001.mp3",	--	There will be vengeance! This is not the last of this!
                "vo\\w\\m\\Hlo_WM062.mp3",	--	Go ahead.
                "vo\\w\\m\\Hlo_WM077.mp3",	--	Go ahead.
                "vo\\w\\m\\Hlo_WM089.mp3",	--	Interesting, go on.
            },
            [this.voice.finish] = {
                "vo\\w\\m\\Atk_WM001.mp3",	--	Now you're going to get it.
                "vo\\w\\m\\Atk_WM003.mp3",	--	You don't deserve to live.
                "vo\\w\\m\\Atk_WM005.mp3",	--	ARRRRGH.
                "vo\\w\\m\\Atk_WM006.mp3",	--	You chose the wrong Bosmer to mess with.
                "vo\\w\\m\\Atk_WM007.mp3",	--	You can't escape me.
                "vo\\w\\m\\Atk_WM009.mp3",	--	One of us will die here and it won't be me.
                "vo\\w\\m\\Atk_WM010.mp3",	--	This is too easy.
                "vo\\w\\m\\Atk_WM011.mp3",	--	Fight coward!
                "vo\\w\\m\\Atk_WM018.mp3",	--	No one can challenge me!
                "vo\\w\\m\\Hlo_WM132.mp3",	--	Hail, friend.
            },
            [this.voice.loseRound] = {
                "vo\\w\\m\\Fle_WM002.mp3",	--	When we meet again, you will die!
                -- "vo\\w\\m\\Fle_WM003.mp3",	--	Get away! I do not wish to fight!
                "vo\\w\\m\\Fle_WM004.mp3",	--	I will deny you your victory and the spoils!
                "vo\\w\\m\\Fle_WM005.mp3",	--	Aaaagh!
                "vo\\w\\m\\Hit_WM001.mp3",	--	Arrgh.
                "vo\\w\\m\\Hit_WM002.mp3",	--	Eeek
                "vo\\w\\m\\Hit_WM003.mp3",	--	Oooff.
                "vo\\w\\m\\Hit_WM004.mp3",	--	Ungh!
                "vo\\w\\m\\Hit_WM005.mp3",	--	Stoopid.
                "vo\\w\\m\\Hit_WM006.mp3",	--	AIIEEE.
                "vo\\w\\m\\Hit_WM007.mp3",	--	Groan.
                "vo\\w\\m\\Hit_WM008.mp3",	--	Groan.
                "vo\\w\\m\\Hit_WM009.mp3",	--	Groan.
                "vo\\w\\m\\Hit_WM010.mp3",	--	Grunt.
                "vo\\w\\m\\Hit_WM011.mp3",	--	Umph!
                "vo\\w\\m\\Hit_WM012.mp3",	--	Ooomph!
                "vo\\w\\m\\Hit_WM013.mp3",	--	Growl.
                "vo\\w\\m\\Hit_WM014.mp3",	--	Gasp.
                "vo\\w\\m\\Hit_WM015.mp3",	--	Scream.
                "vo\\w\\m\\Hlo_WM025.mp3",	--	I really don't want you around here.
                "vo\\w\\m\\Hlo_WM026.mp3",	--	Don't bother me.
                "vo\\w\\m\\Hlo_WM028.mp3",	--	I don't like you much.
            },
            [this.voice.winGame] = {
                "vo\\w\\m\\Hlo_WM022.mp3",	--	Can't you see I wish to be left alone!
                "vo\\w\\m\\Hlo_WM054.mp3",	--	I'm sure this is important, but I really must go.
                "vo\\w\\m\\Hlo_WM114.mp3",	--	Three blessings, friend.
                "vo\\w\\m\\Hlo_WM117.mp3",	--	I am honored to meet you.
                "vo\\w\\m\\Hlo_WM131.mp3",	--	This is a rare honor.
                "vo\\w\\m\\Hlo_WM118.mp3",	--	I think you're a thief, because you've stolen my heart.
                "vo\\w\\m\\Hlo_WM135.mp3",	--	I have a feeling that you and I are about to become very close.
            },
            [this.voice.think] = {
                "vo\\w\\m\\Hlo_WM053.mp3",	--	I couldn't possibly. Too busy.
                "vo\\w\\m\\Hlo_WM057.mp3",	--	This better be important.
                "vo\\w\\m\\Hlo_WM076.mp3",	--	Nice day, don't you think?
                "vo\\w\\m\\Hlo_WM078.mp3",	--	Well, what is this about?
                "vo\\w\\m\\Hlo_WM083.mp3",	--	What is this about?
                "vo\\w\\m\\Idl_WM009.mp3",	--	That's unusual.
            },
            [this.voice.remind] = {
                -- "vo\\w\\m\\Hlo_WM024.mp3",	--	You'll get more than you bargained for from me!
                -- "vo\\w\\m\\Hlo_WM040.mp3",	--	Is it really necessary that we talk?
                "vo\\w\\m\\Hlo_WM058.mp3",	--	I really don't have time for this, so make it quick.
                "vo\\w\\m\\Hlo_WM059.mp3",	--	Hurry this up, will you?
                "vo\\w\\m\\Hlo_WM060.mp3",	--	Sorry, stranger, my time is short, so get on with it.
                "vo\\w\\m\\Hlo_WM086.mp3",	--	Do you want something from me?
                -- "vo\\w\\m\\Hlo_WM087.mp3",	--	How may I help you?
                "vo\\w\\m\\Hlo_WM090.mp3",	--	How do you do?
                "vo\\w\\m\\Hlo_WM091.mp3",	--	What can I do for you?
                "vo\\w\\m\\Hlo_WM108.mp3",	--	Yes?
                "vo\\w\\m\\Hlo_WM109.mp3",	--	Of course. What may I do for you?
                "vo\\w\\m\\Hlo_WM110.mp3",	--	Yes, stranger?
                "vo\\w\\m\\Hlo_WM111.mp3",	--	And how are you? Can I help you?
                -- "vo\\w\\m\\Hlo_WM115.mp3",	--	How can I help? I'll do what I can.
                -- "vo\\w\\m\\Hlo_WM137.mp3",	--	If there is anything I can do, I am humbly at your service.
                "vo\\w\\m\\Idl_WM001.mp3",	--	Sniff.
                "vo\\w\\m\\Idl_WM002.mp3",	--	Cough.
                "vo\\w\\m\\Idl_WM003.mp3",	--	Sigh.
                "vo\\w\\m\\Idl_WM004.mp3",	--	Whistle.
                "vo\\w\\m\\Idl_WM005.mp3",	--	Humm.
                "vo\\w\\m\\Idl_WM006.mp3",	--	Sigh.
                "vo\\w\\m\\Idl_WM007.mp3",	--	Grumbles.
                "vo\\w\\m\\Idl_WM008.mp3",	--	Sigh.
            },
        },
    },
}

-- special
---@type {[string] : {[KoiKoi.VoiceId] : string[]}} id, VoiceId, file excluding directory
this.npcs = {
}

-- special
---@type {[string] : {[KoiKoi.VoiceId] : string[]}} id, VoiceId, file excluding directory
this.creatures = {
    ["dagoth_ur_1"] = {
        [this.voice.continue] = {
            "vo\\misc\\Hit_DU011.mp3", --	Come on!
        },
        [this.voice.finish] = {
            "vo\\misc\\Hit_DU004.mp3", --	Omnipotent. Omniscient. Sovereign. Immutable. How sweet it is to be a god!
            "vo\\misc\\Hit_DU002.mp3", --	Hah-hah-hah-hah. Oh, dear me. Forgive me, but I am enjoying this.
        },
        [this.voice.loseRound] = {
            "vo\\misc\\Hit_DU006.mp3", --	Persistent, aren't you.
            "vo\\misc\\Hit_DU008.mp3", --	STUpid....
            "vo\\misc\\Hit_DU009.mp3", --	You are a stubborn thing, Nerevar.
            "vo\\misc\\Hit_DU012.mp3", --	Damn this thing...
            "vo\\misc\\Hit Heart 4.mp3", --	STOP!
            "vo\\misc\\Hit Heart 6.mp3", --	This is the end. The bitter, bitter end.
        },
        [this.voice.winGame] = {
            "vo\\misc\\Hit_DU005.mp3", --	Farewell, sweet Nerevar. Better luck on your next incarnation.
        },
        [this.voice.think] = {
            "vo\\Misc\\Hit_DU001.mp3", --	Oh, please, Nerevar! Spare me!
            "vo\\misc\\Hit_DU003.mp3", --	I surrender! I surrender! Hah-hah-hah-hah-hah!
            "vo\\misc\\Hit_DU007.mp3", --	This is getting tiresome.
            "vo\\misc\\Hit_DU010.mp3", --	This is taking too long.
        },
        [this.voice.remind] = {
            "vo\\misc\\Dagoth Ur Taunt 3.mp3", --	Come to me, through fire and war. I welcome you.
            "vo\\misc\\Dagoth Ur Taunt 4.mp3", --	Welcome, Moon-and-Star. I have prepared a place for you.
            "vo\\misc\\Dagoth Ur Taunt 6.mp3", --	Welcome, Nerevar. Together we shall speak for the Law and the Land, and shall drive the mongrel dogs of the Empire from Morrowind.
            "vo\\misc\\Dagoth Ur Taunt 7.mp3", --	Is this how you honor the Sixth House, and the tribe unmourned? Come to me openly, and not by stealth.
            "vo\\Misc\\Dagoth Ur Welcome B.mp3", --	Welcome, Moon-and-Star, to this place where destiny is made.
        },
    },
    ["vivec_god"] = {
        [this.voice.continue] = {
            "vo\\Misc\\viv_alm1.mp3",	--	"I won't let you do that."
        },
        [this.voice.finish] = {
            "vo\\Misc\\viv_atk1.mp3",	--	"Foolish, mortal."
        },
        [this.voice.loseRound] = {
            "vo\\Misc\\viv_idl1.mp3",	--	"It is lonely to be a god."
        },
        [this.voice.winGame] = {
            "vo\\Misc\\viv_atk2.mp3",	--	"Don't fight gods, fool."
        },
        [this.voice.think] = {
            "vo\\Misc\\viv_hit1.mp3",
        },
        [this.voice.remind] = {
            "vo\\Misc\\viv_hlo1.mp3",	--	"Yes, incarnate? I am the Vivec and I can answer all your questions."
        },
    },
    ["yagrum bagarn"] = {
        [this.voice.continue] = {
        },
        [this.voice.finish] = {
        },
        [this.voice.loseRound] = {
            "vo\\Misc\\Yagrum_2.mp3",	--	Noooo!
        },
        [this.voice.winGame] = {
        },
        [this.voice.think] = {
        },
        [this.voice.remind] = {
        },
    },
    ["almalexia"] = {
        [this.voice.continue] = {
            "vo\\Misc\\tr_almgreet2.mp3",	--	Come. Bathe in the light of My Mercy.
        },
        [this.voice.finish] = {
            "vo\\Misc\\tr_almgreet1.mp3",	--	Many Blessings upon you, my loyal servant.
        },
        [this.voice.loseRound] = {
        },
        [this.voice.winGame] = {
            -- "vo\\Misc\\tr_almgreet1.mp3",	--	Many Blessings upon you, my loyal servant.
        },
        [this.voice.think] = {
        },
        [this.voice.remind] = {
            "vo\\Misc\\tr_almgreet3.mp3",	--	What may I do for you, my child?
        },
    },

}

return this
