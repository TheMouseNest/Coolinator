---@class addonTableCoolinator
local addonTable = select(2, ...)

local function Announce()
  addonTable.CallbackRegistry:TriggerEvent("Designer.Layout")
end

local function GenerateOptions(parent, yOffset, xOffset, entries)
  local allFrames = {}

  for _, e in ipairs(entries) do
    local frame
    local function Setter(value)
      if not parent.details then
        return
      end
      local oldValue = e.getter(parent.details)
      e.setter(parent.details, value)
      if type(oldValue) == "table" then
        if not tCompare(oldValue, e.getter(parent.details)) then
          Announce()
        end
      elseif oldValue ~= e.getter(parent.details) then
        Announce()
      end
    end
    local function Getter()
      if not parent.details then
        return
      end
      return e.getter(parent.details)
    end
    if e.hide then
      frame = nil
    elseif e.kind == "slider" then
      if e.valuePattern then
        frame = addonTable.CustomiseDialog.Components.GetSlider(parent, e.label, e.min, e.max, function(val) return e.valuePattern:format(val) end, Setter)
      else
        frame = addonTable.CustomiseDialog.Components.GetSlider(parent, e.label, e.min, e.max, e.formatter, Setter)
      end
    elseif e.kind == "dropdown" then
      frame = addonTable.CustomiseDialog.Components.GetBasicDropdown(parent, e.label, function(value)
        if not parent.details then
          return false
        end
        if type(value) == "table" then
          return tCompare(value, e.getter(parent.details))
        else
          return value == e.getter(parent.details)
        end
      end, Setter)
    elseif e.kind == "checkbox" then
      frame = addonTable.CustomiseDialog.Components.GetCheckbox(parent, e.label, 28 + xOffset, Setter)
    elseif e.kind == "colorPicker" then
      frame = addonTable.CustomiseDialog.Components.GetColorPicker(parent, e.label, 28 + xOffset, Setter)
    elseif e.kind == "colorPickerWithCheckbox" then
      frame = addonTable.CustomiseDialog.Components.GetColorPickerWithCheckbox(parent, e.label, 28 + xOffset, Setter)
    end

    if frame then
      frame.kind = e.kind
      frame.getInitData = e.getInitData
      frame.Getter = Getter
      if #allFrames == 0 then
        frame:SetPoint("TOP", 0, yOffset)
      else
        frame:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, yOffset)
      end
      table.insert(allFrames, frame)
      yOffset = 0
    elseif e.kind == "spacer" then
      yOffset = -30
    end
  end

  return allFrames
end

local function GenerateKindOptions(parent, options)
  local container = CreateFrame("Frame", nil, parent)

  local tabManager = CreateFrame("Frame", nil, container)
  tabManager:SetPoint("TOP", 0, -5)
  tabManager:SetPoint("LEFT")
  tabManager:SetPoint("RIGHT")
  tabManager:SetHeight(30)

  local tabs = {}
  local tabMap = {}
  local function InitTab(tab, tabButton, label)
    tab:SetPoint("LEFT")
    tab:SetPoint("RIGHT")
    tab:SetHeight(300)
    tab.button = tabButton
    tabButton.kind = label
    tabButton.label = label
    tabButton:SetScript("OnClick", function()
      container:SetTab(tabButton.label)
    end)
    tab.resourceSpecificSettings = {}

    tabMap[label] = tab
    table.insert(tabs, tab)
  end
  container:SetPoint("TOPLEFT", addonTable.Constants.ButtonFrameOffset, -25)
  container:SetPoint("BOTTOMRIGHT")
  for _, tabDetails in ipairs(options["*"]["*"]) do
    local tabButton = addonTable.CustomiseDialog.Components.GetTab(tabManager, tabDetails.label)
    local c = CreateFrame("Frame", nil, container)
    c:Hide()
    c:SetPoint("TOP", 0, -30)
    InitTab(c, tabButton, tabDetails.label)
    c.allFrames = GenerateOptions(c, 0, 0, tabDetails.entries)
    function c:UpdateOptions(details)
      c.details = details

      for _, f in ipairs(c.allFrames) do
        if f.getInitData then
          f:Init(f.getInitData(c.details))
        end
        if f.SetValue then
          f:SetValue(f.Getter())
        end
      end
    end
  end

  function container:SetTab(label)
    PanelTemplates_SelectTab(tabMap[label].button)
    for _, t in ipairs(tabs ) do
      t:Hide()
      if t.button.label ~= label then
        PanelTemplates_DeselectTab(t.button)
      end
    end
    tabMap[label]:Show()
    tabMap[label]:UpdateOptions(container.details)
  end

  function container:UpdateOptions(details)
    container.details = details
    local any = false
    local lastTab
    for _, t in ipairs(tabs) do
      if t:IsShown() then
        any = true
        PanelTemplates_SelectTab(t.button)
        t:UpdateOptions(details)
      end
      if not lastTab then
        t.button:SetPoint("TOPLEFT", 20, 0)
      else
        t.button:SetPoint("TOPLEFT", lastTab, "TOPRIGHT", 5, 0)
      end
      lastTab = t.button
    end
    if not any then
      tabs[1].button:Click()
    end
  end

  return container
end

local optionsFrames = {}
function addonTable.Designer.GenerateOptionsFromDetails(details)
  if optionsFrames[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)] then
    local frame = optionsFrames[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)]
    local oldDetails = frame.details
    frame.details = details
    if frame.details and (frame.details ~= oldDetails or not frame:IsShown()) then
      frame:Show()
      frame:Update()
    else
      frame:Hide()
    end
    return
  end

  local frame = addonTable.CustomiseDialog.Components.GetContentFrame(
    "CoolinatorDesignerOptionsDialog" .. addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN),
    600, 450
  )
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", 10, -10)
  optionsFrames[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)] = frame

  local function SetTitle()
    frame:SetTitle(addonTable.Locales.CUSTOMISE_COOLINATOR_X:format(addonTable.Constants.KindToLabel[frame.details.kind]))
  end

  local containers = {}
  for kind, o in pairs(addonTable.Designer.WidgetConfiguration) do
    containers[kind] = GenerateKindOptions(frame, o)
    containers[kind]:Hide()
  end

  function frame:Update()
    if not frame.details then
      self:Hide()
      return
    end
    local any = false
    SetTitle(frame.details)
    for kind, c in pairs(containers) do
      c.details = frame.details
      if frame.details.kind == kind then
        c:Show()
        c:UpdateOptions(frame.details)
      else
        c:Hide()
      end
      any = any or c:IsShown()
    end
    if not any then
      frame:Hide()
    end
  end

  addonTable.CallbackRegistry:RegisterCallback("Designer.Close", function()
    frame:Hide()
  end)

  frame:SetScript("OnHide", function()
    for kind, c in pairs(containers) do
      c:Hide()
    end
  end)

  frame.details = details

  frame:Show()
  frame:Update()
end
