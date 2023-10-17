-- Joinable factions
local function factionsVariables()
    clanAundae = tes3.getFaction("Clan Aundae") 
    clanBerne = tes3.getFaction("Clan Berne")
    clanQuarra = tes3.getFaction("Clan Quarra")
    fightersGuild = tes3.getFaction("Fighters Guild")
    houseHlaalu = tes3.getFaction("Hlaalu")
    imperialCult = tes3.getFaction("Imperial Cult")
    imperialLegion = tes3.getFaction("Imperial Legion")
    magesGuild = tes3.getFaction("Mages Guild")
    moragTong = tes3.getFaction("Morag Tong")
    houseRedoran = tes3.getFaction("Redoran")
    houseTelvanni = tes3.getFaction("Telvanni")
    temple = tes3.getFaction("Temple")
    thievesGuild = tes3.getFaction("Thieves Guild")
    twinLamps = tes3.getFaction("Twin Lamps")
    eastEmpire = tes3.getFaction("East Empire Company")
end



-- Variable, dass der Spieler qualifiziert für den nächsten Rang ist.
local playerIsQualified = false

-- Variablen, die prüfen soll, ob die Nachricht von der Fraktion in dieser Spielsession schon angezeigt wurde.
-- So wird verhindert, dass sie bei jedem menuEnter-event angezeigt wird.
local clanAundaeShown = false
local clanBerneShown = false
local clanQuarraShown = false
local fightersGuildShown = false
local houseHlaaluShown = false
local imperialCultShown = false
local imperialLegionShown = false
local magesGuildShown = false
local moragTongShown = false
local houseRedoranShown = false
local houseTelvanniShown = false
local templeShown = false
local thievesGuildShown = false
local twinLampsShown = false
local eastEmpireShown = false




-- Vanilla functions
-- Main function
function advancementCheckGuilds(
    guildName,
    skill1, skill2, skill3, skill4, skill5, skill6, 
    attribute1, attribute2)
    -- All die Parameter, die auswechselbar sein müssen

    factionsVariables()

    -- Rang 0
    if guildName.playerRank == 0 then
        if (
            -- skills müssen mit ihrem Platz im skill table angegeben werden. 
            -- https://mwse.github.io/MWSE/references/skills/?h=skills
            -- Da es zu einem Table gemacht wird, beginnt es aber nicht mit 0, sondern mit 1.
            -- Es ist also immer das value von der Webseite + 1.
            tes3.mobilePlayer.skills[skill1].base >= 10 
            or tes3.mobilePlayer.skills[skill2].base >= 10  
            or tes3.mobilePlayer.skills[skill3].base >= 10  
            or tes3.mobilePlayer.skills[skill4].base >= 10 
            or tes3.mobilePlayer.skills[skill5].base >= 10  
            or tes3.mobilePlayer.skills[skill6].base >= 10 
        )
        and (
            -- Dasselbe bei den attributes.
            --https://mwse.github.io/MWSE/references/attributes/?h=attributes + 1
            tes3.mobilePlayer.attributes[attribute1].base >= 30
            and tes3.mobilePlayer.attributes[attribute2].base >= 30
        )
        then
            -- Die Variable wird auf true gesetzt, damit die Funktion unten weiß, dass der Spieler bereit zum aufranken ist.
            playerIsQualified = true
            return
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end

    -- Rang 1
    if guildName.playerRank == 1 then
        if (
            tes3.mobilePlayer.skills[skill1].base >= 20 
            or tes3.mobilePlayer.skills[skill2].base >= 20  
            or tes3.mobilePlayer.skills[skill3].base >= 20  
            or tes3.mobilePlayer.skills[skill4].base >= 20 
            or tes3.mobilePlayer.skills[skill5].base >= 20  
            or tes3.mobilePlayer.skills[skill6].base >= 20 
        )
        and (
            tes3.mobilePlayer.attributes[attribute1].base >= 30
            and tes3.mobilePlayer.attributes[attribute2].base >= 30
        )
        then
            playerIsQualified = true
            return
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end


    -- Alle Anforderungen nach dem 2. Rang sind komplizierter, da hier nicht nur ein Skill aus all den relevanten
    -- einen bestimmten Wert haben muss, sondern auch noch 2 andere relevante. Somit funktioniert die Methode der ersten beiden hier nicht.


    -- "Array" für die benötigten Skills wird erstellt
    local playerSkillLevels = {}
    playerSkillLevels = {tes3.mobilePlayer.skills[skill1].base, tes3.mobilePlayer.skills[skill2].base, tes3.mobilePlayer.skills[skill3].base, 
                        tes3.mobilePlayer.skills[skill4].base, tes3.mobilePlayer.skills[skill5].base, tes3.mobilePlayer.skills[skill6].base}

    -- Variablen, die prüfen, ob der erste Skill den Wert erfüllt und erst dann wird der zweite geprüft (usw.)-
    local qualifiedLevel1 = false
    local qualifiedLevel2 = false
    local qualifiedLevel3 = false

    -- Skill 1 und Attribute Check
    -- Werte austauschbar durch die Parameter, sodass jede Fraktion mit ihren Werten hier passt.
    local function checkAndIndex(array, value, attributeValue1, attributeValue2)
        -- Erst die beiden relevanten Attribute der Fraktion, wenn diese nicht die Bedingung erfüllen, bricht es direkt ab.
        if tes3.mobilePlayer.attributes[attribute1].base >= attributeValue1
        and tes3.mobilePlayer.attributes[attribute2].base >= attributeValue2 then
            -- For-Schleife:
            -- Es wird von 1 hochgezählt.
            -- index ist dabei die Zählvariable, die auch das Element im Skill-Table (hier: array) angibt.
            -- Die Schleife stoppt, wenn ein Element - also ein Skill >= der benötigte Wert ist.
            -- Dann wird die Variable qualifiedLevel1 auf true gesetzt, damit der nächste Skill getestet wird.
            -- Auf diese Weise kriegen wir auch den ganz bestimmten Skill, der die Bedingung erfüllt heraus,
            -- da die Variable index auch den index des Elementes im array angibt.
            for index in ipairs(array) do
                if array[index] >= value then
                    qualifiedLevel1 = true
                    return
                end
            end
        end
    end

    -- Skill 2 Check
    local function checkAndIndex2(array, value)
        for index2 in ipairs(array) do
            if array[index2] >= value 
            and qualifiedLevel1 == true 
            -- Hier kommt jetzt die zusätzliche Bedingung dazu, dass der neue index ~= dem alten index sein muss.
            -- Das muss getan werden, da sonst der Skill, der die erste Bedingung erfüllt, auch die anderen beiden
            -- erfüllen würde, obwohl wir ja 1 Skill auf z. B. 30 und 2 ANDERE auf z. B. 5 haben müssen.
            -- So wird also garantiert, dass hier ein zweiter Skill gefunden wurde, der die zweite Bedingung erfüllt.
            and index ~= index2
            then
                qualifiedLevel2 = true
                return
            end
        end
    end

    local function checkAndIndex3(array, value)
        for index3 in ipairs(array) do
            if array[index3] >= value 
            and qualifiedLevel2 == true 
            and index2 ~= index3
            and index ~= index3
            then
                -- Finale Ausgabe, die beim Aufruf der Funktion benutzt wird, um die Haupt-Check-Variable auf true zu setzen.
                -- Hiermit sind alle 3 Skillbedingungen und die 2 Attributbedingungen erfüllt.
                qualifiedLevel3 = true
                return
            end
        end
    end


    -- playerRank == 2 bedeutet z. B. Journeyman bei der Figher's Guild zu sein. Somit werden die Anforderungen für den 3. Rang geprüft.
    if guildName.playerRank == 2 then
        -- Hier werden also die Anforderungen für den 3. Rang eingetragen.
        -- Die erste 30 ist das benötigte Skill Level, die beiden danach die benötigten Attribut Levels.
        checkAndIndex(playerSkillLevels, 30, 30, 30)
        -- die 5 ist das benötigte Skill Level für einen zweiten relevanten Skill.
        checkAndIndex2(playerSkillLevels, 5)
        -- die 5 ist das benötigte Skill Level für einen dritten relevanten Skill.
        checkAndIndex3(playerSkillLevels, 5)

        -- Die Funktion setzt qualifiedLevel3 auf true, wenn alle Bedingungen erfüllt sind.
        -- Wenn ja, wird playerIsQualified auf true gesetzt; wenn nein, bleibt es auf false.
        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        -- Das else-Statement ist hier dringend notwendig. Ich weiß nicht genau warum, aber nur so funktioniert es.
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 3 then
        checkAndIndex(playerSkillLevels, 40, 30, 30)
        checkAndIndex2(playerSkillLevels, 10)
        checkAndIndex3(playerSkillLevels, 10)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 4 then
        checkAndIndex(playerSkillLevels, 50, 31, 31)
        checkAndIndex2(playerSkillLevels, 15)
        checkAndIndex3(playerSkillLevels, 15)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 5 then
        checkAndIndex(playerSkillLevels, 60, 32, 32)
        checkAndIndex2(playerSkillLevels, 20)
        checkAndIndex3(playerSkillLevels, 20)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 6 then
        checkAndIndex(playerSkillLevels, 70, 33, 33)
        checkAndIndex2(playerSkillLevels, 25)
        checkAndIndex3(playerSkillLevels, 25)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 7 then
        checkAndIndex(playerSkillLevels, 80, 34, 34)
        checkAndIndex2(playerSkillLevels, 30)
        checkAndIndex3(playerSkillLevels, 30)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 8 then
        checkAndIndex(playerSkillLevels, 90, 35, 35)
        checkAndIndex2(playerSkillLevels, 35)
        checkAndIndex3(playerSkillLevels, 35)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    -- if guildName.playerRank == 9 ist nicht nötig, da es ja keinen 10. Rang gibt.
