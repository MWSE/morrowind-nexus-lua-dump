local this = {}
this.Feats =this.Feats or {}
this.LearnableFeats =this.LearnableFeats or {}
this.RequirimentFeats =this.RequirimentFeats or {}
this.FeatsDifficulty =this.FeatsDifficulty or {}
function this.removeFromTables(id)
  local availableFeats = tes3.player.data.DnDSeries.AvailableFeats or {}
    for i, data1 in ipairs(availableFeats) do
      if data1.id == id then
       table.remove(availableFeats, i)
       tes3.player.data.DnDSeries.AvailableFeats = availableFeats
      end
    end
    for i, data2 in ipairs(this.LearnableFeats) do
      if data2.id == id then
        table.remove(this.LearnableFeats, i)
      end
    end
    for i, data3 in ipairs(this.RequirimentFeats) do
      if data3.id == id then
        table.remove(this.RequirimentFeats, i)
      end
    end
    for i, data4 in ipairs(this.Feats) do
      if data4.id == id then
        table.remove(this.Feats, i)
      end
    end
    end
return this