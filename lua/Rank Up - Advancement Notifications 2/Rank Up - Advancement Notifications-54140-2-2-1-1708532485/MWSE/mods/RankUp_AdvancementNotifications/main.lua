-- Help function
function table_contains(tbl, x)
    found = false
    for _, v in pairs(tbl) do
        if v == x then 
            found = true 
        end
    end
    return found
end



-- DEFINE GLOBALS

-- Anfangsposition der Notifications (bzw. der ersten Notification)
NotifYPos = 0.03
-- Variable, die die ID der jetzigen Notification angibt (sodass wir sie danach löschen können)
CurrentBoxID = 0
-- Table, der die Timer für die einzelnen Notifications hält
NotifTimer = {}
-- Notification Height in px
NotifHeight = 68



-- NOTIFICATION WINDOW MANAGEMENT

function AdvNotifInit()
    local advNotifRegister = tes3ui.registerID("Rank Up!")
    local factionList = require("RankUp_AdvancementNotifications.factionAndIconList")
    if factionList == nil then
        return mwse.log("[Rank Up!] Initialization failed. Not all files are present.")
    end
    mwse.log("[Rank Up!] Initialized.")
end

function CreateAdvNotif(iconPath, congrats, messageText, factionName)
    -- Falls schon eine Notification offen ist, verschiebe diese um 0.13 nach unten
    if (tes3ui.findHelpLayerMenu(CurrentBoxID) ~= nil)  then
        local prevHeight = tes3ui.findHelpLayerMenu(CurrentBoxID):getPropertyInt("height")
        CurrentBoxID = CurrentBoxID + 1

        NotifYPos = NotifYPos + prevHeight*0.0012 + 0.025
    end

    -- Menü erstellen:
    NotifBox = tes3ui.createHelpLayerMenu({id = CurrentBoxID})
    NotifBox.visible = true
    -- Eigenschaften
    NotifBox.absolutePosAlignY = NotifYPos
    NotifBox.absolutePosAlignX = 0.99
    NotifBox.autoHeight = true
    NotifBox.autoWidth = true
    --NotifBox.alpha = 0.85
    NotifBox.flowDirection = tes3.flowDirection.leftToRight
    NotifBox.childAlignY = 0.5

    -- Größter Block für alle Kinderelemente
    local notifBlock = NotifBox:createBlock({id = "RankUp_GroundBlock"})
    notifBlock.flowDirection = tes3.flowDirection.leftToRight
    notifBlock.height = NotifHeight
    notifBlock.autoWidth = true
    notifBlock.childAlignY = 0.5

    -- Block für Icon erstellen:
    local imageBlock = notifBlock:createBlock({id = "RankUp_ImageBlock"})
    imageBlock.autoHeight = true
    imageBlock.autoWidth = true
    imageBlock.wrapText = true
    imageBlock.flowDirection = tes3.flowDirection.topToBottom
    imageBlock.childAlignY = 0.5
    imageBlock.borderRight = IconBorderRight
    -- Icon für die Box:
    local notifIcon1 = imageBlock:createImage({id = "RankUp_Icon", path = iconPath})
    notifIcon1.imageScaleX = IconScale
    notifIcon1.imageScaleY = IconScale
    notifIcon1.borderLeft = IconBorderLeft

    -- Block für Text erstellen:
    local textBlock = notifBlock:createBlock({id = "RankUp_TextBlock"})
    textBlock.flowDirection = tes3.flowDirection.topToBottom
    textBlock.autoHeight = true
    textBlock.autoWidth = true
    textBlock.borderTop = 6
    textBlock.borderBottom = 12
    textBlock.borderRight = 10
    textBlock.borderLeft = 10
    -- Text für die Box:
    local notifText0 = textBlock:createLabel({id = "RankUp_CongratsLabel", text = congrats})
    notifText0.color = ({0.8,1,0.8})
    notifText0.wrapText = true
    notifText0.justifyText = "center"
    notifText0.font = 1
    local notifText1 = textBlock:createLabel({id = "RankUp_MainTextLabel", text = messageText})
    notifText1.color = ({1,1,1})
    notifText1.wrapText = true
    notifText1.justifyText = "center"
    notifText1.font = 0
    local notifText2 = textBlock:createLabel({id = "RankUp_FactionNameLabel", text = factionName})
    notifText2.color = ({1,1,0.5})
    notifText2.wrapText = true
    notifText2.justifyText = "center"
    notifText2.font = 0

    -- Save changes
    NotifBox:updateLayout()
    return true
