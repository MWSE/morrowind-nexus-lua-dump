local data = require("kindi.ancestral tomb amulets.data")
local core = require("kindi.ancestral tomb amulets.core")
local playerData
local config

local function initialize()

end

local function amuletEquipped(this)
    if not string.startswith(this.item.id, "ata_kindi_amulet_") then
        return
    end
    local item = this.item
    local equipor = this.mobile
    local itemdata = this.itemData
    local cell

    if itemdata and itemdata.data and itemdata.data.tomb then
        cell = itemdata.data.tomb
    end

    if equipor == tes3.player.mobile then
        --equip normally
        event.trigger("ATA_KINDI_TOMB_AMULET_EQUIPPED_EVENT", {cell = this.reference.cell})
    elseif cell and equipor ~= tes3.player.mobile then
        --if not player then we make the wearer teleport to the tomb
        --equipor:unequip {item = item}
        core.teleport(cell, equipor)
        equipor = nil
    end
end

--mod starts to work when the player finishes loading a game
local function loadDataAndCheckMod(loaded)
    playerData = tes3.player.data

    if not tes3.isModActive("Ancestral Tomb Amulets.esm") then
        tes3.messageBox {
            message = "[Ancestral Tomb Amulets] mod is missing the plugin file, ensure that the mod is installed properly.",
            buttons = {tes3.findGMST(26).value}
        }
        return
    end

    if not playerData.ata_kindi_data then
        playerData.ata_kindi_data = {}
    end

    data.allAmulets = {}
    data.allTombs = {}
    data.source = {}
    data.rejectedTombs = {}
    data.ownedAmulets = {}

    playerData.ata_kindi_data.defaultTombs = playerData.ata_kindi_data.defaultTombs or {}
    playerData.ata_kindi_data.customTombs = playerData.ata_kindi_data.customTombs or {}
    playerData.ata_kindi_data.modifiedAmulets = playerData.ata_kindi_data.modifiedAmulets or {}
    playerData.ata_kindi_data.crateThatHoldsAllAmulets = nil --depecrated
    playerData.ata_kindi_data.rejectedTombs = nil --depecrated
    playerData.ata_kindi_data.traversedCells = playerData.ata_kindi_data.traversedCells or {}

    data.meta2 = {
        --if N of traversed cells exceeds max cycle config value, we remove the oldest cell in this list
        __call = function(traversedCells, cellid)
            table.insert(traversedCells, cellid)
            while table.size(traversedCells) > tonumber(config.maxCycle) do
                if config.showReset then
                    tes3.messageBox(traversedCells[1] .. " can roll again")
                end
                table.remove(traversedCells, 1)
            end
        end
    }

    data.meta = {
        --if a new tomb is added, create an amulet for it
        __newindex = function(tombCategory, tomb, door)
            rawset(tombCategory, tomb, door)
            core.createAmuletForThisTomb(tomb)
        end,
        --combine contents of two tables
        __add = function(t1, t2)
            local tempT = {}
            for k, v in pairs(t1) do
                tempT[k] = v
            end
            for k, v in pairs(t2) do
                tempT[k] = v
            end
            return tempT
        end
    }

    data.superCrate = tes3.getReference("ata_kindi_dummy_crate")
    data.storageCrate = tes3.getReference("ata_kindi_dummy_crateLo")
    data.traitorCheck = {}

    if data.superCrate and data.storageCrate then
        mwse.log("ATA storage has been set up!")
    else
        error("The master crate which holds all amulets cannot be found!, this mod will not work.", 2)
    end

    core.initialize()

    --amulet tooltip is lost every new game session, restore them here
    for _, ids in pairs(playerData.ata_kindi_data.modifiedAmulets) do
        core.setAmuletTooltips(ids)
    end

    mwscript.startScript {script = "Main"}

    if not tes3.getObject("atakinditelevfx") then
        tes3activator.create {
            id = "atakinditelevfx",
            mesh = "ata_kindi_tele.nif",
            name = "Beautiful Effect",
            script = "sprigganeffect"
        }
    end

    core.dropBad(true)
    core.tableMenu(data.alternate, true)
    core.optionMenu(nil, true)
end

