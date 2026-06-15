---@class addonTableCoolinator
local addonTable = select(2, ...)

local function GetColor(rgb)
  local color = CreateColorFromRGBHexString(rgb)
  return {r = color.r, g = color.g, b = color.b}
end

local function AddAlignment(group)
  if group.kind == "group" then
    if group.layout ~= "standalone" then
      group.alignment = "CENTER"
    end
    for _, entry in ipairs(group.entries) do
      AddAlignment(entry)
    end
  end
end

function addonTable.Core.RemoveDeadGroups(group)
  for i = #group.entries, 1, -1 do
    local entry = group.entries[i]
    if entry.kind == "group" then
      addonTable.Core.RemoveDeadGroups(entry)
      if #entry.entries == 0 then
        table.remove(group.entries, i)
      end
    end
  end
end

function addonTable.Core.UpgradeDesign(design)
  if not design.version or design.version < 1 then
    AddAlignment(design)
    design.version = 1
  end
  if design.version < 2 then
    addonTable.Core.RemoveDeadGroups(design)
    design.version = 2
  end
end

function addonTable.Core.MigrateSettings()
  addonTable.Core.AutoGenerateLayout()

  for _, specDetails in pairs(addonTable.Config.Get(addonTable.Config.Options.DESIGNS)) do
    for _, design in pairs(specDetails) do
      addonTable.Core.UpgradeDesign(design)
    end
  end
end
