local bonfire = require("AA-IoS\\bonfire\\main")

local function killCultistLeader()
    local leader = tes3.getReference("AA_Cultist_Leader_cs")
    leader.mobile.health.current = 1
    tes3.getReference("aa_molag_bal").mobile:startCombat(leader.mobile)
end

local function killCultist2()
    local disc2 = tes3.getReference("AA_Cultist_Disciple02")
    disc2.mobile.health.current = 1
    tes3.getReference("aa_molag_bal").mobile:startCombat(disc2.mobile)
end

local function killCultist1()
    local disc1 = tes3.getReference("AA_Cultist_Disciple01")
    disc1.mobile.health.current = 1
    tes3.getReference("aa_molag_bal").mobile:startCombat(disc1.mobile)
end

local function courtyard8()
    tes3.updateJournal {id = 'AA_StormWatch', index = 30, showMessage = true}
    tes3.updateJournal {id = 'AA_StormWatch_Cult ', index = 15, showMessage = true}

    tes3.mobilePlayer.controlsDisabled = false
    tes3.mobilePlayer.jumpingDisabled = false
    tes3.mobilePlayer.attackDisabled = false
    tes3.mobilePlayer.magicDisabled = false
    tes3.mobilePlayer.mouseLookDisabled = false
end

local function courtyard7()
    tes3.playSound{reference = "aa_molag_bal", sound = "AA_molag_beckon", mixChannel = 1}
    timer.start {type = timer.simulate, iterations = 1, duration = 12.0, callback = courtyard8}
end

local function courtyard6()
    killCultist1()
    -- timer.start {type = timer.simulate, iterations = 1, duration = 1.0, callback = courtyard7}
end

-- local function courtyard5()
--     tes3.say{reference = "AA_Cultist_Leader_cs", soundPath = "AA\\leader_2.wav"}
--     timer.start {type = timer.simulate, iterations = 1, duration = 2.0, callback = courtyard6}
-- end

local function courtyard4()
    tes3.playSound{reference = "aa_molag_bal", sound = "AA_molag_execution", mixChannel = 1}
    timer.start {type = timer.simulate, iterations = 1, duration = 16.0, callback = courtyard6}
end

local function courtyard3()
    tes3.playSound{reference = "AA_Cultist_Leader_cs", sound = "AA_Leader1", mixChannel = 1}
    timer.start {type = timer.simulate, iterations = 1, duration = 14.0, callback = courtyard4}
end

local function courtyard2()
    tes3.getReference("aa_molag_bal"):enable()
    timer.start {type = timer.simulate, iterations = 1, duration = 2.0, callback = courtyard3}
end

local function courtyard1()
    tes3.mobilePlayer.controlsDisabled = true
    tes3.mobilePlayer.jumpingDisabled = true
    tes3.mobilePlayer.attackDisabled = true
    tes3.mobilePlayer.magicDisabled = true
    tes3.mobilePlayer.mouseLookDisabled = true

    tes3.getReference("AA_Cultist_Leader_cs"):enable()
    tes3.getReference("AA_Cultist_Disciple01"):enable()
    tes3.getReference("AA_Cultist_Disciple02"):enable()
    tes3.createReference{object = "aa_coldsummonfx", position = tes3.getReference("aa_molag_bal").position}
    timer.start {type = timer.simulate, iterations = 1, duration = 1.0, callback = courtyard2}
end

local function freePrisonersFadeIn()
    local captive1 = tes3.getReference("AA_hostage01")
    local captive2 = tes3.getReference("AA_hostage02")
    local captive3 = tes3.getReference("AA_hostage03")
    local warden = tes3.getReference("AA_warden")
    local player = tes3.player
    captive1.position = captive1.position + captive1.sceneNode.rotation:transpose().y * 128
    captive2.position = captive2.position + captive2.sceneNode.rotation:transpose().y * 128
    captive3.position = captive3.position + captive3.sceneNode.rotation:transpose().y * 128
    warden.position = warden.position + warden.sceneNode.rotation:transpose().y * 128
    player.position = player.position - player.sceneNode.rotation:transpose().y * 128
    tes3.fadeIn {duration = 1.0}
end

local function freePrisonersFadeOut(ref)
    tes3.fadeOut {duration = 1.0}
    tes3.playSound{sound = "Door Metal Open", reference = ref}
    tes3.setGlobal("AA_CaptivesFreed", 1)
    timer.start {type = timer.simulate, iterations = 1, duration = 1, callback = freePrisonersFadeIn}
end

local function unbrokenWall()
    tes3.getReference("AA_CellBrick0"):disable()
    tes3.getReference("AA_CellBrick1"):disable()
    tes3.getReference("AA_CellBrick2"):disable()
    tes3.getReference("AA_CellBrick3"):disable()
    tes3.getReference("AA_CellBrick4"):disable()
