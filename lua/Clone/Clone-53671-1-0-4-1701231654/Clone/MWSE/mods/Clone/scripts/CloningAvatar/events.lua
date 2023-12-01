local events     = {}

local pathPrefix = "Clone.scripts.CloningAvatar"

local omw, core  = pcall(require, "openmw.core")
if omw then
    pathPrefix = "scripts.CloningAvatar"
end
local cloneRoomManager = require(pathPrefix .. ".CloneRoomManager")
local commonUtil = require(pathPrefix .. ".common.commonUtil")
local dataManager = require(pathPrefix .. ".common.dataManager")
local cloneData = require(pathPrefix .. ".common.cloneData")
function events.onActivate(object, actor)
    local recId = commonUtil.getRefRecordId(object):lower()


    if recId == "tdm_clone_glass1" or recId == "tdm_clone_glass2" then --real body
        local check = dataManager.getValueOrInt("firstMessageGiven")
        if check == 1 then
            commonUtil.delayedAction(function()
                commonUtil.showInfoBox(
                    "Enter the pod, and close the door behind you. \nOnce the door is closed, activate the switch to your side.")
            end, 1
            )
            dataManager.setValue("firstMessageGiven", 2)
        end
    end
    if recId == "zhac_button_1" then --real body
        --  cloneData.transferPlayerData(commonUtil.getPlayer(), commonUtil.getReferenceById("player"), true)
        cloneData.savePlayerData()
        commonUtil.openCloneMenu(true)
    elseif recId == "tdm_controlpanel_left" then
        local var = commonUtil.getScriptVariables("tdm_clone_glass1", "TDM_Glass_Script1", "RotatingItem")

        if var == 0 then
            commonUtil.openManageCloneMenu(recId)
            --tes3.getScript("TDM_Glass_Script1"):getVariableData()
            -- commonUtil.showMessage("Valid State")
        else
            commonUtil.showMessage("Door still open, cannot manage.")
        end
        --local newClone = cloneData.addCloneToWorld("gnisis, arvs-drelen", { x = 3977, y = 3286, z = 256 })
    elseif recId == "tdm_controlpanel_right" then
        --local newClone = cloneData.addCloneToWorld("gnisis, arvs-drelen", { x = 3977, y = 3286, z = 256 })
        local var = commonUtil.getScriptVariables("tdm_clone_glass2", "TDM_Glass_Script2", "RotatingItem")

        if var == 0 then
            commonUtil.openManageCloneMenu(recId)
            --tes3.getScript("TDM_Glass_Script1"):getVariableData()
            -- commonUtil.showMessage("Valid State")
        else
            commonUtil.showMessage("Door still open, cannot manage.")
        end
    elseif recId == "tdm_switch2" then
        local var = commonUtil.getScriptVariables("tdm_clone_glass2", "TDM_Glass_Script2", "RotatingItem")
        local var2 = commonUtil.getScriptVariables("TDM_Switch2", "TDM_Switcher2", "turning")
        if var == 0 and var2 == 0 then
            local pCloneData = cloneData.savePlayerData()

            pCloneData = cloneData.getCloneDataForNPC(commonUtil.getPlayer())
            cloneData.setClonePodName(pCloneData.id, "tdm_controlpanel_right")

            commonUtil.openCloneMenu(true)
        else
            commonUtil.showMessage("Door still open, cannot enter ")
        end
    elseif recId == cloneData.getCloneRecordId() and commonUtil.getQuestStage("TDM_Clone_SQ1") < 30 then
        return false
    elseif recId == cloneData.getCloneRecordId() then
        commonUtil.addTopic("follow")
        commonUtil.addTopic("wait")
    elseif recId == "tdm_switch1" then
        local var = commonUtil.getScriptVariables("tdm_clone_glass1", "TDM_Glass_Script1", "RotatingItem")
        local var2 = commonUtil.getScriptVariables("TDM_Switch1", "TDM_Switcher", "turning")
        if var == 0 and var2 == 0 then
            local pCloneData = cloneData.savePlayerData()
            pCloneData = cloneData.getCloneDataForNPC(commonUtil.getPlayer())
            cloneData.setClonePodName(pCloneData.id, "tdm_controlpanel_left")
            commonUtil.openCloneMenu(true)
            --tes3.getScript("TDM_Glass_Script1"):getVariableData()
            -- commonUtil.showMessage("Valid State")
        else
            commonUtil.showMessage("Door still open, cannot enter ")
        end
    elseif recId == "tdm_clone_glass1" then
        local occupant = cloneData.getCloneIDForPod("tdm_controlpanel_left")
        local playerCloneID = cloneData.getCloneDataForNPC(commonUtil.getPlayer())
        if occupant and playerCloneID and occupant == cloneData.getRealPlayerCloneID() and occupant ~= playerCloneID.id then
            return false
        end
        cloneData.clearCloneIDForPod("tdm_controlpanel_left")
    elseif recId == "tdm_clone_glass2" then
        local occupant = cloneData.getCloneIDForPod("tdm_controlpanel_right")
        local playerCloneID = cloneData.getCloneDataForNPC(commonUtil.getPlayer())
        if occupant and playerCloneID and occupant == cloneData.getRealPlayerCloneID() and occupant ~= playerCloneID.id then
            return false
        end
        cloneData.clearCloneIDForPod("tdm_controlpanel_right")
    end