end

function AdvNotifDisplay_AllReqs(tableIndex, guildName)
    local iconPath = GetIcon(tableIndex)
    NotifHeight = 68
    CreateAdvNotif(iconPath, "Congratulations!","You are now ready to advance in the",guildName)
    --mwse.log("[Rank Up!] Notification displayed.")
    event.trigger("RankUp_Notification_displayed")
end


function AdvNotifDisplay_NotEnoughRep(tableIndex, guildName)
    local iconPath = GetIcon(tableIndex)
    NotifHeight = 68
    CreateAdvNotif(iconPath,"Almost there!","You should complete more duties for the",guildName)
    --mwse.log("[Rank Up!] Notification displayed.")
    event.trigger("RankUp_Notification_displayed")
end

function AdvNotifDisplay_NoReqsMet(tableIndex, guildName)
    local iconPath = GetIcon(tableIndex)
    NotifHeight = 85
    CreateAdvNotif(iconPath,"Long way ahead!","You need to work on your abilities and\ncomplete more tasks to advance in the",guildName)
    --mwse.log("[Rank Up!] Notification displayed.")
    event.trigger("RankUp_Notification_displayed")
end

function AdvNotifDisplay_NeedHigherSkillsAndAttributes(tableIndex, guildName)
    local iconPath = GetIcon(tableIndex)
    NotifHeight = 85
    CreateAdvNotif(iconPath,"Time for some Training!","You need to improve your skills\nand attributes to advance in the",guildName)
    --mwse.log("[Rank Up!] Notification displayed.")
    event.trigger("RankUp_Notification_displayed")
end

function AdvNotifDestroy()
    local currentNotif = tes3ui.findHelpLayerMenu(CurrentBoxID)
    currentNotif:destroy()
    CurrentBoxID = CurrentBoxID-1
    --mwse.log("[Rank Up!] Notification cleared.")
end

function AdvNotifDelay()
    NotifTimer[CurrentBoxID] = timer.start({
        type = timer.real,
        duration = 10,
        callback = AdvNotifDestroy
    })
    --mwse.log("[Rank Up!] Notification delayed.")
end

function AdvNotifClearAll()
    local currentNotif = tes3ui.findHelpLayerMenu(CurrentBoxID)
    -- Do as long as there are notifications still displayed
    while currentNotif ~= nil do
        -- Destory Element
        currentNotif:destroy()
        -- Cancel Element-Timer
        NotifTimer[CurrentBoxID]:cancel()
        -- Look for the former Notification Box
        CurrentBoxID = CurrentBoxID-1
        currentNotif = tes3ui.findHelpLayerMenu(CurrentBoxID)
    end
    --mwse.log("[Rank Up!] All notifications cleared.")
end

function GetIcon(factionIndex)
    return IconPaths[factionIndex]
end



-- REQUIREMENT CHECKS