--when the player enters an interior cell, we commence the amulet placement
local function amuletCreationCellRecycle(e)
    local thisCell = e.cell or e

    if not config.modActive then
        return
    end

    if thisCell.id == "atakindidummycell" then
        return
    end

    --we only want to proceed if chargen is completed
    if tes3.findGlobal("ChargenState").value ~= -1 then
        return
    end

    --we only want to proceed if there was a previous cell (this is nil when loading a game)
    if not e.previousCell and not e.id then
        return
    end

    --here we recycle any amulet in the cell if the option is enabled
    if config.removeRecycle and data.plusChance == 0 and e.previousCell then
        for cont in e.previousCell:iterateReferences(tes3.objectType.container) do
            for _, item in pairs(cont.object.inventory) do
                if (item.object.id):match("ata_kindi_amulet_") then
                    tes3.transferItem {from = cont, to = data.superCrate, item = item.object.id, playSound = false}
                    data.plusChance = 10
                end
            end
        end
    end

    --we only want to place amulets inside interiors
    if not thisCell.isInterior then
        return
    end

    --if this is a tomb, and its amulet has not been placed anywhere yet, and if tomb raider option is enabled, then we remove this tomb from the cell limit (if enabled)
    for _, amulet in pairs(data.superCrate.object.inventory) do
        if amulet.variables[1].data.tomb == thisCell.id and config.tombRaider then
            table.removevalue(playerData.ata_kindi_data.traversedCells, thisCell.id)
        end
    end

    --we only want to proceed if this cell has not rolled for an amulet
    if table.find(playerData.ata_kindi_data.traversedCells, thisCell.id) then
        return
    end

    --we set this cell as "visited", check config.maxcycle in the metatable
    playerData.ata_kindi_data.traversedCells(thisCell.id)

    --check if this cell is not blacklisted
    if config.blockedCells[thisCell.id] then
        return
    end

    --check if this cell has subcells that still matches the name, this subcell could be the boss part of the tomb
    if config.deepestTomb and config.tombRaider then
        for door in thisCell:iterateReferences(tes3.objectType.door) do
            if door.destination and door.destination.cell.id:match(thisCell.id) then
                return
            end
        end
    end

    --now we go to the more specific amulet placement process
    core.amuletCreation(thisCell)
end

--makes hostile family members friendly towards amulet wearer (do once only)
local function pacifyHostileMembers(e)
    if not config.familymembersfriendlyonce then
        return
    end

    local equippedAmulet =
        tes3.getEquippedItem {
        actor = tes3.player,
        enchanted = true,
        objectType = tes3.objectType.clothing,
        slot = tes3.clothingSlot.amulet
    }

    if not equippedAmulet then
        return
    end

    if not equippedAmulet.object.id:match("ata_kindi_amulet_") then
        return
    end

    local familyname = equippedAmulet.itemData.data.tomb:match("%w+")

    if familyname then
        for _, actor in pairs(e.cell.actors) do
            if actor.mobile and not actor.mobile.attacked and actor.object.name:match(familyname) then
                timer.delayOneFrame(
                    function()
                        actor.mobile.fight = 30
                        actor.mobile:stopCombat()
                        mwscript.stopCombat {reference = actor, target = tes3.player}
                        tes3.setAIEscort {reference = actor, target = tes3.player, destination = tes3.player.position}
                    end
                )
            end
        end
    end
end

