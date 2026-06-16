---@class addonTableCoolinator
local addonTable = select(2, ...)

addonTable.Display.LayoutManagerMixin = CreateFromMixins(addonTable.Display.BaseLayoutManagerMixin)
function addonTable.Display.LayoutManagerMixin:OnLoad()
  addonTable.Display.BaseLayoutManagerMixin.OnLoad(self)
  self.auraWrappersPool = CreateFramePool("Frame", UIParent, nil, function(_, frame)
    frame:SetScript("OnShow", nil)
    frame:SetScript("OnHide", nil)
    frame:SetScript("OnSizeChanged", nil)
    frame:SetParent(UIParent)
    frame:ClearAllPoints()
    frame:Hide()
  end)
  self.abilityWrappersPool = CreateFramePool("Frame", UIParent, nil, function(_, frame)
    frame:SetScript("OnShow", nil)
    frame:SetScript("OnHide", nil)
    frame:SetScript("OnSizeChanged", nil)
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

  local hookedAuras = {}
  local function CacheIcons()
    local result = {}
    for itemFrame in BuffIconCooldownViewer.itemFramePool:EnumerateActive() do
      result[itemFrame.layoutIndex] = itemFrame
      if not hookedAuras[itemFrame] then
        hooksecurefunc(itemFrame, "Show", function()
          local parent = itemFrame:GetParent()
          if self.auraWrappersPool:IsActive(parent) then
            parent:Show()
          end
        end)
        hooksecurefunc(itemFrame, "Hide", function()
          local parent = itemFrame:GetParent()
          if self.auraWrappersPool:IsActive(parent) then
            parent:Hide()
          end
        end)
        hooksecurefunc(itemFrame, "SetShown", function(_, value)
          local parent = itemFrame:GetParent()
          if self.auraWrappersPool:IsActive(parent) then
            parent:SetShown(value)
          end
        end)
        hookedAuras[itemFrame] = true
      end
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

  local function CacheAbilities()
    local result = {}
    for itemFrame in EssentialCooldownViewer.itemFramePool:EnumerateActive() do
      result[itemFrame.layoutIndex] = itemFrame
    end
    self.abilityIcons = result
  end

  CacheIcons()
  CacheBars()
  CacheAbilities()

  hooksecurefunc(BuffIconCooldownViewer, "RefreshLayout", function()
    C_Timer.After(0, function()
      if not addonTable.State.CDM then
        return
      end
      CacheIcons()
      for i = 1, #self.auraIcons do
        self.auraIcons[i]:SetParent(addonTable.hiddenFrame)
      end
      for frame in self.auraWrappersPool:EnumerateActive() do
        local aura = self.auraIcons[frame.auraIndex]
        if aura then
          aura:SetParent(frame)
          aura:ClearAllPoints()
          aura:SetPoint("CENTER", frame)
        end
      end
    end)
  end)

  hooksecurefunc(BuffBarCooldownViewer, "RefreshLayout", function()
    C_Timer.After(0, function()
      if not addonTable.State.CDM then
        return
      end
      CacheBars()
      for i = 1, # self.auraBars do
        self.auraBars[i]:SetParent(addonTable.hiddenFrame)
      end
      for frame in self.auraStatusBarPool:EnumerateActive() do
        local aura = self.auraBars[frame.auraIndex]
        if aura then
          frame:UpdateSource(aura)
          frame:ApplySize()
        end
      end
    end)
  end)

  hooksecurefunc(EssentialCooldownViewer, "RefreshLayout", function()
    C_Timer.After(0, function()
      if not addonTable.State.CDM then
        return
      end
      CacheAbilities()
      for i = 1, #self.abilityIcons do
        self.abilityIcons[i]:SetParent(addonTable.hiddenFrame)
      end
      for frame in self.abilityWrappersPool:EnumerateActive() do
        local ability = self.abilityIcons[frame.abilityIndex]
        if ability then
          ability:SetParent(frame)
          ability:SetScale(0.8)
          ability:ClearAllPoints()
          ability:SetPoint("CENTER", frame)
        end
      end
    end)
  end)

  UtilityCooldownViewer:SetParent(addonTable.hiddenFrame)

  self:Layout()
end

function addonTable.Display.LayoutManagerMixin:Delayout()
  self.cooldownPool:ReleaseAll()
  self.auraWrappersPool:ReleaseAll()
  self.abilityWrappersPool:ReleaseAll()
  self.auraFromItemPool:ReleaseAll()
  self.auraStatusBarPool:ReleaseAll()
  for _, pool in pairs(self.classPools) do
    pool:ReleaseAll()
  end
  self.wrappersPool:ReleaseAll()

  self:SetScript("OnUpdate", nil)
  self.toArrange = {}
end

function addonTable.Display.LayoutManagerMixin:Layout()
  if self.disabled then
    return
  end
  self.pending = true

  self.autoSize = addonTable.Config.Get(addonTable.Config.Options.COMPRESS_LAYOUT)
  self.useBlizzardWidgets = addonTable.Config.Get(addonTable.Config.Options.USE_BLIZZARD_WIDGETS)
  if self.useBlizzardWidgets then
    EssentialCooldownViewer:SetParent(UIParent)
  else
    EssentialCooldownViewer:SetParent(addonTable.hiddenFrame)
  end

  self.currentLayout = addonTable.Core.GetCurrentDesign()

  self:Delayout()

  for i = 1, #self.auraIcons do
    self.auraIcons[i]:SetParent(addonTable.hiddenFrame)
  end
  for i = 1, #self.abilityIcons do
    self.abilityIcons[i]:SetParent(addonTable.hiddenFrame)
  end

  local wrapper = self:GetGroup(self.currentLayout)

  wrapper:SetParent(UIParent)
  wrapper:Show()

  self.pending = false
end

function addonTable.Display.LayoutManagerMixin:GetIcon(details)
  local spellID
  if details.resource.spellID then
    spellID = addonTable.Utilities.IsSpellKnown(details.resource.spellID)
    if not spellID then
      return
    end
  end
  if details.resource.kind == "ability" and self.useBlizzardWidgets and addonTable.State.CDM.abilityMap[spellID] then
    local abilityIndex = addonTable.State.CDM.abilityOrder[addonTable.State.CDM.abilityMap[spellID]]
    local ability = self.abilityIcons[abilityIndex]
    local frame = self.abilityWrappersPool:Acquire()
    frame.abilityIndex = abilityIndex
    if ability then
      ability:SetParent(frame)
      ability:ClearAllPoints()
      ability:SetPoint("CENTER", frame)
      ability:SetScale(0.8)
      frame:SetShown(ability:IsShown())
    end
    frame:Show()
    frame:SetSize(addonTable.Constants.nativeSize - 4, addonTable.Constants.nativeSize - 4)

    return frame

  elseif details.resource.kind == "ability" then
    local frame = self.cooldownPool:Acquire()
    frame:Show()
    frame:Enable()
    frame:UpdateSpellByID(spellID)
    return frame

  elseif details.resource.kind == "aura" and addonTable.State.CDM.auraMap[spellID] then
    local auraIndex = addonTable.State.CDM.auraOrder[addonTable.State.CDM.auraMap[spellID]]
    local aura = self.auraIcons[auraIndex]
    local frame = self.auraWrappersPool:Acquire()
    frame.auraIndex = auraIndex
    if aura then
      aura:SetParent(frame)
      aura:ClearAllPoints()
      aura:SetPoint("CENTER", frame)
      frame:SetShown(aura:IsShown())
    end
    frame:SetSize(addonTable.Constants.nativeSize - 4, addonTable.Constants.nativeSize - 4)

    return frame
  elseif details.resource.kind == "aura" and addonTable.Constants.AurasFromItems[spellID] then
    local frame = self.auraFromItemPool:Acquire()
    frame:Show()
    frame:Setup(details)
    return frame
  elseif details.resource.kind == "item" then
    if C_Item.GetItemCount(details.resource.itemID) < 1 then
      return
    end
    local frame = self.cooldownPool:Acquire()
    frame:Show()
    frame:Enable()
    frame:UpdateItemByID(details.resource.itemID)
    return frame
  elseif details.resource.kind == "equipment" then
    local location = ItemLocation:CreateFromEquipmentSlot(details.resource.equipmentSlot)
    if not C_Item.DoesItemExist(location) then
      return
    end
    local frame = self.cooldownPool:Acquire()
    frame:Show()
    frame:Enable()
    frame:UpdateItemByEquipmentSlot(details.resource.equipmentSlot)
    return frame
  end
end

function addonTable.Display.LayoutManagerMixin:GetBar(details)
  if details.resource.kind == "aura" then
    local spellID = addonTable.Utilities.IsSpellKnown(details.resource.spellID)
    if not spellID then
      return
    end
    local auraIndex = addonTable.State.CDM.barOrder[addonTable.State.CDM.auraMap[details.resource.spellID]]
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
