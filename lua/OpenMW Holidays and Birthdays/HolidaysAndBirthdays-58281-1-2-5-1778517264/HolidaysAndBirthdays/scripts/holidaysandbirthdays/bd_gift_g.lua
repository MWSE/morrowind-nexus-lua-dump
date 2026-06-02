local world = require('openmw.world')
local core = require('openmw.core')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local constants = require('scripts.holidaysandbirthdays.constants')
local modInfo = require('scripts.holidaysandbirthdays.modinfo')
local l10n = core.l10n(modInfo.name)

TodaysGiftName = ""

local function getBirthDayGift(actor, year)
	local giftType = constants.bdGiftsMap[math.random(1, 4)]
	local giftList = constants.bdGifts[giftType]
	local giftData = giftList[math.random(1, #giftList)]
	local giftTemplate = nil
	local giftTable = {}
	local giftDraft = nil
	if giftType == "armor_gifts" then
		giftTemplate = types.Armor.record(giftData.ID)
		TodaysGiftName = "A piece of armor: " .. giftTemplate.name
		giftTable = {
			id = "HB_generated_armor_gift_01",
			name = "3E" .. year .. " Well Made" .. giftTemplate.name,
			template = giftTemplate,
			baseArmor = giftTemplate.baseArmor + math.random(5, 12),
			enchantCapacity = giftTemplate.enchantCapacity + math.random(5, 12)
		}
		giftDraft = types.Armor.createRecordDraft(giftTable)
	elseif giftType == "weapon_gifts" then
		giftTemplate = types.Weapon.record(giftData.ID)
		TodaysGiftName = "A weapon: " .. giftTemplate.name
		giftTable = {
			id = "HB_generated_weapon_gift_01",
			name = "3E" .. year .. " Well Made " .. giftTemplate.name,
			template = giftTemplate,
			chopMaxDamage = giftTemplate.chopMaxDamage + math.random(3, 10),
			slashMaxDamage = giftTemplate.slashMaxDamage + math.random(3, 10),
			thrustMaxDamage = giftTemplate.thrustMaxDamage + math.random(3, 10),
			enchantCapacity = giftTemplate.enchantCapacity + math.random(5, 12)
		}
		giftDraft = types.Weapon.createRecordDraft(giftTable)
	elseif giftType == "clothing_gifts" then
		giftTemplate = types.Clothing.record(giftData.ID)
		TodaysGiftName = "Some fine clothing: " .. giftTemplate.name
		giftTable = {
			id = "HB_generated_clothing_gift_01",
			name = "3E" .. year .. " Elegant " .. giftTemplate.name,
			template = giftTemplate,
			enchantCapacity = giftTemplate.enchantCapacity + math.random(5, 12),
		}
		giftDraft = types.Clothing.createRecordDraft(giftTable)
	elseif giftType == "book_gifts" then
		giftTemplate = types.Book.record(giftData.ID)
		TodaysGiftName = "A book! " .. giftTemplate.name
		giftTable = {
			id = "HB_generated_book_gift_01",
			name = "3E" .. year .. " Gifted " .. giftTemplate.name,
			template = giftTemplate
		}
		giftDraft = types.Book.createRecordDraft(giftTable)
	end
	local giftRecord = world.createRecord(giftDraft)
	world.createObject(giftRecord.id):moveInto(types.Actor.inventory(actor))
end

local function getBirthDayNote(actor, year)
	local noteTemplate = types.Book.record('sc_Indie')
	local text = constants.bdNoteTemplate:gsub("{text}", l10n("bd_note_base")):gsub("{chirp}",
		constants.birthdayChirps[math.random(1, #constants.birthdayChirps)]):gsub("{giftName}", TodaysGiftName)
	local noteTable = { id = 'hb_tmp_bk_note_01', name = "Birthday Note 3E" .. year, template = noteTemplate, text = text }
	local noteDraft = types.Book.createRecordDraft(noteTable)
	local newRecord = world.createRecord(noteDraft)
	world.createObject(newRecord.id):moveInto(types.Actor.inventory(actor))
end

local function isItDone()
    local stage = -1
    for _, player in pairs(world.players) do
        stage = types.Player.quests(player)[constants.theStage].stage -- :3
        if stage == 50 then
            local itIsDone = true
            player:sendEvent("holidays_internal_onItIsDone", itIsDone)
        end
    end
end

local checkTimerFn = time.runRepeatedly(isItDone, 60 * time.second, {
    type = time.SimulationTime, -- pauses with game
    initialDelay = 5
})


local function processBirthDayGift(t)
	getBirthDayGift(t.actor, t.year)
	getBirthDayNote(t.actor, t.year)
end

return {
	eventHandlers = {
		holidays_internal_onBirthday = processBirthDayGift,
	},
}