end

function events.cellChanged(newCell)
    if newCell.name == "Gnisis, Arvs-Drelen" then
        local val = dataManager.getValue("ZHAC_CloneRoomState", -1)
        if val == -1 then
            print("cell init")
            dataManager.setValue("ZHAC_CloneRoomState", 1)
            cloneRoomManager.initRoom(newCell)
            if not omw then
                cloneRoomManager.setObjStates(1, newCell)
            end
        elseif val > -1 then
            cloneRoomManager.setObjStates(val, newCell)
        end
    end
end

function events.onInit()
    local gameStarted = dataManager.getValue("gameStarted", false)
    if not gameStarted then
        --   cloneData.addCloneToWorld("gnisis, arvs-drelen", { x = 3977, y = 3286, z = 256 })
        dataManager.setValue("gameStarted", true)
    end
end

function events.onQuestUpdate(id, stage)
    if id:lower() == "tdm_clone_mq" then
        if stage == 50 then
            dataManager.setValue("ZHAC_CloneRoomState", 2)
        elseif stage == 60 then
            dataManager.setValue("ZHAC_CloneRoomState", 3)
        elseif stage == 70 then
            local playerCell = commonUtil.getPlayer().cell
            if playerCell.name:lower() == "gnisis, arvs-drelen" then
                cloneRoomManager.setObjStates(4, playerCell)
            end
            dataManager.setValue("ZHAC_CloneRoomState", 4)
        end
    end
end

function events.onKeyPress(keyChar)
    if keyChar == commonUtil.getKeyBindingChar() then
        if commonUtil.menuMode() then
            return
        end
        --commonUtil.showMessage("K Pressed")
        commonUtil.openCloneMenu()
    end
end

function events.onPlayerDeath(player)
    cloneData.handleCloneDeath()
end

function events.onConsoleCommand(command)
    if command == "luaclonetp" or command == "clonetp" then
        commonUtil.addItem("ingred_6th_corprusmeat_03", 5)
        commonUtil.addItem("ingred_daedras_heart_01", 5)
        commonUtil.addItem("ingred_frost_salts_01", 5)
        commonUtil.teleportActor(commonUtil.getPlayer(), "gnisis, arvs-drelen", { x = 4096, y = 5888, z = 128 })
        cloneRoomManager.setObjStates(4, commonUtil.getPlayer().cell)
        commonUtil.writeToConsole("Teleported to Gnisis")
        commonUtil.closeMenu()
    end
end

return events