end

local function brokenWall()
    tes3.getReference("AA_CellBrick0"):enable()
    tes3.getReference("AA_CellBrick1"):enable()
    tes3.getReference("AA_CellBrick2"):enable()
    tes3.getReference("AA_CellBrick3"):enable()
    tes3.getReference("AA_CellBrick4"):enable()

    tes3.getReference("AA_PlaneWall"):disable()
    tes3.setGlobal("AA_Escarpe", 2)
end

local function switchBallistaModel(ref)
    local switch = ref.sceneNode:getObjectByName("AASwitch")
    if switch ~= nil then
        switch.switchIndex = 1
    end
end

local function sabotageBalista(ref)
    local balistasSabotaged = tes3.getGlobal("AA_balistasSabotaged")
    if (balistasSabotaged) then
        tes3.setGlobal("AA_balistasSabotaged", balistasSabotaged + 1)
        balistasSabotaged = tes3.getGlobal("AA_balistasSabotaged")
    end
    if (balistasSabotaged < 10) then
        tes3.playSound{sound = "LockedChest", reference = ref}
        tes3.messageBox{
            message = "You have sabotaged a ballista, there are still " .. tostring(10 - tes3.getGlobal("AA_balistasSabotaged")) .. " to go."
        }
    else
        tes3.messageBox{
            message = "You have sabotaged all the ballistas."
        }
        tes3.updateJournal{id = 'AA_Stormwatch_Defenses', index = 5, showMessage = true}
    end
    if (ref.data.aa_sabotaged == nil) then
        switchBallistaModel(ref)
        ref.data.aa_sabotaged = true
    end
end

local function removePlayerInventory()
    local inv = tes3.player.object.inventory
    for item in tes3.iterate(inv) do
		tes3.transferItem({
			from = tes3.player,
			to = tes3.getReference("AA_GuardChest"),
			item = item.object,
			playSound = false,
			count = math.abs(item.count),
			updateGUI = false,
		})
    end
    tes3.setGlobal("AA_InventoryRemoved", 1)
end

local function hideAgent()
    local o = tes3.getReference('AA_agent01')
    if (string.startswith(o.id, 'AA_agent01')) then
        o:disable()
    end
end

local function showAgent()
    local o = tes3.getReference('AA_agent01')
    if (string.startswith(o.id, 'AA_agent01')) then
        o:enable()
    end
end

local function dispActivate(e)
    if (e.activator == tes3.player) then
        if (e.target.baseObject.id == "TS_RM_Ballister" and tes3.getJournalIndex {id = 'AA_Stormwatch_Defenses'} == 1) then
            if (e.target.data.aa_sabotaged == nil) then
                sabotageBalista(e.target)
            else
                tes3.messageBox{
                    message = "You have already sabotaged this ballista, there are still " .. tostring(10 - tes3.getGlobal("AA_balistasSabotaged")) .. " to go."
                }
            end
        end
        if (e.target.baseObject.id == "TS_dr_dung_cage_03" and tes3.getJournalIndex {id = 'AA_Stormwatch_Hostages'} >= 1 and tes3.getGlobal("AA_CaptivesFreed") == 0) then
            freePrisonersFadeOut(e.target)
        end
        if (e.target.baseObject.id == "AA_Lever" and tes3.getJournalIndex {id = 'AA_Stormwatch_Defenses'} == 5) then
            local gate = tes3.getReference("TS_ex_gg_portcullis_1")
            gate.position = {gate.position.x, gate.position.y, 992.527 + 300}
            e.target.orientation = {math.rad(45), e.target.orientation.y, e.target.orientation.z}
            tes3.updateJournal {id = 'AA_Stormwatch_Defenses', index = 10, showMessage = true}
        end
    end
end