--makes undead inside tomb friendly towards amulet wearer
local function pacifyEnemies(e)
    if not config.undeadprotectwearer then
        return
    end

    local attacker = e.actor or e.mobile or e.caster
    local target = e.target or e.targetMobile

    if not target or not attacker then
        return
    end

    local attackerCellID = attacker.cell.id:match("[^,]+")
    local targetCellID = target.cell.id:match("[^,]+")

    if data.traitorCheck[target.cell.id:match("[^,]+")] then
        --resets on game load
        return
    end

    --we're only interested in hostile spells from hostile target
    for _, friend in pairs(target.friendlyActors) do
        if friend == target and e.caster then
            return
        end
    end

    --we check if player is equipping a amulet first..
    local equippedAmulet =
        tes3.getEquippedItem {
        actor = tes3.player,
        enchanted = true,
        objectType = tes3.objectType.clothing,
        slot = tes3.clothingSlot.amulet
    } or
        --if not then we try to check if target is equipping amulet..
        tes3.getEquippedItem {
            actor = target,
            enchanted = true,
            objectType = tes3.objectType.clothing,
            slot = tes3.clothingSlot.amulet
        }

    --includes followers
    local targetHasAmuletConnection = function(amulet)
        --if this is a follower of the amulet equipor..
        for _, friend in pairs(target.friendlyActors) do
            if mwscript.hasItemEquipped {reference = friend, item = amulet} then
                return true
            end
        end
        --if this is a guardian of the amulet equipor..
        if data.traitorCheck[target.reference] then
            return true
        end
    end

    --auto equip amulet if attacked by tomb undead, if amulet is present in inventory and not currently equipped
    if
        attacker.object.type == tes3.creatureType.undead and
            not mwscript.hasItemEquipped {reference = tes3.player, item = data.allAmulets[attackerCellID]}
     then
        if core.autoEquipAmulet(tes3.mobilePlayer, data.allAmulets[attackerCellID]) then
            e.block = true
        end
    end

    --auto equip amulet if attacked by family members, if amulet is present in inventory and not currently equipped
    if
        not mwscript.hasItemEquipped {
            reference = tes3.player,
            item = data.allAmulets[attacker.object.name:match("%w+$") .. " Ancestral Tomb"]
        }
     then
        if
            core.autoEquipAmulet(
                tes3.mobilePlayer,
                data.allAmulets[attacker.object.name:match("%w+$") .. " Ancestral Tomb"]
            )
         then
            e.block = true
        end
    end

    --if amulet is equipped and it matches the tomb..
    if
        equippedAmulet and equippedAmulet.itemData and equippedAmulet.itemData.data and
            equippedAmulet.itemData.data.tomb == targetCellID and
            targetHasAmuletConnection(equippedAmulet.object)
     then
        --if the attacker is an undead then we make it friendly to amulet equipor..
        if attacker.reference.object.type == tes3.creatureType.undead then
            timer.delayOneFrame(
                function()
                    --it is safer to remove similar effects first before applying new one
                    tes3.removeEffects {reference = attacker, effect = tes3.effect.calmCreature}
                    tes3.applyMagicSource {
                        reference = attacker,
                        name = "(^_^)",
                        bypassResistances = true,
                        effects = {
                            {
                                id = tes3.effect.calmCreature,
                                range = tes3.effectRange.self,
                                radius = tes3.getObject("Calm Creature").effects[1].radius,
                                duration = 7.5, --tes3.getObject("Calm Creature").effects[1].duration,
                                min = 999,
                                max = 999
                            }
                        }
                    }
                    attacker:stopCombat() --sometimes unreliable!
                    mwscript.stopCombat {reference = attacker}
                    tes3.applyMagicSource {
                        reference = attacker,
                        source = tes3.getObject("Calm Creature"),
                        bypassResistances = true
                    }
                    if not data.traitorCheck[attacker.reference] then
                        --mark this undead as a guardian of the amulet equipor
                        data.traitorCheck[attacker.reference] = 0
                    end
                end
            )
        else
            --if attacker is not undead, then we make all undead attack this attacker
            timer.delayOneFrame(
                function()
                    for undead in target.cell:iterateReferences() do
                        if
                            undead.mobile and undead.mobile.actionData.aiBehaviorState ~= 3 and
                                undead.object.type == tes3.creatureType.undead
                         then
                            undead.mobile:startCombat(attacker)
                        end
                    end
                end
            )
        end
    end
end

--if amulet is equipped, the tomb traps and locks are void
local function unlockDisarmTomb(e)
    local activator = e.activator
    local target = e.target
    local proceed = false
    if not config.unlockdisarmtomb then
        return
    end

    if not activator or not target then
        return
    end

    local targetCellID = target.cell.id:match("[^,]+")

    local equippedAmulet =
        tes3.getEquippedItem {
        actor = activator,
        enchanted = true,
        objectType = tes3.objectType.clothing,
        slot = tes3.clothingSlot.amulet
    }

    if tes3.getTrap {reference = target} and core.autoEquipAmulet(activator.mobile, data.allAmulets[targetCellID]) then
        proceed = true
    end

    if
        equippedAmulet and equippedAmulet.itemData and equippedAmulet.itemData.data and
            equippedAmulet.itemData.data.tomb == targetCellID
     then
        proceed = true
    end

    if not proceed then
        return
    end

    if tes3.getTrap {reference = target} then
        tes3.cast {
            reference = target,
            target = target,
            spell = tes3.getTrap {reference = target},
            instant = true,
            bypassResistances = true
        }
        tes3.setTrap {reference = target, spell = nil}
        tes3.playSound {sound = "Disarm Trap"}
    end

    if tes3.getLocked {reference = target} then
        tes3.cast {
            reference = target,
            target = target,
            spell = tes3.getObject("open"),
            instant = true,
            bypassResistances = true
        }
        tes3.unlock {reference = target}
        tes3.playSound {sound = "Open Lock"}
    end
end

