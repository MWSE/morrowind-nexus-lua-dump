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
readJournal = 2, -- 0 = Disabled | 1 = Enabled | 2 = Enabled, On Link Click | 3 = Enabled, On Link Click, Automatic
readLastJournal = true,
readDialogChoice = true,
readDialog = 3, -- 0 = no, 1 = read topic, 2 = read topic and header, 3 = read topic, header, notify, 4 = read topic, header, notify, persuasion/service
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

local config = mwse.loadConfig(configName, defaultConfig)

local languages = {
[1] = '409', -- English (United States) e.g. Microsoft Zira, Microsoft David, Microsoft Mark
[2] = '809', -- English (United Kingdom) e.g. Microsoft George, Microsoft Hazel
[3] = 'C09', -- English (Australia) e.g. Microsoft James, Microsoft Catherine
[4] = '1009', -- English (Canada) e.g. Microsoft Richard, Microsoft Linda
[5] = '4009', -- English (India) e.g. Microsoft Ravi, Microsoft Heera
}

local speechParams = {
['argonian'] = { Male = {}, Female = {}, },
['breton'] = { Male = { pitch = 4, speed = -1 }, Female = { pitch = 2, speed = -1 }, },
['dark elf'] = { Male = { pitch = -10, speed = 0 }, Female = { pitch = -8, speed = 0 }, },
['high elf'] = { Male = { pitch = 6, speed = -1 }, Female = { pitch = 6, speed = -1 }, },
['imperial'] = { Male = { pitch = 0, speed = -1 }, Female = { pitch = 0, speed = -1 }, },
['khajiit'] = { Male = {}, Female = {}, },
['nord'] = { Male = { pitch = -4, speed = -1 }, Female = { pitch = -4, speed = -1 }, },
['orc'] = { Male = { pitch = -2, speed = -1 }, Female = { pitch = -2, speed = -1 }, },
['redguard'] = { Male = { pitch = -8, speed = -1 }, Female = { pitch = -8, speed = 0 }, },
['wood elf'] = { Male = { pitch = 8, speed = -1 }, Female = { pitch = 8, speed = -1 }, },
}


local SAPIwind = require(modPrefix .. '.speech')

local this = {}

function this.getSpeechParamsForReference(reference)
	SAPIwind.volume = config.volume
	local baseObj = reference.baseObject
	local race = baseObj.race.id:lower()
	local sex = 'Male'
	if baseObj.female then
		sex = 'Female'
	end
	---sex = 'Female' -- just for debugging
	local s = string.format("Gender=%s;Age!=Child;Language=%s", sex, languages[config.language])
	if speechParams[race]
	and speechParams[race][sex] then
		local r = table.copy(speechParams[race][sex])
		r.tokensRequired = s
		if not (config.speedDelta == 0) then
			r.speed = r.speed + config.speedDelta
		end
		return r
	elseif sex then
		return { tokensRequired = s }
	end
	return {}
end

local function setSubstitutions()

-- begin SUBSTITUTIONS

local SPC = "[!&,%.:;%?]"
-- add a missing space after a special punctuation character
SAPIwind.setSubstitution("("..SPC..")(%a)", "%1 %2")
--[[
-- replace line breaks after a special punctuation character with spacing
["("..SPC..")\r?\n"] = "%1 ",
--]]

local CONSONANT = 'BCDFGHKLMNPQRSTVXZbcdfghklmnpqrstvxz'
---local WOVEL = 'AEIOUaeiou'

local the1st = "%1 the 1st%2"

