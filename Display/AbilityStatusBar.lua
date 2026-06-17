---@class addonTableCoolinator
local addonTable = select(2, ...)

addonTable.Display.AbilityStatusBarMixin = {}

function addonTable.Display.AbilityStatusBarMixin:OnLoad()
  self:SetScript("OnEvent", self.OnEvent)

  self.wrapper = CreateFrame("Frame", nil, self)
  self.wrapper:SetAllPoints()
  self.statusBar = CreateFrame("StatusBar", nil, self.wrapper)
  self.statusBar:SetAllPoints()

  self.background = self.statusBar:CreateTexture(nil, "BACKGROUND")
  self.background:SetAllPoints()
  self.borderWrapper = CreateFrame("Frame", nil, self.wrapper)
  self.borderWrapper:SetAllPoints()
  self.border = self.borderWrapper:CreateTexture(nil, "BORDER")
  self.border:SetPoint("CENTER", self.statusBar)
  self.borderMask = self.statusBar:CreateMaskTexture()
  self.borderMask:SetAllPoints(self.statusBar)

  self.Icon = self.wrapper:CreateTexture(nil, "OVERLAY")
  self.Icon:SetSize(addonTable.Constants.nativeSize, addonTable.Constants.nativeSize)
  self.Icon:SetPoint("CENTER")

  self.TextsContainer = CreateFrame("Frame", nil, self.wrapper)
  self.TextsContainer:SetAllPoints()
  self.TextsContainer.Charges = self.TextsContainer:CreateFontString(nil, nil, "NumberFontNormal")
  --self.TextsContainer.Duration = self.TextsContainer:CreateFontString(nil, nil, "NumberFontNormal")
end

function addonTable.Display.AbilityStatusBarMixin:Enable(details)
  self:RegisterEvent("SPELL_UPDATE_COOLDOWN")

  addonTable.CallbackRegistry:RegisterCallback("UpdateSpellIcons", function(_, spellID)
    if self.spellID and (not spellID or C_Spell.GetBaseSpell(self.spellID) == spellID) then
      self.Icon:SetTexture(C_Spell.GetSpellTexture(self.spellID))
    end
  end, self)
end

function addonTable.Display.AbilityStatusBarMixin:Disable(details)
  self:UnregisterAllEvents()

  if self.ticker then
    self.ticker:Cancel()
  end
end

function addonTable.Display.AbilityStatusBarMixin:OnEvent()
  self:UpdateSpellByID(self.spellID)
end

function addonTable.Display.AbilityStatusBarMixin:Setup(details)
  self:SetScript("OnUpdate", self.OnUpdate)
  self.details = details

  self.rawWidth, self.rawHeight, self.borderWidth, self.borderHeight, self.lowerScale = addonTable.Display.ApplyStatusBar(details, self.statusBar, self.border, self.borderMask, self.background)

  self:UpdateSpellByID(addonTable.Utilities.IsAbilitySpellKnown(details.resource.spellID) or details.resource.spellID)

  self.borderWrapper:SetFrameLevel(self.statusBar:GetFrameLevel() + 2)

end

function addonTable.Display.AbilityStatusBarMixin:ApplySize()
  if self.details.icon.show then
    local iconSize
    if self.details.layout == "vertical" then
      iconSize = self.rawWidth * self.details.scale
      PixelUtil.SetSize(self, self.rawWidth * self.details.scale, self.rawHeight * self.details.scale + (self.borderHeight - self.rawHeight) / 2 + 1 + iconSize)
    else
      iconSize = self.rawHeight * self.details.scale
      PixelUtil.SetSize(self, self.rawWidth * self.details.scale + (self.borderWidth - self.rawWidth) / 2 + 1 + iconSize, self.rawHeight * self.details.scale)
    end
    PixelUtil.SetSize(self.Icon, iconSize, iconSize)
  else
    PixelUtil.SetSize(self, self.rawWidth * self.details.scale, self.rawHeight * self.details.scale)
  end
  PixelUtil.SetSize(self.statusBar, self.rawWidth * self.lowerScale, self.rawHeight * self.lowerScale)
  PixelUtil.SetSize(self.border, self.borderWidth * self.lowerScale, self.borderHeight * self.lowerScale)

  PixelUtil.SetPoint(self.TextsContainer.Charges, "BOTTOMRIGHT", self.Icon, "BOTTOMRIGHT", -5, 5)

  self.Icon:ClearAllPoints()
  self.statusBar:ClearAllPoints()
  --self.TextsContainer.Duration:ClearAllPoints()
  if self.details.layout == "horizontal" then
    self.Icon:SetPoint(self.details.icon.position == "left" and "LEFT" or "RIGHT")
    self.statusBar:SetPoint(self.details.icon.position == "left" and "RIGHT" or "LEFT")
    --self.TextsContainer.Duration:SetPoint("RIGHT", self.widgets.statusBar, -8, 0)
  else
    self.Icon:SetPoint(self.details.icon.position == "left" and "BOTTOM" or "TOP")
    self.statusBar:SetPoint(self.details.icon.position == "left" and "TOP" or "BOTTOM")
    --self.TextsContainer.Duration:SetPoint("BOTTOM", self.widgets.statusBar, 0, 8)
  end
end

function addonTable.Display.AbilityStatusBarMixin:UpdateSpellByID(spellID)
  self.spellID = spellID

  self.Icon:SetTexture(C_Spell.GetSpellTexture(spellID))

  if self.ticker then
    self.ticker:Cancel()
  end

  local baseDuration = C_Spell.GetSpellCooldownDuration(spellID, true)
  self.statusBar:SetTimerDuration(baseDuration, nil, Enum.StatusBarTimerDirection.RemainingTime)

  self.wrapper:SetAlphaFromBoolean(baseDuration:IsZero(), 0, 1)

  self.ticker = C_Timer.NewTicker(0.1, function()
    baseDuration = C_Spell.GetSpellCooldownDuration(spellID, true)
    self.wrapper:SetAlphaFromBoolean(baseDuration:IsZero(), 0, 1)
  end)
end