local function dispUpdate(e)
    -- print(tes3.getJournalIndex {id = 'AA_StormWatch'})
    if (tes3.getPlayerCell().id == 'Balmora, Caius Cosades\' House' and tes3.getJournalIndex {id = 'A2_6_Incarnate'} < 50) then
        hideAgent()
    elseif (tes3.getPlayerCell().id == 'Balmora, Caius Cosades\' House' and tes3.getJournalIndex {id = 'A2_6_Incarnate'} >= 50) then
        showAgent()
    elseif (tes3.getPlayerCell().id == 'Fort Stormwatch, Basement' and tes3.getJournalIndex {id = 'AA_Stormwatch_Cult'} == 5 and tes3.getGlobal("AA_InventoryRemoved") == 0) then
        -- print('test')
        removePlayerInventory()
    end
    if (tes3.getPlayerCell().id == "Fort Stormwatch, Basement") then
        if (tes3.getGlobal("AA_Escarpe") == 0) then
            unbrokenWall()
        elseif (tes3.getGlobal("AA_Escarpe") == 1) then
            brokenWall()
        elseif (tes3.getGlobal("AA_Escarpe") == 2) then
            if (tes3.getGlobal("AA_chest") == 1 and tes3.getJournalIndex {id = 'AA_Stormwatch_Cult'} == 5) then
                tes3.updateJournal {id = 'AA_Stormwatch_Cult', index = 10, showMessage = true}
            end
        end
    end
    if (tes3.getGlobal("AA_OF_Appear") == 0 and (tes3.getJournalIndex {id = 'AA_StormSide_OF'} == 0) and (tes3.getJournalIndex {id = 'AA_Stormwatch_Cult'} == 10 or tes3.getJournalIndex {id = 'AA_Stormwatch_Hostages'} == 10 or tes3.getJournalIndex {id = 'AA_Stormwatch_Defenses'} == 10)) then
        local mess = tes3.getReference("AA_OFMessenger")
        local newPosition = tes3.player.position - tes3.player.sceneNode.rotation:transpose().y * 128
        tes3.positionCell({ reference = mess, cell = tes3.player.cell, position = newPosition })
        tes3.setGlobal("AA_OF_Appear", 1)
        tes3.messageBox("You feel someone walking up behind you...")
    end
    if (tes3.getGlobal("AA_QuestComplete") == 0 and tes3.getJournalIndex {id = 'AA_StormWatch'} == 40) then
        tes3.setGlobal("AA_QuestComplete", 1)
        tes3.positionCell{oritentation = {0, 0, 180}, position = {62681, 184288, 188}}
        tes3.setGlobal("GameHour", 9.0)
    end
end

local function dispDeath(e)
    if (e.reference ~= tes3.player and e.reference ~= tes3.getReference("AA_Librarian")) then
        if (tes3.getPlayerCell().id == "Fort Stormwatch, Mess Hall") then
            tes3.setGlobal("AA_Enemies_MessHall", tes3.getGlobal("AA_Enemies_MessHall") + 1)
        elseif (tes3.getPlayerCell().id == "Fort Stormwatch, Prison Library") then
            tes3.setGlobal("AA_Enemies_Library", tes3.getGlobal("AA_Enemies_Library") + 1)
        elseif (string.find(e.reference.id, "Supply")) then
            tes3.setGlobal("AA_Enemies_Supply", tes3.getGlobal("AA_Enemies_Supply") + 1)
        end

        if (e.reference == tes3.getReference("aa_molag_bal")) then
            tes3.updateJournal {id = 'AA_StormWatch', index = 35, showMessage = true}
        end

        if (e.reference == tes3.getReference("AA_Cultist_Disciple01")) then
            killCultist2()
        elseif (e.reference == tes3.getReference("AA_Cultist_Disciple02")) then
            killCultistLeader()
            tes3.playSound{reference = "AA_Cultist_Leader_cs", sound = "AA_Leader2", mixChannel = 1}
            timer.start {type = timer.simulate, iterations = 1, duration = 3.0, callback = courtyard7}
        end
    end
end

local function onShrineAttacked(id)
    if id == "aa_bloodshrine01" then
        tes3.setGlobal("aa_bloodshrine_g01", 1)
    elseif id == "aa_bloodshrine02" then
        tes3.setGlobal("aa_bloodshrine_g02", 1)
    elseif id == "aa_bloodshrine03" then
        tes3.setGlobal("aa_bloodshrine_g03", 1)
    else
        return -- wasn't actually a shrine
    end

    if tes3.getGlobal("AA_AreasLiberated") < 3 then
        if tes3.getJournalIndex{id = 'AA_StormSide_OF'} >= 5 then
            debug.log(tes3.getGlobal("AA_MessLiberated"))
            debug.log(tes3.getGlobal("AA_Enemies_MessHall"))
            debug.log(tes3.getGlobal("aa_bloodshrine_g01"))
            if (
                tes3.getGlobal("AA_MessLiberated") == 0
                and tes3.getGlobal("AA_Enemies_MessHall") == 6
                and tes3.getGlobal("aa_bloodshrine_g01") == 1
            ) then
                tes3.setGlobal("AA_AreasLiberated", tes3.getGlobal("AA_AreasLiberated") + 1 )
                tes3.setGlobal("AA_MessLiberated", 1)
            end
            if (
                tes3.getGlobal("AA_LibraryLiberated") == 0
                and tes3.getGlobal("AA_Enemies_Library") == 9
                and tes3.getGlobal("aa_bloodshrine_g02") == 1
            ) then
                tes3.setGlobal("AA_AreasLiberated", tes3.getGlobal("AA_AreasLiberated") + 1 )
                tes3.setGlobal("AA_LibraryLiberated", 1)
            end
            if (
                tes3.getGlobal("AA_SupplyLiberated") == 0
                and tes3.getGlobal("AA_Enemies_Supply") == 11
                and tes3.getGlobal("aa_bloodshrine_g03") == 1
            ) then
                tes3.setGlobal("AA_AreasLiberated", tes3.getGlobal("AA_AreasLiberated") + 1 )
                tes3.setGlobal("AA_SupplyLiberated", 1)
            end
        end
    end

    if tes3.getGlobal("AA_AreasLiberated") == 3 then
        tes3.updateJournal {id = 'AA_StormSide_OF', index = 15, showMessage = true}
        tes3.setGlobal("AA_AreasLiberated", 4)
    end
