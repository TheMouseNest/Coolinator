---@class addonTableCoolinator
local addonTable = select(2, ...)

addonTable.Display.LayoutManagerMixin = CreateFromMixins(addonTable.Display.BaseLayoutManagerMixin)
function addonTable.Display.LayoutManagerMixin:OnLoad()
  addonTable.Display.BaseLayoutManagerMixin.OnLoad(self)
  self.auraWrappersPool = CreateFramePool("Frame", UIParent, nil, function(_, frame)
    frame:SetParent(UIParent)
    frame:ClearAllPoints()
    frame:Hide()
  end)
  self.cooldownPool = addonTable.Display.GeneratePool(addonTable.Display.CooldownMixin)
  self.auraFromItemPool = addonTable.Display.GeneratePool(addonTable.Display.AuraFromItemMixin)
  self.auraStatusBarPool = addonTable.Display.GeneratePool(addonTable.Display.AuraStatusBarMixin)
  self.classPools = {}
  for key, mixin in pairs(addonTable.Display.ClassResourceStatusBar) do
    self.classPools[key] = addonTable.Display.GeneratePool(mixin)
  end


  addonTable.CallbackRegistry:RegisterCallback("Layout", self.Layout, self)
  addonTable.CallbackRegistry:RegisterCallback("Designer.Open", function()
    self.disabled = true
    self:Delayout()
  end)
  addonTable.CallbackRegistry:RegisterCallback("Designer.Close", function()
    self.disabled = false
    self:Layout()
  end)

  local function CacheIcons()
    local result = {}
	  for itemFrame in BuffIconCooldownViewer.itemFramePool:EnumerateActive() do
	    result[itemFrame.layoutIndex] = itemFrame
	  end
	  self.auraIcons = result
  end

  local function CacheBars()
    local result = {}
	  for itemFrame in BuffBarCooldownViewer.itemFramePool:EnumerateActive() do
	    result[itemFrame.layoutIndex] = itemFrame
	  end
	  self.auraBars = result
  end

  CacheIcons()
  CacheBars()

  hooksecurefunc(BuffIconCooldownViewer, "RefreshLayout", function()
    C_Timer.After(0, function()
      if not addonTable.State then
        return
      end
      CacheIcons()
      for i = 1, #self.auraIcons do
        self.auraIcons[i]:SetParent(addonTable.hiddenFrame)
      end
      for frame in self.auraWrappersPool:EnumerateActive() do
        local aura = self.auraIcons[frame.auraIndex]
        if not aura then
          return
        end
        aura:SetParent(frame)
        aura:ClearAllPoints()
        aura:SetPoint("CENTER", frame)
      end
    end)
  end)

  hooksecurefunc(BuffBarCooldownViewer, "RefreshLayout", function()
    C_Timer.After(0, function()
      if not addonTable.State then
        return
      end
      for frame in self.auraStatusBarPool:EnumerateActive() do
        frame:ApplySize()
        local aura = self.auraBars[frame.auraIndex]
        aura:SetParent(frame)
      end
    end)
  end)

  EssentialCooldownViewer:SetParent(addonTable.hiddenFrame)
  UtilityCooldownViewer:SetParent(addonTable.hiddenFrame)

  self:Layout()
end

function addonTable.Display.LayoutManagerMixin:Delayout()
  self.cooldownPool:ReleaseAll()
  self.auraWrappersPool:ReleaseAll()
  self.auraFromItemPool:ReleaseAll()
  for _, pool in pairs(self.classPools) do
    pool:ReleaseAll()
  end
  self.wrappersPool:ReleaseAll()
end

function addonTable.Display.LayoutManagerMixin:Layout()
  if self.disabled then
    return
  end
  self.currentLayout = addonTable.Core.GetCurrentDesign()

  self:Delayout()

  for i = 1, #self.auraIcons do
    self.auraIcons[i]:SetParent(addonTable.hiddenFrame)
  end

  local wrapper = self:GetGroup(self.currentLayout)

  wrapper:SetParent(UIParent)
  wrapper:Show()
end

function addonTable.Display.LayoutManagerMixin:GetIcon(details)
  local spellID = addonTable.Utilities.IsSpellKnown(details.resource.spellID)
  if not spellID then
    return
  end
  if details.resource.kind == "ability" then
    local frame = self.cooldownPool:Acquire()
    frame:Show()
    frame:Enable()
    frame:UpdateSpellByID(spellID)
    return frame

  elseif details.resource.kind == "aura" and addonTable.State.spellIDMap[spellID] then
    local auraIndex = addonTable.State.auraOrder[addonTable.State.spellIDMap[spellID]]
    local aura = self.auraIcons[auraIndex]
    if not aura then
      return
    end
    local frame = self.auraWrappersPool:Acquire()
    frame.auraIndex = auraIndex
    frame:Show()
    frame:SetSize(addonTable.Design.nativeSize - 4, addonTable.Design.nativeSize - 4)
    aura:SetParent(frame)
    aura:ClearAllPoints()
    aura:SetPoint("CENTER", frame)

    return frame
  elseif details.resource.kind == "aura" and addonTable.Constants.AurasFromItems[spellID] then
    local frame = self.auraFromItemPool:Acquire()
    frame:Show()
    frame:Setup(details)
    return frame
  end
end

function addonTable.Display.LayoutManagerMixin:GetBar(details)
  if details.resource.kind == "aura" then
    local spellID = addonTable.Utilities.IsSpellKnown(details.resource.spellID)
    if not spellID then
      return
    end
    local auraIndex = addonTable.State.barOrder[addonTable.State.spellIDMap[details.resource.spellID]]
    local aura = self.auraBars[auraIndex]
    if not aura then
      return
    end
    local monitor = self.auraStatusBarPool:Acquire()
    monitor.auraIndex = auraIndex
    monitor:Show()
    monitor:Setup(aura, details)
    return monitor
  elseif details.resource.kind == "class" then
    if not self.classPools[details.resource.resource] then
      addonTable.Utilities.Message("Unknown class resource")
      return
    end
    local bar = self.classPools[details.resource.resource]:Acquire()
    bar:Show()
    bar:Setup(details)
    return bar
  end
end
