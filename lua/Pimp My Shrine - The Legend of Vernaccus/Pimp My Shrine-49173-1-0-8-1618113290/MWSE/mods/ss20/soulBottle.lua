local common = require('ss20.common')
local config = common.config

local journalID = 'ss20_CS'
local jIndex = config.journal_cs.indexes.bottlePickedUp


local function doAttackSounds()
    local path = 'Vo\\d\\m\\'
    local soundIds = {
        'CrAtk_AM003.mp3',
        'CrAtk_AM001.mp3',
        'CrAtk_AM002.mp3',
        'CrAtk_AM004.mp3',
        'CrAtk_AM001.mp3',
        'CrAtk_AM003.mp3',
    }
    local sourceRef = tes3.getReference("ss20_in_daeCenserOut") or tes3.player
    common.log:debug("sound source: %s", sourceRef)
    local interval = 0.5
    for i, sound in ipairs(soundIds) do
        timer.start{
            type = timer.real,
            duration = i * interval + math.random(0, 0.5),
            callback = function()
                local soundPath = string.format("%s%s", path, sound)
                common.log:debug("playing %s", soundPath)
                tes3.playSound{
                    reference = sourceRef,
                    soundPath = soundPath,
                    volume = 1.0
                }
            end
        }
    end
end


local function onBottlePickUp(e)
    local currentIndex = tes3.getJournalIndex{ id = journalID }
    if currentIndex >= jIndex then return end

    common.log:debug("id: %s", e.target.baseObject.id)
    if e.target.baseObject.id:lower() == 'ss20_bottle_of_souls' then
        common.messageBox{
            header = e.target.object.name,
            message = "This bottle will store the soul shards gathered from fallen enemies within it. With these soul shards, you can build new rooms, summon new furniture, or teleport back to the shrine. ",
            buttons = {
                { 
                    text = "Okay", 
                    callback = function() timer.delayOneFrame(function() 
                        mwscript.addSpell{ reference = tes3.player, spell = config.manipulateSpellId }
                        tes3.playSound{ reference = tes3.player, sound = "mysticism cast"}
                        common.messageBox{ 
                            header = "Transmutation Spell",
                            message = "You have learned the Transmutation spell. With this spell you can use soul shards to build and arrange the furniture within the shrine. Cast the spell to enter the Transmutation Menu and purchase resource packs or build furniture. \n\nTo manipulate the furniture you've placed, equip the spell and enter the \"Magic Ready\" mode (R key, or M key if quick-cast is enabled in MCP). Furniture that can be manipulated will glow white. Press the activate key while in this mode to pick up and put down the furniture. ",
                            buttons = {
                                { 
                                    text = "Okay",
                                    callback = function()
                                        doAttackSounds()
                                        
                                        timer.start{
                                            duration = 2,
                                            callback = function()
                                                tes3.messageBox("You hear a commotion outside the shrine.")
                                                tes3.updateJournal({
                                                    id = journalID,
                                                    index = jIndex
                                                })
                                            end
                                        }
                                        
                                    end
                                }
                            }
                        }
                    end)end
                }
            }
        }
    end
end
event.register("activate", onBottlePickUp)



local function onDeath(e)
    if tes3.player.object.inventory:contains("ss20_Bottle_of_Souls") then
        local multi = config.soulMultipliers[e.reference.baseObject.objectType]
        if multi then
            local hasNoSoul = e.reference.object.type == tes3.creatureType.daedra
                or e.reference.object.type == tes3.creatureType.undead
            if hasNoSoul then return end
            local shardsCaptured = math.floor(multi * math.remap(e.reference.object.level, 1, 100, config.soulsAtLvl1, config.soulsAtLvl100))
            if common.mcmConfig.showSoulMessage then
                tes3.messageBox("%d soul shards captured!", shardsCaptured)
            end
            common.modSoulShards(shardsCaptured)
            local journal = {
                id = 'ss20_CS',
                index = 19
            }
            if tes3.getJournalIndex{id = journal.id} < journal.index then
                if common.getSoulShards() > 400 then
                    tes3.updateJournal(journal)
                end
            end
        end
    end
end
event.register("death", onDeath)
