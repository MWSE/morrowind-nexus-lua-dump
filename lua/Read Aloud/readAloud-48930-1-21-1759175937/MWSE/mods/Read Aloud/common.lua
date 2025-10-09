local author = 'abot, NullCascade'
local modName = 'Read Aloud'
---local modPrefix = author .. '/'.. modName
local modPrefix = modName
local configName = string.gsub(modName, ' ', '_') -- replace spaces with underscores

-- begin tweakables

local defaultConfig = {
volume = 50, -- Speech volume
speedDelta = 0, -- speech delta speed
language = 1, -- default to US English
useOnlyPlayerVoice = true,
readBooksScrolls = 3, -- 0 = Disabled | 1 = Enabled | 2 = Enabled, On Link Click | 3 = Enabled, On Link Click, Automatic
readJournal = 3, -- 0 = Disabled | 1 = Enabled | 2 = Enabled, On Link Click | 3 = Enabled, On Link Click, Last journal entry | 4 = Enabled, On Link Click, Automatic
readLastJournal = true,
readDialogChoice = true,
readDialog = 3, -- 0 = no | 1 = read topic | 2 = read topic and header | 3 = read topic, header, notify | 4 = read topic, header, notify, persuasion/service
readGreeting = true,
readSigns = true,
playerVoiceOnly = true,
keepReadingOnMenuClose = false,
daedricTranslation = true,
readDaedricTranslation = true,
daedricSkill = true,
logLevel = 0, -- 0 = disabled, 1 = low, 2 = medium, 3 ...
stopReadingKey = {
	keyCode = tes3.scanCode.s,
	isShiftDown = false,
	isAltDown = true,
	isControlDown = false,
	},
}
-- end tweakables

local config = mwse.loadConfig(configName, defaultConfig) or {}

local languages = {
[1] = '409', -- English (United States) e.g. Microsoft Zira, Microsoft David, Microsoft Mark
[2] = '809', -- English (United Kingdom) e.g. Microsoft George, Microsoft Hazel
[3] = 'C09', -- English (Australia) e.g. Microsoft James, Microsoft Catherine
[4] = '1009', -- English (Canada) e.g. Microsoft Richard, Microsoft Linda
[5] = '4009', -- English (India) e.g. Microsoft Ravi, Microsoft Heera
[6] = '410', -- Italian e.g. Microsoft Elsa
[7] = 'C0A', -- Spanish
}

local speechParams = {
['argonian'] = { Male = { pitch = -5, speed = -1 }, Female = { pitch = -4, speed = -1 }, },
['breton'] = { Male = { pitch = 4, speed = -1 }, Female = { pitch = 2, speed = -1 }, },
['dark elf'] = { Male = { pitch = -10, speed = 0 }, Female = { pitch = -8, speed = 0 }, },
['high elf'] = { Male = { pitch = 6, speed = -1 }, Female = { pitch = 6, speed = -1 }, },
['imperial'] = { Male = { pitch = 0, speed = -1 }, Female = { pitch = 0, speed = -1 }, },
['khajiit'] = { Male = { pitch = -3, speed = -1 }, Female = { pitch = -2, speed = -1 }, },
['nord'] = { Male = { pitch = -4, speed = -1 }, Female = { pitch = -4, speed = -1 }, },
['orc'] = { Male = { pitch = -2, speed = -1 }, Female = { pitch = -2, speed = -1 }, },
['redguard'] = { Male = { pitch = -8, speed = -1 }, Female = { pitch = -8, speed = 0 }, },
['wood elf'] = { Male = { pitch = 8, speed = -1 }, Female = { pitch = 8, speed = -1 }, },
}

local SAPIwind = require(modPrefix .. '.speech')

local this = {}

function this.getVoices()
	return SAPIwind.getVoices()
end

function this.setVoiceByIndex(i)
	return SAPIwind.setVoiceByIndex(i)
end

function this.getSpeechParamsForReference(reference)
	SAPIwind.volume = config.volume
	local baseObj = reference.baseObject
	local raceLcId = 'imperial'
	local race = baseObj.race
	if race then
		raceLcId = baseObj.race.id:lower()
	end
	local sex = 'Male'
	if baseObj.female then
		sex = 'Female'
	end
	---sex = 'Female' -- just for debugging
	local s = string.format("Gender=%s;Age!=Child;Language=%s", sex, languages[config.language])
	---local s = string.format("Gender=%s;Language=%s", sex, languages[config.language])
	local speedDelta = config.speedDelta
	if speechParams[raceLcId]
	and speechParams[raceLcId][sex] then
		local r = table.copy(speechParams[raceLcId][sex])
		r.tokensRequired = s
		r.speed = r.speed + speedDelta
		return r
	elseif sex then
		if sex == 'Male' then
			return {pitch = -1, speed = speedDelta, tokensRequired = s}
		else
			return {pitch = 1, speed = speedDelta, tokensRequired = s}
		end
	end
	return {pitch = 0, speed = speedDelta, tokensRequired = s}
