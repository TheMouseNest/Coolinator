---@class addonTableCoolinator
local addonTable = select(2, ...)

local function GetVisibleAurasOrdered(layout, mapping)
  local activeBars = {}
  for _, group in ipairs(layout.entries) do
    if group.kind == "bar" then
      if group.resource.kind == "aura" then
        if mapping[group.resource.spellID] then
          table.insert(activeBars, mapping[group.resource.spellID])
        end
      end
    elseif group.kind == "group" then
      local newActiveBars = GetVisibleAurasOrdered(group, mapping)
      tAppendAll(activeBars, newActiveBars)
    end
  end

  return activeBars
end

local cooldownCategories = {
	Enum.CooldownViewerCategory.Essential,
	Enum.CooldownViewerCategory.Utility,
	Enum.CooldownViewerCategory.TrackedBuff,
	Enum.CooldownViewerCategory.TrackedBar,
};

local SAVE_FIELD_ID_ACTIVE_LAYOUT_NAMES = 2;
local SAVE_FIELD_ID_LAYOUTS = 3;
local SAVE_FIELD_ID_LAYOUT_ID_DATA = 4;

local SAVE_FIELD_ID_COOLDOWN_ORDER = 1;
local SAVE_FIELD_ID_CATEGORY_OVERRIDES = 2;
local SAVE_FIELD_ID_ALERT_OVERRIDES = 3;

function addonTable.Core.GetCDMData(doNotTryAgain)
  local tag = CooldownViewerUtil.GetCurrentClassAndSpecTag()
  local raw = C_CooldownViewer.GetLayoutData()
  raw = raw:match("^%d%|(.*)$")
  if raw then
    local cdmData = C_EncodingUtil.DeserializeCBOR(C_EncodingUtil.DecompressString(C_EncodingUtil.DecodeBase64(raw), Enum.CompressionMethod.Deflate))
    if cdmData[1] < 4 then
      CooldownViewerSettings.dataSerialization:WriteData()
      if not doNotTryAgain then
        return addonTable.Core.GetCDMData(true)
      end
    end
    assert(cdmData[1] == 4, "Layout has changed, contact developer - " .. tostring(cdmData[1]))

    return cdmData, tag
  end

  return nil, tag
end

function addonTable.Core.GetCDMLayoutName()
  return "Coolinator (" .. CooldownViewerUtil.GetCurrentClassAndSpecTag() .. ")"
end