end

-- East Empire Company aus Bloodmoon braucht eine einige, da sie nur 9 Ränge und 5 relevante Skills hat
function advancementCheckEastEmpireCompany(
    guildName,
    skill1, skill2, skill3, skill4, skill5,
    attribute1, attribute2)
    -- All die Parameter, die auswechselbar sein müssen

    factionsVariables()

    -- Rang 0
    if guildName.playerRank == 0 then
        if (
            -- skills müssen mit ihrem Platz im skill table angegeben werden. 
            -- https://mwse.github.io/MWSE/references/skills/?h=skills
            -- Da es zu einem Table gemacht wird, beginnt es aber nicht mit 0, sondern mit 1.
            -- Es ist also immer das value von der Webseite + 1.
            tes3.mobilePlayer.skills[skill1].base >= 10 
            or tes3.mobilePlayer.skills[skill2].base >= 10  
            or tes3.mobilePlayer.skills[skill3].base >= 10  
            or tes3.mobilePlayer.skills[skill4].base >= 10 
            or tes3.mobilePlayer.skills[skill5].base >= 10  
        )
        and (
            -- Dasselbe bei den attributes.
            --https://mwse.github.io/MWSE/references/attributes/?h=attributes + 1
            tes3.mobilePlayer.attributes[attribute1].base >= 30
            and tes3.mobilePlayer.attributes[attribute2].base >= 30
        )
        then
            -- Die Variable wird auf true gesetzt, damit die Funktion unten weiß, dass der Spieler bereit zum aufranken ist.
            playerIsQualified = true
            return
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end

    -- Rang 1
    if guildName.playerRank == 1 then
        if (
            tes3.mobilePlayer.skills[skill1].base >= 20 
            or tes3.mobilePlayer.skills[skill2].base >= 20  
            or tes3.mobilePlayer.skills[skill3].base >= 20  
            or tes3.mobilePlayer.skills[skill4].base >= 20 
            or tes3.mobilePlayer.skills[skill5].base >= 20  
        )
        and (
            tes3.mobilePlayer.attributes[attribute1].base >= 30
            and tes3.mobilePlayer.attributes[attribute2].base >= 30
        )
        then
            playerIsQualified = true
            return
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end


    -- Alle Anforderungen nach dem 2. Rang sind komplizierter, da hier nicht nur ein Skill aus all den relevanten
    -- einen bestimmten Wert haben muss, sondern auch noch 2 andere relevante. Somit funktioniert die Methode der ersten beiden hier nicht.


     -- "Array" für die benötigten Skills wird erstellt
    local playerSkillLevels = {}
    playerSkillLevels = {tes3.mobilePlayer.skills[skill1].base, tes3.mobilePlayer.skills[skill2].base, tes3.mobilePlayer.skills[skill3].base, 
                        tes3.mobilePlayer.skills[skill4].base, tes3.mobilePlayer.skills[skill5].base}

    local qualifiedLevel1 = false
    local qualifiedLevel2 = false
    local qualifiedLevel3 = false

    local function checkAndIndex(array, value, attributeValue1, attributeValue2)
        if tes3.mobilePlayer.attributes[attribute1].base >= attributeValue1
        and tes3.mobilePlayer.attributes[attribute2].base >= attributeValue2 then
            for index in ipairs(array) do
                if array[index] >= value then
                    qualifiedLevel1 = true
                    return
                end
            end
        end
    end

    local function checkAndIndex2(array, value)
        for index2 in ipairs(array) do
            if array[index2] >= value 
            and qualifiedLevel1 == true 
            and index ~= index2
            then
                qualifiedLevel2 = true
                return
            end
        end
    end

    local function checkAndIndex3(array, value)
        for index3 in ipairs(array) do
            if array[index3] >= value 
            and qualifiedLevel2 == true 
            and index2 ~= index3
            and index ~= index3
            then
                qualifiedLevel3 = true
                return
            end
        end
    end


    if guildName.playerRank == 2 then
        checkAndIndex(playerSkillLevels, 30, 30, 30)
        checkAndIndex2(playerSkillLevels, 5)
        checkAndIndex3(playerSkillLevels, 5)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 3 then
        checkAndIndex(playerSkillLevels, 40, 30, 30)
        checkAndIndex2(playerSkillLevels, 10)
        checkAndIndex3(playerSkillLevels, 10)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 4 then
        checkAndIndex(playerSkillLevels, 50, 31, 31)
        checkAndIndex2(playerSkillLevels, 15)
        checkAndIndex3(playerSkillLevels, 15)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 5 then
        checkAndIndex(playerSkillLevels, 60, 32, 32)
        checkAndIndex2(playerSkillLevels, 20)
        checkAndIndex3(playerSkillLevels, 20)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 6 then
        checkAndIndex(playerSkillLevels, 70, 33, 33)
        checkAndIndex2(playerSkillLevels, 25)
        checkAndIndex3(playerSkillLevels, 25)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 7 then
        checkAndIndex(playerSkillLevels, 90, 35, 35)
        checkAndIndex2(playerSkillLevels, 35)
        checkAndIndex3(playerSkillLevels, 35)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 
end

