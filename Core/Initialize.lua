---@class addonTableCoolinator
local addonTable = select(2, ...)

addonTable.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
addonTable.CallbackRegistry:OnLoad()
addonTable.CallbackRegistry:GenerateCallbackEvents(addonTable.Constants.Events)

local hidden = CreateFrame("Frame")
hidden:Hide()
addonTable.hiddenFrame = hidden

function addonTable.Core.AutoGenerateLayout()
  local spec = addonTable.Utilities.GetSpecID()
  local designs = addonTable.Config.Get(addonTable.Config.Options.DESIGNS)
  if not designs[spec] then
    designs[spec] = {}
  end
  designs[spec][addonTable.Constants.DefaultName] = addonTable.Core.GenerateDefaultCDMLayout()
end

function addonTable.Core.Initialize()
  addonTable.Config.InitializeData()
  addonTable.SlashCmd.Initialize()

  addonTable.Core.MigrateSettings()

  addonTable.Assets.Initialize()

  addonTable.CustomiseDialog.Initialize()
  addonTable.Designer.Initialize()
end

local function TriggerUpdate()
  C_Timer.After(0.1, function()
    if CooldownViewerSettings.layoutManager.currentSpecTag ~= CooldownViewerUtil.GetCurrentClassAndSpecTag() then
      addonTable.State = nil
      addonTable.Dialogs.ShowConfirm(addonTable.Locales.SPEC_MISMATCH_IN_BLIZZARD_CDM, RELOADUI, CANCEL, ReloadUI)
      return
    end

    addonTable.Core.AutoGenerateLayout()
    addonTable.SpellEquivalence = addonTable.Core.GenerateSpellOverrides()
    local layout = addonTable.Core.GetCurrentDesign()
    if layout then
      addonTable.State = addonTable.Core.GetCDMOrder(layout)
      if not addonTable.State then
        addonTable.Core.ApplyLayoutToCDM(layout)
        return
      end
      addonTable.CallbackRegistry:TriggerEvent("Layout")
    end
  end)
end

local isBarsChanged = false
addonTable.CallbackRegistry:RegisterCallback("AuraBarsChanged", function()
  isBarsChanged = true
  addonTable.Core.ApplyLayoutToCDM(addonTable.Core.GetCurrentDesign())
end)
addonTable.CallbackRegistry:RegisterCallback("Designer.Close", function()
  if isBarsChanged then
    addonTable.Dialogs.ShowConfirm(addonTable.Locales.DUE_TO_AURA_BARS_CHANGING_RELOAD_REQUIRED, RELOADUI, CANCEL, ReloadUI)
  end
end)
addonTable.CallbackRegistry:RegisterCallback("RefreshStateChange", function(_, refreshState)
  if refreshState[addonTable.Constants.Design] then
    TriggerUpdate()
  end
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:SetScript("OnEvent", function(_, eventName, data1, data2)
  if eventName == "ADDON_LOADED" and data1 == "Coolinator" then
    addonTable.Core.Initialize()
  elseif eventName == "TRAIT_CONFIG_UPDATED" and addonTable.State then
    TriggerUpdate()
  elseif eventName == "SPELLS_CHANGED" and addonTable.State then
    addonTable.CallbackRegistry:TriggerEvent("UpdateSpellIcons")
  elseif eventName == "PLAYER_ENTERING_WORLD" and not data1 and not data2 then
    addonTable.CallbackRegistry:TriggerEvent("Layout")
  elseif eventName == "PLAYER_EQUIPMENT_CHANGED" then
    addonTable.CallbackRegistry:TriggerEvent("Layout")
  end
end)

EventUtil.ContinueAfterAllEvents(function()
  addonTable.Core.AutoGenerateLayout()
  addonTable.SpellEquivalence = addonTable.Core.GenerateSpellOverrides()
  C_Timer.After(0.1, function()
    local layout = addonTable.Core.GetCurrentDesign()
    addonTable.State = addonTable.Core.GetCDMOrder(layout)

    if not addonTable.State then
      addonTable.Core.ApplyLayoutToCDM(layout)
      return
    end

    addonTable.Display.LayoutManager = addonTable.Utilities.InitFrameWithMixin(UIParent, addonTable.Display.LayoutManagerMixin)
    addonTable.Designer.LayoutManager = addonTable.Utilities.InitFrameWithMixin(UIParent, addonTable.Designer.LayoutManagerMixin)
  end)
end, "VARIABLES_LOADED", "PLAYER_ENTERING_WORLD", "COOLDOWN_VIEWER_DATA_LOADED")

local LEM = LibStub("LibEditModeOverride-1.0")
local doneOverrides = false
local function EditModeOverrides()
  if not LEM:IsReady() or doneOverrides then
    return
  end
  LEM:LoadLayouts()
  if not LEM:CanEditActiveLayout() or InCombatLockdown() then
    return
  end
  LEM:SetFrameSetting(BuffIconCooldownViewer, Enum.EditModeCooldownViewerSetting.IconSize, 100)
  LEM:SetFrameSetting(BuffIconCooldownViewer, Enum.EditModeCooldownViewerSetting.Opacity, 100)
  LEM:SetFrameSetting(BuffIconCooldownViewer, Enum.EditModeCooldownViewerSetting.VisibleSetting, Enum.CooldownViewerVisibleSetting.Always)
  LEM:SetFrameSetting(BuffIconCooldownViewer, Enum.EditModeCooldownViewerSetting.HideWhenInactive, 1)
  LEM:SetFrameSetting(BuffIconCooldownViewer, Enum.EditModeCooldownViewerSetting.ShowTimer, 1)
  LEM:SetFrameSetting(BuffIconCooldownViewer, Enum.EditModeCooldownViewerSetting.ShowTooltips, 1)

  LEM:SetFrameSetting(BuffBarCooldownViewer, Enum.EditModeCooldownViewerSetting.IconSize, 100)
  LEM:SetFrameSetting(BuffBarCooldownViewer, Enum.EditModeCooldownViewerSetting.BarWidthScale, 150)
  LEM:SetFrameSetting(BuffBarCooldownViewer, Enum.EditModeCooldownViewerSetting.Opacity, 100)
  LEM:SetFrameSetting(BuffBarCooldownViewer, Enum.EditModeCooldownViewerSetting.VisibleSetting, Enum.CooldownViewerVisibleSetting.Always)
  LEM:SetFrameSetting(BuffBarCooldownViewer, Enum.EditModeCooldownViewerSetting.HideWhenInactive, 1)
  LEM:SetFrameSetting(BuffBarCooldownViewer, Enum.EditModeCooldownViewerSetting.ShowTimer, 1)
  LEM:SetFrameSetting(BuffBarCooldownViewer, Enum.EditModeCooldownViewerSetting.ShowTooltips, 1)
  LEM:ApplyChanges()
  doneOverrides = true
end

EventUtil.ContinueAfterAllEvents(EditModeOverrides, "PLAYER_LOGIN")
EventUtil.ContinueAfterAllEvents(EditModeOverrides, "PLAYER_LOGIN", "EDIT_MODE_LAYOUTS_UPDATED")

function addonTable.Core.GetCurrentDesign()
  local spec = addonTable.Utilities.GetSpecID()
  local assignment = addonTable.Config.Get(addonTable.Config.Options.DESIGN_ASSIGNMENTS)[spec]
  local designs = addonTable.Config.Get(addonTable.Config.Options.DESIGNS)
  return designs[spec][assignment or addonTable.Constants.DefaultName]
end
