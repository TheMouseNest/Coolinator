---@class addonTableCoolinator
local addonTable = select(2, ...)

local function GetColor(rgb, a)
  local color = CreateColorFromRGBHexString(rgb)
  return {r = color.r, g = color.g, b = color.b, a = a}
end

local function GetSpellID(info)
  return info.overrideTooltipSpellID or info.overrideSpellID or info.spellID
end

function addonTable.Core.GetAllAuras()
  local auraTracked = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.TrackedBuff, true)
  local auraBars = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.TrackedBar, true)

  local result = {}

  for _, aura in ipairs(auraTracked) do
    table.insert(result, GetSpellID(C_CooldownViewer.GetCooldownViewerCooldownInfo(aura)))
  end
  for _, aura in ipairs(auraBars) do
    table.insert(result, GetSpellID(C_CooldownViewer.GetCooldownViewerCooldownInfo(aura)))
  end

  return result
end

function addonTable.Core.GetAllAbilities()
  local abilityTracked = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Essential, true)
  local abilityBars = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Utility, true)

  local result = {}

  for _, ability in ipairs(abilityTracked) do
    table.insert(result, GetSpellID(C_CooldownViewer.GetCooldownViewerCooldownInfo(ability)))
  end
  for _, ability in ipairs(abilityBars) do
    table.insert(result, GetSpellID(C_CooldownViewer.GetCooldownViewerCooldownInfo(ability)))
  end

  return result
end

--- Generates default CDM layout for current spec
function addonTable.Core.GenerateDefaultCDMLayout()
  local spellEssential = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Essential, true)
  local spellUtility = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Utility, true)

  local auraTracked = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.TrackedBuff, true)
  local auraBars = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.TrackedBar, true)

  spellEssential = tFilter(spellEssential, function(id) return C_CooldownViewer.GetCooldownViewerCooldownInfo(id).flags ~= Enum.CooldownSetSpellFlags.HideByDefault end, true)
  spellUtility = tFilter(spellUtility, function(id) return C_CooldownViewer.GetCooldownViewerCooldownInfo(id).flags ~= Enum.CooldownSetSpellFlags.HideByDefault end, true)

  auraTracked = tFilter(auraTracked, function(id) return C_CooldownViewer.GetCooldownViewerCooldownInfo(id).flags ~= Enum.CooldownSetSpellFlags.HideByDefault end, true)
  auraBars = tFilter(auraBars, function(id) return C_CooldownViewer.GetCooldownViewerCooldownInfo(id).flags ~= Enum.CooldownSetSpellFlags.HideByDefault end, true)

  local result = {
    kind = "group",
    layout = "vertical",
    anchor = {"BOTTOM", "UIParent", "BOTTOM", 0, 200},
    padding = 0.2,
    alpha = 1,
    scale = 1,
    entries = {
      {
        kind = "group",
        layout = "horizontal",
        direction = "right",
        padding = 0.1,
        alpha = 1,
        scale = 1,
        entries = {},
      },
      {
        kind = "group",
        layout = "horizontal",
        direction = "right",
        padding = 0.1,
        alpha = 1,
        scale = 1,
        entries = {},
      },
      {
        kind = "group",
        layout = "horizontal",
        direction = "right",
        padding = 0.1,
        alpha = 1,
        scale = 1,
        entries = {},
      },
    }
  }

  for _, id in ipairs(spellUtility) do
    table.insert(result.entries[1].entries, {kind = "icon", resource = {kind = "ability", spellID = GetSpellID(C_CooldownViewer.GetCooldownViewerCooldownInfo(id))}, height = 1, scale = 0.8, alpha = 1})
  end

  for _, id in ipairs(spellEssential) do
    table.insert(result.entries[2].entries, {kind = "icon", resource = {kind = "ability", spellID = GetSpellID(C_CooldownViewer.GetCooldownViewerCooldownInfo(id))}, height = 1, scale = 1.25, alpha = 1})
  end

  for _, id in ipairs(auraTracked) do
    table.insert(result.entries[3].entries, {kind = "icon", resource = {kind = "aura", spellID = GetSpellID(C_CooldownViewer.GetCooldownViewerCooldownInfo(id))}, height = 1, scale = 1, alpha = 1})
  end

  local barGroups = {
    kind = "group",
    layout = "vertical",
    padding = 0.2,
    alpha = 1,
    scale = 1,
    entries = {
    }
  }
  for _, id in ipairs(auraBars) do
    local spellID = GetSpellID(C_CooldownViewer.GetCooldownViewerCooldownInfo(id))
    table.insert(barGroups.entries, {
      kind = "bar",
      resource = {kind = "aura", spellID = spellID},
      width = 1, --0 -- widest of the entries just above or just below in the layout
      height = 1,
      scale = 1.5,
      layout = "horizontal",
      direction = "right",
      icon = {show = true, position = "left"},
      alpha = 1,
      foreground = {
        asset = "Cooli: Fade Bottom",
        color = {r = 0, g = 1, b = 0},
      },
      background = {
        asset = "Cooli: Solid White",
        color = GetColor("94ff21", 0.3),
      },
      border = {
        asset = "Cooli: Blizzard Midnight",
        color = {r = 1, g = 1, b = 1},
      },
    })
  end

  table.insert(result.entries, barGroups)

  --[[table.insert(result.entries, {
    kind = "bar",
    resource = {kind = "class", resource = "icicles"},
    width = 2, --0, -- widest of the entries just above or just below in the layout
    height = 0.65,
    scale = 1.5,
    alpha = 1,
    layout = "horizontal",
    direction = "left",
    icon = {show = true, position = "right"},
    foreground = {
      asset = "Cooli: Fade Right",
      color = {r = 0, g = 0, b = 1},
    },
    background = {
      asset = "Cooli: Solid White",
      color = GetColor("6bcbff", 0.3),
    },
    border = {
      asset = "Platy: Round Thin",
      color = {r = 0, g = 0, b = 0},
    },
  })]]

  return {
    kind = "group",
    layout = "standalone",
    entries = {
      result
    }
  }
end