function AttributeCheck(faction, playerNextRank)
    --mwse.log("[Rank Up!] Attribute check started.")
    local playerAttributesMeetReqs = 0
    -- Prüfe alle 2 Attribute (es läuft 1,2 und nicht zu 3)
    for i=1, 2 do
        -- Wenn das Attribut des Spielers (wobei nur die für die Fraktion relevanten Attribute geprüft werden) größer-gleich dem benötigten Wert ist, dann zähle +1
        if tes3.mobilePlayer.attributes[i].base == nil then
            mwse.log("[Rank Up!] Player attributes couldn't be read.")
            return false
        end
        if faction.ranks[playerNextRank].attributes[i] == nil then
            mwse.log("[Rank Up!] Faction attributes couldn't be read.")
            return false
        end

        -- Funktion
        -- bei mobilePlayer.attributes muss bei Zelle i zugegriffen werden und dann +1 gerechnet werden, weil der player Attribute Table bei 1 statt bei 0 beginnt aus irgendnem Grund
        -- (strength = 0, aber playerStrength = mobilePlayer.attributes[1].base)
        if (tes3.mobilePlayer.attributes[faction.attributes[i]+1].base >= faction.ranks[playerNextRank].attributes[i]) then
            -- Hilfsvariable, damit der Check bei 2 erreichten Attributswerten als true returned wird
            playerAttributesMeetReqs = playerAttributesMeetReqs+1
            -- Wenn der Spieler die 2 relevanten Attribute auf dem nötigen Wert hat, returne true
            if playerAttributesMeetReqs==2 then
                --mwse.log("[Rank Up!] Attribute check successful returning true.")
                return true
            end
        end
    end
    -- Der Spieler hat 0 oder 1 Attribut auf dem nötigen Wert
    --mwse.log("[Rank Up!] Attribute check successful returning false.")
    return false
end

function SkillCheck(faction, playerNextRank)
    --mwse.log("[Rank Up!] Skill check started.")
    local playerSkillsMeetReqs = 0
    -- Anzahl der für diese Fraktion relevanten Skills. -1, weil der Table aus irgendeinem Grund immer als letzten Wert "-1" hat, deswegen wollen wir am vorletzten Index stoppen.
    local numOfSkills = #faction.skills-1
    -- Anzahl der für diesen Rang relevanten Skills (z. B. bei "Lawman"-Hlaalu 2 relevante)
    local numOfRankSkills = #faction.ranks[playerNextRank].skills
    local alreadyCheckedSkills = {}
    --TESTING:
    --mwse.log("Number of relevant skills is:")
    --mwse.log(numOfSkills)
    --mwse.log("Number of relevant skill values for next rank is:")
    --mwse.log(numOfRankSkills)

    -- Prüfe die Spieler-Skill-Werte mit den zu benötigten Werten. Die Anzahl dieser ist in numOfRankSkills gespeichert.
    for j=1, numOfRankSkills do
        --mwse.log("Rank Skill to be checked:")
        --mwse.log(j)
        -- Laufe über alle 6-7 relevanten Skills beim Spieler, um sie mit den zu benötigten Werten zu vergleichen.
        -- Sobald ein Skill dem Wert entspricht, brechen wir die untere Schleife ab und vergleichen erneut mit dem nächsten Wert (z.B. mind. 1 Skill auf 5)
        for i=1, numOfSkills do
            --TESTING:
            --mwse.log("Player skill base is:")
            --mwse.log(tes3.mobilePlayer.skills[faction.skills[i]+1].base)
            --mwse.log("Needed skill level is:")
            --mwse.log(faction.ranks[playerNextRank].skills[j])

            -- Mache den Check nur, wenn der Skill noch nicht für einen vorherigen Vergleich positiv war:
            if table_contains(alreadyCheckedSkills,i)==false then
                -- faction.skills[i] gibt den Index des skills im tes3.skill Namespace wieder; mobilePlayer.skills verwendet aber tes3statisticskill - diese Struktur beginnt bei Index 1, deswegen benötigt man +1
                -- Wir vergleichen den Wert des Skills beim Spieler mit dem benötigten Wert für den nächsten Rang:
                if (tes3.mobilePlayer.skills[faction.skills[i]+1].base >= faction.ranks[playerNextRank].skills[j]) then                
                    -- Betrachte den nächsten nötigen Wert (z. B. 1 Skill auf 30 ist positiv, jetzt 1 Skill auf 5 suchen)
                    -- Hilfsvariable, die tracked, ob schon genug Skills auf dem benötigten Level sind
                    playerSkillsMeetReqs = playerSkillsMeetReqs+1
                    table.insert(alreadyCheckedSkills,i)
                    break
                end
            end
            --mwse.log("[Rank Up!] Skill was already considered for a previous check.")
        end

        -- Wenn der Spieler die relevanten Skill-Werte erreicht hat:
        -- Bricht somit auch die Schleife ab, falls z. B. schon die ersten beiden Skills genug waren
        if playerSkillsMeetReqs >= numOfRankSkills then
            --mwse.log("[Rank Up!] Skill check successful returning true.")
            return true
        end
    end

    -- Der Spieler hat nicht genug Skills auf dem nötigen Level
    --mwse.log("[Rank Up!] Skill check successful returning false.")
    return false
