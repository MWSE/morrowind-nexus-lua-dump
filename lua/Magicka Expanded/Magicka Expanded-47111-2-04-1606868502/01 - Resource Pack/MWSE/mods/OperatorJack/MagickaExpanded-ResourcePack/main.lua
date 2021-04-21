local pathId = "operatorJackGearAdded"
local sharedContainerId = "OJ_ME_BookContainer"

local merchants = {
  ["simine fralinie"] = sharedContainerId,
  ["jobasha"] = sharedContainerId,
  ["TR_m1_Felisel_Gavos"] = sharedContainerId,
  ["TR_m1_Sevaen_Ondyn"] = sharedContainerId,
  ["TR_m2_Edheldur"] = sharedContainerId,
  ["TR_m1_Cornelius_Arjax"] = sharedContainerId,
  ["dorisa darvel"] = sharedContainerId,
  ["codus callonus"] = sharedContainerId,
}

local function placeContainer(merchant, containerId)
  local container = tes3.createReference{
      object = containerId,
      position = merchant.position:copy(),
      orientation = merchant.orientation:copy(),
      cell = merchant.cell
  }
  tes3.setOwner{ reference = container, owner = merchant}
end

local function onMobileActivated(e)
  local obj = e.reference.baseObject
  local container = merchants[obj.id:lower()]
  if container then
      if e.reference.data[pathId] ~= true then
          e.reference.data[pathId] = true
          placeContainer(e.reference, container)
      end
  end
end
event.register("mobileActivated", onMobileActivated )

local lists = {
  ["OJ_ME_LeveledList_Common"] = {
    "l_b_loot_tomb",
    "l_b_loot_tomb01",
    "l_b_loot_tomb02",
    "l_b_loot_tomb03",
    "random_book_wizard_all"
  },
  ["OJ_ME_LeveledList_Uncommon"] = {
    "l_b_loot_tomb",
    "l_b_loot_tomb01",
    "l_b_loot_tomb02",
    "l_b_loot_tomb03",
    "random_book_wizard_all"
  },
  ["OJ_ME_LeveledList_Rare"] = {
    "l_b_loot_tomb",
    "l_b_loot_tomb01",
    "l_b_loot_tomb02",
    "l_b_loot_tomb03",
  },
  ["OJ_ME_LeveledList_Mythic"] = {
    "l_b_loot_tomb",
    "l_b_loot_tomb01",
    "l_b_loot_tomb02",
    "l_b_loot_tomb03",
  },
}
local function distributeLists()
  for list, listsToAddTo in pairs(lists) do
    for _, listToAddTo in ipairs(listsToAddTo) do
      mwscript.addToLevItem({
        list = listToAddTo,
        item = list,
        level = 1
      })
    end
  end
end
event.register("initialized", distributeLists)