function addonTable.Core.ApplyLayoutToCDM(layout)
  local auraMapping = addonTable.Core.GetCDMMapping()
  local activeBars = GetVisibleAurasOrdered(layout, auraMapping)

  local cd1 = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Essential, true)
  local cd2 = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Utility, true)

  local part1 = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.TrackedBuff, true)
  local part2 = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.TrackedBar, true)

  local auras = {}
  tAppendAll(auras, part1)
  tAppendAll(auras, part2)
  local bars = {}

  for _, cdmID in ipairs(activeBars) do
    local index = tIndexOf(auras, cdmID)
    if index then
      table.remove(auras, index)
      table.insert(bars, cdmID)
    end
  end

  local abilitySpells = {}
  tAppendAll(abilitySpells, cd1)
  tAppendAll(abilitySpells, cd2)

  local compiledLayout = {
    [SAVE_FIELD_ID_COOLDOWN_ORDER] = nil,
    [SAVE_FIELD_ID_CATEGORY_OVERRIDES] = {
      [Enum.CooldownViewerCategory.TrackedBuff] = #auras > 0 and auras or nil,
      [Enum.CooldownViewerCategory.TrackedBar] = #bars > 0 and bars or nil,
      [Enum.CooldownViewerCategory.Essential] = abilitySpells,
    },
  }

  local emptyData = {
    [1] = 4,
    [2] = {},
    [3] = {},
    [4] = {},
  }

  local saved, wantedTag = addonTable.Core.GetCDMData()
  local cdmData = saved or emptyData

  assert(cdmData[1] == 4, "Layout format changed, contact developer")

  for key, value in pairs(emptyData) do
    if cdmData[key] == nil then
      cdmData[key] = value
    end
  end

  local layoutName = addonTable.Core.GetCDMLayoutName()

  local foundID
  for id, tag in pairs(cdmData[SAVE_FIELD_ID_LAYOUT_ID_DATA]) do
    if tag == layoutName then
      foundID = id
    end
  end
  if foundID then
    compiledLayout[SAVE_FIELD_ID_ALERT_OVERRIDES] = cdmData[SAVE_FIELD_ID_LAYOUTS][wantedTag][foundID][SAVE_FIELD_ID_ALERT_OVERRIDES]
  end
  if not foundID then
    foundID = 1
    while cdmData[SAVE_FIELD_ID_LAYOUT_ID_DATA][foundID] do
      foundID = foundID + 1
    end
  end

  if cdmData[SAVE_FIELD_ID_LAYOUTS][wantedTag] == nil then
    cdmData[SAVE_FIELD_ID_LAYOUTS][wantedTag] = {}
  end
  cdmData[SAVE_FIELD_ID_LAYOUTS][wantedTag][foundID] = compiledLayout
  cdmData[SAVE_FIELD_ID_LAYOUT_ID_DATA][foundID] = layoutName

  if cdmData[SAVE_FIELD_ID_ACTIVE_LAYOUT_NAMES] == nil then
    cdmData[SAVE_FIELD_ID_ACTIVE_LAYOUT_NAMES] = {}
  end
  cdmData[SAVE_FIELD_ID_ACTIVE_LAYOUT_NAMES][wantedTag] = foundID

  local input = C_EncodingUtil.EncodeBase64(C_EncodingUtil.CompressString(C_EncodingUtil.SerializeCBOR(cdmData), Enum.CompressionMethod.Deflate))
  C_CVar.SetCVar("cooldownViewerEnabled", "0")
  addonTable.Utilities.PurgeKey(CooldownViewerSettings.dataSerialization, "cachedSerializedData")
  addonTable.Utilities.PurgeKey(CooldownViewerSettings.dataProvider, "displayData")
  addonTable.Utilities.PurgeKey(CooldownViewerSettings.layoutManager, "activeLayoutID")
  C_CooldownViewer.SetLayoutData("1|" .. input)
  C_Timer.After(0, function()
    C_CVar.SetCVar("cooldownViewerEnabled", "1")
  end)
end

function addonTable.Core.GetCDMMapping(activeOnly)
  local allAuras = {}

  tAppendAll(allAuras, C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.TrackedBuff, not activeOnly))
  tAppendAll(allAuras, C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.TrackedBar, not activeOnly))
  local auraMapping = {}
  for _, cdmID in ipairs(allAuras) do
    local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cdmID)
    auraMapping[info.spellID] = cdmID
    auraMapping[info.overrideSpellID] = cdmID
    auraMapping[C_Spell.GetBaseSpell(info.spellID)] = cdmID
    auraMapping[C_Spell.GetBaseSpell(info.overrideSpellID)] = cdmID
    if info.overrideTooltipSpellID then
      auraMapping[info.overrideTooltipSpellID] = cdmID
      auraMapping[C_Spell.GetBaseSpell(info.overrideTooltipSpellID)] = cdmID
    end
    for _, spellID in ipairs(info.linkedSpellIDs) do
      auraMapping[spellID] = cdmID
    end
  end

  local allAbilities = {}
  tAppendAll(allAbilities, C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Essential, not activeOnly))
  tAppendAll(allAbilities, C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Utility, not activeOnly))
  local abilityMapping = {}
  for _, cdmID in ipairs(allAbilities) do
    local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cdmID)
    abilityMapping[info.spellID] = cdmID
    abilityMapping[info.overrideSpellID] = cdmID
    abilityMapping[C_Spell.GetBaseSpell(info.spellID)] = cdmID
    abilityMapping[C_Spell.GetBaseSpell(info.overrideSpellID)] = cdmID
    if info.overrideTooltipSpellID then
      abilityMapping[info.overrideTooltipSpellID] = cdmID
      abilityMapping[C_Spell.GetBaseSpell(info.overrideTooltipSpellID)] = cdmID
    end
    for _, spellID in ipairs(info.linkedSpellIDs) do
      abilityMapping[spellID] = cdmID
    end
  end

  return auraMapping, allAuras, abilityMapping, allAbilities
