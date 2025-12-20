local author = 'abot, NullCascade'
local modName = 'Read Aloud'
local modPrefix = modName
local configName = modName:gsub(' ', '_') -- replace spaces with underscores

-- begin tweakables

local defaultConfig = {
volume = 40, -- Speech volume
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
altClickTopic = false,
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
	isControlDown = false
}
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

---@param reference tes3reference
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

local math_floor = math.floor

--- see https://stackoverflow.com/questions/46535491/changing-number-as-a-word-to-the-number-value
local iniw = {
	num = {'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven',
		'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'},
	tens = {'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'},
	bases = {
		{math_floor(1e18), ' quintillion'}, {math_floor(1e15), ' quadrillion'},
		{math_floor(1e12), ' trillion'}, {math_floor(1e9), ' billion'},
		{1000000, ' million'}, {1000, ' thousand'}, {100, ' hundred'}
	}
}

---@param num number|string
local function integerNumberInWords(num)
	-- Returns a string (spelling of integer number n)
	-- n should be from -2^53 to 2^53  (-2^63 < n < 2^63 for integer argument in Lua 5.3)
    local n = tonumber(num)
	if not n then
        return num
    end
	local t = {}
	local table_insert = table.insert
	if n < 0 then
		table_insert(t, 'minus')
	end
	n = math_floor(math.abs(n))
	if n == 0 then
		return 'zero'
	end
	if n >= 1e21 then
		table_insert(t, 'infinity')
	else
		local AND
		for _, base in ipairs(iniw.bases) do
			local value = base[1]
			if n >= value then
				table_insert( t, integerNumberInWords(n / value)..base[2] )
				n, AND = n % value, false or nil
			end
		end
		if n > 0 then
			table_insert(t, AND and 'and') -- a nice pun !
			table_insert(t,
				iniw.num[n]
				or iniw.tens[math_floor(n / 10) - 1]..
					( (n % 10 ~= 0) and '-'..iniw.num[n % 10] or '' )
			)
		end
	end
	return table.concat(t, ' ')
end


local function setSubstitutions()

-- begin SUBSTITUTIONS
-- note: I've made the table sorted so now things can be declared in order of priority
-- e.g. %name replaced before trying to fix gro- pronunciation /abot

local SPEC = "[!,:;%.%?%-&]"
-- add a missing space after a special punctuation character
--[[
-- replace line breaks after a special punctuation character with spacing
["("..SPC..")\r?\n"] = "%1 ",
]]

---local CNSNT = '[BbCcDdFfGgHhKkLlMmNnPpQqRrSsTtVvXxZz]'
local CNSNT = '[BbCcDdFfGgHhKkLlMmNnQqRrSsTtVvXxZz]'

---local vowel = '[AaEeIiOoUu]'
local GP2 = "%s-[gG][pP]?([%s%p<%)$])"

local the1st = "%1 the 1st%2"