local subs = {
-- replace <P> tags in e.g. sc_cureblight_ranged
["<[Pp]/?>"] = "\n",

-- 3E 127 --> 3rd Era 127 e.g. BookSkill_Enchant2
["(%d)[Ee],? ?(%d+)%.?"] = function(digit, year)
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

-- single letter I as roman 1 in titles, II is already recognized as 2
["([Aa]ct )I([%p%s$])"] = "%11%2",
["([Bb]ook )I([%p%s$])"] = "%11%2",
["([Cc]hapter )I([%p%s$])"] = "%11%2",
["([Ss]cene )I([%p%s$])"] = "%11%2",
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
["%sII([%p%s$])"] = " the 2nd%1",
["%sIII([%p%s$])"] = " the 3rd%1",
["%sIV([%p%s$])"] = " the 4th%1",
["%sV([%p%s$])"] = " the fifth%1",
["%sVI([%p%s$])"] = " the 6th%1",
["%sVII([%p%s$])"] = " the 7th%1",
["%sVIII([%p%s$])"] = " the eighth%1",
["%sIX([%p%s$])"] = " the ninth%1",
["%sX([%p%s$])"] = " the 10th%1",
["%sXI([%p%s$])"] = " the 11th%1",
["%sXII([%p%s$])"] = " the twelfth%1",
["%sXIII([%p%s$])"] = " the 13th%1",

-- weird, but some books have lines ending with only \r and no \n.
-- They show fine in the construction set, but sound with no pause
["\r$"] = "\n",

-- replace * in bk_hospitality_papers scroll *Certification of Hospitality*<BR>
["%*(.*)%*<[Bb][Rr]>"] = "%1\n",

-- replace double with single spaces
["%s%s"] = " ",

-- replace double -- with single -
["%-%-"] = "%-",

-- replace weird characters
["[\130]"] = ",",
["[\096\145\146]"] = "'",
["[\147\148]"] = '"',
['=='] = '',

-- fix sound of dialog journal ending like: Elone, 'Tell You what'.
["'([^']+)'%."] = "%1%.",

-- 'Hla' -> 'la'
["[hH]([lL][aeiouAEIOU]%A+)"] = "%1",

-- 'Redguard' --> "Red-guard"
["([rR][eE][dD])([gG][uU][aA][rR][dD])"] = "%1-%2",

-- "Gra-" --> "Ghraa-"
["(%A[dDgG])([rR][aA])(%A)"] = "%1h%2a%3",

-- aedra --> aeddra
["(%A[aA][eE])([dD])([rR][aA]%A)"] = "%1%2%2%3",

-- "Gro-" --> "Ghro-"
["(%A[dDgG])([rR][oO])(%A)"] = "%1h%2%3",

["[Vv]ol([%s%p])"] = "Volume%1",

["([%W]?)([Bb]a)(l%s)"] = "%1%2a%3", -- Bal --> Baal
["([%W]?)([Ss]o)(r%s)"] = "%1%2o%3", -- Sor --> Soor
["([%W]?)[Uu][Ss](%s)"] = "%1as%2", -- us --> as

["%D\1%s*[gG][pP]?(%p?)$"] = "one gold piece%1", -- 1gp, 1g --> 1 gold piece
["(%d+)%s*[gG][pP]?(%p?)$"] = "%1 gold pieces%2", -- 20gp, 20g --> 20 gold pieces

["([bB])attlemage"] = "%1attle-mage",
["[Mm]orrowind's"] = "Morro-wind's",
["([Tt])hu'um"] = "%1huum",
["%s(["..CONSONANT.."])y(["..CONSONANT.."])[%s%p$]"] = "%1ee%2",
["%s([Mm][aA][rR])(%p)"] = "%1 %2", -- "Molag Mar." --> "Molag Mar ." else it sounds like "Molag March"
---["[Pp]rocessus"] = "Process-us",
["[Mm]on[%s%p$]"] = 'Monn',
["[Sk]yrim[%s%p]"] = 'skireem',
["[wW]a+it"] = 'wait',

-- replace 3 or 4 consecutive uppercase letters with lowercase
["(%u%u%u%u?)"] = string.lower("%1"),

}
-- end SUBSTITUTIONS

	for k, v in pairs(subs) do
		SAPIwind.setSubstitution(k,v)
	end
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