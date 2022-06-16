local core = require('openmw.core')
local ui = require('openmw.ui')
local async = require('openmw.async')
local util = require('openmw.util')
local input = require('openmw.input')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')

local fHD = {"Today is the New Life Festival. This is a celebration of the birth of a new year, and the death of the old one. This is also the summoning day of Clavicus Vile.", "Today is Scour Day! It's a celebration held in High Rock, that was originally a day to clean up after the New Life Festival. Now it's a party of its own.", "Today is Ovank'a! It's a day where the people of the Alik'r Desert offer prayers to Stendarr in hopes of a mild and merciful year.", "Today is Meridia's Summoning Day", "Today is the South Winds Prayer Day! It's a day taken very seriously by all religions of Tamriel. They pray for a good planting season, and citizens with every affliction know in Tamriel flock to services in cities' temples, as free healings are given on this day.", "Today is the Day of Lights! This is celebrated as a holy day by many villages in Hammerfell on the Iliac Bay. It's a very serious holiday, where they pray for good farming and fishing. In the Skyrim city of Dawnstar, little candies are given out to celebrate, however it is not known if these events are related.", "Today is Waking Day! This ancient holiday was started by the people of Yeorth Burrowland to wake the spirits of nature after a long cold winter. Now it's a celebration of the end of winter.", "Today is Mad Pelagius Day! In High Rock this is a mock memorial to the maddest emperor in recent history, Pelagius Septim III! It is also Sheogorath's Summoning day.", "Today is Othroktide! People in Dwynnen celebrate the day when Baron Othrok took Dwynnen from the undead forces who claimed it in the Battle of Wightmoor.", "Today is the Day of Release! People in Glenumbra remember the battle between Aiden Direnni and the Alessian Army in the first era. This day is celebrated with great... vigor.", "Today is the Feast of the Dead! In Skyrim's Windhelm a great feast is held, and during the feast the names of the Five Hundred Companions of Ysgramor are recited.", "Today is Heart's Day! Today the legend of the lovers Polydor and Eloisa is sung to the younger generations. Many inns in various cities offer free rooms for visitors, for if such kindness had been extended to the lovers it would always be springtime in the world. Today is also Sanguine's Summoning Day.", "Today is Perseverance Day! Once it was a solemn memorial day to those killed in battle while resisting the Camoran Usurper. Now, however, it has become quite the party in Ykalon!", "Today is Aduros Nau! Villages in Bantha celebrate the baser urges that come with Springtide on Aduros Nau. While traditions vary from village to village, none of them are overly virtuous.", "Today is Hermaeus Mora's Summoning Day", "Today is the day of First Planting! It's a celebration where the seeds from the autumn harvest are planted. It's also the festival of fresh beginnings, both for crops and for men and mer everywhere. Neighbors are reconciled in their disputes, resolutions are formed, bad habits dropped, and the diseased cured. Clerics often offer free curing services today!", "Today is the Day of Waiting! On this day, settlements in the Dragontail Mountains lock themselves inside as each year on this day a dragon is supposed to come out of the desert and devour the wicked.", "Today is Azura's Summoning Day", "Today is Flower Day! In High Rock children pick the new flowers of spring while older Bretons come out to welcome the season with dancing and singing.", "Today is the Festival of Blades! The people of the Alik'r Desert celebrate the victor of the first Redguard over a race of giant goblins and their god Malooc. The story is considered a myth by many scholars, but it's still a very popular holiday in the desert.", "Today is the day of Gardtide! People in Tamarilyn Point hold a festival to honor Druagaa, the old goddess of flowers. While actual worship of the goddess is all but dead, the celebration is always a great success.", "Today is Peryite's Summoning Day", "Today is the Day of the Dead! In Daggerfall it is believed that the dead rise up on this holiday to wreak vengeance on the living. In 3E 404 King Lysandus' spectre began his haunting on this day.", "Today is the Day of Shame. On the Hammerfell seaside no one leaves their homes. It is believed that a Crimson Ship, filled with victims of the Knahaten Plague who were refused refuge hundreds of years ago, will return on this day.", "Today is the Jester's Festival! On this day troupes of jesters and fools encourage people of all walks of life to celebrate the foolish and absurd. Performers roam the streets and mock the powerful, and towns celebrate with festive pranks and silly games!", "Today is the day of Second Planting! This day is similar to First Planting, but with an emphasis on improvements on the first seeding and the soul. The free clinics of temples are open for the last time this year, offering cures to those suffering from any disease or affliction. Because peace is stressed at this time, battle injuries are healed only at full price.", "Today is Marukh's Day! Certain communities in Skeffington Wood celebrate by comparing themselves to the virtuous prophet Marukth. People pray for the strength to resist temptation. Today is also Namira's Summoning Day.", "Today is the Fire Festival! In Northmoor, High Rock, the people celebrate what started as a pompous display of magic and military strength in ancient days. Today is simply a festival.", "Today is Fishing Day! Bretons who live on the Iliac Bay celebrate the bounty the Bay provides. On this day they tend to make so much noise that the fish are scared away for weeks!", "Today is Drigh R'Zimb! In Abibon-Gora, during the hottest time of the year, Redguards hold a jubilation for the sun Daibethe.", "Today is Hircine's Summoning Day", "Today is the Mid Year Celebration! Temples offer blessings for only half the donation they usually suggest. Some who are blessed feel confident enough to enter dangerous dungeons they are not prepared for, and so this joyous festival has been known to become a day of defeat and tragedy.", "Today is Dancing Day! In Daggerfall the Red Prince Atryck popularized this day in the second era. It's an occasion of great pomp and merriment for all the people of Daggerfall.", "Today is Tibedetha! Also known as 'Tibers Day', the people of Alcaire celebrate Tiber Septim, who was born there.", "Today is the Merchants' Festival! Today every marketplace and equipment store has dropped their prices by at least half! The only one not dropping prices is the Mages Guild. Today is also Vaernima's Summoning Day.", "Today is Divad Etep't! The people of Antiphyllos mourn the death of one of the greatest of the early Reduard heroes, Divant, today.", "Today is Sun's Rest! Today most shops are closed, as most citizens choose to devote this day to relaxation, not commerce or prayer. Temples, taverns, and the Mages Guild are still open however.", "Today is Fiery Night! Today the natives of the Alik'r Desert celebrate the hottest day of the year. It's a lively celebration with a meaning lost in antiquity.", "Today is Maiden Katrica! The people of Ayasofya show their appreciation for the warrior that saved their country. This is their largest party of the year.", "Today is Koomu Alezer'i! Meaning 'We Acknowledge', this holiday has been celebrated in Sentinel for thousands of years. They solemnly thank the gods for their bounty, and pray to be worthy of the graces of the gods.", "Today is the Feast of the Tiger! In the Bantha rainforest they have a great celebration in each village to praise the bountiful harvest!", "Today is Appreciation Day! In the province of Anticlere, the people regard this day as a holy and contemplative day devoted to Mara, their goddess protector.", "Today is Harvest's End! The work of the year is over! The seeding, sowing, and reaping is done! Now is the time to celebrate and enjoy the fruits of the harvest! Taverns offer free drinks all day long!", "Today is Tales and Tallows Day! The older, more superstitious do not speak all day long for fear that the evil spirits of the dead will enter their bodies. The younger enjoy the day but still avoid going out at night, as everyone knows the dead walk tonight.", "Today is Khurat! Every town in the Wrothgarian Mountains celebrates this day as the finest young scholars are accepted into the various priesthoods. Even those without children of age go to pray for wisdom and benevolence of the clergy.", "Today is Riglametha! The people in Lainlyn celebrate the many blessings of their city. Pagents are held on such themes as the Ghraewaj, when the daedra worshippers in Lainlyn were changed to harpies for their blasphemy.", "Today is Children's Day! Originally a memorial day for dozens of Children who were taken from Betony by vampires and never seen again. Now a days it's a celebration of youth.", "Today is Dirij Tereur! In the Alik'r Desert today is a sacred day honoring Frandar Hund, the spiritual leader of the Reguards who led them to Hammerfell.", "Today is Malacath's Summoning Day", "Today is the Witches Festival! On this day ghosts, demons, and evil spirits are mocked. Beggars take to the street to ask for alms, while children ask for festival treats, and people are obliged to provide it to them. Today is also Mephala's Summoning Day.", "Today is Broken Diamonds Day. In Glenpoint the death of Kintyra Septim II is remembered. She was killed by the order of her cousin and usurper Uriel III. It is a silent day of prayer for the wisdom and benevolence of the imperial family of Tamriel.", "Today is Emperor's Day! This is the Emperor's Birthday. In the Imperial City great traveling carnivals entertain the masses, while the arisocracy enjoy the annual Goblin Chase on horseback.", "Today is Boethiah's Summoning Day", "Today is the Serpent's Dance! In Satakalaam the day started as a serious religious holiday dedicated to a snake god. Today it is just a reason for a street festival.", "Today is the Moon Festival! In the Glenumbra Moors Bretons hold the Moon Festival. It's a joyous holiday in honor of Secunda, the goddess of the moon.", "Today is Hel Anseilak! For the people of Pothago, this is the most holy day. Meaning 'Communion with the Saints of the Sword' the day celebrates the rich heritage of the ancient way of Hel Ansei.", "Today is the Warriors Festival! On this day equipment stores and blacksmiths sell weapons at half price! This often leads to untrained boys getting into amateur skirmishes. This is also Mehrunes Dagon's Summoning Day.", "Today is the North Winds Prayer Day! Today the people give thanks to the gods for a good harvest and a mild winter. Temples offer all their services for half the normal donation asked.", "Today is Baranth Do! Meaning 'Goodbye to the Beast of Last Year', this holiday is celebrated in the Alik'r Desert. Pagents featuring demonic representations of the old year are popular today.", "Today is Chil'a! Meaning 'Blessing of the new year', today is both a sacred day and a festival. Archpriests and baroness each consecrate the ashes of the old year in a solemn ceremony, followed by street parades, balls, and tournaments. Today is also Molag Bal's summoning day.", "Today is Saturalia! Once a holiday for the god of debauchery, this day has become a time of gift giving, parties, and parading.", "Today is the Old Life Festival! This is a time where people write messages of remembrance for their dead loved ones, and may occasionally receive an answer from Aetherius. It's a time to reflect on the past year."}

