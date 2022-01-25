local common = require('ss20.common')
local config = common.config

local teleportShardCost = 100
local function onActivateTeleport(e)
    if e.item.id == 'ss20_Bottle_of_Souls' then
        tes3ui.leaveMenuMode()
        timer.delayOneFrame(function()
            local currentShards =common.getSoulShards()
            local buttons = {
                {
                    header = e.item.name,
                    text = string.format("Teleport to Shrine of Vernaccus (%s Soul Shards)", teleportShardCost),
                    callback = function()
                        common.modSoulShards(-teleportShardCost)
                        tes3.positionCell(config.shrineTeleportPosition)
                        tes3.playSound{
                            reference = tes3.player,
                            sound = 'mysticism cast'
                        }
                    end,
                    requirements = function()
                        return currentShards >= teleportShardCost
                    end,
                    showRequirements = function()
                        return tes3.getJournalIndex{id = "ss20_main"} >= 40
                    end,
                    tooltipDisabled = {
                        text = "You do not have enough Soul Shards."
                    }
                },
                {
                    header = e.item.name,
                    text = string.format("Teleport to Horvatha's Boudoir (%s Soul Shards)", teleportShardCost),
                    callback = function()
                        common.modSoulShards(-teleportShardCost)
                        tes3.positionCell(config.horavathaTeleportPosition)
                        tes3.playSound{
                            reference = tes3.player,
                            sound = 'mysticism cast'
                        }
                    end,
                    requirements = function()
                        return currentShards >= teleportShardCost
                    end,
                    showRequirements = function()
                        return tes3.getJournalIndex{id = "ss20_main"} >= 40
                    end,
                    tooltipDisabled = {
                        
                        text = "You do not have enough Soul Shards."
                    }
                },
                { text = "Cancel"} 
            }
            common.messageBox{
                header = "Bottle of Souls",
                message = string.format("You have %s Soul Shards.", currentShards),
                buttons = buttons
            }
        end)
    
    elseif e.item.id == 'ss20_misc_bustHoravatha' then
        common.messageBox{
            header = e.item.name,
            message = "Teleport to Horavatha?",
            buttons = {
                {
                    text = "Teleport",
                    callback = function()
                        if tes3.getJournalIndex{id = "ss20_main"} >= 25 then
                            tes3.positionCell(config.horavathaBustTeleportPosition)
                            tes3.playSound{
                                reference = tes3.player,
                                sound = 'mysticism cast'
                            }
                        else
                            common.messageBox({
                                message = 'Horavatha: "Go talk to Vernie before pestering me!"',
                                buttons = {
                                    { text = "Okay"}
                                }
                            })
                        end
                    end
                },

                { text = "Cancel" }
            }
        }
    end
end

event.register("equip", onActivateTeleport)