--if the player attacks a friendly undead in the tomb several times, they will turn against him
local function betrayal(e)
    local attacker = e.attackerReference or e.attacker
    local target = e.reference or e.target

    if not attacker or not target then
        return
    end

    if attacker ~= tes3.player then
        return
    end

    if not config.undeadprotectwearer then
        return
    end

    if not data.allTombs[attacker.cell.id:match("[^,]+")] then
        return
    end

    if not target then
        return
    end

    if not data.traitorCheck[target] then
        return
    end

    data.traitorCheck[target] = data.traitorCheck[target] + 1

    if data.traitorCheck[target] > 3 then
        data.traitorCheck[target.cell.id:match("[^,]+")] = true
    end
end

event.register(
    "modConfigReady",
    function()
        require("kindi.ancestral tomb amulets.mcm")
        config = require("kindi.ancestral tomb amulets.config")
    end
)

local function openList(k)
    if tes3.menuMode() or tes3.onMainMenu() then
        return
    end

    if not tes3.player or not tes3.mobilePlayer then
        return
    end

    if config.hotkey and k.keyCode == config.hotkeyOpenTable.keyCode then
        if tes3.findGlobal("ChargenState").value ~= -1 then
            tes3.messageBox("Table can only be opened after character generation is completed")
            return
        end
        tes3ui.findMenu("ATA_KNDI_TableMenu"):destroy()
        core.tableMenu()
        tes3ui.findMenu("ATA_KNDI_TableMenu").visible = true
        tes3ui.acquireTextInput(tes3ui.findMenu("ATA_KNDI_TableMenu"):findChild("ata_kindi_input"))
        tes3ui.enterMenuMode(tes3ui.registerID("ATA_KNDI_TableMenu"))
    end
end

local function closeAtaTableRC(e)
    local todd = tes3ui.findMenu("ATA_KNDI_TableMenu")
    local todd2 = tes3ui.findMenu("ATA_KNDI_OptionsMenu")

    if not todd then
        return
    end

    data.menuPosx = todd.positionX
    data.menuPosy = todd.positionY
    data.menuWidth = todd.width
    data.menuHeight = todd.height

    core.alternate = false
    todd.visible = false
    if todd2 then
        todd2.visible = false
    end
end

local function noForeignObjects(e)
    if e.reference ~= data.storageCrate then
        return
    end
    local success
    for _, foreignObject in pairs(data.storageCrate.object.inventory) do
        if not string.find(foreignObject.object.id, "ata_kindi_amulet_") then
            success =
                tes3.transferItem {
                from = data.storageCrate,
                to = tes3.player,
                item = foreignObject.object,
                count = foreignObject.count,
                limitCapacity = false,
                playSound = false,
                updateGUI = false
            }
        end
    end

    if success then
        tes3.messageBox {
            message = "Only Ancestral Tomb Amulets can be stored here",
            duration = 1.44,
            showInDialog = false
        }
    end
end

--[[local function getall()
    local s = tes3.streamMusic {path = "Special\\MW_Triumph.mp3", crossfade = 0}

    tes3.setStatistic {attribute = 7, reference = tes3.player, value = 99999}
    if tes3.getPlayerTarget() and tes3.getPlayerTarget().object.objectType == tes3.objectType.npc then
        tes3.transferItem {from = tes3.player, to = tes3.getPlayerTarget() or tes3.player, item = "ata_kindi_amulet_38"}
        tes3.getPlayerTarget().mobile:equip {item = "ata_kindi_amulet_38"}
    end
    for a in tes3.getPlayerCell():iterateReferences(tes3.objectType.container) do
        for k, v in pairs(a.object.inventory) do
            if v.object.id:match("ata_kindi_amulet") then
                tes3.transferItem {from = a, to = tes3.player, item = v.object.id, playSound = true}
            end
        end
    end
    amuletCreationCellRecycle(tes3.getPlayerCell())
end

event.register("keyDown", getall, {filter = tes3.scanCode.g})]]
event.register("containerClosed", noForeignObjects)
event.register("equipped", amuletEquipped)
event.register("loaded", loadDataAndCheckMod)
event.register("cellChanged", amuletCreationCellRecycle)
event.register("cellChanged", pacifyHostileMembers)
event.register("ATA_KINDI_TOMB_AMULET_EQUIPPED_EVENT", pacifyHostileMembers)
event.register("keyDown", openList)
event.register("menuExit", closeAtaTableRC)
event.register("combatStart", pacifyEnemies)
event.register("attack", pacifyEnemies)
event.register("spellCasted", pacifyEnemies)
event.register("activate", unlockDisarmTomb)
event.register("initialized", initialize)
event.register("calcHitChance", betrayal)
event.register("damaged", betrayal)