local function seti()
  local t = calendar.formatGameTime('*t')
  if t.day == 1 and t.month == 1 then i = 1
   return i
  elseif t.day == 2 and t.month == 1 then i = 2
   return i
  elseif t.day == 12 and t.month == 1 then i = 3
   return i
  elseif t.day == 13 and t.month == 1 then i = 4
   return i
  elseif t.day == 15 and t.month == 1 then i = 5
   return i
  elseif t.day == 16 and t.month == 1 then i = 6
   return i
  elseif t.day == 18 and t.month == 1 then i = 7
   return i
  elseif t.day == 2 and t.month == 2 then i = 8
   return i
  elseif t.day == 5 and t.month == 2 then i = 9
   return i
  elseif t.day == 8 and t.month == 2 then i = 10
   return i
  elseif t.day == 13 and t.month == 2 then i = 11
   return i
  elseif t.day == 16 and t.month == 2 then i = 12
   return i
  elseif t.day == 27 and t.month == 2 then i = 13
   return i
  elseif t.day == 28 and t.month == 2 then i = 14
   return i
  elseif t.day == 5 and t.month == 3 then i = 15
   return i
  elseif t.day == 7 and t.month == 3 then i = 16
   return i
  elseif t.day == 9 and t.month == 3 then i = 17
   return i
  elseif t.day == 21 and t.month == 3 then i = 18
   return i
  elseif t.day == 25 and t.month == 3 then i = 19
   return i
  elseif t.day == 26 and t.month == 3 then i = 20
   return i
  elseif t.day == 1 and t.month == 4 then i = 21
   return i
  elseif t.day == 9 and t.month == 4 then i = 22
   return i
  elseif t.day == 13 and t.month == 4 then i = 23
   return i
  elseif t.day == 20 and t.month == 4 then i = 24
   return i
  elseif t.day == 28 and t.month == 4 then i = 25
   return i
  elseif t.day == 7 and t.month == 5 then i = 26
   return i
  elseif t.day == 9 and t.month == 5 then i = 27
   return i
  elseif t.day == 20 and t.month == 5 then i = 28
   return i
  elseif t.day == 30 and t.month == 5 then i = 29
   return i
  elseif t.day == 1 and t.month == 6 then i = 30
   return i
  elseif t.day == 5 and t.month == 6 then i = 31
   return i
  elseif t.day == 16 and t.month == 6 then i = 32
   return i
  elseif t.day == 23 and t.month == 6 then i = 33
   return i
  elseif t.day == 24 and t.month == 6 then i = 34
   return i
  elseif t.day == 10 and t.month == 7 then i = 35
   return i
  elseif t.day == 12 and t.month == 7 then i = 36
   return i
  elseif t.day == 20 and t.month == 7 then i = 37
   return i
  elseif t.day == 29 and t.month == 7 then i = 38
   return i
  elseif t.day == 2 and t.month == 8 then i = 39
   return i
  elseif t.day == 11 and t.month == 8 then i = 40
   return i
  elseif t.day == 14 and t.month == 8 then i = 40
   return i
  elseif t.day == 21 and t.month == 8 then i = 42
   return i
  elseif t.day == 27 and t.month == 8 then i = 43
   return i
  elseif t.day == 3 and t.month == 9 then i = 44
   return i
  elseif t.day == 6 and t.month == 9 then i = 45
   return i  
  elseif t.day == 12 and t.month == 9 then i = 46
   return i
  elseif t.day == 19 and t.month == 9 then i = 47
   return i
  elseif t.day == 5 and t.month == 10 then i = 48
   return i
  elseif t.day == 8 and t.month == 10 then i = 49
   return i
  elseif t.day == 13 and t.month == 10 then i = 50
   return i   
  elseif t.day == 23 and t.month == 10 then i = 51
   return i
  elseif t.day == 30 and t.month == 10 then i = 52
   return i
  elseif t.day == 2 and t.month == 11 then i = 53
   return i
  elseif t.day == 3 and t.month == 11 then i = 54
   return i
  elseif t.day == 8 and t.month == 11 then i = 55
   return i
  elseif t.day == 18 and t.month == 11 then i = 56
   return i
  elseif t.day == 20 and t.month == 11 then i = 57
   return i
  elseif t.day == 15 and t.month == 12 then i = 58
   return i
  elseif t.day == 18 and t.month == 12 then i = 59
   return i
  elseif t.day == 24 and t.month == 12 then i = 60
   return i
  elseif t.day == 25 and t.month == 12 then i = 61
   return i
  elseif t.day == 31 and t.month == 12 then i = 62
   return i                                          
  else i = 0
   return i
  end
end

i = seti()


local function HdayU()
  if i >= 1 then
  ui.showMessage(fHD[i])
  end
end


local timer = nil
local hday = nil
local function startUpdating()   
  timer = time.runRepeatedly(seti, 1 * time.minute, { type = time.GameTime})   
  hday = time.runRepeatedly(HdayU, 1 * time.day, { type = time.GameTime})
end

startUpdating()

return {
  engineHandlers = {  
   onKeyPress = function(key)
    if key.code == input.KEY.H then
      ui.showMessage(fHD[i])
      end
  end,  
    }
}