local subs = {

{"[Ss]orondar", "Sorondaar"},
{"[tT]?[hH]?[rR]ondar", "Rondaar"},

{"("..SPEC..")(%a)", "%1 %2"},

-- replace <P> tags in e.g. sc_cureblight_ranged
{"<[Pp]/?>", "%.\n"},

-- replace <BR> tags
{"<[Bb][Rr]/?>", "%.\n"},

-- 3E 127 --> 3rd Era 127 e.g. BookSkill_Enchant2
{"(%d+)[Ee],? ?(%d+)%.?", function(digit, year)
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
	return digit..th..' Era '..year
end},

{"_+", "_"}, -- strip long __ to _ (pronounced underscore)
{"[pP]auldron", "paauldron"},
{"[mM]yself", "my self"},
{"[dD]ragonstar", "draagon star"},
{"[dD]ragon", "draagon"},
{"[cC]'mon", "come on"},
{"[sS]+[hH][hH]+(%W)", "shush%1"}, -- Shhh! --> shush
{"(%w+)(%.%.%.)", "%1 %2"}, -- and... --> and ...

{"([bB])attlemage", "%1attle%-mage"},
{"[bB]ring([eEiI%p%s$])", "bringh%1"},

{"%]%.?", "%] %."}, -- force a pause after closed bracket

-- single letter I as roman 1 in titles, II is already recognized as 2
{"([Aa]ct )I([%p%s$])", "%11%2"},
{"([Bb]ook )I([%p%s$])", "%11%2"},
{"([Cc]hapter )I([%p%s$])", "%11%2"},
{"([Ss]cene )I([%p%s$])", "%11%2"},
{"([Vv]erse )I([%p%s$])", "%11%2"},
{"[Vv]ol([%s%p])", "Volume%1"},
{"([Vv]olume )I([%p%s$])", "%11%2"},

{"%s[Pp]art I([%p%s$])", " part 1%1"},
{"%s[Pp]art II([%p%s$])", " part 2%1"},
{"%s[Pp]art III([%p%s$])", " part 3%1"},
{"%s[Pp]art IV([%p%s$])", " part 4%1"},
{"%s[Pp]art V([%p%s$])", " part 5%1"},
{"%s[Pp]art VI([%p%s$])", " part 6%1"},
{"%s[Pp]art VII([%p%s$])", " part 7%1"},
{"%s[Pp]art VIII([%p%s$])", " part 8%1"},
{"%s[Pp]art IX([%p%s$])", " part 9%1"},
{"%s[Pp]art X([%p%s$])", " part 10%1"},
{"%s[Pp]art XI([%p%s$])", " part 11%1"},
{"%s[Pp]art XII([%p%s$])", " part 12%1"},
---{"%s[Pp]art XIII([%p%s$])", " part 13%1"},

{"(I'll%s", "I will "},
{"ETC", " E T C "},

{"([Aa]ntiochus )I([%p%s$])", the1st},
{"([Cc]assynder )I([%p%s$])", the1st},
{"([Cc]ephorus )I([%p%s$])", the1st},
{"([Kk]atariah )I([%p%s$])", the1st},
{"([Kk]intyra )I([%p%s$])", the1st},
{"([Ma]Magnus )I([%p%s$])", the1st},
{"([Pp]elagius )I([%p%s$])", the1st},
{"([Tt]iber )I([%p%s$])", the1st},
{"([Uu]riel )I([%p%s$])", the1st},

{"([Bb]ook%s)I([%.$])", "%1the first%2"},
{"([Vv]olume%s)I([%.$])", "%1the first%2"},
{"^I%.[%s$]", " First: "},
{"^II%p[%s$]", " Second: "},
{"^III%p[%s$]", " Third: "},
{"^IV%p[%s$]", " Fourth: "},
{"^V%p[%s$]", " Fifth%1: "},
{"^VI%p[%s$]", " Sixth: "},
{"^VII%p[%s$]", " Seventh: "},
{"^VIII%p[%s$]", " Eighth: "},
{"^IX%p[%s$]", " Ninth: "},
{"^X%p[%s$]", " Tenth: "},
{"^XI%p[%s$]", " Eleventh: "},
{"^XII%p[%s$]", " Twelfth: "},
{"^XIII%p[%s$]", " 13th: "},

{"%sII([%p%s$])", " the second%1"},
{"%sIII([%p%s$])", " the third%1"},
{"%sIV([%p%s$])", " the fourth%1"},
{"%sV([%p%s$])", " the fifth%1"},
{"%sVI([%p%s$])", " the sixth%1"},
{"%sVII([%p%s$])", " the seventh%1"},
{"%sVIII([%p%s$])", " the eighth%1"},
{"%sIX([%p%s$])", " the ninth%1"},
{"%sX([%p%s$])", " the tenth%1"},
{"%sXI([%p%s$])", " the eleventh%1"},
{"%sXII([%p%s$])", " the twelfth%1"},
{"%sXIII([%p%s$])", " the 13th%1"},

-- weird, but some books have lines ending with only \r and no \n.
-- They show fine in the construction set, but sound with no pause
{"\r$", "%.\n"},

-- replace * in bk_hospitality_papers scroll *Certification of Hospitality*<BR>
{"%*(.*)%*<[Bb][Rr]>", "%1%.\n"},

-- replace double with single spaces
{"%s%s", " "},

{"^1"..GP2, " one gold piece%1"}, -- 1gp, 1g --> 1 gold piece
{"[^%d%a]1"..GP2, " one gold piece%1"},
{"(%d+)"..GP2, function(n, rest)
	return integerNumberInWords(n)..' gold pieces'..rest
end}, -- 20gp, 20g --> 20 gold pieces

{"([%s:;%?&]?)(%d+)([$%s!:;%?&])", function(a, n, b)
	local result = a..integerNumberInWords(n)..b
---mwse.log("---> a = %s n = %s b = %s result = %s", a, n, b, result)
	return result
end}, -- 20gp, 20g --> 20 gold pieces

{"[Ee]%-e%-%-?e%-excuse me", "Excuse me"},
{"^[MmUu]mm?m?(%A)", "hmm%1"}, -- Mmmm... --> Hmm...

-- replace double -- with single -
{"%-%-", "%-"},

{"%%%.", "%%"}, -- so it does not sound like percent dot

-- replace weird characters
{"[\130]", ","},
{"[\096\145\146]", "'"},
{"[\147\148]", '"'},
{"==", ""},

-- fix sound of dialog journal ending like: Elone, 'Tell You what'.
{"'([^']+)'%.", "%1%."},

-- 'Hla' -> 'la'
{"[hH]([lL][AaEeIiOoUu]%A+)", "%1"},

-- 'Redguard' --> "Red-guard"
{"([rR][eE][dD])([gG][uU][aA][rR][dD])", "%1%-%2"},

-- "Gra-" --> "Ghraa-"
{"([dDgG])([rR][aA])[%-']", "%1h%2a%-"},
-- "Gro-" --> "Ghro-"
{"([dDgG])([rR][oO])[%-']", "%1h%2%-"},

-- aedra --> aeddra
{"(%A[aA][eE])([dD])([rR][aA]%A)", "%1%2%2%3"},

-- double vocal in 3 letters e.g. Bal --> Baal
{"^("..CNSNT..")([Aa])([cfhlmqr]%W)", "%1%2%2%3"},
{"([%W])("..CNSNT..")([Aa])([cfhlmqr]%W)", "%1%2%3%3%4"},

{"([%W])US(%s?)", "%1us%2"}, -- US --> us
{"([tT]h)'(%s)", "%1e%2"}, -- th' part --> the part

{" pts", " points"},
{"[Bb]attlemage", "Battle mage"},
{"ethandus", "eth-andus"},
{"[Mm]orrowind's", "Morro%-wind's"},
{"[Mm]orrowind", "Morro%-wind"},
{"wind", "weend"},
{"([Tt])hu'um", "%1huum"},
{"scius", "scious"},
{"%s([Mm][aA][rR])(%p)", "%1 %2"}, -- "Molag Mar." --> "Molag Mar ." else it sounds like "Molag March"

{"(%A)[Mm]on([%s%p<$])", "%1Monn%2"},
{"[Ss]kyrim([%s%p<$])", "skireem%1"},
{"[sS]talhrim([%s%p<$])", "stallhrim%1"},
{"[wW]a+it", 'wait'},
{"[sS]igh(%A)", "siigh%1"},
{"[kK]oal%s", "coal "},
{"([%a+]%s)("..CNSNT..")y("..CNSNT.."[%A%p<$]?)", "%1%2ee%3"}, -- e.g. Divayth Fyr --> Divayth feer
{"[vV][vV]ardenfell", "Vardenfell"},
{"(%d+)x(%s-%w+)", "%1%2"},
{"^[mM]oreso([%s%p])", "more so%1"},
{"moreso([%s%p])", "more so%1"},
{"stoneskin", "stone-skin"},
{"chaurus([%s%p])", "chau-rus%1"},
{"(%s"..CNSNT..")i("..CNSNT.."[%s%p])", "%1ee%2"},
-- replace 2 or 3 consecutive uppercase letters with lowercase
{"(%u%u%u%?)", function(s) return s:lower() end},

}
-- end SUBSTITUTIONS

	for _, v in ipairs(subs) do
		SAPIwind.setSubstitution(v[1],v[2])
	end
end

setSubstitutions()

this.author = author
this.modName = modName
this.mcmName = modName
this.modPrefix = modPrefix
this.configName = modName:gsub(' ', '_')
this.defaultConfig = defaultConfig
this.config = config

this.playerSpeechParams = {}

return this
