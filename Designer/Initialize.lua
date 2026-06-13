---@class addonTableCoolinator
local addonTable = select(2, ...)

function addonTable.Designer.GenerateEditable()
  local specID = addonTable.Utilities.GetSpecID()
  local assignments = addonTable.Config.Get(addonTable.Config.Options.DESIGN_ASSIGNMENTS)
  if assignments[specID] and assignments[specID] ~= addonTable.Constants.DefaultName then
    return true
  else
    addonTable.Dialogs.ShowEditBox(addonTable.Locales.CHOOSE_A_NEW_DESIGN_NAME, OKAY, CANCEL, function(text)
      if text == addonTable.Constants.DefaultName then
        addonTable.Dialogs.ShowAcknowledge(addonTable.Locales.INVALID_DESIGN_NAME)
      else
        local designs = addonTable.Config.Get(addonTable.Config.Options.DESIGNS)[specID]
        designs[text] = CopyTable(designs[addonTable.Constants.DefaultName])
        assignments[specID] = text
        addonTable.CallbackRegistry:TriggerEvent("Designer.Open")
      end
    end)
  end
end

function addonTable.Designer.GetCurrent()
  local specID = addonTable.Utilities.GetSpecID()
  local assignments = addonTable.Config.Get(addonTable.Config.Options.DESIGN_ASSIGNMENTS)
  assert(assignments[specID] and assignments[specID] ~= addonTable.Constants.DefaultName)
  local designs = addonTable.Config.Get(addonTable.Config.Options.DESIGNS)
  return designs[specID][assignments[specID]]
end

function addonTable.Designer.GetActiveAuras(design)
  local result = {}
  if design.kind == "group" then
    for _, entry in ipairs(design.entries) do
      Mixin(result, addonTable.Designer.GetActiveAuras(entry))
    end
  elseif design.kind == "bar" and design.resource.kind == "aura" then
    result[design.resource.spellID] = true
  elseif design.kind == "icon" and design.resource.kind == "aura" then
    result[design.resource.spellID] = true
  end

  return result
end

function addonTable.Designer.GetActiveAbilities(design)
  local result = {}
  if design.kind == "group" then
    for _, entry in ipairs(design.entries) do
      Mixin(result, addonTable.Designer.GetActiveAbilities(entry))
    end
  elseif design.kind == "bar" and design.resource.kind == "ability" then
    result[C_Spell.GetBaseSpell(design.resource.spellID)] = true
  elseif design.kind == "icon" and design.resource.kind == "ability" then
    result[C_Spell.GetBaseSpell(design.resource.spellID)] = true
  end
  
  return result
end

function addonTable.Designer.GetAvailableClassResources()
  return addonTable.Constants.ClassResources[addonTable.Utilities.GetSpecID()]
end

function addonTable.Designer.Initialize()
  addonTable.CallbackRegistry:RegisterCallback("Designer.Options", function(_, details)
    addonTable.Designer.GenerateOptionsFromDetails(details)
  end)
end