-- Der Imperial Cult braucht eine eigene, weil er 7 relevant Skills hat
function advancementCheckImperialCult(
    guildName,
    skill1, skill2, skill3, skill4, skill5, skill6, skill7, 
    attribute1, attribute2)
    -- All die Parameter, die auswechselbar sein müssen

    factionsVariables()

    -- Rang 0
    if guildName.playerRank == 0 then
        if (
            -- skills müssen mit ihrem Platz im skill table angegeben werden. 
            -- https://mwse.github.io/MWSE/references/skills/?h=skills
            -- Da es zu einem Table gemacht wird, beginnt es aber nicht mit 0, sondern mit 1.
            -- Es ist also immer das value von der Webseite + 1.
            tes3.mobilePlayer.skills[skill1].base >= 10 
            or tes3.mobilePlayer.skills[skill2].base >= 10  
            or tes3.mobilePlayer.skills[skill3].base >= 10  
            or tes3.mobilePlayer.skills[skill4].base >= 10 
            or tes3.mobilePlayer.skills[skill5].base >= 10  
            or tes3.mobilePlayer.skills[skill6].base >= 10 
            or tes3.mobilePlayer.skills[skill7].base >= 10 
        )
        and (
            -- Dasselbe bei den attributes.
            --https://mwse.github.io/MWSE/references/attributes/?h=attributes + 1
            tes3.mobilePlayer.attributes[attribute1].base >= 30
            and tes3.mobilePlayer.attributes[attribute2].base >= 30
        )
        then
            -- Die Variable wird auf true gesetzt, damit die Funktion unten weiß, dass der Spieler bereit zum aufranken ist.
            playerIsQualified = true
            return
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end

    -- Rang 1
    if guildName.playerRank == 1 then
        if (
            tes3.mobilePlayer.skills[skill1].base >= 20 
            or tes3.mobilePlayer.skills[skill2].base >= 20  
            or tes3.mobilePlayer.skills[skill3].base >= 20  
            or tes3.mobilePlayer.skills[skill4].base >= 20 
            or tes3.mobilePlayer.skills[skill5].base >= 20  
            or tes3.mobilePlayer.skills[skill6].base >= 20 
            or tes3.mobilePlayer.skills[skill7].base >= 20 
        )
        and (
            tes3.mobilePlayer.attributes[attribute1].base >= 30
            and tes3.mobilePlayer.attributes[attribute2].base >= 30
        )
        then
            playerIsQualified = true
            return
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end


    -- Alle Anforderungen nach dem 2. Rang sind komplizierter, da hier nicht nur ein Skill aus all den relevanten
    -- einen bestimmten Wert haben muss, sondern auch noch 2 andere relevante. Somit funktioniert die Methode der ersten beiden hier nicht.


     -- "Array" für die benötigten Skills wird erstellt
    local playerSkillLevels = {}
    playerSkillLevels = {tes3.mobilePlayer.skills[skill1].base, tes3.mobilePlayer.skills[skill2].base, tes3.mobilePlayer.skills[skill3].base, 
                        tes3.mobilePlayer.skills[skill4].base, tes3.mobilePlayer.skills[skill5].base, tes3.mobilePlayer.skills[skill6].base, tes3.mobilePlayer.skills[skill7].base}

    local qualifiedLevel1 = false
    local qualifiedLevel2 = false
    local qualifiedLevel3 = false

    local function checkAndIndex(array, value, attributeValue1, attributeValue2)
        if tes3.mobilePlayer.attributes[attribute1].base >= attributeValue1
        and tes3.mobilePlayer.attributes[attribute2].base >= attributeValue2 then
            for index in ipairs(array) do
                if array[index] >= value then
                    qualifiedLevel1 = true
                    return
                end
            end
        end
    end

    local function checkAndIndex2(array, value)
        for index2 in ipairs(array) do
            if array[index2] >= value 
            and qualifiedLevel1 == true 
            and index ~= index2
            then
                qualifiedLevel2 = true
                return
            end
        end
    end

    local function checkAndIndex3(array, value)
        for index3 in ipairs(array) do
            if array[index3] >= value 
            and qualifiedLevel2 == true 
            and index2 ~= index3
            and index ~= index3
            then
                qualifiedLevel3 = true
                return
            end
        end
    end


    -- playerRank == 2 bedeutet z. B. Journeyman bei der Figher's Guild zu sein. Somit werden die Anforderungen für den 3. Rang geprüft.
    if guildName.playerRank == 2 then
        -- Hier werden also die Anforderungen für den 3. Rang eingetragen.
        -- Die erste 30 ist das benötigte Skill Level, die beiden danach die benötigten Attribut Levels.
        checkAndIndex(playerSkillLevels, 30, 30, 30)
        -- die 5 ist das benötigte Skill Level für einen zweiten relevanten Skill.
        checkAndIndex2(playerSkillLevels, 5)
        -- die 5 ist das benötigte Skill Level für einen dritten relevanten Skill.
        checkAndIndex3(playerSkillLevels, 5)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 3 then
        checkAndIndex(playerSkillLevels, 40, 30, 30)
        checkAndIndex2(playerSkillLevels, 10)
        checkAndIndex3(playerSkillLevels, 10)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 4 then
        checkAndIndex(playerSkillLevels, 50, 31, 31)
        checkAndIndex2(playerSkillLevels, 15)
        checkAndIndex3(playerSkillLevels, 15)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 5 then
        checkAndIndex(playerSkillLevels, 60, 32, 32)
        checkAndIndex2(playerSkillLevels, 20)
        checkAndIndex3(playerSkillLevels, 20)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 6 then
        checkAndIndex(playerSkillLevels, 70, 33, 33)
        checkAndIndex2(playerSkillLevels, 25)
        checkAndIndex3(playerSkillLevels, 25)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 7 then
        checkAndIndex(playerSkillLevels, 80, 34, 34)
        checkAndIndex2(playerSkillLevels, 30)
        checkAndIndex3(playerSkillLevels, 30)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 8 then
        checkAndIndex(playerSkillLevels, 90, 35, 35)
        checkAndIndex2(playerSkillLevels, 35)
        checkAndIndex3(playerSkillLevels, 35)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    -- if guildName.playerRank == 9 ist nicht nötig, da es ja keinen 10. Rang gibt.
end

-- Die Vampire Clans brauchen ab Rang 0 mehrere Skills auf bestimmten Leveln, deswegen hier eine einzelne Funktion.
function advancementCheckVampireClans(
    guildName,
    skill1, skill2, skill3, skill4, skill5, skill6, 
    attribute1, attribute2)
    -- All die Parameter, die auswechselbar sein müssen

    factionsVariables()

    -- "Array" für die benötigten Skills wird erstellt
    local playerSkillLevels = {}
    playerSkillLevels = {tes3.mobilePlayer.skills[skill1].base, tes3.mobilePlayer.skills[skill2].base, tes3.mobilePlayer.skills[skill3].base, 
                        tes3.mobilePlayer.skills[skill4].base, tes3.mobilePlayer.skills[skill5].base, tes3.mobilePlayer.skills[skill6].base}

    local qualifiedLevel1 = false
    local qualifiedLevel2 = false
    local qualifiedLevel3 = false

    local function checkAndIndex(array, value, attributeValue1, attributeValue2)
        if tes3.mobilePlayer.attributes[attribute1].base >= attributeValue1
        and tes3.mobilePlayer.attributes[attribute2].base >= attributeValue2 then
            for index in ipairs(array) do
                if array[index] >= value then
                    qualifiedLevel1 = true
                    return
                end
            end
        end
    end

    local function checkAndIndex2(array, value)
        for index2 in ipairs(array) do
            if array[index2] >= value 
            and qualifiedLevel1 == true 
            and index ~= index2
            then
                qualifiedLevel2 = true
                return
            end
        end
    end

    local function checkAndIndex3(array, value)
        for index3 in ipairs(array) do
            if array[index3] >= value 
            and qualifiedLevel2 == true 
            and index2 ~= index3
            and index ~= index3
            then
                qualifiedLevel3 = true
                return
            end
        end
    end


    if guildName.playerRank == 0 then
        -- Hier ist wichtig, dass attribute1 auch das erst genannte in der Liste ist,
        -- da sie bei den Vampire Clans verschieden hohe Anforderungen haben.
        -- https://en.uesp.net/wiki/Morrowind:Berne_Clan
        -- z. B. muss hier attribute1 = willpower sein
        checkAndIndex(playerSkillLevels, 30, 40, 30)
        checkAndIndex2(playerSkillLevels, 20)
        checkAndIndex3(playerSkillLevels, 20)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 1 then
        checkAndIndex(playerSkillLevels, 40, 45, 35)
        checkAndIndex2(playerSkillLevels, 20)
        checkAndIndex3(playerSkillLevels, 20)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 
    
    if guildName.playerRank == 2 then
        checkAndIndex(playerSkillLevels, 50, 50, 40)
        checkAndIndex2(playerSkillLevels, 25)
        checkAndIndex3(playerSkillLevels, 25)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 3 then
        checkAndIndex(playerSkillLevels, 60, 55, 45)
        checkAndIndex2(playerSkillLevels, 25)
        checkAndIndex3(playerSkillLevels, 25)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 4 then
        checkAndIndex(playerSkillLevels, 70, 60, 50)
        checkAndIndex2(playerSkillLevels, 30)
        checkAndIndex3(playerSkillLevels, 30)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 5 then
        checkAndIndex(playerSkillLevels, 80, 65, 55)
        checkAndIndex2(playerSkillLevels, 30)
        checkAndIndex3(playerSkillLevels, 30)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 6 then
        checkAndIndex(playerSkillLevels, 90, 70, 60)
        checkAndIndex2(playerSkillLevels, 35)
        checkAndIndex3(playerSkillLevels, 35)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 7 then
        checkAndIndex(playerSkillLevels, 100, 75, 65)
        checkAndIndex2(playerSkillLevels, 35)
        checkAndIndex3(playerSkillLevels, 35)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    if guildName.playerRank == 8 then
        checkAndIndex(playerSkillLevels, 110, 80, 70)
        checkAndIndex2(playerSkillLevels, 35)
        checkAndIndex3(playerSkillLevels, 35)

        if qualifiedLevel3 == true then
            playerIsQualified = true
            return playerIsQualified
        else
            playerIsQualified = false
            return playerIsQualified
        end
    end 

    -- if guildName.playerRank == 9 ist nicht nötig, da es ja keinen 10. Rang gibt.
end



-- Check if OAAB Twin Lamps is installed
local OAABtwinLampsInstalled = tes3.isModActive("OAAB Brother Junipers Twin Lamps.esp")
-- Check if Higher Faction Requirements is installed
local HFRFullInstalled = tes3.isModActive("higher faction requirements - Full.ESP")
local HFRMorrowindOnlyInstalled = tes3.isModActive("higher faction requirements - Morrowind Only.ESP")