end

local function setSubstitutions()

-- begin SUBSTITUTIONS
-- note: I've made the table sorted so now things can be declared in order of priority
-- e.g. %name replaced before trying to fix gro- pronunciation /abot

local SPEC = "[!&,:;%.%?%-]"
-- add a missing space after a special punctuation character
SAPIwind.setSubstitution("("..SPEC..")(%a)", "%1 %2")
--[[
-- replace line breaks after a special punctuation character with spacing
["("..SPC..")\r?\n"] = "%1 ",
]]

---local CONSONANT = '[BbCcDdFfGgHhKkLlMmNnPpQqRrSsTtVvXxZz]'
local CONSONANT = '[BbCcDdFfGgHhKkLlMmNnPpQqRrSsVvXxZz]'
---local vowel = '[AaEeIiOoUu]'
local GP2 = "%s-[gG][pP]?([%s%p<%)$])"

local the1st = "%1 the 1st%2"

local subs = {
-- replace <P> tags in e.g. sc_cureblight_ranged
["<[Pp]/?>"] = "\n",

-- replace <BR> tags
["<[Bb][Rr]/?>"] = "\n",

-- 3E 127 --> 3rd Era 127 e.g. BookSkill_Enchant2
["(%d+)[Ee],? ?(%d+)%.?"] = function(digit, year)
	local th
	if digit == '1' then
		th = 'st'
	elseif digit == '2' then
		th = 'nd'
	elseif digit == '3' then
		th = 'rd'
	else
		th = 'th'
	end
	return string.format("%s%s Era %s. ", digit, th, year)
end,

["[cC]'mon"] = "come on",
["[sS]+[hH][hH]+(%W)"] = "shush%1", -- Shhh! --> shush
["(%w+)(%.%.%.)"] = "%1 %2", -- and... --> and ...

["([bB])attlemage"] = "%1attle%-mage",
["[bB]ring([eEiI%p%s$])"] = "bringh%1",

["%]%.?"] = "%] %.", -- force a pause after closed bracket

-- single letter I as roman 1 in titles, II is already recognized as 2
["([Aa]ct )I([%p%s$])"] = "%11%2",
["([Bb]ook )I([%p%s$])"] = "%11%2",
["([Cc]hapter )I([%p%s$])"] = "%11%2",
["([Ss]cene )I([%p%s$])"] = "%11%2",
["([Vv]erse )I([%p%s$])"] = "%11%2",
["([Vv]olume )I([%p%s$])"] = "%11%2",

["%s[Pp]art I([%p%s$])"] = " part 1%1",
["%s[Pp]art II([%p%s$])"] = " part 2%1",
["%s[Pp]art III([%p%s$])"] = " part 3%1",
["%s[Pp]art IV([%p%s$])"] = " part 4%1",
["%s[Pp]art V([%p%s$])"] = " part 5%1",
["%s[Pp]art VI([%p%s$])"] = " part 6%1",
["%s[Pp]art VII([%p%s$])"] = " part 7%1",
["%s[Pp]art VIII([%p%s$])"] = " part 8%1",
["%s[Pp]art IX([%p%s$])"] = " part 9%1",
["%s[Pp]art X([%p%s$])"] = " part 10%1",
["%s[Pp]art XI([%p%s$])"] = " part 11%1",
["%s[Pp]art XII([%p%s$])"] = " part 12%1",
---["%s[Pp]art XIII([%p%s$])"] = " part 13%1",

["([Aa]ntiochus )I([%p%s$])"] = the1st,
["([Cc]assynder )I([%p%s$])"] = the1st,
["([Cc]ephorus )I([%p%s$])"] = the1st,
["([Kk]atariah )I([%p%s$])"] = the1st,
["([Kk]intyra )I([%p%s$])"] = the1st,
["([Ma]Magnus )I([%p%s$])"] = the1st,
["([Pp]elagius )I([%p%s$])"] = the1st,
["([Tt]iber )I([%p%s$])"] = the1st,
["([Uu]riel )I([%p%s$])"] = the1st,

---["%sI([%p$])"] = " the first%1", --- too hard to tell
["([Bb]ook%s)I([%p$])"] = "%1the first%2",
["([Vv]olume%s)I([%p$])"] = "%1the first%2",

["^II%p%s"] = " Second: ",
["^III%p%s"] = " Third: ",
["^IV%p%s"] = " Fourth: ",
["^V%p%s"] = " Fifth%1: ",
["^VI%p%s"] = " Sixth: ",
["^VII%p%s"] = " Seventh: ",
["^VIII%p%s"] = " Eighth: ",
["^IX%p%s"] = " Ninth: ",
["^X%p%s"] = " Tenth: ",
["^XI%p%s"] = " Eleventh: ",
["^XII%p%s"] = " Twelfth: ",
["^XIII%p%s"] = " 13th: ",

["%sII([%p%s$])"] = " the second%1",
["%sIII([%p%s$])"] = " the third%1",
["%sIV([%p%s$])"] = " the fourth%1",
["%sV([%p%s$])"] = " the fifth%1",
["%sVI([%p%s$])"] = " the sixth%1",
["%sVII([%p%s$])"] = " the seventh%1",
["%sVIII([%p%s$])"] = " the eighth%1",
["%sIX([%p%s$])"] = " the ninth%1",
["%sX([%p%s$])"] = " the tenth%1",
["%sXI([%p%s$])"] = " the eleventh%1",
["%sXII([%p%s$])"] = " the twelfth%1",
["%sXIII([%p%s$])"] = " the 13th%1",

-- weird, but some books have lines ending with only \r and no \n.
-- They show fine in the construction set, but sound with no pause
["\r$"] = "\n",

-- replace * in bk_hospitality_papers scroll *Certification of Hospitality*<BR>
["%*(.*)%*<[Bb][Rr]>"] = "%1\n",

-- replace double with single spaces
["%s%s"] = " ",

["^1"..GP2] = " one gold piece%1", -- 1gp, 1g --> 1 gold piece
["[^%d%a]1"..GP2] = " one gold piece%1",
["(%d+)"..GP2] = " %1 gold pieces%2", -- 20gp, 20g --> 20 gold pieces

["[Ee]%-e%-%-?e%-excuse me"] = 'Excuse me',
["^[MmUu]mm?m?(%A)"] = 'hmm%1', -- Mmmm... --> Hmm...
["[Mm]yself"] = 'may self',

-- replace double -- with single -
["%-%-"] = "%-",

["%%%."] = "%%", -- so it does not sound like percent dot

-- replace weird characters
["[\130]"] = ",",
["[\096\145\146]"] = "'",
["[\147\148]"] = '"',
["=="] = "",

-- fix sound of dialog journal ending like: Elone, 'Tell You what'.
["'([^']+)'%."] = "%1%.",

-- 'Hla' -> 'la'
["[hH]([lL][AaEeIiOoUu]%A+)"] = "%1",

-- 'Redguard' --> "Red-guard"
["([rR][eE][dD])([gG][uU][aA][rR][dD])"] = "%1%-%2",

-- "Gra-" --> "Ghraa-"
["([dDgG])([rR][aA])[%-']"] = "%1h%2a%-",
-- "Gro-" --> "Ghro-"
["([dDgG])([rR][oO])[%-']"] = "%1h%2%-",

-- aedra --> aeddra
["(%A[aA][eE])([dD])([rR][aA]%A)"] = "%1%2%2%3",

["[Vv]ol([%s%p])"] = "Volume%1",

-- double vocal in 3 letters e.g. Bal --> Baal
["^("..CONSONANT..")([Aa])([cfhlmqr]%W)"] = "%1%2%2%3",
["([%W])("..CONSONANT..")([Aa])([cfhlmqr]%W)"] = "%1%2%3%3%4",

["([%W])US(%s?)"] = "%1us%2", -- US --> us
["([tT]h)'(%s)"] = "%1e%2", -- th' part --> the part

[" pts"] = " points",
["[Bb]attlemage"] = "Battle mage",
["ethandus"] = "eth-andus",
["[Mm]orrowind's"] = "Morro%-wind's",
["([Tt])hu'um"] = "%1huum",
['scius'] = 'scious',
["%s([Mm][aA][rR])(%p)"] = "%1 %2", -- "Molag Mar." --> "Molag Mar ." else it sounds like "Molag March"

["(%A)[Mm]on([%s%p<$])"] = '%1Monn%2',
["[Sk]yrim([%s%p<$])"] = 'skireem%1',
["[wW]a+it"] = 'wait',
["[sS]igh(%A)"] = 'siigh%1',
["[kK]oal%s"] = 'coal ',
["([%a+]%s)("..CONSONANT..")y("..CONSONANT.."[%A%p<$]?)"] = "%1%2ee%3", -- e.g. Divayth Fyr --> Divayth feer

-- replace 2 or 3 consecutive uppercase letters with lowercase
["(%u%u%u%?)"] = function(s) return string.lower(s) end,

}
-- end SUBSTITUTIONS

	for k, v in pairs(subs) do
		SAPIwind.setSubstitution(k,v)
	end
	SAPIwind.sortSubstitutions()
end

setSubstitutions()

this.author = author
this.modName = modName
this.mcmName = modName
this.modPrefix = modPrefix
this.configName = string.gsub(modName, ' ', '_') -- replace spaces with underscores
this.defaultConfig = defaultConfig
this.config = config

this.playerSpeechParams = {}

return this
