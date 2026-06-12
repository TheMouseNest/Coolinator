---@class addonTableCoolinator
local addonTable = select(2, ...)

local function GetColor(rgb)
  local color = CreateColorFromRGBHexString(rgb)
  return {r = color.r, g = color.g, b = color.b}
end

local truncateMap = {
  ["NONE"] = "NONE",
  ["LEFT"] = "LAST",
  ["RIGHT"] = "FIRST",
}

function addonTable.Core.UpgradeDesign(design)
end

function addonTable.Core.MigrateSettings()
end
