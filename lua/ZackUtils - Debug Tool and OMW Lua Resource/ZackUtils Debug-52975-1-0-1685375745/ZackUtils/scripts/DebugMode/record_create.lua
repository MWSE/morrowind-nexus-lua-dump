local types = require('openmw.types')
local world = require("openmw.world")
local player = nil
local function getPlayer()
    if (player == nil) then
        for i, ref in ipairs(world.activeActors) do
            if (ref.type == types.Player) then
                player = ref
            end
        end
    end
end


local function createPotion(name)
    getPlayer()
    local potion = {
        name = name,
        weight = 0.1,
        value = 10,
        icon = "icons\\m\\tx_potion_exclusive_01.dds",
        model = "o\\contain_de_chest_01.nif"
    }
    local ret = types.Potion.createRecordDraft(potion)
    local record = world.createRecord(ret)
    local item = world.createObject(record.id, 1)
    item:moveInto(types.Actor.inventory(player))
end

local function createMisc(name)
    getPlayer()
    local miscitem = {
        name = name,
        weight = 0.1,
        value = 10,
        icon = "icons\\m\\misc_skull00.tga",
        model = "m\\misc_skull00.nif"
    }
    local ret = types.Miscellaneous.createRecordDraft(miscitem)
    local record = world.createRecord(ret)
    local item = world.createObject(record.id, 1)
    item:moveInto(types.Actor.inventory(player))
end
local function createActivator(name)
    getPlayer()
    local npc = {
        name = name,
        model = "i\\active_port_roth.nif",
        mwscript = "warp_roth"
    }
    local ret = types.Activator.createRecordDraft(npc)
    local record = world.createRecord(ret)
    local object = world.createObject(record.id, 1)
    object:teleport(player.cell.name, player.position)
end
local function createBook(name)
    getPlayer()
    local rec = {
        name = name,
        model = "m\\text_octavo_01.nif",
        icon = "icons\\m\\tx_octavo_01.tga",
        text = '<DIV ALIGN="CENTER"><FONT COLOR="000000" SIZE="3" FACE="Magic Cards"><BR>\n' ..
            'The Anuad Paraphrased<BR><BR>\n' ..
            '<DIV ALIGN="LEFT"><BR><BR>\n' ..
            'The first ones were brothers: Anu and Padomay. They came into the Void, and Time began.<BR>',
        enchant = "",
        enchantCapacity = 1,
        skill = "encshant",
        mwscript = "",
        weight = 1,
        value = 100,
        isScroll = false,
    }
    local ret = types.Book.createRecordDraft(rec)
    local record = world.createRecord(ret)
    local item = world.createObject(record.id, 1)
    item:moveInto(types.Actor.inventory(player))
end
local function createArmor(name)
    getPlayer()
    local rec = {
        name = name,
        model = "a\\A_M_Chitin_Gauntlet_gnd.nif",
        icon = "icons\\a\\tx_chitin_gauntlet.tga",
        enchant = "",
        enchantCapacity = 1,
        type = 9,
        baseArmor = 100,
        health = 100,
        mwscript = "theranaSkirtScript",
        weight = 1,
        value = 100,
    }
    local ret = types.Armor.createRecordDraft(rec)
    local record = world.createRecord(ret)
    local item = world.createObject(record.id, 1)
    item:moveInto(types.Actor.inventory(player))
end
local function createClothing(name, enchant)
    getPlayer()
    if (enchant == nil) then
        enchant = "azura's ring"
    end
    local rec = {
        name = name,
        model = "c\\c_ring_exquisite_1.nif",
        icon = "icons\\c\\tx_ring_exquisite01.tga",
        enchant = enchant,
        enchantCapacity = 100,
        type = types.Clothing.TYPE.Ring,
        mwscript = "theranaSkirtScript",
        weight = 1,
        value = 100,
    }
    local ret = types.Clothing.createRecordDraft(rec)
    local record = world.createRecord(ret)
    local item = world.createObject(record.id, 1)
    item:moveInto(types.Actor.inventory(player))
end
local function createWeapon(name)
    getPlayer()
    local rec = {
        name = name,
        model = "w\\w_iron_dagger.nif",
        icon = "icons\\w\\tx_dagger_iron.tga",
        enchant = "",
        enchantCapacity = 1,
        type = 0,
        speed = 2,
        reach = 1,
        health = 100,
        mwscript = "theranaSkirtScript",
        weight = 1,
        value = 100,
        chopMinDamage = 5,
        chopMaxDamage = 10,
        slashMinDamage = 10,
        slashMaxDamage = 20,
        thrustMinDamage = 20,
        thrustMaxDamage = 30,
    }
    local ret = types.Weapon.createRecordDraft(rec)
    local record = world.createRecord(ret)
    local item = world.createObject(record.id, 1)
    item:moveInto(types.Actor.inventory(player))
end
local function generateRandomString()
    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local randomString = ""
    
    for i = 1, 4 do
      local randomIndex = math.random(#letters)
      local randomLetter = string.sub(letters, randomIndex, randomIndex)
      randomString = randomString .. randomLetter
    end
    
    return randomString
  end
  
local function fullTest()
    math.randomseed(os.time())
createWeapon("Weapon " ..generateRandomString())
createArmor("Armor " ..generateRandomString())
createMisc("Misc " ..generateRandomString())
createPotion("Potion " ..generateRandomString())
createActivator("Activator " ..generateRandomString())
createBook("Book " ..generateRandomString())
createClothing("Clothing " ..generateRandomString())

end
return {
    interfaceName = "CreateTest",
    interface     = {
        version = 1,
        createWeapon = createWeapon,
        createArmor = createArmor,
        createMisc = createMisc,
        createPotion = createPotion,
        createActivator = createActivator,
        createBook = createBook,
        createClothing = createClothing,
        fullTest = fullTest,
    },
}
