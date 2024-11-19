---uiHelper
--- *The Stat Menu:*
---
--- `Various elements can be accessed from the Stat Menu.`
---@class bs_MenuStat
local MenuStat = {}

--- Get the Stat Menu Element
---@return tes3uiElement? StatMenu
function MenuStat:get() return tes3ui.findMenu(tes3ui.registerID("MenuStat")) end

--- Get the first child with this Id/Name
---@param child string|number The Id/Name of the child element
---@return tes3uiElement? childElement
function MenuStat:child(child) return self:get() and self:get():findChild(child) end

--- Check if the Stat Menu is visible
---@return boolean visible
function MenuStat:visible() return self:get() and self:get().visible end

--- Update the Stat Menu layout
function MenuStat:update() return self:get() and self:get():updateLayout() end

--- Get the Skill List Element
---@return tes3uiElement? SkillList
function MenuStat:SkillList() return self:child("MenuStat_scroll_pane"):getContentElement() end

--- Get the Birthsign Element
---@return tes3uiElement?
function MenuStat:Birthsign() return self:child("birth") end

---Get the Reputation Block
---@return tes3uiElement
function MenuStat:RepBlock() return self:child("MenuStat_reputation_name").parent end

---Get the Bounty Block
---@return tes3uiElement
function MenuStat:BountyBlock() return self:child("MenuStat_Bounty_name").parent end


--- Get specific Skill Elements
---@return tes3uiElement? SkillElement

--- Get the Acrobatics Skill Element
function MenuStat:Acrobatics() return self:Skill(tes3.skill.acrobatics) end

--- Get the Alchemy Skill Element
function MenuStat:Alchemy() return self:Skill(tes3.skill.alchemy) end

--- Get the Alteration Skill Element
function MenuStat:Alteration() return self:Skill(tes3.skill.alteration) end

--- Get the Armorer Skill Element
function MenuStat:Armorer() return self:Skill(tes3.skill.armorer) end

--- Get the Athletics Skill Element
function MenuStat:Athletics() return self:Skill(tes3.skill.athletics) end

--- Get the Axe Skill Element
function MenuStat:Axe() return self:Skill(tes3.skill.axe) end

--- Get the Block Skill Element
function MenuStat:Block() return self:Skill(tes3.skill.block) end

--- Get the Blunt Weapon Skill Element
function MenuStat:BluntWeapon() return self:Skill(tes3.skill.bluntWeapon) end

--- Get the Conjuration Skill Element
function MenuStat:Conjuration() return self:Skill(tes3.skill.conjuration) end

--- Get the Destruction Skill Element
function MenuStat:Destruction() return self:Skill(tes3.skill.destruction) end

--- Get the Enchant Skill Element
function MenuStat:Enchant() return self:Skill(tes3.skill.enchant) end

--- Get the Hand to Hand Skill Element
function MenuStat:HandToHand() return self:Skill(tes3.skill.handToHand) end

--- Get the Heavy Armor Skill Element
function MenuStat:HeavyArmor() return self:Skill(tes3.skill.heavyArmor) end

--- Get the Illusion Skill Element
function MenuStat:Illusion() return self:Skill(tes3.skill.illusion) end

--- Get the Light Armor Skill Element
function MenuStat:LightArmor() return self:Skill(tes3.skill.lightArmor) end

--- Get the Long Blade Skill Element
function MenuStat:LongBlade() return self:Skill(tes3.skill.longBlade) end

--- Get the Marksman Skill Element
function MenuStat:Marksman() return self:Skill(tes3.skill.marksman) end

--- Get the Medium Armor Skill Element
function MenuStat:MediumArmor() return self:Skill(tes3.skill.mediumArmor) end

--- Get the Mercantile Skill Element
function MenuStat:Mercantile() return self:Skill(tes3.skill.mercantile) end

--- Get the Mysticism Skill Element
function MenuStat:Mysticism() return self:Skill(tes3.skill.mysticism) end

--- Get the Restoration Skill Element
function MenuStat:Restoration() return self:Skill(tes3.skill.restoration) end

--- Get the Security Skill Element
function MenuStat:Security() return self:Skill(tes3.skill.security) end

--- Get the Short Blade Skill Element
function MenuStat:ShortBlade() return self:Skill(tes3.skill.shortBlade) end

--- Get the Sneak Skill Element
function MenuStat:Sneak() return self:Skill(tes3.skill.sneak) end

--- Get the Spear Skill Element
function MenuStat:Spear() return self:Skill(tes3.skill.spear) end

--- Get the Speechcraft Skill Element
function MenuStat:Speechcraft() return self:Skill(tes3.skill.speechcraft) end

--- Get the Unarmored Skill Element
function MenuStat:Unarmored() return self:Skill(tes3.skill.unarmored) end

--- Get specific Faction Elements
---@return tes3uiElement? FactionElement

