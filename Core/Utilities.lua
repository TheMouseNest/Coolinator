---@class addonTableCoolinator
local addonTable = select(2, ...)

function addonTable.Utilities.Message(text)
  print("|cff96742a" .. addonTable.Locales.COOLINATOR .. "|r: " .. text)
end

function addonTable.Utilities.InitFrameWithMixin(parent, mixin)
  local f = CreateFrame("Frame", nil, parent)
  Mixin(f, mixin)
  f:OnLoad()
  return f
end

do
  local callbacksPending = {}
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("ADDON_LOADED")
  frame:SetScript("OnEvent", function(_, _, addonName)
    if callbacksPending[addonName] then
      for _, cb in ipairs(callbacksPending[addonName]) do
        xpcall(cb, CallErrorHandler)
      end
      callbacksPending[addonName] = nil
    end
  end)

  local AddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded

  -- Necessary because cannot nest EventUtil.ContinueOnAddOnLoaded
  function addonTable.Utilities.OnAddonLoaded(addonName, callback)
    if select(2, AddOnLoaded(addonName)) then
      xpcall(callback, CallErrorHandler)
    else
      callbacksPending[addonName] = callbacksPending[addonName] or {}
      table.insert(callbacksPending[addonName], callback)
    end
  end
end

function addonTable.Utilities.GetSpecID()
  local specIndex = C_SpecializationInfo.GetSpecialization()
  local spec = C_SpecializationInfo.GetSpecializationInfo(specIndex)
  return spec
end

function addonTable.Utilities.PurgeKey(t, k)
  t[k] = nil
  local c = 42
  repeat
    if t[c] == nil then
      t[c] = nil
    end
    c = c + 1
  until issecurevariable(t, k)
end

function addonTable.Utilities.IsSpellKnown(spellID)
  if addonTable.Constants.AurasFromItems[spellID] then
    return spellID
  end
  local mapped = addonTable.State.spellIDMap[spellID]
  if mapped then
    local isKnown = C_CooldownViewer.GetCooldownViewerCooldownInfo(mapped).isKnown
    if isKnown then
      return spellID
    end
  end
  if not C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Player) and not C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet) then
    spellID = addonTable.SpellEquivalence[spellID]
    if not spellID or not C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Player) and not C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet) then
      return nil
    end
  end
  return spellID
end
