---@class addonTableCoolinator
local addonTable = select(2, ...)

-- Needed to prevent multi-selected widgets breaking
local function RecursiveApply(tbl, to)
  for key, val in pairs(tbl) do
    if type(val) == "table" then
      RecursiveApply(val, to[key])
    else
      to[key] = val
    end
  end
end

function addonTable.Core.ApplyPresetToDetails(details)
  local hasAnchor = details.anchor
  RecursiveApply(addonTable.Core.GetPreset(details), details)
  if not hasAnchor and details.kind == "group" then
    details.anchor = nil
  end
end

function addonTable.Core.ApplyPresets(design)
  for _, entry in ipairs(design.entries) do
    local preset = addonTable.Core.GetPreset(entry)
    if preset then
      Mixin(entry, CopyTable(preset))
      if design.layout ~= "standalone" and entry.kind == "group" then
        entry.anchor = nil
      end
    end
    if entry.kind == "group" then
      addonTable.Core.ApplyPresets(entry)
    end
  end
end

function addonTable.Core.SavePreset(label, details, overwrite)
  local presets = addonTable.Config.Get(addonTable.Config.Options.PRESETS)
  local new = CopyTable(details)
  if details.kind == "group" then
    presets[details.kind] = presets[details.kind] or {}
    new.entries = nil
    if overwrite or not presets["group"][label] then
      presets["group"][label] = new
    end
  elseif details.kind == "icon" then
    presets[details.kind] = presets[details.kind] or {}
    presets[details.kind][details.resource.kind] = presets[details.kind][details.resource.kind] or {}
    new.resource = nil
    if overwrite or not presets["icon"][details.resource.kind][label] then
      presets["icon"][details.resource.kind][label] = new
    end
  elseif details.kind == "bar" then
    presets[details.kind] = presets[details.kind] or {}
    presets[details.kind][details.resource.kind] = presets[details.kind][details.resource.kind] or {}
    if details.resource.kind == "aura" or details.resource.kind == "ability" then
      new.resource = nil
      if overwrite or not presets[details.kind][details.resource.kind][label] then
        presets[details.kind][details.resource.kind][label] = new
      end
    elseif details.resource.kind == "class" then
      presets[details.kind][details.resource.kind][details.resource.resource] = presets[details.kind][details.resource.kind][details.resource.resource] or {}
      new.resource = nil
      presets[details.kind][details.resource.kind][details.resource.resource] = new
      if overwrite or not presets[details.kind][details.resource.kind][details.resource.resource][label] then
        presets[details.kind][details.resource.kind][label] = new
      end
    end
  end
end

function addonTable.Core.GetPreset(details)
  if not details.preset then
    return
  end
  local presets = addonTable.Config.Get(addonTable.Config.Options.PRESETS)
  if details.kind == "group" then
    return presets[details.kind][details.preset]
  elseif details.kind == "icon" then
    return presets[details.kind][details.resource.kind][details.preset]
  elseif details.kind == "bar" then
    if details.resource.kind == "aura" or details.resource.kind == "ability" then
      return presets[details.kind][details.resource.kind][details.preset]
    elseif details.resouce.kind == "class" then
      return presets[details.kind][details.resource.kind][details.resource.resource][details.preset]
    end
  end
end

function addonTable.Core.GetApplicablePresets(details)
  local presets = addonTable.Config.Get(addonTable.Config.Options.PRESETS)
  if details.kind == "group" then
    return presets[details.kind] or {}
  elseif details.kind == "icon" then
    return presets[details.kind][details.resource.kind]
  elseif details.kind == "bar" then
    if details.resource.kind == "aura" or details.resource.kind == "ability" then
      return presets[details.kind] and presets[details.kind][details.resource.kind] or {}
    elseif details.resouce.kind == "class" then
      return presets[details.kind] and presets[details.kind][details.resource.kind] and presets[details.kind][details.resource.kind][details.resource.resource] or {}
    end
  end
  return {}
end

function addonTable.Core.GeneratePresetsFromDesign(design, overwrite)
  for _, entry in ipairs(design.entries) do
    if entry.preset then
      addonTable.Core.SavePreset(entry.preset, entry, overwrite)
    end
    if entry.kind == "group" then
      addonTable.Core.GeneratePresetsFromDesign(entry, overwrite)
    end
  end
end

function addonTable.Core.RemovePresetFromDesign(label, details, design)
  for _, entry in ipairs(design.entries) do
    if entry.preset and entry.preset == label then
      if entry.kind == details.kind then
        if entry.kind == "group" then
          entry.preset = nil
        elseif entry.kind == "bar" and entry.resource.kind == details.resource.kind then
          if details.resource.kind == "aura" or details.resource.kind == "ability" then
            entry.preset = nil
          elseif details.resource.kind == "class" and details.resource.resource == entry.resource.resource then
            entry.preset = nil
          end
        elseif entry.kind == "icon" and entry.resource.kind == details.resource.kind then
          entry.preset = nil
        end
      end
    end
    if entry.kind == "group" then
      addonTable.Core.RemovePresetFromDesign(label, details, entry)
    end
  end

  local presets = addonTable.Config.Get(addonTable.Config.Options.PRESETS)
  if details.kind == "group" then
    presets[details.kind][label] = nil
  elseif details.kind == "bar" then
    if details.resource.kind == "aura" or details.resource.kind == "ability" then
      presets[details.kind][details.resource.kind][label] = nil
    elseif details.resource.kind == "class" then
      presets[details.kind][details.resource.kind][details.resource.resource][label] = nil
    end
  elseif details.kind == "icon" then
    presets[details.kind][details.resource.kind][label] = nil
  end
end
