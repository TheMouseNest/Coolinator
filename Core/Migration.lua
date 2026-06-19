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

local function AddStylev3(group)
  for i = #group.entries, 1, -1 do
    local entry = group.entries[i]
    if entry.kind == "group" then
      AddStylev3(entry)
    elseif entry.kind == "icon" then
      entry.style = "blizzard"
    end
  end
end

local function UseBaseSpellsv4(group)
  for i = #group.entries, 1, -1 do
    local entry = group.entries[i]
    if entry.kind == "group" then
      UseBaseSpellsv4(entry)
    elseif entry.kind == "icon" and entry.resource.kind == "ability" then
      entry.resource.spellID = C_Spell.GetBaseSpell(entry.resource.spellID)
    elseif entry.kind == "icon" and entry.resource.kind == "aura" then
      entry.resource.spellID = C_Spell.GetBaseSpell(entry.resource.spellID)
    end
  end
end

local function Textsv6(group)
  for i = #group.entries, 1, -1 do
    local entry = group.entries[i]
    if entry.kind == "group" then
      Textsv6(entry)
    elseif entry.kind == "icon" then
      entry.showTooltips = true
      entry.texts = {
        cooldown = {
          anchor = {},
          scale = Round(14/12 * 100) / 100,
          color = GetColor("FFFFFF"),
          visible = true,
          showFractions = false,
        },
        count = {
          anchor = {"BOTTOMLEFT", -2, -2},
          scale = Round(11/12 * 100) / 100,
          color = GetColor("FFFFFF"),
          visible = true,
        }
      }
    end
  end
end

local function Textsv7(group)
  for i = #group.entries, 1, -1 do
    local entry = group.entries[i]
    if entry.kind == "group" then
      Textsv7(entry)
    elseif entry.kind == "icon" then
      entry.showTooltips = nil
      entry.texts.keybinding = {
        anchor = {"TOPRIGHT", 18, 18},
        scale = Round(13/12 * 100) / 100,
        color = GetColor("b3b3b3"),
        visible = true,
        widthLimit = 0.8,
      }
      entry.texts.count = {
        anchor = {"BOTTOMRIGHT", 18, -18},
        scale = 1,
        color = GetColor("ffffff"),
        visible = true,
        widthLimit = 0.8,
      }
      entry.texts.cooldown = {
        anchor = {},
        scale = Round(20/12 * 100) / 100,
        color = GetColor("FFFFFF"),
        visible = true,
        showFractions = false,
        widthLimit = 0.9,
      }
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
  if design.version < 3 then
    AddStylev3(design)
    design.version = 3
  end

  if design.version < 5 then
    UseBaseSpellsv4(design)
    design.version = 5
  end

  if design.version < 6 then
    Textsv6(design)
    design.version = 6
  end

  if design.version < 8 then
    Textsv7(design)
    design.version = 8
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