end

local function TriggerReload(reason)
  addonTable.Dialogs.ShowConfirm(addonTable.Locales.PLEASE_RELOAD_TO_GET_COOLINATOR_WORKING_REASON_X:format(reason), RELOADUI, CANCEL, ReloadUI)
end

function addonTable.Core.GetCDMOrder(layout)
  local cdmData, tag = addonTable.Core.GetCDMData()
  if not cdmData then
    TriggerReload(0)
    return
  end
  local id
  local correctName = addonTable.Core.GetCDMLayoutName()
  for i, name in pairs(cdmData[SAVE_FIELD_ID_LAYOUT_ID_DATA] or {}) do
    if name == correctName then
      id = i
      break
    end
  end
  if not id then
    TriggerReload(1)
    return
  end

  if cdmData[SAVE_FIELD_ID_ACTIVE_LAYOUT_NAMES][tag] ~= id then
    TriggerReload(2)
    return
  end

  if cdmData[SAVE_FIELD_ID_LAYOUTS][tag][id][SAVE_FIELD_ID_COOLDOWN_ORDER] ~= nil or cdmData[SAVE_FIELD_ID_LAYOUTS][tag][id][SAVE_FIELD_ID_CATEGORY_OVERRIDES][-2] ~= nil then
    TriggerReload(3)
    return
  end

  local bars = cdmData[SAVE_FIELD_ID_LAYOUTS][tag][id][SAVE_FIELD_ID_CATEGORY_OVERRIDES][Enum.CooldownViewerCategory.TrackedBar] or {}
  local auraMappingAll, orderedAuras, abilityMappingAll, orderedAbilities = addonTable.Core.GetCDMMapping()
  local auraMappingActive, _, abilityMappingActive = addonTable.Core.GetCDMMapping(true)

  local aurasSaved = cdmData[SAVE_FIELD_ID_LAYOUTS][tag][id][SAVE_FIELD_ID_CATEGORY_OVERRIDES][Enum.CooldownViewerCategory.TrackedBuff]
  local abilitiesSaved = cdmData[SAVE_FIELD_ID_LAYOUTS][tag][id][SAVE_FIELD_ID_CATEGORY_OVERRIDES][Enum.CooldownViewerCategory.Essential]
  if aurasSaved == nil or #aurasSaved ~= (#orderedAuras - #bars) or abilitiesSaved == nil or #abilitiesSaved ~= #orderedAbilities then
    TriggerReload(4)
    return
  end

  local allBars = GetVisibleAurasOrdered(layout, auraMappingAll)

  if #bars ~= #allBars then
    TriggerReload(5)
    return
  end

  local auraOrder = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.TrackedBuff, false)
  tAppendAll(auraOrder, C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.TrackedBar, false))

  local abilityOrder = C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Essential, false)
  tAppendAll(abilityOrder, C_CooldownViewer.GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Utility, false))

  local barOrder = {}

  for _, cdmID in ipairs(bars) do
    if tIndexOf(allBars, cdmID) == nil then
      TriggerReload(6)
      return
    end
  end

  for index = #auraOrder, 1, -1 do
    if tIndexOf(bars, auraOrder[index]) ~= nil then
      table.insert(barOrder, 1, auraOrder[index])
      table.remove(auraOrder, index)
    end
  end

  local auraOrderMap, barOrderMap, abilityOrderMap = {}, {}, {}
  local auraCount, barCount = 0, 0

  for index, cdmID in ipairs(auraOrder) do
    auraCount = auraCount + 1
    auraOrderMap[cdmID] = index
  end

  for index, cdmID in ipairs(barOrder) do
    barCount = barCount + 1
    barOrderMap[cdmID] = index
  end

  for index, cdmID in ipairs(abilityOrder) do
    abilityOrderMap[cdmID] = index
  end

  return {auraMap = auraMappingActive, abilityMap = abilityMappingActive, auraOrder = auraOrderMap, auraCount = auraCount, barOrder = barOrderMap, barCount = barCount, abilityOrder = abilityOrderMap}
end