end

function ReputationCheck(faction, playerNextRank)
    --mwse.log("[Rank Up!] Rep check started.")
    local playerRep = faction.playerReputation
    -- Wenn der Spieler mehr oder gleich viel Ruf bei der Fraktion hat, wie für seinen Rang benötigt werden:
    if (playerRep >= faction.ranks[playerNextRank].reputation) then
        --mwse.log("[Rank Up!] Rep check successful returning true.")
        return true
    end
    -- Der Spieler hat nicht genügend Ruf
    --mwse.log("[Rank Up!] Rep check successful returning false.")
    return false
end

-- Funktion, um die Fraktionen zu speichern, welchen der Spieler angehört
function CheckPlayerFactions()
    local newArr = {}
    local playerDidJoin
    -- Erstelle 2 neue Tables mit den Fraktionen, welchen der Spieler angehört und den Namen der Fraktionen
    local joinedFactionsTableCell = 0
    for i=1, #GetFactionNames, 1 do
        if tes3.getFaction(GetFactionNames[i]).playerJoined == true then
            -- Extra Zähler, damit wir bei dem Table bei 1 anfangen
            joinedFactionsTableCell = joinedFactionsTableCell+1
            -- Extra Variable um i einzutragen, da das sonst nicht richtig geht scheinbar
            playerDidJoin = i
            newArr[joinedFactionsTableCell] = playerDidJoin
        end
    end

    -- Wenn der Spieler keiner Fraktion angehört:
    if newArr == nil then 
        --mwse.log("[Rank Up!] Player Faction check successful, but player isn't in any faction.")
        return nil
    else
        --mwse.log("[Rank Up!] Player Faction check successful.")
        return newArr
    end
end

-- Main Funktion um alle Anforderungen zu prüfen
function CheckRequirements(faction)
    --mwse.log("[Rank Up!] Requirements check started for faction:")
    --mwse.log(faction)
    -- Bestimme den nächsten Rang in der Fraktion
    local playerNextRank = faction.playerRank+2
    if playerNextRank == nil then
        return false
    end
    -- Wenn der Spieler schon max Rank ist
    if playerNextRank > 10 then
        mwse.log("[Rank Up!] Player is already the highest rank.")
        return 0
    end

    -- Prüfe Skills und Attribute
    if AttributeCheck(faction, playerNextRank) and SkillCheck(faction, playerNextRank) then
        -- Prüfe den Ruf
        if ReputationCheck(faction, playerNextRank) then
            -- Wenn Attribute, Skills und Ruf ausreichen, dann:
            return 2
        end
        -- Wenn Attribute und Skills ausreichen, aber noch nicht genug Ruf, dann:
        return 1
    -- Wenn die Skills und Attribute nicht hoch genug sind:
    else 
        -- Prüfe den Ruf
        if ReputationCheck(faction, playerNextRank) then
            -- Wenn Attribute, Skills NICHT, ABER der Ruf ausreicht:
            return 3
        end
    end
    -- Wenn alle 3 Sachen nicht ausreichen:
    return 0
end



-- MAIN FUNCTION