-- Funktionen nur initialisieren, wenn der Mod installiert ist
if OAABtwinLampsInstalled == true then
    function advancementCheckTwinLamps(
        guildName,
        skill1, skill2, skill3, skill4, skill5, 
        attribute1, attribute2)
        -- All die Parameter, die auswechselbar sein müssen

        factionsVariables()

        -- Rang 0
        if guildName.playerRank == 0 then
            if (
                -- Dasselbe bei den attributes.
                --https://mwse.github.io/MWSE/references/attributes/?h=attributes + 1
                tes3.mobilePlayer.attributes[attribute1].base >= 25
                and tes3.mobilePlayer.attributes[attribute2].base >= 25
            )
            then
                -- Die Variable wird auf true gesetzt, damit die Funktion unten weiß, dass der Spieler bereit zum aufranken ist.
                playerIsQualified = true
                return
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end

        -- Rang 1
        if guildName.playerRank == 1 then
            if (
                tes3.mobilePlayer.skills[skill1].base >= 10 
                or tes3.mobilePlayer.skills[skill2].base >= 10  
                or tes3.mobilePlayer.skills[skill3].base >= 10  
                or tes3.mobilePlayer.skills[skill4].base >= 10 
                or tes3.mobilePlayer.skills[skill5].base >= 10  
            )
            and (
                tes3.mobilePlayer.attributes[attribute1].base >= 30
                and tes3.mobilePlayer.attributes[attribute2].base >= 30
            )
            then
                playerIsQualified = true
                return
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end


        -- "Array" für die benötigten Skills wird erstellt
        local playerSkillLevels = {}
        playerSkillLevels = {tes3.mobilePlayer.skills[skill1].base, tes3.mobilePlayer.skills[skill2].base, tes3.mobilePlayer.skills[skill3].base, 
                            tes3.mobilePlayer.skills[skill4].base, tes3.mobilePlayer.skills[skill5].base, tes3.mobilePlayer.skills[skill6].base}

        local qualifiedLevel1 = false
        local qualifiedLevel2 = false
        local qualifiedLevel3 = false


        local function checkAndIndex(array, value, attributeValue1, attributeValue2)
            if tes3.mobilePlayer.attributes[attribute1].base >= attributeValue1
            and tes3.mobilePlayer.attributes[attribute2].base >= attributeValue2 then
                for index in ipairs(array) do
                    if array[index] >= value then
                        qualifiedLevel1 = true
                        return
                    end
                end
            end
        end

        local function checkAndIndex2(array, value)
            for index2 in ipairs(array) do
                if array[index2] >= value 
                and qualifiedLevel1 == true 
                and index ~= index2
                then
                    qualifiedLevel2 = true
                    return
                end
            end
        end

        local function checkAndIndex3(array, value)
            for index3 in ipairs(array) do
                if array[index3] >= value 
                and qualifiedLevel2 == true 
                and index2 ~= index3
                and index ~= index3
                then
                    qualifiedLevel3 = true
                    return
                end
            end
        end


        if guildName.playerRank == 2 then
            checkAndIndex(playerSkillLevels, 15, 33, 33)
            checkAndIndex2(playerSkillLevels, 5)
            checkAndIndex3(playerSkillLevels, 5)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 3 then
            checkAndIndex(playerSkillLevels, 20, 35, 35)
            checkAndIndex2(playerSkillLevels, 10)
            checkAndIndex3(playerSkillLevels, 10)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 4 then
            checkAndIndex(playerSkillLevels, 25, 35, 35)
            checkAndIndex2(playerSkillLevels, 15)
            checkAndIndex3(playerSkillLevels, 15)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 5 then
            checkAndIndex(playerSkillLevels, 30, 40, 40)
            checkAndIndex2(playerSkillLevels, 20)
            checkAndIndex3(playerSkillLevels, 20)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 6 then
            checkAndIndex(playerSkillLevels, 40, 50, 50)
            checkAndIndex2(playerSkillLevels, 30)
            checkAndIndex3(playerSkillLevels, 30)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 
    end
end

