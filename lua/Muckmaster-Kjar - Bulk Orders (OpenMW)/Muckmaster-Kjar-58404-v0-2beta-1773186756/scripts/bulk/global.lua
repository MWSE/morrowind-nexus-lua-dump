local core                      = require('openmw.core')
local store                     = require('openmw.storage')
local types                     = require('openmw.types')
local util                      = require 'openmw.util'
local world                     = require('openmw.world')
local I                         = require('openmw.interfaces')
local calendar                  = require('openmw_aux.calendar')
local time                      = require('openmw_aux.time')

local CreateBookDraft = types.Book.createRecordDraft

local function getId(thing)
  local idType, recordId = type(thing)

  if idType == 'string' then
    recordId = thing
  else
    local dataType = thing.__type.name

    if dataType == 'ESM::Weapon' then
      recordId = thing.id
    elseif dataType == 'MWLua::GObject' then
      recordId = thing.recordId
    else
      error('Wtf is this: ' .. thing.__type.name)
    end
  end

  return recordId
end

local typesList = {
  types.Apparatus,
  types.Armor,
  types.Book,
  types.Clothing,
  types.Ingredient,
  types.Light,
  types.Lockpick,
  types.Miscellaneous,
  types.Potion,
  types.Probe,
  types.Repair,
  types.Weapon,
}

local function getRecord(id)
  for _,t in pairs(typesList) do
    if t.records and t.records[id] then
      return t.records[id]
    end
  end
end

local function getOrCreateObject(actor, recordOrId, amt)
  local inv = actor.type.inventory(actor)
  local recordId = recordOrId
  for i=1,amt,1 do 
    local newObj = world.createObject(recordId, 1)
    newObj:moveInto(inv)
  end
end

local function fillInvoice(data)

  local player, items, invoice = data.self, data.items, data.invoice
  
  local record = types.Book.record(invoice)
  
  local draft = {
      template = record,
      text = record.text .. "\nFILLED" .. "<BR>",
      name = "FILLED - " .. record.name ,
  }
  draft = CreateBookDraft(draft)
  
  local id = world.createRecord(draft).id
  
  getOrCreateObject(player, id, 1)
  
  invoice:remove(1)
  
  for k,v in pairs(items) do
  
    local id = getRecord(k)
    
    getOrCreateObject(player, k, v)
  end
end

local function payGold(data)
  local gold, price = data.gold, data.price

  gold:remove(price)
end

local function createInvoice(data)

  local player, trader, items = data.self, data.trader, data.items  
  
  local traderName = types.NPC.records[trader].name
  local playerName = types.NPC.record(player).name
  
  local gameTime = calendar.gameTime()
  
  local newTime = calendar.gameTime() + ( math.random(1 * time.day, 3 * time.day))
  
  local gameTimeFormat = calendar.formatGameTime("%d/%m/%Y", gameTime)
  
  local newTimeFormat = calendar.formatGameTime("%H:%M %d/%m/%Y", newTime)

  local bookTemplate = types.Book.records["bk_bib_note_template"]
  
  local bookText = "<DIV ALIGN=\"LEFT\"><FONT COLOR=\"000000\" SIZE=\"3\" FACE=\"Magic Cards\"><BR>"
  
  local bookHeader = "Merchant Invoice\n\nSeller: " .. traderName .. "\nBuyer: " .. playerName .. "\nDate: " .. gameTimeFormat .. "\nTo be received on: " .. newTimeFormat .. "\n\nItems Received:\n"
  
  local bookItems = ""
  
  for k,v in pairs(items) do
  
    local name = getRecord(k).name
  
    bookItems = bookItems .. " - " .. name .. " x " .. v .. "\n"
  end
  
  local bookFooter = "\n\nThis invoice is stamped and signed\n\n\n"
  
  local bookData = "### mnemospore data ###>\n"
  
  bookData = bookData .. newTime .. ":"
  
  for k,v in pairs(items) do 
     bookData = bookData .. k .. "," .. v .. ":"
  end
  
  local bookEnd = "<BR>"
  
  bookText = bookText .. bookHeader .. bookItems .. bookFooter .. bookData .. bookEnd
  
  bookName = "Merchant Invoice, " .. traderName .. ", " .. gameTimeFormat
  
  local draft = {
      template = bookTemplate,
      text = bookText,
      name = bookName,
  }
  draft = CreateBookDraft(draft)
  
  local id = world.createRecord(draft).id
  
  getOrCreateObject(player, id, 1)
end

return {
  engineHandlers = {
  },
  eventHandlers = {
    BIB_CreateInvoice = createInvoice,
    BIB_FillInvoice = fillInvoice,
    BIB_PayGold = payGold
  },
}