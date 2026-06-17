---@class addonTableCoolinator
local addonTable = select(2, ...)

addonTable.Display.LayoutManagerMixin = CreateFromMixins(addonTable.Display.BaseLayoutManagerMixin)
function addonTable.Display.LayoutManagerMixin:OnLoad()
  addonTable.Display.BaseLayoutManagerMixin.OnLoad(self)
  self:SetScript("OnEvent", self.OnEvent)
  self:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
  self:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")

  self.disabled = {}

  self.groupPool = addonTable.Display.GeneratePool(addonTable.Display.GroupMixin)
  self.abilityWrappersPool = CreateFramePool("Frame", UIParent, nil, function(_, frame)
    frame:SetScript("OnShow", nil)
    frame:SetScript("OnHide", nil)
    frame:SetScript("OnSizeChanged", nil)
    frame:SetParent(UIParent)
    frame:ClearAllPoints()
    frame:Hide()
  end)
  self.auraIconPool = addonTable.Display.GeneratePool(addonTable.Display.AuraIconMixin)
  self.cooldownPool = addonTable.Display.GeneratePool(addonTable.Display.CooldownMixin)
  self.auraFromItemPool = addonTable.Display.GeneratePool(addonTable.Display.AuraFromItemMixin)
  self.abilityBarPool = addonTable.Display.GeneratePool(addonTable.Display.AbilityStatusBarMixin)
  self.auraStatusBarPool = addonTable.Display.GeneratePool(addonTable.Display.AuraStatusBarMixin)
  self.classPools = {}
  for key, mixin in pairs(addonTable.Display.ClassResourceStatusBar) do
    self.classPools[key] = addonTable.Display.GeneratePool(mixin)
  end

  addonTable.CallbackRegistry:RegisterCallback("Layout", self.Layout, self)
  addonTable.CallbackRegistry:RegisterCallback("Designer.Open", function()
    self.disabled.designer = true
    self:Delayout()
  end)
  addonTable.CallbackRegistry:RegisterCallback("Designer.Close", function()
    self.disabled.designer = nil
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
          if self.auraIconPool:IsActive(parent) then
            parent:Show()
          end
        end)
        hooksecurefunc(itemFrame, "Hide", function()
          local parent = itemFrame:GetParent()
          if self.auraIconPool:IsActive(parent) then
            parent:Hide()
          end
        end)
        hooksecurefunc(itemFrame, "SetShown", function(_, value)
          local parent = itemFrame:GetParent()
          if self.auraIconPool:IsActive(parent) then
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
      for frame in self.auraIconPool:EnumerateActive() do
        local aura = self.auraIcons[frame.auraIndex]
        if aura then
          frame:UpdateSource(aura)
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
  local oldPending = self.pending
  self.pending = true
  self.cooldownPool:ReleaseAll()
  self.auraIconPool:ReleaseAll()
  self.abilityWrappersPool:ReleaseAll()
  self.auraFromItemPool:ReleaseAll()
  self.auraStatusBarPool:ReleaseAll()
  self.abilityBarPool:ReleaseAll()
  for _, pool in pairs(self.classPools) do
    pool:ReleaseAll()
  end
  self.groupPool:ReleaseAll()

  self:SetScript("OnUpdate", nil)
  self.toArrange = {}

  self.pending = oldPending
end

function addonTable.Display.LayoutManagerMixin:Layout()
  if next(self.disabled) then
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
  if details.resource.kind == "ability" and self.useBlizzardWidgets and addonTable.State.CDM.abilityMap[spellID] then
    local spellID = addonTable.Utilities.IsAbilitySpellKnown(details.resource.spellID)
    if not spellID then
      return
    end
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
    local _, _, overlay = ability:GetRegions()
    overlay:Hide()
    addonTable.Display.StyleIcon({id  = details.style}, frame, ability.Icon, ability.ChargeCount.Current, {ability.Icon}, {ability.Cooldown})

    return frame

  elseif details.resource.kind == "ability" then
    if not addonTable.Utilities.IsAbilitySpellKnown(details.resource.spellID) then
      return
    end
    local frame = self.cooldownPool:Acquire()
    frame:Show()
    frame:Enable()
    frame:Setup(details)
    return frame

  elseif details.resource.kind == "aura" and addonTable.State.CDM.auraMap[details.resource.spellID] then
    local spellID = addonTable.Utilities.IsAuraSpellKnown(details.resource.spellID)
    if not spellID then
      return
    end
    local auraIndex = addonTable.State.CDM.auraOrder[addonTable.State.CDM.auraMap[spellID]]
    local aura = self.auraIcons[auraIndex]
    if aura then
      local frame = self.auraIconPool:Acquire()
      frame.auraIndex = auraIndex
      frame:Setup(aura, details)
      return frame
    end
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
    frame:Setup(details)
    return frame
  elseif details.resource.kind == "equipment" then
    local location = ItemLocation:CreateFromEquipmentSlot(details.resource.equipmentSlot)
    if not C_Item.DoesItemExist(location) then
      return
    end
    local frame = self.cooldownPool:Acquire()
    frame:Show()
    frame:Enable()
    frame:Setup(details)
    return frame
  end
end

function addonTable.Display.LayoutManagerMixin:GetBar(details)
  if details.resource.kind == "aura" then
    local spellID = addonTable.Utilities.IsAuraSpellKnown(details.resource.spellID)
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
  elseif details.resource.kind == "ability" then
    if not addonTable.Utilities.IsAbilitySpellKnown(details.resource.spellID) then
      return
    end
    local frame = self.abilityBarPool:Acquire()
    frame:Show()
    frame:Enable()
    frame:Setup(details)
    return frame

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

function addonTable.Display.LayoutManagerMixin:OnEvent(eventName)
  if eventName == "UNIT_ENTERED_VEHICLE" then
    self.disabled.vehicle = true
    self:Delayout()
  else
    self.disabled.vehicle = nil
  end
end