--- Get the Ashlanders Faction Element
function MenuStat:Ashlanders() return self:findFaction("Ashlanders") end

--- Get the Blades Faction Element
function MenuStat:Blades() return self:findFaction("Blades") end

--- Get the Camonna Tong Faction Element
function MenuStat:CamonnaTong() return self:findFaction("Camonna Tong") end

--- Get the Census and Excise Faction Element
function MenuStat:CensusAndExcise() return self:findFaction("Census and Excise") end

--- Get the Clan Aundae Faction Element
function MenuStat:ClanAundae() return self:findFaction("Clan Aundae") end

--- Get the Clan Berne Faction Element
function MenuStat:ClanBerne() return self:findFaction("Clan Berne") end

--- Get the Clan Quarra Faction Element
function MenuStat:ClanQuarra() return self:findFaction("Clan Quarra") end

--- Get the East Empire Company Faction Element
function MenuStat:EastEmpireCompany() return self:findFaction("East Empire Company") end

--- Get the Fighters Guild Faction Element
function MenuStat:FightersGuild() return self:findFaction("Fighters Guild") end

--- Get the Hlaalu Faction Element
function MenuStat:Hlaalu() return self:findFaction("Hlaalu") end

--- Get the Imperial Cult Faction Element
function MenuStat:ImperialCult() return self:findFaction("Imperial Cult") end

--- Get the Imperial Knights Faction Element
function MenuStat:ImperialKnights() return self:findFaction("Imperial Knights") end

--- Get the Imperial Legion Faction Element
function MenuStat:ImperialLegion() return self:findFaction("Imperial Legion") end

--- Get the Mages Guild Faction Element
function MenuStat:MagesGuild() return self:findFaction("Mages Guild") end

--- Get the Redoran Faction Element
function MenuStat:Redoran() return self:findFaction("Redoran") end

--- Get the Royal Guard Faction Element
function MenuStat:RoyalGuard() return self:findFaction("Royal Guard") end

--- Get the Sixth House Faction Element
function MenuStat:SixthHouse() return self:findFaction("Sixth House") end

--- Get the T_Cyr_Abecean Trading Company Faction Element
function MenuStat:TCyrAbeceanTradingCompany() return self:findFaction("T_Cyr_AbeceanTradingCompany") end

--- Get the T_Cyr_Fighters Guild Faction Element
function MenuStat:TCyrFightersGuild() return self:findFaction("T_Cyr_FightersGuild") end

--- Get the Temple Faction Element
function MenuStat:Temple() return self:findFaction("Temple") end

--- Get the T_Glb_Archaeological Society Faction Element
function MenuStat:TGlbArchaeologicalSociety() return self:findFaction("T_Glb_ArchaeologicalSociety") end

--- Get the T_Mw_Clan_Baluath Faction Element
function MenuStat:TMwClanBaluath() return self:findFaction("T_Mw_Clan_Baluath") end

--- Get the T_Mw_Clan_Orlukh Faction Element
function MenuStat:TMwClanOrlukh() return self:findFaction("T_Mw_Clan_Orlukh") end

--- Get the T_Mw_HouseDres Faction Element
function MenuStat:TMwHouseDres() return self:findFaction("T_Mw_HouseDres") end

--- Get the T_Mw_HouseIndoril Faction Element
function MenuStat:TMwHouseIndoril() return self:findFaction("T_Mw_HouseIndoril") end

--- Get the T_Mw_Imperial Navy Faction Element
function MenuStat:TMwImperialNavy() return self:findFaction("T_Mw_ImperialNavy") end

--- Get the T_Sky_ClanKhulari Faction Element
function MenuStat:TSkyClanKhulari() return self:findFaction("T_Sky_ClanKhulari") end


---## `Mod: Fist of Azura's Star`
--- Perk List
---@return tes3uiElement
function MenuStat:AzuraPerks() return self:child("bs_AzuraPerks") end

---## `Child 1`
---@param skill tes3.skill
function MenuStat:SkillLabel(skill) return self:Skill(skill).children[1] end
---## `Child 2`
---@param skill tes3.skill
function MenuStat:SkillValue(skill) return self:Skill(skill).children[2] end
---Returns Skills Element:
---@param skill tes3.skill
---@return tes3uiElement? skillElement
function MenuStat:Skill(skill)
  for _, skillElement in ipairs(self:SkillList().children) do
    if skillElement:getPropertyInt("MenuStat_message") == skill then
      return skillElement
    end
  end
end

---Used to Manually Find Faction Element, if its not predefined.
---@param factionID string 
---@return tes3uiElement?
function MenuStat:findFaction(factionID)
  for child in table.traverse(self:SkillList().children) do
      if child.name == "MenuStat_faction_layout" then
          if child:getPropertyObject("MenuStat_message").id == factionID then
              return child
          end
      end
  end
end

return MenuStat