end

local function onAttack(e)
    if e.reference == tes3.player then
        local target = tes3.getPlayerTarget()
        if target then
            onShrineAttacked(target.id:lower())
        end
    end
end

local function onMarksmanHit(e)
    if e.firingReference == tes3.player then
        onShrineAttacked(e.target.id:lower())
    end
end

local function dispCellChange(e)
    if (tes3.getGlobal("AA_NoTeleport") == 1) then
        tes3.worldController.flagTeleportingDisabled = true
	tes3.worldController.flagLevitationDisabled = true
        tes3.setGlobal("GameHour", 22.0)
        tes3.getReference("aa_molag_bal"):disable()
    else
        tes3.worldController.flagTeleportingDisabled = false
	tes3.worldController.flagLevitationDisabled = false
    end

    if (tes3.getJournalIndex {id = 'AA_StormWatch'} == 25 and tes3.getPlayerCell().isInterior == false) then
        courtyard1()
    else
        tes3.getReference("aa_molag_bal"):disable()
        tes3.getReference("AA_Cultist_Leader_cs"):disable()
        tes3.getReference("AA_Cultist_Disciple01"):disable()
        tes3.getReference("AA_Cultist_Disciple02"):disable()
    end

    if (tes3.getGlobal("AA_OF_Appear") == 1 and tes3.getJournalIndex {id = 'AA_Stormwatch_Cult'} + tes3.getJournalIndex {id = 'AA_Stormwatch_Hostages'} + tes3.getJournalIndex {id = 'AA_Stormwatch_Defenses'} < 30) then
        local mess = tes3.getReference("AA_OFMessenger")
        mess.position = tes3.player.position - tes3.player.sceneNode.rotation:transpose().z * 10000
	end
	if (tes3.getGlobal("AA_OF_Appear") == 1 and (tes3.getJournalIndex {id = 'AA_Stormwatch_Cult'} == 10 and tes3.getJournalIndex {id = 'AA_Stormwatch_Hostages'} == 10 and tes3.getJournalIndex {id = 'AA_Stormwatch_Defenses'} == 10) and (tes3.getPlayerCell().id ~= "Fort Stormwatch, Main Hall" and tes3.getPlayerCell().isInterior == true)) then
        local mess = tes3.getReference("AA_OFMessenger")
        local newPosition = tes3.player.position + tes3.player.sceneNode.rotation:transpose().y * 128
        tes3.positionCell({ reference = mess, cell = tes3.player.cell, position = newPosition })
        tes3.setGlobal("AA_OF_Appear", 2)
        tes3.messageBox("You feel a familiar presence walking up behind you...")
    elseif (tes3.getGlobal("AA_OF_Appear") == 2) then
        local mess = tes3.getReference("AA_OFMessenger")
        mess.position = tes3.player.position - tes3.player.sceneNode.rotation:transpose().z * 10000
    end
end

local function RestCellCheck(e)
    local playerCell = tostring(tes3.player.cell.id:lower())
    if playerCell == "fort stormwatch, prison chapel" then return end
    if string.find(playerCell,"stormwatch") then
        tes3.findGMST(57).value = "Resting here is too dangerous. You'll need to find safety."
        e.allowRest = false
    else
        tes3.findGMST(57).value = "Resting here is illegal. You'll need to find a bed."
    end
end

local function init()
    print('===========')
    print('AA MAIN BEGIN...')
    event.register('activate', dispActivate)
    event.register('simulate', dispUpdate)
    event.register('death', dispDeath)
    event.register("projectileHitObject", onMarksmanHit)
    event.register("attack", onAttack )
    event.register("cellChanged", dispCellChange)
event.register("uiShowRestMenu", RestCellCheck)
    print('AA MAIN SUCCESS')
    print('==========')

    -- bonfire.init()
end

event.register('initialized', init)