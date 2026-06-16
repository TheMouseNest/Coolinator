---@class addonTableCoolinator
local addonTable = select(2, ...)

function addonTable.Core.GetSpellFromCDMInfo(info)
  return C_Spell.GetBaseSpell(info.overrideTooltipSpellID or info.overrideSpellID or info.spellID)
end

function addonTable.Core.GetAllAuras()
  local auraTracked = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.TrackedBuff, true)
  local auraBars = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.TrackedBar, true)

  local result = {}

  for _, aura in ipairs(auraTracked) do
    table.insert(result, C_Spell.GetBaseSpell(addonTable.Core.GetSpellFromCDMInfo(C_CooldownViewer.GetCooldownViewerCooldownInfo(aura))))
  end
  for _, aura in ipairs(auraBars) do
    table.insert(result, C_Spell.GetBaseSpell(addonTable.Core.GetSpellFromCDMInfo(C_CooldownViewer.GetCooldownViewerCooldownInfo(aura))))
  end

  return result
end

function addonTable.Core.GetAllAbilities()
  local abilityTracked = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Essential, true)
  local abilityBars = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Utility, true)

  local result = {}
  local seen = {}

  local function AutoIncludeBase(spellID)
    local base = C_Spell.GetBaseSpell(spellID)
    if base then
      seen[base] = true
    end
  end

  local function RecordSeen(info)
    seen[info.overrideSpellID] = true
    AutoIncludeBase(info.overrideSpellID)
    if info.overrideTooltipSpellID then
      seen[info.overrideTooltipSpellID] = true
      AutoIncludeBase(info.overrideTooltipSpellID)
    end
    seen[info.spellID] = true
    AutoIncludeBase(info.spellID)
  end
  for _, ability in ipairs(abilityTracked) do
    local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(ability)
    RecordSeen(info)
    table.insert(result, addonTable.Core.GetSpellFromCDMInfo(info))
  end
  for _, ability in ipairs(abilityBars) do
    local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(ability)
    RecordSeen(info)
    table.insert(result, addonTable.Core.GetSpellFromCDMInfo(info))
  end

  -- Pull in remaing spells from spellbook, just in case Blizzard missed one
  local specID = addonTable.Utilities.GetSpecID()
  local className = UnitClass("player")
  for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
    local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
    if skillLineInfo.name == className or skillLineInfo.specID == specID then
      local offset, numSlots = skillLineInfo.itemIndexOffset, skillLineInfo.numSpellBookItems
      for j = offset+1, offset+numSlots do
        local info = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
        if info.spellID and not info.isPassive then
          local spellID = info.spellID
          local base = C_Spell.GetBaseSpell(spellID)
          if not seen[spellID] and not seen[base] then
            table.insert(result, base or spellID)
          end
          seen[spellID] = true
          if base then
            seen[base] = true
          end
        end
      end
    end
  end

  return result
end

function addonTable.Core.GetAllItems()
  return {
    245897, 245898, 241309, 241308, 241305, 241304, 241307, 241306, 241287, 241286, 241303, 241302, 241301, 241300, 241295, 241294, 241289, 241288, 245900, 245901, 241297, 241296, 241299, 241298, 263974, 241293, 241292, 241339, 241338, 258138
  }
end

function addonTable.Core.GetAllEquipment()
  local result = {}
  for i = 1, 16 do
    table.insert(result, i)
  end
  table.remove(result, 4)
  return result
end