if HFRFullInstalled == true or HFRMorrowindOnlyInstalled == true then
    -- Mod "Higher Faction Requirements"
    -- Genau das selbe wie "advancementCheckStandard" aber nur mit 5 skills
    function advancementCheckEastEmpireCompanyHFRFull(
        guildName,
        skill1, skill2, skill3, skill4, skill5, skill6, 
        attribute1, attribute2)
        -- All die Parameter, die auswechselbar sein müssen

        factionsVariables()

        -- "Array" für die benötigten Skills wird erstellt
        local playerSkillLevels = {}
        playerSkillLevels = {tes3.mobilePlayer.skills[skill1].base, tes3.mobilePlayer.skills[skill2].base, tes3.mobilePlayer.skills[skill3].base, 
                            tes3.mobilePlayer.skills[skill4].base, tes3.mobilePlayer.skills[skill5].base}

        local qualifiedLevel1 = false
        local qualifiedLevel2 = false
        local qualifiedLevel3 = false

        local function checkAndIndex(array, value, attributeValue1, attributeValue2)
            if tes3.mobilePlayer.attributes[attribute1].base >= attributeValue1
            and tes3.mobilePlayer.attributes[attribute2].base >= attributeValue2 then
                for index in ipairs(array) do
                    if array[index] >= value then
                        qualifiedLevel1 = true
                        return
                    end
                end
            end
        end

        local function checkAndIndex2(array, value)
            for index2 in ipairs(array) do
                if array[index2] >= value 
                and qualifiedLevel1 == true 
                and index ~= index2
                then
                    qualifiedLevel2 = true
                    return
                end
            end
        end

        local function checkAndIndex3(array, value)
            for index3 in ipairs(array) do
                if array[index3] >= value 
                and qualifiedLevel2 == true 
                and index2 ~= index3
                and index ~= index3
                then
                    qualifiedLevel3 = true
                    return
                end
            end
        end

        -- Requirements für z. B. "Retainer" bei Hlaalu
        if guildName.playerRank == 0 then
            -- Werte können aus dem Construction Set (mit dem Mod als active file) beim Reiter "Character" - "Faction..." entnommen werden
            checkAndIndex(playerSkillLevels, 30, 40, 40)
            checkAndIndex2(playerSkillLevels, 20)
            checkAndIndex3(playerSkillLevels, 20)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 1 then
            checkAndIndex(playerSkillLevels, 35, 45, 45)
            checkAndIndex2(playerSkillLevels, 25)
            checkAndIndex3(playerSkillLevels, 25)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 
        
        if guildName.playerRank == 2 then
            checkAndIndex(playerSkillLevels, 40, 50, 50)
            checkAndIndex2(playerSkillLevels, 30)
            checkAndIndex3(playerSkillLevels, 30)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 3 then
            checkAndIndex(playerSkillLevels, 50, 55, 55)
            checkAndIndex2(playerSkillLevels, 35)
            checkAndIndex3(playerSkillLevels, 35)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 4 then
            checkAndIndex(playerSkillLevels, 60, 60, 60)
            checkAndIndex2(playerSkillLevels, 40)
            checkAndIndex3(playerSkillLevels, 40)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 5 then
            checkAndIndex(playerSkillLevels, 70, 65, 65)
            checkAndIndex2(playerSkillLevels, 45)
            checkAndIndex3(playerSkillLevels, 45)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 6 then
            checkAndIndex(playerSkillLevels, 80, 70, 70)
            checkAndIndex2(playerSkillLevels, 50)
            checkAndIndex3(playerSkillLevels, 50)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 7 then
            checkAndIndex(playerSkillLevels, 90, 75, 75)
            checkAndIndex2(playerSkillLevels, 60)
            checkAndIndex3(playerSkillLevels, 60)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 8 then
            checkAndIndex(playerSkillLevels, 95, 80, 80)
            checkAndIndex2(playerSkillLevels, 70)
            checkAndIndex3(playerSkillLevels, 70)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 
    end

    -- Der Imperial Cult braucht eine eigene, weil er 7 relevant Skills hat
    -- Bei dieser Version hat er auch die eigene Klasse "Low"
    function advancementCheckImperialCultHFR(
        guildName,
        skill1, skill2, skill3, skill4, skill5, skill6, skill7, 
        attribute1, attribute2)
        -- All die Parameter, die auswechselbar sein müssen

        factionsVariables()

        -- "Array" für die benötigten Skills wird erstellt
        local playerSkillLevels = {}
        playerSkillLevels = {tes3.mobilePlayer.skills[skill1].base, tes3.mobilePlayer.skills[skill2].base, tes3.mobilePlayer.skills[skill3].base, 
                            tes3.mobilePlayer.skills[skill4].base, tes3.mobilePlayer.skills[skill5].base, tes3.mobilePlayer.skills[skill6].base, tes3.mobilePlayer.skills[skill7].base}

        local qualifiedLevel1 = false
        local qualifiedLevel2 = false
        local qualifiedLevel3 = false

        local function checkAndIndex(array, value, attributeValue1, attributeValue2)
            if tes3.mobilePlayer.attributes[attribute1].base >= attributeValue1
            and tes3.mobilePlayer.attributes[attribute2].base >= attributeValue2 then
                for index in ipairs(array) do
                    if array[index] >= value then
                        qualifiedLevel1 = true
                        return
                    end
                end
            end
        end

        local function checkAndIndex2(array, value)
            for index2 in ipairs(array) do
                if array[index2] >= value 
                and qualifiedLevel1 == true 
                and index ~= index2
                then
                    qualifiedLevel2 = true
                    return
                end
            end
        end

        local function checkAndIndex3(array, value)
            for index3 in ipairs(array) do
                if array[index3] >= value 
                and qualifiedLevel2 == true 
                and index2 ~= index3
                and index ~= index3
                then
                    qualifiedLevel3 = true
                    return
                end
            end
        end


        if guildName.playerRank == 0 then
            checkAndIndex(playerSkillLevels, 25, 35, 35)
            checkAndIndex2(playerSkillLevels, 15)
            checkAndIndex3(playerSkillLevels, 15)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 1 then
            checkAndIndex(playerSkillLevels, 30, 40, 40)
            checkAndIndex2(playerSkillLevels, 20)
            checkAndIndex3(playerSkillLevels, 20)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        -- playerRank == 2 bedeutet z. B. Journeyman bei der Figher's Guild zu sein. Somit werden die Anforderungen für den 3. Rang geprüft.
        if guildName.playerRank == 2 then
            -- Hier werden also die Anforderungen für den 3. Rang eingetragen.
            -- Die erste 30 ist das benötigte Skill Level, die beiden danach die benötigten Attribut Levels.
            checkAndIndex(playerSkillLevels, 35, 45, 45)
            -- die 5 ist das benötigte Skill Level für einen zweiten relevanten Skill.
            checkAndIndex2(playerSkillLevels, 25)
            -- die 5 ist das benötigte Skill Level für einen dritten relevanten Skill.
            checkAndIndex3(playerSkillLevels, 25)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 3 then
            checkAndIndex(playerSkillLevels, 40, 50, 50)
            checkAndIndex2(playerSkillLevels, 30)
            checkAndIndex3(playerSkillLevels, 30)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 4 then
            checkAndIndex(playerSkillLevels, 50, 55, 55)
            checkAndIndex2(playerSkillLevels, 40)
            checkAndIndex3(playerSkillLevels, 40)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 5 then
            checkAndIndex(playerSkillLevels, 60, 60, 60)
            checkAndIndex2(playerSkillLevels, 45)
            checkAndIndex3(playerSkillLevels, 45)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 6 then
            checkAndIndex(playerSkillLevels, 70, 65, 65)
            checkAndIndex2(playerSkillLevels, 50)
            checkAndIndex3(playerSkillLevels, 50)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 7 then
            checkAndIndex(playerSkillLevels, 80, 70, 70)
            checkAndIndex2(playerSkillLevels, 60)
            checkAndIndex3(playerSkillLevels, 60)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 8 then
            checkAndIndex(playerSkillLevels, 90, 75, 75)
            checkAndIndex2(playerSkillLevels, 70)
            checkAndIndex3(playerSkillLevels, 70)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        -- if guildName.playerRank == 9 ist nicht nötig, da es ja keinen 10. Rang gibt.
    end

    -- Mod "Higher Faction Requirements"
    -- "High" Standards Script - für die 3 Great Houses
    function advancementCheckHighHFR(
        guildName,
        skill1, skill2, skill3, skill4, skill5, skill6, 
        attribute1, attribute2)
        -- All die Parameter, die auswechselbar sein müssen

        factionsVariables()

        -- "Array" für die benötigten Skills wird erstellt
        local playerSkillLevels = {}
        playerSkillLevels = {tes3.mobilePlayer.skills[skill1].base, tes3.mobilePlayer.skills[skill2].base, tes3.mobilePlayer.skills[skill3].base, 
                            tes3.mobilePlayer.skills[skill4].base, tes3.mobilePlayer.skills[skill5].base, tes3.mobilePlayer.skills[skill6].base}

        local qualifiedLevel1 = false
        local qualifiedLevel2 = false
        local qualifiedLevel3 = false

        local function checkAndIndex(array, value, attributeValue1, attributeValue2)
            if tes3.mobilePlayer.attributes[attribute1].base >= attributeValue1
            and tes3.mobilePlayer.attributes[attribute2].base >= attributeValue2 then
                for index in ipairs(array) do
                    if array[index] >= value then
                        qualifiedLevel1 = true
                        return
                    end
                end
            end
        end

        local function checkAndIndex2(array, value)
            for index2 in ipairs(array) do
                if array[index2] >= value 
                and qualifiedLevel1 == true 
                and index ~= index2
                then
                    qualifiedLevel2 = true
                    return
                end
            end
        end

        local function checkAndIndex3(array, value)
            for index3 in ipairs(array) do
                if array[index3] >= value 
                and qualifiedLevel2 == true 
                and index2 ~= index3
                and index ~= index3
                then
                    qualifiedLevel3 = true
                    return
                end
            end
        end

        -- Requirements für z. B. "Retainer" bei Hlaalu
        if guildName.playerRank == 0 then
            -- Werte können aus dem Construction Set (mit dem Mod als active file) beim Reiter "Character" - "Faction..." entnommen werden
            checkAndIndex(playerSkillLevels, 30, 45, 45)
            checkAndIndex2(playerSkillLevels, 20)
            checkAndIndex3(playerSkillLevels, 20)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 1 then
            checkAndIndex(playerSkillLevels, 35, 50, 50)
            checkAndIndex2(playerSkillLevels, 25)
            checkAndIndex3(playerSkillLevels, 25)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 
        
        if guildName.playerRank == 2 then
            checkAndIndex(playerSkillLevels, 40, 55, 55)
            checkAndIndex2(playerSkillLevels, 30)
            checkAndIndex3(playerSkillLevels, 30)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 3 then
            checkAndIndex(playerSkillLevels, 50, 60, 60)
            checkAndIndex2(playerSkillLevels, 35)
            checkAndIndex3(playerSkillLevels, 35)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 4 then
            checkAndIndex(playerSkillLevels, 60, 65, 65)
            checkAndIndex2(playerSkillLevels, 40)
            checkAndIndex3(playerSkillLevels, 40)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 5 then
            checkAndIndex(playerSkillLevels, 70, 70, 70)
            checkAndIndex2(playerSkillLevels, 50)
            checkAndIndex3(playerSkillLevels, 50)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 6 then
            checkAndIndex(playerSkillLevels, 80, 75, 75)
            checkAndIndex2(playerSkillLevels, 60)
            checkAndIndex3(playerSkillLevels, 60)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 7 then
            checkAndIndex(playerSkillLevels, 90, 80, 80)
            checkAndIndex2(playerSkillLevels, 70)
            checkAndIndex3(playerSkillLevels, 70)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 8 then
            checkAndIndex(playerSkillLevels, 100, 85, 85)
            checkAndIndex2(playerSkillLevels, 80)
            checkAndIndex3(playerSkillLevels, 80)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        -- if guildName.playerRank == 9 ist nicht nötig, da es ja keinen 10. Rang gibt.
    end

    -- "Normal" Standards Script
    function advancementCheckStandardHFR(
        guildName,
        skill1, skill2, skill3, skill4, skill5, skill6, 
        attribute1, attribute2)
        -- All die Parameter, die auswechselbar sein müssen

        factionsVariables()

        -- "Array" für die benötigten Skills wird erstellt
        local playerSkillLevels = {}
        playerSkillLevels = {tes3.mobilePlayer.skills[skill1].base, tes3.mobilePlayer.skills[skill2].base, tes3.mobilePlayer.skills[skill3].base, 
                            tes3.mobilePlayer.skills[skill4].base, tes3.mobilePlayer.skills[skill5].base, tes3.mobilePlayer.skills[skill6].base}

        local qualifiedLevel1 = false
        local qualifiedLevel2 = false
        local qualifiedLevel3 = false

        local function checkAndIndex(array, value, attributeValue1, attributeValue2)
            if tes3.mobilePlayer.attributes[attribute1].base >= attributeValue1
            and tes3.mobilePlayer.attributes[attribute2].base >= attributeValue2 then
                for index in ipairs(array) do
                    if array[index] >= value then
                        qualifiedLevel1 = true
                        return
                    end
                end
            end
        end

        local function checkAndIndex2(array, value)
            for index2 in ipairs(array) do
                if array[index2] >= value 
                and qualifiedLevel1 == true 
                and index ~= index2
                then
                    qualifiedLevel2 = true
                    return
                end
            end
        end

        local function checkAndIndex3(array, value)
            for index3 in ipairs(array) do
                if array[index3] >= value 
                and qualifiedLevel2 == true 
                and index2 ~= index3
                and index ~= index3
                then
                    qualifiedLevel3 = true
                    return
                end
            end
        end

        -- Requirements für z. B. "Retainer" bei Hlaalu
        if guildName.playerRank == 0 then
            -- Werte können aus dem Construction Set (mit dem Mod als active file) beim Reiter "Character" - "Faction..." entnommen werden
            checkAndIndex(playerSkillLevels, 30, 40, 40)
            checkAndIndex2(playerSkillLevels, 20)
            checkAndIndex3(playerSkillLevels, 20)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 1 then
            checkAndIndex(playerSkillLevels, 35, 45, 45)
            checkAndIndex2(playerSkillLevels, 25)
            checkAndIndex3(playerSkillLevels, 25)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 
        
        if guildName.playerRank == 2 then
            checkAndIndex(playerSkillLevels, 40, 50, 50)
            checkAndIndex2(playerSkillLevels, 30)
            checkAndIndex3(playerSkillLevels, 30)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 3 then
            checkAndIndex(playerSkillLevels, 50, 55, 55)
            checkAndIndex2(playerSkillLevels, 35)
            checkAndIndex3(playerSkillLevels, 35)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 4 then
            checkAndIndex(playerSkillLevels, 60, 60, 60)
            checkAndIndex2(playerSkillLevels, 40)
            checkAndIndex3(playerSkillLevels, 40)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 5 then
            checkAndIndex(playerSkillLevels, 70, 65, 65)
            checkAndIndex2(playerSkillLevels, 45)
            checkAndIndex3(playerSkillLevels, 45)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 6 then
            checkAndIndex(playerSkillLevels, 80, 70, 70)
            checkAndIndex2(playerSkillLevels, 50)
            checkAndIndex3(playerSkillLevels, 50)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 7 then
            checkAndIndex(playerSkillLevels, 90, 75, 75)
            checkAndIndex2(playerSkillLevels, 60)
            checkAndIndex3(playerSkillLevels, 60)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 8 then
            checkAndIndex(playerSkillLevels, 95, 80, 80)
            checkAndIndex2(playerSkillLevels, 70)
            checkAndIndex3(playerSkillLevels, 70)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 
    end

    function advancementCheckTempleHFR(
        guildName,
        skill1, skill2, skill3, skill4, skill5, skill6, 
        attribute1, attribute2)
        -- All die Parameter, die auswechselbar sein müssen

        factionsVariables()

        -- "Array" für die benötigten Skills wird erstellt
        local playerSkillLevels = {}
        playerSkillLevels = {tes3.mobilePlayer.skills[skill1].base, tes3.mobilePlayer.skills[skill2].base, tes3.mobilePlayer.skills[skill3].base, 
                            tes3.mobilePlayer.skills[skill4].base, tes3.mobilePlayer.skills[skill5].base, tes3.mobilePlayer.skills[skill6].base}

        local qualifiedLevel1 = false
        local qualifiedLevel2 = false
        local qualifiedLevel3 = false

        local function checkAndIndex(array, value, attributeValue1, attributeValue2)
            if tes3.mobilePlayer.attributes[attribute1].base >= attributeValue1
            and tes3.mobilePlayer.attributes[attribute2].base >= attributeValue2 then
                for index in ipairs(array) do
                    if array[index] >= value then
                        qualifiedLevel1 = true
                        return
                    end
                end
            end
        end

        local function checkAndIndex2(array, value)
            for index2 in ipairs(array) do
                if array[index2] >= value 
                and qualifiedLevel1 == true 
                and index ~= index2
                then
                    qualifiedLevel2 = true
                    return
                end
            end
        end

        local function checkAndIndex3(array, value)
            for index3 in ipairs(array) do
                if array[index3] >= value 
                and qualifiedLevel2 == true 
                and index2 ~= index3
                and index ~= index3
                then
                    qualifiedLevel3 = true
                    return
                end
            end
        end

        -- Requirements für z. B. "Retainer" bei Hlaalu
        if guildName.playerRank == 0 then
            -- Werte können aus dem Construction Set (mit dem Mod als active file) beim Reiter "Character" - "Faction..." entnommen werden
            checkAndIndex(playerSkillLevels, 25, 40, 40)
            checkAndIndex2(playerSkillLevels, 15)
            checkAndIndex3(playerSkillLevels, 15)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 1 then
            checkAndIndex(playerSkillLevels, 30, 45, 45)
            checkAndIndex2(playerSkillLevels, 20)
            checkAndIndex3(playerSkillLevels, 20)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 
        
        if guildName.playerRank == 2 then
            checkAndIndex(playerSkillLevels, 40, 50, 50)
            checkAndIndex2(playerSkillLevels, 30)
            checkAndIndex3(playerSkillLevels, 30)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 3 then
            checkAndIndex(playerSkillLevels, 50, 55, 55)
            checkAndIndex2(playerSkillLevels, 35)
            checkAndIndex3(playerSkillLevels, 35)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 4 then
            checkAndIndex(playerSkillLevels, 60, 60, 60)
            checkAndIndex2(playerSkillLevels, 40)
            checkAndIndex3(playerSkillLevels, 40)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 5 then
            checkAndIndex(playerSkillLevels, 70, 65, 65)
            checkAndIndex2(playerSkillLevels, 50)
            checkAndIndex3(playerSkillLevels, 50)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 6 then
            checkAndIndex(playerSkillLevels, 80, 70, 70)
            checkAndIndex2(playerSkillLevels, 60)
            checkAndIndex3(playerSkillLevels, 60)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 7 then
            checkAndIndex(playerSkillLevels, 90, 80, 80)
            checkAndIndex2(playerSkillLevels, 70)
            checkAndIndex3(playerSkillLevels, 70)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 

        if guildName.playerRank == 8 then
            checkAndIndex(playerSkillLevels, 100, 85, 85)
            checkAndIndex2(playerSkillLevels, 80)
            checkAndIndex3(playerSkillLevels, 80)

            if qualifiedLevel3 == true then
                playerIsQualified = true
                return playerIsQualified
            else
                playerIsQualified = false
                return playerIsQualified
            end
        end 
    end
