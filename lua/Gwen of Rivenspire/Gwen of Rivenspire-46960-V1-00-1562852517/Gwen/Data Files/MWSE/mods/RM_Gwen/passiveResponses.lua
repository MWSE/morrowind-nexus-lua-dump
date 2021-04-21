--[[
    -- "minDistance" : specifies the minimum distance required
    --
--]]


local gwen
local function onLoaded(e)
    gwen = tes3.getReference("RM_Gwen")
end
event.register("loaded", onLoaded)
local response = {}

---------------------------------
--- Other Mods
---------------------------------
--- Paxon the Rat - Tizzo - 5000
response["aa1_paxon"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 5000
    return {
    }
end
--- Publius - Gavrilo - 5010
response["aa_publius"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 5010
    return {
    }
end
--- Get Sharp! - G7 and Me :D - 6000
response["rm_grindwheel"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 6000
    return {
        "Gwen: Any idea how you work this thing?",
        "Gwen: I wouldn't mind finding some way to sharpen my poleaxe.",
        "Gwen: Is it me, or is it hot here?",
        "Gwen: Where's the Smith?",
    }
end
response["rm_quench"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 6001
    return {
        "Gwen: Got anything blunt you can stick in here?",
        "Gwen: This thing is due for an oil change.",
        "Gwen: I wonder why oil works better than water?",
        "Gwen: Where's that Smith when you need one?",
    }
end
-----------------------
---  Quests - NPCs 0K
-----------------------
response["milie hastien"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1
    return {
        "Gwen: I love this shop.",
        "Gwen: She makes all her own clothes you know.",
        "Gwen: Have you seen her jewellery?",
        "Gwen: It needs more candles in here so I can see everything better.",
        "Gwen: She deserves a bigger shop.",
        "Gwen: She has everything a girl could need in here.",
    }
end
--- Fields of Kummu Quest
response["nevrasa dralor"] = function(ref, distance, script, journal)
        script.luapass = 2
       if distance < 768 then
          if journal.MV_WanderingPilgrim >= 100 then
               return { "Oh, hello Nevrasa.",
                        "Look, there's that Pilgrim we helped.", }
           elseif journal.MV_WanderingPilgrim >= 30 then
              return { "Come on slow coach. Pick your feet up woman.",
                       "What do you think of the Empire Nevrasa?", }
           else
              return { "Do you think we should help that Pilgrim?",
                       "She looks all helpless.", }
          end
        end
end
--- Beauty and the Bandit Quest
response["maurrie aurmine"] = function(ref, distance, script, journal)
        script.luapass = 3
       if distance < 768 then
          if journal.MV_VictimRomance >= 105 then
               return { "Hello Maurrie.",
               "Look, there's Maurrie. Give her a wave!", }
           elseif journal.MV_VictimRomance >= 40 then
              return { "Gwen: If we're going to Pelagiad I see no reason why we can't visit the tavern.",
                       "Gwen: Do you think we will find this Nelos Onmar?",
                       "Gwen: Careful, Nelos is a bandit. He might be dangerous.", }
           else
              return { "Gwen: Another Breton. She looks distressed doesn't she?",
                       "Gwen: I wonder why she's out here all alone?", }
            end
        end
end
--- Cloud Cleaver    
response["hlormar wine-sot"] = function(ref, distance, script, journal)
        script.luapass = 4
       if distance < 512 then
          if journal.MV_AbusedHealer >= 85 then
               return { "Hello Hlormar.", "Now you have your axe, how about buying some clothes!", }
           elseif journal.MV_AbusedHealer >= 30 then
              return { "Gwen: Great. Now we have a big dumb Nord with us.",
              "Gwen: Seriously Hlormar. Are you not cold?",
              "Gwen: Put it away Wine-sot before I chop it off!",
              "Gwen: If it was any colder you could get mistaken for a girl Hlormar.", }
           else
              return { "Gwen: OH! Put it away!", "Why do Nords never seem to know how to dress?", }
            end
          end
end
--- Boots of Blinding Speed
response["pemenie"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 5
    if journal.MV_TraderAbandoned < 20 then
        return
    end
    return {
        "Gwen: If we're going to Gnaar Mok, what do you say to checking out Khartag Point?",
        "Gwen: I was wondering Pemenie. Would you be missed?",
        "Gwen: Nice boots. They'd look better on me.",
        "Gwen: So why did you get abandoned then? Run too fast did you?",
        "Gwen: I'm sure I've heard your name somewhere before Pemenie...",
    }
end
--- Missing Pants
response["hentus yansurnummu"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 6
    if journal.MS_HentusPants > 5 then
        return
    end
    return {
        "Gwen: Ha! Put some pants on man.",
        "Gwen: Caught short was you?",
        "Gwen: I bet you won't leave your clothes on the bank no more.",
    }
end
--- Mask of Vivec

--------------------------
---- Flora - 100
---------------------------
response["flora_willow_flower_02"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 131
    return {
        "Gwen: Willow flowers seems to flower all year round.",
        "Gwen: Can we use willow petals for anything?",
        "Gwen: I used to pick these for my mother back home.",
    }
end
response["flora_stoneflower_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 134
end
response["flora_bc_mushroom_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end

    -- update script variables
    script.luapass = 101

    -- return the message list
    return {
        "Gwen: Oo. Mushrooms. I like these ones.",
        "Gwen: I like these mushroom much more than those violet ones.",
    }
end
response["flora_bc_podplant_02"] = function(ref, distance, script, journal)
    if distance > 512 then return end

    -- update script variables
    script.luapass = 102

    -- return the message list
    return {
        "Gwen: These flowers are so pretty.",
        "Gwen: Such pretty flowers in such a horrible place.",
    }
end
response["flora_bc_mushroom_07"] = function(ref, distance, script, journal)
    if distance > 512 then return end

    -- update script variables
    script.luapass = 103

    -- return the message list
    return {
        "Gwen: I wonder why they called these violets, they're not even purple.",
        "Gwen: Do we need any of these violet mushrooms for anything?",
        "Gwen: See these mushrooms? You can eat them, but only once!",
    }
end
response["flora_bc_shelffungus_02"] = function(ref, distance, script, journal)
    if distance > 512 then return end

    -- update script variables
    script.luapass = 104

    -- return the message list
    return {
        "Gwen: Be careful of that fungus, it's poisonous.",
        "Gwen: I wonder if that fungus is any use?",
        "Gwen: Fungus. Everywhere.",
        "Gwen: The trees around here are massive aren't they?",
    }
end
response["flora_heather_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 130
    return {
        "Gwen: Heather smells so nice. Don't you think so?",
        "Gwen: Those Heather flowers are so nice.",
        "Gwen: I knew someone once that used to sell heather door to door.",
        "Gwen: Heather flowers are so pretty.",
        "Gwen: Did you know, If you crush heather flowers up you can use the oil as perfume.",
    }
end
response["flora_ash_yam_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 135
    return {
        "Gwen: My mother had a recipe for Ash Yam soup.",
        "Gwen: Ash Yams are delicious!",
        "Gwen: Yams and slaughterfish. Yummy.",
        "Gwen: Yummy, yammy!",
        "Gwen: Sometimes I used to take yams back with me after we dropped off our cargo."
    }
end
response["flora_corkbulb"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 136
    return {
        "Gwen: It's hard to believe they fletch arrows from these roots isn't it?",
        "Gwen: Did you know you can cure paralyzation with corkbulb roots?",
        "Gwen: This corkbulb is supposed to be so good for you.",
        "Gwen: My sister used to clean her teeth with corkbuld stalks.",
    }
end
----------------------------------------------------------------
local function hacklo (ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 137
    return {}
end
response["flora_hackle-lo_01"] = hacklo
response["flora_hackle-lo_02"] = hacklo
----------------------------------------------------------------
local function wheat (ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 133
    return {}
end
response["flora_wickwheat_01"] = wheat
response["flora_wickwheat_02"] = wheat
response["flora_wickwheat_03"] = wheat
response["flora_wickwheat_04"] = wheat
----------------------------------------------------------------
local function rice (ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 132
    return {}
end
response["flora_saltrice_01"] = rice
response["flora_saltrice_02"] = rice
----------------------------------------------------------------
response["flora_gold_kanet_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 138
    return {
        "Gwen: I love gold kanet don't you?",
        "Gwen: Those flowers have always caught my eye. We don't have them in High Rock.",
        "Gwen: Kanet must be the most beautiful flower in Vvardenfell.",
        "Gwen: I bet any girl would love to receive a posy of those kanets.",
    }
end
response["flora_kreshweed_02"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 139
    return {
    }
end
response["flora_comberry_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 140
    return {
    }
end
response["flora_ashtree_04"] = function(ref, distance, script, journal)
    if distance > 1024 then return end
    script.luapass = 141
    return {
    }
end
response["tramaroot_01"] = function(ref, distance, script, journal)
    if distance > 1024 then return end
    script.luapass = 142
    return {
        "Gwen: Careful of those thorns on that tramaroot.",
        "Gwen: Ugly plant that is. Catches your dress when walk passed it as well.",
    }
end
response["flora_muckspunge_02"] = function(ref, distance, script, journal)
    if distance > 1024 then return end
    script.luapass = 143
    return {
    }
end
----------------------------------------------------------------
-- Random Ashlanders - 190
----------------------------------------------------------------
local function ashlanders (ref, distance, script, journal)
    if distance > 768 then return end
    script.luapass = 190
    mwscript.removeItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
    mwscript.addItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.addItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
    return {
        "Gwen: Damned Ashlanders!",
        "Gwen: You should have stayed in your hut, bitch!",
        "Gwen: Ashlander with attitude.",
        "Gwen: Bloody Ashlanders. They think they own the place.",
    }
end
response["seba anurnudai"] = ashlanders
response["patus assumanallit"] = ashlanders
response["shara atinsabia"] = ashlanders
response["benudni ilurnubishpal"] = ashlanders
response["shipal zansatanit"] = ashlanders
response["adaishah ahanidiran"] = ashlanders
response["shullay malman-ammu"] = ashlanders
response["sal pudashara"] = ashlanders
response["ibasour sershurrapal"] = ashlanders
response["munbebi addarari"] = ashlanders
response["shanat kaushminipu"] = ashlanders
response["tibdan shalarnetus"] = ashlanders
response["mamaea ularshanentus"] = ashlanders
response["ainat maessabibi"] = ashlanders
response["dakin kuntarnammu"] = ashlanders
response["zanat assarnuridan"] = ashlanders
response["nirait shin-ilu"] = ashlanders
response["manirai mirshamammu"] = ashlanders
response["shishi yanumibaal"] = ashlanders
response["odairan addaribantes"] = ashlanders
response["turan tibashipal"] = ashlanders
response["subenend urshummarnamus"] = ashlanders
response["assamanu shashipal"] = ashlanders
response["pilu shilansour"] = ashlanders
response["salmus kaushmamanu"] = ashlanders
----------------------------------------------------------------
-- Random Ashlanders - Non Treatening - 191
----------------------------------------------------------------
local function ashlanders2 (ref, distance, script, journal)
    if distance > 768 then return end
    script.luapass = 191
    return {
    }
end
response["rasamsi esunarnat"] = ashlanders2
response["adairan lalansour"] = ashlanders2
----------------------
-- Random NPCs - 250
----------------------
response["gaeldol"] = function(ref, distance, script, journal)
    if distance > 512 then return end

    -- update script variables
    script.luapass = 250

    -- return the message list
    return {
        "Gwen: Oh my, look at his hat.",
        "Gwen: Nice hat. Sexy...",
        "Gwen: Oh, I so need a hat like that! Not.",
        "Gwen: If that hat is a fashion statement I'm glad to be out of fashion.",
        "Gwen: What on Nirn has he got on his head?",
    }
end
response["hul"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 251
    return {
        "Gwen: Hello Hul.",
        "Gwen: Hey, Hul. Still walking up and down I see?",
    }
end
response["dur gro-grambak"] = function(ref, distance, script, journal)
    if distance > 1024 then return end

    -- update script variables
    script.luapass = 252

    -- return the message list
    return {
        "Gwen: Big dumb Orc alert.",
        "Gwen: Honour they say. That's what makes them so nuts!",
    }
end
response["scamp_creeper"] = function(ref, distance, script, journal)
    if distance > 256 then return end
    script.luapass = 253
    return {
            "Gwen: I don't like this scamp. He's creepy.",
            "Gwen: You know you're going to get ripped off by a scamp right?",
            "Gwen: I wonder just how much gold he makes?",
            "Gwen: What does he do with all the money?",
            "Gwen: He's addicted to skooma you know? We used to sell a lot of it to him.",
            "Gwen: I bet this scamp would buy our extra potions.",
            "Gwen: He buys almost anything this scamp.",
            "Gwen: I imagine he has his own junk yard somewhere.",
            "Gwen: I wonder how many people come here to sell him things?",
            "Gwen: At least we know where we can off load skooma.",
            }
end
response["nalcarya of white haven"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 254
    return {}
end
response["ralen hlaalo"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 255
    return {
            "Gwen: It stinks in here!",
            "Gwen: What is that awful smell?",
            "Gwen: I reckon we could rob this place blind and no one would ever know.",
            "Gwen: Let's take all the furniture and sell it to the Creeper.",
            "Gwen: Booze! And it's free. I don't think he will be needed it anymore do you?",
            "Gwen: The gaurds should move this bloody body before it stinks up the town!",
            "Gwen: Seriously. Is that gooey stuff coming out of him. It smells terrible.",
            }
end
response["imperial guard"] = function(ref, distance, script, journal)
    if distance > 256 then return end
    script.luapass = 256
    return {
        "Gwen: I don't like them but I do find that uniform strangely alluring.",
        "Gwen: Sh! Here comes the guard.",
        "Gwen: Look at the guards faces. They all look like they've never had any fun. Ever.",
    }
end
response["sevyni saryon"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 259
    return {
        "Gwen: I don't like them but I do find that uniform strangely alluring.",
        "Gwen: Sh! Here comes the guard.",
        "Gwen: Look at the guards faces. They all look like they've never had any fun. Ever.",
    }
end
--------------------------------------------------------------------
local function netchfarm (ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 257
    return {
        "Gwen: Wow. Have you ever seen so many netch before all in one place?",
        "Gwen: Look at the size of that one!",
        "Gwen: Those things have really tough skin. It's hard to believe they can hover like that.",
    }
end
response["fevasa saryon"] = netchfarm
response["irvama othrelas"] = netchfarm
---------------------------------------------------------------------
response["hlaalu guard_outside"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 258
    return {
    }
end
response["sevyni saryon"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 259
    return {
            }
end
response["aurane frernis"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 260
    return {
            }
end
response["fargoth"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 261
    return {
            }
end
response["punibi yahaz"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 262
    return { "Gwen: Don't you get bored standing here all day Punibi?",
            }
end
response["ancestor_ghost_vabdas"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 263
    return { "Gwen: OH! A ghost.",
                "Gwen: Well that's not something you see every day is it?",
                "Gwen: I almost wet myself when I saw that ghost.",
            }
end
response["alynu aralen"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 264
    return { "Gwen: Filthy spies.",
                "Gwen: Strip them of cash and leave them to rot.",
                "Gwen: Death is too good for spies.",
            }
end
response["sedrane arvel"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 265
    return { 
            }
end
response["edras oril"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 266
    return { 
            }
end
---------------------------
local function slaves (ref, distance, script, journal)
    if distance > 768 then return end
    script.luapass = 267
    return {
        "Gwen: I abore slavery.",
        "Gwen: It's disgusting how they treat these people.",
        "Gwen: Poor Argonians. Second class here.",
        "Gwen: I imagine those bracers hurt. They look so tight.",
        "Gwen: Setting them all free from this sad life is the only option.",
        "Gwen: I couldn't live with myself if I had slaves.",
    }
end
response["unjara"] = slaves
response["twice_bitten"] = slaves
response["morning_clouds"] = slaves
response["grey_throat"] = slaves
---------------------------
response["verick gemain"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 268
    return { 
            }
end
response["shenk"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 269
    return { 
            }
end
response["falanaamo"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 270
    return { 
            }
end
response["folms mirel"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 271
    return { 
            }
end
response["maeonius yentimilal"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 272
    return {
            }
end
response["nevusa veleth"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 273
    return {
            }
end
response["lucan ostorius"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 274
    return {
            }
end
response["midnabi sobdishapal"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 275
    return {
            }
end
response["fonus rathryon"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 276
    return {
            }
end
response["dead random male"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 277
    return { "Gwen: Something's amiss here.",
                "Gwen: That body stinks.",
                "Gwen: Dead bodies are never a good sign.",
            }
end
response["snowy granius"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 278
    return {
            }
end
response["louis beauchamp"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 279
    return {
            }
end
---------------------------
-- Diseased Creatures - 500
---------------------------
response["kagouti_diseased"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 500
    return {
        "Gwen: Careful, that Kagouti has yellow tick.",
        "Gwen: It's diseased. No wonder it's mad.",
        "Gwen: That thing was scratching itself. I think it's got something.",
    }
end
--------------------------
-- Random Things - 550
--------------------------
response["ex_t_door_stone_large"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 550
    return {
        "Gwen: Abandon hope all ye who enter...",
        "Gwen: They can't even make doors that open right.",
        "Gwen: Inn's have beds and beds aren't just for sleeping in.",
    }
end
response["ex_imp_wall_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 551
    return {
        "Gwen: They don't half build these fort quickly.",
        "Gwen: Look at the size of those walls.",
        "Gwen: I wonder where they get the stone from for these forts? It doesn't look like anything you find here.",
    }
end
response["ex_nord_well_01"] = function(ref, distance, script, journal)
    if distance > 768 then return end
    script.luapass = 552
    return {
        "Gwen: Well? Get it? Well. Umf, nevermind.",
        "Gwen: I'm glad they cover those things up. Wouldn't like to fall down a well would you?",
        "Gwen: Truth is a well we all draw from and slowly poison.",
    }
end
response["in_nord_fireplace_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 553
    return {
        "Gwen: That's just want I need. I nice warm fire.",
        "Gwen: Doesn't that fireplace look inviting?",
        "Gwen: I bet we could make a roast on that.",
    }
end
response["ex_dwrv_bridge10"] = function(ref, distance, script, journal)
    if distance > 1024 then return end
    script.luapass = 554
    return {
        "Gwen: Dwemer ruins always give me the shivers.",
        "Gwen: I've read some books on the Dwemer you know.",
        "Gwen: I wonder how they all died out like they did?",
    }
end
response["ex_velothi_entrance_02"] = function(ref, distance, script, journal)
    if distance > 1500 then return end
    script.luapass = 555
    return {
        "Gwen: Exploring tombs just doesn't feel right does it?",
        "Gwen: All those dead people just rotting away in those tombs.",
        "Gwen: The Velothi have some strange ideas about funerals don't they?",
    }
end
response["ex_cave_door_01"] = function(ref, distance, script, journal)
    if distance > 1500 then return end
    script.luapass = 556
    return {
        "Gwen: So many caves everywhere.",
        "Gwen: I wonder who put all the doors on these caves?",
        "Gwen: I wouldn't like to live in a cave. Glad I'm not a bandit.",
    }
end
response["ex_stronghold_pylon02"] = function(ref, distance, script, journal)
    if distance > 2500 then return end
    script.luapass = 557
    return {
        "Gwen: These strongholds were built to last. I wonder how old this one is?",
        "Gwen: I've heard stories about these places.",
        "Gwen: I wonder what they used those sand pits for?",
        "Gwen: They're really quite big aren't they?",
        "Gwen: I had never seen a stronghold until I tagged along with you.",
    }
end
response["ex_dae_pillar_02_ruin"] = function(ref, distance, script, journal)
    if distance > 1500 then return end
    script.luapass = 558
    return {
        "Gwen: These places are really creepy.",
        "Gwen: Always something nasty hanging around these places.",
        "Gwen: They should get priests to clense all the ruins.",
        "Gwen: I wonder what horrible creatures lurk around here?",
        "Gwen: Just imagine the debauchery that went on in Daedric ruins.",
    }
end
-----------------------------------------------------------
local function crates (ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 559
    return {
    }
end
response["crate_01_empty"] = crates
response["crate_01"] = crates
response["crate_02_random_pos"] = crates
-----------------------------------------------------------
local function barrels (ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 560
    return {
    }
end
response["barrel_01"] = barrels
response["barrel_02"] = barrels
response["barrel_02_cheapfood5"] = barrels
-----------------------------------------------------------
response["ex_gg_gateswitch_01"] = function(ref, distance, script, journal)
    if distance > 240 then return end
    script.luapass = 561
    return {
        "Gwen: Pressing that switch could be a bad idea.",
        "Gwen: Not sure about you but, I don't like the idea of going behind the Ghostgate.",
    }
end
response["in_velothi_ashpit_02"] = function(ref, distance, script, journal)
    if distance > 240 then return end
    script.luapass = 562
    return {
        "Gwen: It's just not right to rob tombs.",
        "Gwen: This place gives me the chills.",
    }
end
response["terrain_cairn_al_02"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 563
    return {
        "Gwen: I wonder who piled all these rocks on top of one another?",
        "Gwen: How are these cairns even supposed to guide you?",
    }
end
response["ac_maar_gan_magic_rock"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 564
    return {
    }
end
response["in_dwrv_corr2_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 565
    mwscript.removeItem{reference="RM_Gwen", item="rm_gwen_torch", count=1}
    mwscript.addItem{reference="RM_Gwen", item="rm_gwen_torch", count=1}
    return {
    }
end
response["ex_dwrv_wall30"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 566
    return {
    }
end
--------------------------
---  Shop Signs - 800
--------------------------
response["active_sign_c_inn_02"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 800
    return {
        "Gwen: A tavern!",
        "Gwen: Did you know that drinking is good for you?",
        "Gwen: Inn's have beds and beds aren't just for sleeping in.",
    }
end
response["furn_bannerd_goods_balmoraoutf"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 801
    return {
        "Gwen: Clagius. What a drag.",
        "Gwen: It says outfitter when it should say clutter monkey.",
        "Gwen: False advertising. He sells more pots and pans than outfits.",
        "Gwen: I have no idea why Clagius insists he's an outfitter.",
    }
end
response["furn_bannerd_wa_shop_meldor"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 802
    return {
        "Gwen: Meldor's armoury.",
        "Gwen: Creepy little wood elf. He says armourer but he's never made a thing.",
        "Gwen: Going in Meldor's shop?",
        "Gwen: Meldor the armourer. I'll believe that when I see it.",
        "Gwen: Do you think Meldor has ever held a hammer?",
    }
end
response["furn_bannerd_clothing_01_hastie"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    if journal.RM_GwenMain < 145 then
        return
    end
    script.luapass = 803
    return {
        "Gwen: Milie Hastien's shop.",
        "Gwen: Let's visit Milie while we're here.",
        "Gwen: Are we Going in Milie's?",
        "Gwen: Milie has some really nice stuff you know.",
        "Gwen: Milie's a Breton you know, like me.",
        "Gwen: I really like Milie.",
    }
end
response["furn_banner_temple_02"] = function(ref, distance, script, journal)
    if distance > 512 then return end

    -- update script variables
    script.luapass = 804

    -- return the message list
    return {
        "Gwen: The Temple.",
        "Gwen: Are we going in the temple?",
    }
end
response["furn_banner_tavern_southwall"] = function(ref, distance, script, journal)
    if distance > 512 then return end

    -- update script variables
    script.luapass = 805

    -- return the message list
    return {
        "Gwen: Southwall Corner Club.",
        "Gwen: Watch out! Thieves are about.",
        "Gwen: They would steal your Grandmother off her porch these people.",
    }
end
response["active_sign_c_inn_shenks"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 806
    return {
        "Gwen: Shenk's Shovel. Interesting name.",
        "Gwen: I wonder how this place got its name?",
        "Gwen: Nice place for a drink or two.",
    }
end
response["active_sign_c_goods_caldera"] = function(ref, distance, script, journal)
    if distance > 512 then return end

    -- update script variables
    script.luapass = 807

    -- return the message list
    return {
        "Gwen: Verick Germain: Trader.",
        "Gwen: I heard this Germain has a bit of everything for sale.",
        "Gwen: Is it worth a look in here?",
    }
end
response["active_sign_c_clothing_falanaam"] = function(ref, distance, script, journal)
    if distance > 512 then return end

    -- update script variables
    script.luapass = 808

    -- return the message list
    return {
        "Gwen: Falanaamo: Clothier.",
        "Gwen: We could always go in here and buy me all the clothes.",
        "Gwen: Need any new clothes?",
    }
end
response["furn_banner_tavern_maar gaan"] = function(ref, distance, script, journal)
    if distance > 512 then return end

    -- update script variables
    script.luapass = 809

    -- return the message list
    return {
        "Gwen: A tavern. How convenient.",
        "Gwen: Good place to get that dust out of our throats don't you think?",
        "Gwen: I wonder if they have any whisky left here?",
    }
end
response["furn_banner_tavern_suran_02"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 810
    return {
        "Gwen: I bet you love it in there don't you?",
        "Gwen: Naked dancers...",
        "Gwen: I wouldn't pay for it. Filthy whores.",
        "Gwen: Probably catch something in there.",
        "Gwen: I wonder how many men they're had? And women. Not fussy I heard.",
        "Gwen: Do anything for coin those whores.",
        "Gwen: I wonder like to be their last customer.",
        "Gwen: Imagine, how many times they've lay on their backs for money.",
        "Gwen: You will be scratching yourself for weeks if you use this place.",
        "Gwen: I can't believe their virtue and honour is so cheap.",
        "Gwen: I'd call them sluts, but sluts don't get paid.",
        "Gwen: They put all women to shame they do.",
        "Gwen: I'm glad I've never had to resort to an aching back and sore knees for a septim or two.",
        "Gwen: Why don't you go in and ask for a price list instead of just looking?",
        "Gwen: I've heard they do an oral special, and I don't mean they talk to you!",
    }
end
response["active_sign_c_arms_caldera"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 811
    return {
        "Gwen: Shouldn't we get our gear checked?",
        "Gwen: I've heard good things about Hodlismod.",
        "Gwen: If you need an armourer I suggest Hodlismod.",
    }
end
response["active_sign_c_pawn_irgola"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 812
    return {
        "Gwen: We could use Irgola to buy the stuff the Creeper won't.",
        "Gwen: Irgola could buy all the loot we don't need.",
        "Gwen: I wonder if Irgola sell ingredients?",
    }
end
response["ex_vivec_roadmarker_01"] = function(ref, distance, script, journal)
    if distance > 1024 then return end
    script.luapass = 813
    return {
        "Gwen: Oh of all the places we could visit you had to pick Vivec.",
        "Gwen: I hate this place with a passion you know.",
        "Gwen: I hope you know your way around here?",
        "Gwen: Vivec. The worst place ever.",
    }
end
response["act_banner_tel_branora"] = function(ref, distance, script, journal)
    if distance > 1024 then return end
    script.luapass = 814
    return {
        "Gwen: Welcome to mushroom land and have a nice day!",
        "Gwen: Sheeh, Telvanni. Hate this bunch.",
        "Gwen: While we're here why don't we tell them about that new invention? Stairs.",
        "Gwen: I thought I had a bad attitude until I met a Telvanni.",
    }
end
response["act_banner_sadrith_mora"] = function(ref, distance, script, journal)
    if distance > 1024 then return end
    script.luapass = 815
    return {
        "Gwen: I remember coming here once to sell them some cargo. Shifty bunch.",
        "Gwen: Why don't we visit Muriel's while we're here?",
        "Gwen: While we're here why don't we tell them about that new invention? Stairs.",
        "Gwen: I thought I had a bad attitude until I met a Telvanni.",
    }
end
response["active_sign_caldera_01"] = function(ref, distance, script, journal)
    if distance > 1024 then return end
    script.luapass = 816
    return {
        "Gwen: Shouldn't we check the signpost?",
        "Gwen: Choices, choices. Show me a sign...post.",
        "Gwen: Caldera, this way.",
        "Gwen: So, where are we going then. Caldera maybe?",
    }
end
response["ex_aldruhn_roadmarker_01"] = function(ref, distance, script, journal)
    if distance > 1024 then return end
    script.luapass = 817
    return {
        "Gwen: Are we going to Ald-ruhn?",
        "Gwen: Ald-ruhn, where the crab people live.",
        "Gwen: They have a pub in Ald-ruhn.",
        "Gwen: Not far to Ald-ruhn from here. Maybe we could stock up things.",
    }
end
--------------------------
---- Creatures - 900
--------------------------
response["mudcrab"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 900
    return {
        "Gwen: Mudcrabs are so sneaky. You can hardly see them.",
        "Gwen: Evil little sods these.",
        "Gwen: Careful. These buggers will have your toes.",
        "Gwen: Oh look. Lunch is attacking us.",
    }
end
response["rat"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 901
    mwscript.removeItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
    mwscript.addItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.addItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
    return {
        "Gwen: Rats! I hate rats.",
        "Gwen: Horrible creatures.",
        "Gwen: Furry little balls of doom.",
        "Gwen: Ugly, horrible...things!.",
    }
end
response["scamp"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 902
    mwscript.removeItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
    mwscript.addItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.addItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
    return {
        "Gwen: Don't scamps make your skin crawl?",
        "Gwen: They have to be one of the ugliest things in Vvardenfell.",
        "Gwen: Can't we skin it?",
        "Gwen: They're so annoying. I prefer them dead.",
        "Gwen: I could make a bloody hand bag out of that thing.",
    }
end
response["nix-hound"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 903
    return {
        "Gwen: I would love to train one of those things.",
        "Gwen: Some people keep them as guard hounds you know.",
        "Gwen: Nix are so nasty, also so tasty.",
        "Gwen: We should get a fire going and make ourselves some nix steaks.",
    }
end
response["cliff racer"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 904
    mwscript.removeItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
    mwscript.addItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    return {
        "Gwen: I loathe bloody cliff racers.",
        "Gwen: There should be a bounty or something on cliff racers.",
        "Gwen: Just imagine a world without cliff racers.",
        "Gwen: flying rats!",
    }
end
response["scrib"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 905
    return {
        "Gwen: Is it me or are scribs so cute!",
        "Gwen: I just decided. I want a pet scrib.",
        "Gwen: Look at it. Don't you just want to pet them when you see a scrib?",
        "Gwen: Not sure which I like the best. Guar or scrib.",
    }
end
response["alit"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 906
    return {
        "Gwen: Nasty little sods those alit.",
        "Gwen: I'm glad they didn't get a hold of me with those bloody teeth.",
        "Gwen: Alits sure look better when they're dead.",
        "Gwen: What would you think of alit shoes?",
    }
end
response["centurion_spider"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 907
    return {
        "Gwen: I don't like spiders at the best of times but metal ones...",
    }
end
response["shalk"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 908
    return {
        "Gwen: Shalk, never thought I would be so far out to see one before.",
        "Gwen: I read about these things.",
        "Gwen: You can use the resin from shalk as glue you know?",
    }
end
response["slaughterfish"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 909
    mwscript.removeItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
    mwscript.addItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    return {
        "Gwen: Get a bite of one of those bloody fish and you go do-lally.",
        "Gwen: Let's scrape all the scales off the bastards.",
        "Gwen: Roasted slaughterfish on a nice open fire. what do you say to that?",
    }
end
--------------------------
---- Furniture - 1000
--------------------------
response["furn_spinningwheel_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1000
    return {}
end
response["furn_web00"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1001
    return {}
end
response["in_6th_chalk00"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1002
    return {}
end
response["furn_shrine_aralor_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1003
    return {}
end
response["furn_mist256"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1004
    return {}
end
response["furn_fireplace10"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1005
    return {}
end
response["furn_de_minercave_grill_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1006
    return {}
end
response["furn_de_loom_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1007
    return {}
end
------------------------------------------------------------------
local function fpit (ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1008
    return {"Gwen: Nice to see a good fire isn't it?",
            }
end
response["furn_de_firepit"] = fpit
response["light_pitfire00"] = fpit
response["furn_de_firepit_f"] = fpit
------------------------------------------------------------------
response["furn_6th_ashstatue"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1009
    return {}
end
response["furn_6th_ashaltar"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1010
    return {}
end
response["furn_6th_bells"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1011
    return {}
end
response["furn_6th_banner"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1012
    return {}
end
response["furn_ashl_chimes_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1013
    return {}
end
response["in_lava_1024"] = function(ref, distance, script, journal)
    if distance > 768 then return end
    script.luapass = 1014
    return {}
end
response["ex_dae_azura"] = function(ref, distance, script, journal)
    if distance > 4096 then return end
    script.luapass = 1015
    return {"Gwen: Are we going to Azura's shrine?", 
            "Gwen: Azura's shrine is there.",
            "Gwen: I wonder what Azura thinks of it here all alone?",}
end
---------------------------------------
--- Shrines
---------------------------------------
response["furn_shrine_llothis_cure_01"] = function(ref, distance, script, journal)
    if distance > 900 then return end
    if script.rm_shrine ~= 0 then return end
    script.rm_shrine = 2
    script.rm_gwen_global = 0
 --   script.luapass = 1016
    tes3.setAIActivate({ reference = gwen, target = ref })
    return {"I think I'll be having a blessing.",}
end
response["furn_shrine_rilm_cure_01"] = function(ref, distance, script, journal)
    if distance > 900 then return end
    if script.rm_shrine ~= 0 then return end
    script.rm_shrine = 2
    script.rm_gwen_global = 0
 ---   script.luapass = 1017
 tes3.setAIActivate({ reference = gwen, target = ref })
    return {"Oh, Rilm's gift. I'll have me some of that."}
end
----------------------------------------
local function swamparea (ref, distance, script, journal)
    if distance > 1024 then return end
    script.luapass = 1018
    return {
        "Gwen: This swamp stinks!",
        "Gwen: Honestly. I'm going to ruin these shoes here.",
        "Gwen: Was that a frog I just saw?",
        "Gwen: It sounds quite peaceful here if you just listen.",
        "Gwen: This place is just perfect for crab hunting.",
        "Gwen: I wonder why they call them knees?",
        "Gwen: I wouldn't be happy if my knees look like these.",
        "Gwen: Smells like rotting wood here.",
    }
end
response["terrain_bc_scum_02"] = swamparea
response["terrain_bc_scum_01"] = swamparea
-----------------------------------------
response["ex_de_shipwreck"] = function(ref, distance, script, journal)
    if distance > 2048 then return end
    script.luapass = 1019
    return {}
end
response["ex_common_window_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1020
    return {
        "Gwen: I love these houses. So much nicer than those drab things in Balmora.",
        "Gwen: Look at that brickwork. You don't see that in mushroom land.",
        "Gwen: I wonder why those Telvanni don't build proper houses like these?",
        "Gwen: You would think everyone would want to live in these houses wouldn't you?",
        "Gwen: These houses make me miss home.",
        "Gwen: Reminds me of High Rock here.",
        "Gwen: Looks so much like Shornhelm.",
        "Gwen: If you ever get to Glenumbra you see houses just like these.",
        "Gwen: Camlorn is very similar. Just a lot bigger than this place.",
    }
end
response["ex_imp_dragonstatue"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1021
    return {
        "Gwen: that statue is impressive.",
        "Gwen: The Imperial dragon is looking down on us. What's knew?",
        "Gwen: I wonder how long it took them to make that statue?",
    }
end
response["ex_redoran_hut_02"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1022
    return {
        "Gwen: These houses look like they have eyes and a big mouth.",
        "Gwen: Kind of creepy here isn't it?",
        "Gwen: I wonder why they shaped their homes like this?",
        "Gwen: Seriously now. Who lives in a crab?",
    }
end
response["ex_redoran_steps_01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1023
    return {
        "Gwen: Great. More steps.",
        "Gwen: I would have made this place flat before I built on it. So many steps around here.",
    }
end
response["ex_t_slavepod_01"] = function(ref, distance, script, journal)
    if distance > 768 then return end
    script.luapass = 1024
    return {
        "Gwen: It's disgusting how the Telvanni still have slaves.",
        "Gwen: I wish we could free all the slaves.",
        "Gwen: Slaves. Just proves how backward these Telvanni really are.",
        "Gwen: I'd like to keep a Telvanni slave. See how they like it!",
        "Gwen: It must be terrible being a slave.",
        "Gwen: Slavery still. These Telvanni make my blood boil.",
    }
end
response["crate_01_food_misc01"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1025
    return {
        "Gwen: We shoud check out those crates.",
        "Gwen: Hey. These crates might have ingredients in them.",
        "Gwen: I wonder if we can check those crates while no one is looking?",
        "Gwen: There could be saltrice in those crates.",
        "Gwen: There could be Wickwheat in those crates.",
    }
end
local function ropebridge (ref, distance, script, journal)
    if distance > 1024 then return end
    script.luapass = 1026
    return {
        "Gwen: I never liked these bloody bridges.",
        "Gwen: These bridges just don't feel safe to me.",
        "Gwen: Why didn't they build a proper bloody bridge?",
        "Gwen: Did you see the bridge sway?",
        "Gwen: Honestly. Who makes bridges out of rope?",
        "Gwen: I think I would rather jump across than use a rope bridge.",
        "Gwen: The things I do for you! I hate these bridges.",
        "Gwen: Let's levitate across instead of using these bridges in future.",
        "Gwen: I really hate these things. So unsteady.",
    }
end
response["ex_ropebridge_01"] = ropebridge
response["ex_ropebridge_1024_01"] = ropebridge
response["ex_ropebridge_512_01"] = ropebridge
response["ex_ropebridge_2048_01"] = ropebridge
-----------------------------------------------
response["ex_hlaalu_bridge_01"] = function(ref, distance, script, journal)
    if distance > 1024 then return end
    script.luapass = 1027
    return {
        "Gwen: Don't fall in the water!",
        "Gwen: I never liked walking across bridges. My mother always said it was bad luck.",
    }
end
response["ex_ship_plank"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1028
    return {
        "Gwen: I like the water.",
        "Gwen: Can we go on a boat?",
        "Gwen: I feel like swimming.",
        "Gwen: I miss my ship.",
        "Gwen: Sailing the high seas. Nothing like it.",
    }
end
response["a_siltstrider"] = function(ref, distance, script, journal)
    if distance > 768 then return end
    script.luapass = 1029
    return {
        "Gwen: These striders have massive legs.",
        "Gwen: Are we going to ride that ugly thing?",
        "Gwen: Riding on striders always makes me feel sick.",
    }
end
response["light_de_streetlight_01_223"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1030
    return {
    }
end
response["bk_alchemistsformulary"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1031
    return {
        "Gwen: That looks like a really useful book you know.",
        "Gwen: I bet there are some good recipes in that book.",
        "Gwen: Alchemist Formulary. I can't remember if I've read that or not?",
           }
end
response["furn_de_firepit_f_400"] = function(ref, distance, script, journal)
    if distance > 512 then return end
    script.luapass = 1032
    return {
        "Gwen: I'd like to grill some steaks on that fire wouldn't you?",
        "Gwen: A nice warm fire. That's just what we need.",
        "Gwen: Ever had a thing called toast? I hear it's nice.",
           }
end
response["ernil omoran"] = function(ref, distance, script, journal)
    if distance > 1024 then return end
    script.luapass = 1033
    return {
        "Gwen: What is that bloody smell?",
        "Gwen: Something definitely died around here.",
        "Gwen: I can smell death.",
           }
end

--- Bath Nodes
--- Outside Balmora
response["rm_bathnode"] = function(ref, distance, script, jounral)
    if distance > 1500 then return end
    script.luapass = 1034
    mwscript.addItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
        if script.bathing == 10 then return end
        if script.bathing == 1 then return end
         if script.rm_fzone == 5 then
    return {
        "Gwen: I think this would be a good place to bathe don't you?",
        "Gwen: I wouldn't mind a swim here.",
        "Gwen: That water looks awfully nice. How about it?",
        "Gwen: A little close to Balmora but I think we could skinny dip here without anyone noticing.",
            }
        elseif script.rm_fzone <= 4 then
            return {
                "Gwen: If we were closer I would be tempted to go bathing here.",
                "Gwen: The water here is so clear.",
                "Gwen: I would strip down and swim here if I knew you better.",
            }
        end     
    
end
--- Pelagaid 01
response["rm_bathnode01"] = function(ref, distance, script, jounral)
    if distance > 1500 then return end
    script.luapass = 1035
    mwscript.addItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
        if script.bathing == 10 then return end
        if script.bathing == 1 then return end
         if script.rm_fzone == 5 then
    return {
        "Gwen: I think this would be a good place to bathe don't you?",
        "Gwen: I wouldn't mind a swim here. Maybe after we could go into Pelagaid and do some shopping?",
        "Gwen: That water looks awfully nice. How about it?",
            }
        elseif script.rm_fzone <= 4 then
            return {
                "Gwen: If we were closer I would be tempted to go bathing here.",
                "Gwen: The water here is so clear.",
                "Gwen: I would strip down and swim here if I knew you better.",
            }
        end     
    
end
--- Balur's Farm House
response["rm_bathnode02"] = function(ref, distance, script, jounral)
    if distance > 1500 then return end
    script.luapass = 1036
    mwscript.addItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
        if script.bathing == 10 then return end
        if script.bathing == 1 then return end
         if script.rm_fzone == 5 then
    return {
        "Gwen: I think this would be a good place to bathe don't you?",
        "Gwen: I wouldn't mind a swim here. Maybe after we could check out that farmhouse?",
        "Gwen: That water looks awfully nice. How about it?",
        "Gwen: Now that's the kind of farmhouse I would love. Right next to a lake so I could swim. Speaking of swimming...",
            }
        elseif script.rm_fzone <= 4 then
            return {
                "Gwen: If we were closer I would be tempted to go bathing here.",
                "Gwen: The water here is so clear.",
                "Gwen: I would strip down and swim here if I knew you better.",
            }
        end     
    
end
--- Dagon Fel Beach
response["rm_bathnode03"] = function(ref, distance, script, jounral)
    if distance > 1500 then return end
    script.luapass = 1037
    mwscript.addItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
        if script.bathing == 10 then return end
        if script.bathing == 1 then return end
         if script.rm_fzone == 5 then
    return {
        "Gwen: I think this would be a good place to bathe don't you?",
        "Gwen: An empty beach! This is a great place to have a cheeky swim.",
        "Gwen: That water looks awfully nice. How about it?",
        "Gwen: What do you say to getting all naked and going for a dip?",
            }
        elseif script.rm_fzone <= 4 then
            return {
                "Gwen: If we were closer I would be tempted to go bathing here.",
                "Gwen: The water here is so clear.",
                "Gwen: I would strip down and swim here if I knew you better.",
            }
        end     
    
end
--- Pelagiad Sandy Strip
response["rm_bathnode04"] = function(ref, distance, script, jounral)
    if distance > 1500 then return end
    script.luapass = 1038
    mwscript.addItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
        if script.bathing == 10 then return end
        if script.bathing == 1 then return end
         if script.rm_fzone == 5 then
    return {
        "Gwen: I think this would be a good place to bathe don't you?",
        "Gwen: This look like a nice little strip to erm, strip.",
        "Gwen: That water looks awfully nice. How about it?",
        "Gwen: What do you say to getting all naked and going for a dip?",
        "Gwen: I don't think they can see us from town here. How about a swim?",
            }
        elseif script.rm_fzone <= 4 then
            return {
                "Gwen: If we were closer I would be tempted to go bathing here.",
                "Gwen: The water here is so clear.",
                "Gwen: I would strip down and swim here if I knew you better.",
            }
        end     
    
end
--- Gnisis Beach
response["rm_bathnode05"] = function(ref, distance, script, jounral)
    if distance > 2400 then return end
    script.luapass = 1039
    mwscript.addItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
        if script.bathing == 10 then return end
        if script.bathing == 1 then return end
         if script.rm_fzone == 5 then
    return {
        "Gwen: Nice place for a swim.",
        "Gwen: This look like a nice little strip to erm, strip.",
        "Gwen: That water looks awfully nice. How about it?",
        "Gwen: What do you say to getting all naked and going for a dip?",
        "Gwen: I don't think they can see us from town here. How about a swim?",
        "Gwen: We could go for a swim then go into Gnisis if you like?"
            }
        elseif script.rm_fzone <= 4 then
            return {
                "Gwen: If we were closer I would be tempted to go bathing here.",
                "Gwen: The water here is so clear.",
                "Gwen: I would strip down and swim here if I knew you better.",
            }
        end     
    
end
--- Lower Khuul
response["rm_bathnode06"] = function(ref, distance, script, jounral)
    if distance > 2400 then return end
    script.luapass = 1040
    mwscript.addItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
        if script.bathing == 10 then return end
        if script.bathing == 1 then return end
         if script.rm_fzone == 5 then
    return {
        "Gwen: Nice place for a swim.",
        "Gwen: This look like a nice little strip to erm, strip.",
        "Gwen: That water looks awfully nice. How about it?",
        "Gwen: What do you say to getting all naked and going for a dip?",
        "Gwen: I don't think they can see us from town here. How about a swim?",
        "Gwen: What a perfect place for a swim."
            }
        elseif script.rm_fzone <= 4 then
            return {
                "Gwen: If we were closer I would be tempted to go bathing here.",
                "Gwen: The water here is so clear.",
                "Gwen: I would strip down and swim here if I knew you better.",
            }
        end     
    
end
--- Sturdumz
response["rm_bathnode07"] = function(ref, distance, script, jounral)
    if distance > 2048 then return end
    script.luapass = 1041
    mwscript.addItem{reference="RM_Gwen", item="RM_Gwen_Halberd", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenSword", count=1}
    mwscript.removeItem{reference="RM_Gwen", item="RM_GwenShield", count=1}
        if script.bathing == 10 then return end
        if script.bathing == 1 then return end
         if script.rm_fzone == 5 then
    return {
        "Gwen: Nice place for a swim.",
        "Gwen: This look like a nice little strip to erm, strip.",
        "Gwen: That water looks awfully nice. How about it?",
        "Gwen: What do you say to getting all naked and going for a dip?",
        "Gwen: I don't think they can see us from town here. How about a swim?",
        "Gwen: What a perfect place for a swim."
            }
        elseif script.rm_fzone <= 4 then
            return {
                "Gwen: If we were closer I would be tempted to go bathing here.",
                "Gwen: The water here is so clear.",
                "Gwen: I would strip down and swim here if I knew you better.",
            }
        end     
    
end


return response

