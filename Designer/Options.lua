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
    tab.resourceSpecificSettings = {}

    tabMap[label] = tab
    table.insert(tabs, tab)
  end
  local paths = {
    ["*"] = {
      ["*"] = {}
    }
  }
  local tabsPool = CreateObjectPool(function()
    return addonTable.CustomiseDialog.Components.GetTab(tabManager)
  end, Pool_HideAndClearAnchors)
  local wrappersPool = CreateFramePool("Frame", container)

  container:SetPoint("TOPLEFT", addonTable.Constants.ButtonFrameOffset, -25)
  container:SetPoint("BOTTOMRIGHT")
  for k1, l1 in pairs(options) do
    for k2, l2 in pairs(l1) do
      for _, tabDetails in ipairs(l2) do
        local c = CreateFrame("Frame", nil, container)
        c.label = tabDetails.label
        c:Hide()
        c:SetPoint("LEFT")
        c:SetPoint("RIGHT")
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
        if not paths[k1] then
          paths[k1] = {}
        end
        if not paths[k1][k2] then
          paths[k1][k2] = {}
        end
        table.insert(paths[k1][k2], c)
      end
    end
  end

  function container:SetTab(label)
    PanelTemplates_SelectTab(tabMap[label].button)
    for _, t in ipairs(tabs ) do
      t:Hide()
      if t.children[1].label ~= label then
        PanelTemplates_DeselectTab(t.button)
      end
    end
    tabMap[label]:Show()
    for _, child in ipairs(tabMap[label].children) do
      child:UpdateOptions(container.details)
    end
  end

  local previousPath = ""

  local function SetupPath(details)
    local newPath = details.resource and (details.resource.kind .. "$" .. (details.resource.resource or "")) or "ALL"
    if newPath == previousPath then
      return
    end
    local rootListing = paths["*"]["*"]
    for _, t in ipairs(tabs) do
      for _, child in ipairs(t.children) do
        child:Hide()
      end
    end
    tabsPool:ReleaseAll()
    wrappersPool:ReleaseAll()
    tabs = {}
    tabMap = {}
    for _, entry in ipairs(rootListing) do
      local wrapper = wrappersPool:Acquire()
      wrapper.button = tabsPool:Acquire()
      wrapper.button:SetText(entry.label)
      wrapper.button:GetScript("OnShow")(wrapper.button) -- auto size
      wrapper.button:Show()
      wrapper:SetAllPoints()
      wrapper.children = {entry}
      entry:SetParent(wrapper)
      entry:SetPoint("TOP", wrapper, 0, -35)
      entry:Show()
      entry:SetHeight(entry.allFrames[1]:GetTop() - entry.allFrames[#entry.allFrames]:GetBottom())
      tabMap[entry.label] = wrapper
      table.insert(tabs, wrapper)
    end
    if details.resource and paths[details.resource.kind] then
      for _, entry in ipairs(paths[details.resource.kind]["*"] or {}) do
        if tabMap[entry.label] then
          local wrapper = tabMap[entry.label]
          entry:SetPoint("TOP", wrapper.children[#wrapper.children], "BOTTOM", 0, -30)
          entry:Show()
          table.insert(wrapper.children, entry)
        else
          local wrapper = wrappersPool:Acquire()
          wrapper.button = tabsPool:Acquire()
          wrapper.button:SetText(entry.label)
          wrapper.button:GetScript("OnShow")(wrapper.button) -- auto size
            wrapper.button:Show()
          wrapper:SetAllPoints()
          wrapper.children = {entry}
          entry:SetParent(wrapper)
          entry:Show()
          entry:SetPoint("TOP", wrapper, 0, -35)
          tabMap[entry.label] = wrapper
          table.insert(tabs, wrapper)
        end
        entry:SetHeight(entry.allFrames[1]:GetTop() - entry.allFrames[#entry.allFrames]:GetBottom())
      end
      if paths[details.resource.kind][details.resource.resource] then
        for _, entry in ipairs(paths[details.resource.kind][details.resource.resource] or {}) do
          if tabMap[entry.label] then
            local wrapper = tabMap[entry.label]
            entry:SetPoint("TOP", wrapper.children[#wrapper.children], "BOTTOM", 0, -30)
            entry:Show()
            table.insert(wrapper.children, entry)
          else
            local wrapper = wrappersPool:Acquire()
            wrapper.button = tabsPool:Acquire()
            wrapper.button:SetText(entry.label)
            wrapper.button:GetScript("OnShow")(wrapper.button) -- auto size
            wrapper.button:Show()
            wrapper:SetAllPoints()
            wrapper.children = {entry}
            entry:SetParent(wrapper)
            entry:Show()
            entry:SetPoint("TOP", wrapper, 0, -35)
            tabMap[entry.label] = wrapper
            table.insert(tabs, wrapper)
          end
          entry:SetHeight(entry.allFrames[1]:GetTop() - entry.allFrames[#entry.allFrames]:GetBottom())
        end
      end
    end
    for _, t in ipairs(tabs) do
      t.button:SetScript("OnClick", function()
        container:SetTab(t.children[1].label)
      end)
    end
    previousPath = newPath
  end

  function container:UpdateOptions(details)
    SetupPath(details)
    container.details = details
    local any = false
    local lastTab
    for _, t in ipairs(tabs) do
      if t:IsShown() then
        any = true
        PanelTemplates_SelectTab(t.button)
        for _, child in ipairs(t.children) do
          child:UpdateOptions(details)
        end
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
    local label = addonTable.Constants.KindToLabel[frame.details.kind]
    if frame.details.kind == "bar" and frame.details.resource then
      label = label .. " - " .. addonTable.Constants.BarResourceLabelMap[frame.details.resource.kind]
      if frame.details.resource.kind == "class" then
        label = label .. " - " .. addonTable.Constants.BarClassResourceLabelMap[frame.details.resource.resource]
      end
    elseif frame.details.kind == "icon" then
      label = label .. " - " .. addonTable.Constants.IconResourceLabelMap[frame.details.resource.kind]
    end
    frame:SetTitle(addonTable.Locales.CUSTOMISE_COOLINATOR_X:format(label))
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
    SetTitle()
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