end

-- 2nd Main function that gets called at every event
function menuEnterCallback(e)
    -- Standard Functions, wenn HFR nicht installiert ist
    if HFRFullInstalled == false and HFRMorrowindOnlyInstalled == false then
        -- Damit die Variablen hier benutzt werden können.
        factionsVariables()
        -- Die Funktion durchführen, wenn der Spieler in der Mages Guild ist und die Nachricht noch nicht angezeigt wurde.
        -- So ist der code effizienter, weil er nicht bei jedem Menu event die Funktionen durchläuft, falls sie schon gezeigt wurden.
        if magesGuild.playerJoined == true and magesGuildShown == false then

            advancementCheckGuilds(magesGuild, 17, 12, 11, 10, 13, 15, 2, 3)
            
            if playerIsQualified == true and magesGuildShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Mages Guild.",
                    buttons = {"OK"},
                    callback = messageButtonPressed, 
                    showInDialog = true, 
                    duration = 15 
                })
                magesGuildShown = true
                return magesGuildShown
            end
        end  

        if fightersGuild.playerJoined == true and fightersGuildShown == false then
            -- Main function wird mit den Parametern der Fighter's Guild aufgerufen.
            -- Dabei sind die ersten 6 Zahlen das value der Skills + 1
            -- und die beiden letzten Zahlen das value der Attribute + 1.
            -- (+1 weil sie zu einem Table gemacht werden, welcher bei 1 und nicht bei 0 beginnt)
            advancementCheckGuilds(fightersGuild, 2, 7, 1, 5, 4, 6, 1, 6)

            if playerIsQualified == true and fightersGuildShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Fighters Guild.",
                    buttons = {"OK"},
                    callback = messageButtonPressed, 
                    showInDialog = true, 
                    duration = 15 
                })
                fightersGuildShown = true
                return fightersGuildShown
            end
        end

        if houseHlaalu.playerJoined == true and houseHlaaluShown == false then
            
            -- Main function wird mit den Parametern des House Hlaalu aufgerufen.
            advancementCheckGuilds(houseHlaalu, 22, 24, 25, 19, 23, 26, 5, 4)
            
            if playerIsQualified == true and houseHlaaluShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Great House Hlaalu.",
                    buttons = {"OK"}, 
                    callback = messageButtonPressed,
                    showInDialog = true, 
                    duration = 15
                })
                houseHlaaluShown = true
                return houseHlaaluShown
            end
        end

        if thievesGuild.playerJoined == true and thievesGuildShown == false then

            advancementCheckGuilds(thievesGuild, 21, 22, 24, 19, 23, 20, 4, 7)
            
            if playerIsQualified == true and thievesGuildShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Thieves Guild.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                thievesGuildShown = true
                return
            end
        end

        if moragTong.playerJoined == true and moragTongShown == false then

            advancementCheckGuilds(moragTong, 21, 13, 24, 22, 23, 20, 5, 4)
            
            if playerIsQualified == true and moragTongShown == false then
                tes3.messageBox({ 
                    message = "You meet the skill and attribute requirements to advance in the Morag Tong.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                moragTongShown = true
                return
            end
        end

        if houseRedoran.playerJoined == true and houseRedoranShown == false then
            
            advancementCheckGuilds(houseRedoran, 2, 9, 4, 6, 3, 8, 6, 1)
            
            if playerIsQualified == true and houseRedoranShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Great House Redoran.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                houseRedoranShown = true
                return
            end
        end


        if houseTelvanni.playerJoined == true and houseTelvanniShown == false then

            advancementCheckGuilds(houseTelvanni, 12, 14, 11, 10, 13, 15, 2, 3)
            
            if playerIsQualified == true and houseTelvanniShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Great House Telvanni.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                houseTelvanniShown = true
                return
            end
        end

        if temple.playerJoined == true and templeShown == false then

            advancementCheckGuilds(temple, 17, 5, 14, 15, 16, 18, 2, 7)
            
            if playerIsQualified == true and templeShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Tribunal Temple.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                templeShown = true
                return
            end
        end

        if imperialLegion.playerJoined == true and imperialLegionShown == false then

            advancementCheckGuilds(imperialLegion, 9, 1, 5, 4, 6, 8, 6, 7)
            
            if playerIsQualified == true and imperialLegionShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Imperial Legion.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                imperialLegionShown = true
                return
            end
        end

        -- Benutzt eine eigene Funktion, weil er 7 relevante Skills hat
        if imperialCult.playerJoined == true and imperialCultShown == false then

            advancementCheckImperialCult(imperialCult, 5, 14, 15, 16, 10, 26, 18, 7, 3)
            
            if playerIsQualified == true and imperialCultShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Imperial Cult.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                imperialCultShown = true
                return
            end
        end

        -- Die Vampire Clans haben auch eine eigene Funktion, da sie andere Requirement Zahlen haben.
        if clanAundae.playerJoined == true and clanAundaeShown == false then
            -- wichtig, dass attribute1 = das linke in der Tabelle ist und attribute2 = das rechte
            advancementCheckVampireClans(clanAundae, 21, 9, 14, 13, 15, 18, 3, 2)
            
            if playerIsQualified == true and clanAundaeShown == false then
                tes3.messageBox({ 
                    message = "You meet the skill and attribute requirements to advance in the Aundae Vampire Clan.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                clanAundaeShown = true
                return
            end
        end

        if clanBerne.playerJoined == true and clanBerneShown == false then

            advancementCheckVampireClans(clanBerne, 21, 9, 24, 23, 20, 18, 3, 5)
            
            if playerIsQualified == true and clanBerneShown == false then
                tes3.messageBox({ 
                    message = "You meet the skill and attribute requirements to advance in the Berne Vampire Clan.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                clanBerneShown = true
                return
            end
        end

        if clanQuarra.playerJoined == true and clanQuarraShown == false then

            advancementCheckVampireClans(clanQuarra, 21, 9, 11, 27, 6, 18, 1, 6)
            
            if playerIsQualified == true and clanQuarraShown == false then
                tes3.messageBox({ 
                    message = "You meet the skill and attribute requirements to advance in the Quarra Vampire Clan.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                clanQuarraShown = true
                return
            end
        end

        if eastEmpire.playerJoined == true and eastEmpireShown == false then

            advancementCheckEastEmpireCompany(eastEmpire, 26, 25, 19, 6, 3, 7, 3)
            
            if playerIsQualified == true and eastEmpireShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the East Empire Company.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                eastEmpireShown = true
                return
            end
        end
    end

    -- Wenn OAAB Brother Junipers Twin Lamps installiert ist
    if OAABtwinLampsInstalled == true then
        if twinLamps.playerJoined == true and twinLampsShown == false then

            advancementCheckTwinLamps(twinLamps, 26, 20, 19, 18, 9, 5, 2)
            
            if playerIsQualified == true and twinLampsShown == false then
                tes3.messageBox({ 
                    message = "You meet the skill and attribute requirements to advance in the Twin Lamps.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                twinLampsShown = true
                return
            end
        end    
    end

    -- Wenn Higher Faction Requirements Full Installiert ist
    -- Benutzt neue Functions, außer für die Vampire Clans
    if HFRFullInstalled == true then
        factionsVariables()
        -- Die Funktion durchführen, wenn der Spieler in der Mages Guild ist und die Nachricht noch nicht angezeigt wurde.
        -- So ist der code effizienter, weil er nicht bei jedem Menu event die Funktionen durchläuft, falls sie schon gezeigt wurden.
        if magesGuild.playerJoined == true and magesGuildShown == false then

            advancementCheckStandardHFR(magesGuild, 17, 12, 11, 10, 13, 15, 2, 3)
            
            if playerIsQualified == true and magesGuildShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Mages Guild.",
                    buttons = {"OK"},
                    callback = messageButtonPressed, 
                    showInDialog = true, 
                    duration = 15 
                })
                magesGuildShown = true
                return magesGuildShown
            end
        end  

        if fightersGuild.playerJoined == true and fightersGuildShown == false then
            -- Main function wird mit den Parametern der Fighter's Guild aufgerufen.
            -- Dabei sind die ersten 6 Zahlen das value der Skills + 1
            -- und die beiden letzten Zahlen das value der Attribute + 1.
            -- (+1 weil sie zu einem Table gemacht werden, welcher bei 1 und nicht bei 0 beginnt)
            advancementCheckStandardHFR(fightersGuild, 2, 7, 1, 5, 4, 6, 1, 6)

            if playerIsQualified == true and fightersGuildShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Fighters Guild.",
                    buttons = {"OK"},
                    callback = messageButtonPressed, 
                    showInDialog = true, 
                    duration = 15 
                })
                fightersGuildShown = true
                return fightersGuildShown
            end
        end

        if thievesGuild.playerJoined == true and thievesGuildShown == false then

            advancementCheckStandardHFR(thievesGuild, 21, 22, 24, 19, 23, 20, 4, 7)
            
            if playerIsQualified == true and thievesGuildShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Thieves Guild.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                thievesGuildShown = true
                return
            end
        end

        if moragTong.playerJoined == true and moragTongShown == false then

            advancementCheckStandardHFR(moragTong, 21, 13, 24, 22, 23, 20, 5, 4)
            
            if playerIsQualified == true and moragTongShown == false then
                tes3.messageBox({ 
                    message = "You meet the skill and attribute requirements to advance in the Morag Tong.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                moragTongShown = true
                return
            end
        end

        -- Die 3 Great Houses benutzen advancementCheckHigh
        if houseHlaalu.playerJoined == true and houseHlaaluShown == false then
            
            -- Main function wird mit den Parametern des House Hlaalu aufgerufen.
            advancementCheckHighHFR(houseHlaalu, 22, 24, 25, 19, 23, 26, 5, 4)
            
            if playerIsQualified == true and houseHlaaluShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Great House Hlaalu.",
                    buttons = {"OK"}, 
                    callback = messageButtonPressed,
                    showInDialog = true, 
                    duration = 15
                })
                houseHlaaluShown = true
                return houseHlaaluShown
            end
        end

        if houseRedoran.playerJoined == true and houseRedoranShown == false then
            
            advancementCheckHighHFR(houseRedoran, 2, 9, 4, 6, 3, 8, 6, 1)
            
            if playerIsQualified == true and houseRedoranShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Great House Redoran.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                houseRedoranShown = true
                return
            end
        end


        if houseTelvanni.playerJoined == true and houseTelvanniShown == false then

            advancementCheckHighHFR(houseTelvanni, 12, 14, 11, 10, 13, 15, 2, 3)
            
            if playerIsQualified == true and houseTelvanniShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Great House Telvanni.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                houseTelvanniShown = true
                return
            end
        end

        if temple.playerJoined == true and templeShown == false then

            advancementCheckTempleHFR(temple, 17, 5, 14, 15, 16, 18, 2, 7)
            
            if playerIsQualified == true and templeShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Tribunal Temple.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                templeShown = true
                return
            end
        end

        if imperialLegion.playerJoined == true and imperialLegionShown == false then

            advancementCheckStandardHFR(imperialLegion, 9, 1, 5, 4, 6, 8, 6, 7)
            
            if playerIsQualified == true and imperialLegionShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Imperial Legion.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                imperialLegionShown = true
                return
            end
        end

        -- Benutzt eine eigene Funktion, weil er 7 relevante Skills hat
        if imperialCult.playerJoined == true and imperialCultShown == false then

            advancementCheckImperialCultHFR(imperialCult, 5, 14, 15, 16, 10, 26, 18, 7, 3)
            
            if playerIsQualified == true and imperialCultShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Imperial Cult.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                imperialCultShown = true
                return
            end
        end

        -- Die Vampire Clans haben auch eine eigene Funktion, da sie andere Requirement Zahlen haben.
        if clanAundae.playerJoined == true and clanAundaeShown == false then
            -- wichtig, dass attribute1 = das linke in der Tabelle ist und attribute2 = das rechte
            advancementCheckVampireClans(clanAundae, 21, 9, 14, 13, 15, 18, 3, 2)
            
            if playerIsQualified == true and clanAundaeShown == false then
                tes3.messageBox({ 
                    message = "You meet the skill and attribute requirements to advance in the Aundae Vampire Clan.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                clanAundaeShown = true
                return
            end
        end

        if clanBerne.playerJoined == true and clanBerneShown == false then

            advancementCheckVampireClans(clanBerne, 21, 9, 24, 23, 20, 18, 3, 5)
            
            if playerIsQualified == true and clanBerneShown == false then
                tes3.messageBox({ 
                    message = "You meet the skill and attribute requirements to advance in the Berne Vampire Clan.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                clanBerneShown = true
                return
            end
        end

        if clanQuarra.playerJoined == true and clanQuarraShown == false then

            advancementCheckVampireClans(clanQuarra, 21, 9, 11, 27, 6, 18, 1, 6)
            
            if playerIsQualified == true and clanQuarraShown == false then
                tes3.messageBox({ 
                    message = "You meet the skill and attribute requirements to advance in the Quarra Vampire Clan.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                clanQuarraShown = true
                return
            end
        end

        if eastEmpire.playerJoined == true and eastEmpireShown == false then

            advancementCheckEastEmpireCompanyHFRFull(eastEmpire, 26, 25, 19, 6, 3, 7, 3)
            
            if playerIsQualified == true and eastEmpireShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the East Empire Company.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                eastEmpireShown = true
                return
            end
        end
    end

    -- Wenn Higher Faction Requirements Full Installiert ist
    -- Benutzt alle HFR Functions außer für East Empire Company
    if HFRMorrowindOnlyInstalled == true then
        factionsVariables()
        -- Die Funktion durchführen, wenn der Spieler in der Mages Guild ist und die Nachricht noch nicht angezeigt wurde.
        -- So ist der code effizienter, weil er nicht bei jedem Menu event die Funktionen durchläuft, falls sie schon gezeigt wurden.
        if magesGuild.playerJoined == true and magesGuildShown == false then

            advancementCheckStandardHFR(magesGuild, 17, 12, 11, 10, 13, 15, 2, 3)
            
            if playerIsQualified == true and magesGuildShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Mages Guild.",
                    buttons = {"OK"},
                    callback = messageButtonPressed, 
                    showInDialog = true, 
                    duration = 15 
                })
                magesGuildShown = true
                return magesGuildShown
            end
        end  

        if fightersGuild.playerJoined == true and fightersGuildShown == false then
            -- Main function wird mit den Parametern der Fighter's Guild aufgerufen.
            -- Dabei sind die ersten 6 Zahlen das value der Skills + 1
            -- und die beiden letzten Zahlen das value der Attribute + 1.
            -- (+1 weil sie zu einem Table gemacht werden, welcher bei 1 und nicht bei 0 beginnt)
            advancementCheckStandardHFR(fightersGuild, 2, 7, 1, 5, 4, 6, 1, 6)

            if playerIsQualified == true and fightersGuildShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Fighters Guild.",
                    buttons = {"OK"},
                    callback = messageButtonPressed, 
                    showInDialog = true, 
                    duration = 15 
                })
                fightersGuildShown = true
                return fightersGuildShown
            end
        end

        if thievesGuild.playerJoined == true and thievesGuildShown == false then

            advancementCheckStandardHFR(thievesGuild, 21, 22, 24, 19, 23, 20, 4, 7)
            
            if playerIsQualified == true and thievesGuildShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Thieves Guild.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                thievesGuildShown = true
                return
            end
        end

        if moragTong.playerJoined == true and moragTongShown == false then

            advancementCheckStandardHFR(moragTong, 21, 13, 24, 22, 23, 20, 5, 4)
            
            if playerIsQualified == true and moragTongShown == false then
                tes3.messageBox({ 
                    message = "You meet the skill and attribute requirements to advance in the Morag Tong.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                moragTongShown = true
                return
            end
        end

        -- Die 3 Great Houses benutzen advancementCheckHigh
        if houseHlaalu.playerJoined == true and houseHlaaluShown == false then
            
            -- Main function wird mit den Parametern des House Hlaalu aufgerufen.
            advancementCheckHighHFR(houseHlaalu, 22, 24, 25, 19, 23, 26, 5, 4)
            
            if playerIsQualified == true and houseHlaaluShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Great House Hlaalu.",
                    buttons = {"OK"}, 
                    callback = messageButtonPressed,
                    showInDialog = true, 
                    duration = 15
                })
                houseHlaaluShown = true
                return houseHlaaluShown
            end
        end

        if houseRedoran.playerJoined == true and houseRedoranShown == false then
            
            advancementCheckHighHFR(houseRedoran, 2, 9, 4, 6, 3, 8, 6, 1)
            
            if playerIsQualified == true and houseRedoranShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Great House Redoran.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                houseRedoranShown = true
                return
            end
        end


        if houseTelvanni.playerJoined == true and houseTelvanniShown == false then

            advancementCheckHighHFR(houseTelvanni, 12, 14, 11, 10, 13, 15, 2, 3)
            
            if playerIsQualified == true and houseTelvanniShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Great House Telvanni.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                houseTelvanniShown = true
                return
            end
        end

        if temple.playerJoined == true and templeShown == false then

            advancementCheckTempleHFR(temple, 17, 5, 14, 15, 16, 18, 2, 7)
            
            if playerIsQualified == true and templeShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Tribunal Temple.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                templeShown = true
                return
            end
        end

        if imperialLegion.playerJoined == true and imperialLegionShown == false then

            advancementCheckStandardHFR(imperialLegion, 9, 1, 5, 4, 6, 8, 6, 7)
            
            if playerIsQualified == true and imperialLegionShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Imperial Legion.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                imperialLegionShown = true
                return
            end
        end

        -- Benutzt eine eigene Funktion, weil er 7 relevante Skills hat
        if imperialCult.playerJoined == true and imperialCultShown == false then

            advancementCheckImperialCultHFR(imperialCult, 5, 14, 15, 16, 10, 26, 18, 7, 3)
            
            if playerIsQualified == true and imperialCultShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the Imperial Cult.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                imperialCultShown = true
                return
            end
        end

        -- Die Vampire Clans haben auch eine eigene Funktion, da sie andere Requirement Zahlen haben.
        if clanAundae.playerJoined == true and clanAundaeShown == false then
            -- wichtig, dass attribute1 = das linke in der Tabelle ist und attribute2 = das rechte
            advancementCheckVampireClans(clanAundae, 21, 9, 14, 13, 15, 18, 3, 2)
            
            if playerIsQualified == true and clanAundaeShown == false then
                tes3.messageBox({ 
                    message = "You meet the skill and attribute requirements to advance in the Aundae Vampire Clan.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                clanAundaeShown = true
                return
            end
        end

        if clanBerne.playerJoined == true and clanBerneShown == false then

            advancementCheckVampireClans(clanBerne, 21, 9, 24, 23, 20, 18, 3, 5)
            
            if playerIsQualified == true and clanBerneShown == false then
                tes3.messageBox({ 
                    message = "You meet the skill and attribute requirements to advance in the Berne Vampire Clan.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                clanBerneShown = true
                return
            end
        end

        if clanQuarra.playerJoined == true and clanQuarraShown == false then

            advancementCheckVampireClans(clanQuarra, 21, 9, 11, 27, 6, 18, 1, 6)
            
            if playerIsQualified == true and clanQuarraShown == false then
                tes3.messageBox({ 
                    message = "You meet the skill and attribute requirements to advance in the Quarra Vampire Clan.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                clanQuarraShown = true
                return
            end
        end

        if eastEmpire.playerJoined == true and eastEmpireShown == false then

            advancementCheckEastEmpireCompany(eastEmpire, 26, 25, 19, 6, 3, 7, 3)
            
            if playerIsQualified == true and eastEmpireShown == false then
                tes3.messageBox({ 
                    message = "Congratulations! You meet the skill and attribute requirements to advance in the East Empire Company.",
                    buttons = {"OK"}, 
                    showInDialog = true, 
                    duration = 15 
                })
                eastEmpireShown = true
                return
            end
        end
    end
end

-- Wenn der Button der messageBox ("OK") gedrückt wird, wird die Funktion erneut aufgerufen.
-- Dies verhindert, dass alle Fenster gleichzeitig angezeigt werden wollen.
-- Nur so wird der nächste Check erneut initiiert.
messageButtonPressed = function(e)
    menuEnterCallback()
end

event.register(tes3.event.menuEnter, menuEnterCallback)



-- Damit sich die Funktion oben nochmal durchläuft, wenn ein neues save game geladen wird.
--- @param e loadEventData
local function loadCallback(e)
    mwse.log("[Advancement Notifications] Loaded.")
    clanAundaeShown = false
    clanBerneShown = false
    clanQuarraShown = false
    fightersGuildShown = false
    houseHlaaluShown = false
    imperialCultShown = false
    imperialLegionShown = false
    magesGuildShown = false
    moragTongShown = false
    houseRedoranShown = false
    houseTelvanniShown = false
    templeShown = false
    thievesGuildShown = false
    twinLampsShown = false
    eastEmpireShown = false
end

event.register(tes3.event.load, loadCallback)


-- Die Funktion auch aufrufen, wenn ein Level Up passiert.
-- Dazu werden auch wieder alle Variablen auf false gesetzt, damit die Nachrichten nochmal auftauchen.
--- @param e levelUpEventData 
local function levelUpCallback(e)
    clanAundaeShown = false
    clanBerneShown = false
    clanQuarraShown = false
    fightersGuildShown = false
    houseHlaaluShown = false
    imperialCultShown = false
    imperialLegionShown = false
    magesGuildShown = false
    moragTongShown = false
    houseRedoranShown = false
    houseTelvanniShown = false
    templeShown = false
    thievesGuildShown = false
    twinLampsShown = false
    eastEmpireShown = false
end

event.register(tes3.event.levelUp, levelUpCallback, {priority = 100})