local function main()
    -- PlayerJoinedFactions enthält die Indexe zu den Fraktionen, die der Spieler angehört. Diese sind können somit auf GetFactionNames und FactionTableNames angewendet werden, da sie dieselbe Reihenfolge haben
    local PlayerJoinedFactions = CheckPlayerFactions()
        -- Wenn der Spieler keiner Fraktion angehört, returne direkt
    if PlayerJoinedFactions == nil then
        --mwse.log("[Rank Up!] Player isn't part of any faction.")
        return false
    end

    local faction
    local factionName
    -- Nötig, da wir sonst die Funktion öfter aufrufen müssen um die verschiedenen Returns zu prüfen
    local playerRequirementCheck

    -- Überprüfe alle Fraktionen, welchen der Spieler angehört
    for i=1, #PlayerJoinedFactions do
        -- Wenn irgendwie was schiefgeloffen ist 
        if PlayerJoinedFactions[i] == nil then
            mwse.log("[Rank Up!] Something went wrong; PlayerJoinedFactions is empty.")
            return false
        end

        -- Bei jeder Iteration andere faction betrachten
        faction = tes3.getFaction(GetFactionNames[PlayerJoinedFactions[i]])

        -- Test, ob die faction richtig übernommen wurde
        if faction == nil then
            mwse.log("[Rank Up!] No faction found.")
            return false
        end
        
        -- Der aktuelle Fraktionsname wird aus dem FactionTableNames-Table entnommen am Index, der in PlayerJoinedFactions gespeichert ist
        factionName = FactionTableNames[PlayerJoinedFactions[i]]

        -- Überprüfe die Anforderungen und speichere das Return:
        playerRequirementCheck = CheckRequirements(faction)

        -- Wenn alle Anforderungen erfüllt sind:
        if playerRequirementCheck == 2 then
            --mwse.log("[Rank Up!] All requirements met.")
            -- Übergebe den Index der Fraktion (ist in allen Tables gleich) damit wir das Icon holen können, und übergebe den Fraktionsname, der in der Nachricht angezeigt wird
            AdvNotifDisplay_AllReqs(PlayerJoinedFactions[i],factionName)
        -- Wenn noch Ruf fehlt:
        elseif playerRequirementCheck == 1 then
            --mwse.log("[Rank Up!] All requirements but reputation met.")
            AdvNotifDisplay_NotEnoughRep(PlayerJoinedFactions[i],factionName)
        -- Wenn NUR der Ruf erfüllt ist:
        elseif playerRequirementCheck == 3 then
            AdvNotifDisplay_NeedHigherSkillsAndAttributes(PlayerJoinedFactions[i],factionName)
            --mwse.log("[Rank Up!] Only reputation requirements met.")
        -- Wenn alle 3 Sachen NICHT erfüllt sind:
        elseif playerRequirementCheck == 0 then
            AdvNotifDisplay_NoReqsMet(PlayerJoinedFactions[i],factionName)
            --mwse.log("[Rank Up!] None of the requirements were met.")
        end
    end
    -- Position der Notifications wird zurück auf den Anfangswert gesetzt
    NotifYPos = 0.04
end



-- EVENTS


--- @param e keyDownEventData
local function keyPressed(e)
    -- Just clear messages when pressing Shift+U
    if (e.isShiftDown) then
        if tes3ui.findHelpLayerMenu(CurrentBoxID) ~= nil then
            AdvNotifClearAll()
            return mwse.log("[Rank Up!] Player cleared all messages.")
        else
            return --mwse.log("[Rank Up!] Notifications are already deleted. Skipping Shift+U press.")
        end
    end

    -- If there are already notifications displayed, don't do anything
    if tes3ui.findHelpLayerMenu(CurrentBoxID) ~= nil or tes3ui.findHelpLayerMenu(CurrentBoxID-1) ~= nil then
        return --mwse.log("[Rank Up!] Notifications are already displayed. Skipping U-key press.")
    -- If there are no notifications displayed already, begin with the checks and displaying:
    else
        mwse.log("[Rank Up!] Starting checks.")
        -- Call main function
        main()
        return
    end
end

event.register(tes3.event.initialized, AdvNotifInit, {priority = -10})
event.register("RankUp_Notification_displayed", AdvNotifDelay)
--event.register("RankUp_Notification_cleared", AdvNotifDelay)
-- Wenn die U-Taste gedrückt wird, führe die Funktion keyPressed() aus.
event.register(tes3.event.keyDown, keyPressed, {filter = tes3.scanCode.u})