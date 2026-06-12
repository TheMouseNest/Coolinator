---@class addonTableCoolinator
local addonTable = select(2, ...)

local LSM = LibStub("LibSharedMedia-3.0")

addonTable.Designer.IconMixin = {}

function addonTable.Designer.IconMixin:OnLoad()
  self:SetSize(addonTable.Design.nativeSize - 4, addonTable.Design.nativeSize - 4)
  self:SetFlattensRenderLayers(true)

  self.Icon = self:CreateTexture()
  self.Icon:SetSize(addonTable.Design.nativeSize, addonTable.Design.nativeSize)
  self.Icon:SetPoint("CENTER")
  local mask = self:CreateMaskTexture()
  mask:SetAtlas("UI-HUD-CoolDownManager-Mask")
  mask:SetAllPoints(self.Icon)
  self.Icon:AddMaskTexture(mask)

  local overlay = self:CreateTexture(nil, "OVERLAY")
  overlay:SetAtlas("UI-HUD-CoolDownManager-IconOverlay")
  overlay:SetSize(50+18, 50+16)

  self.BaseCooldown = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
  self.BaseCooldown:SetAllPoints()
  self.BaseCooldown:SetDrawEdge(false)
	self.BaseCooldown:SetSwipeColor(0, 0, 0);
  self.BaseCooldown:SetSwipeTexture("Interface/HUD/UI-HUD-CoolDownManager-Icon-Swipe")

  self.CountFrame = CreateFrame("Frame", nil, self)
  self.CountFrame:SetAllPoints()
  self.CountFrame.text = self.CountFrame:CreateFontString(nil, nil, "NumberFontNormal")
  self.CountFrame.text:SetPoint("BOTTOMRIGHT", -2, -2)

  self:SetScript("OnEnter", self.OnEnter)
  self:SetScript("OnLeave", self.OnLeave)
end

function addonTable.Designer.IconMixin:Setup(details)
  self.details = details
  local texture = C_Spell.GetSpellTexture(details.resource.spellID)
  self.Icon:SetTexture(texture)
  self.CountFrame.text:SetText("")

  self.Icon:SetDesaturated(not addonTable.Utilities.IsSpellKnown(details.resource.spellID))
end

function addonTable.Designer.IconMixin:OnEnter()
  GameTooltip_SetDefaultAnchor(GameTooltip, self)
  GameTooltip:SetSpellByID(self.details.resource.spellID)
  if self.Icon:IsDesaturated() then
    GameTooltip:AddLine(RED_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.UNLEARNED))
    GameTooltip:Show()
  end

  local parent = self:GetParent()
  if parent:GetScript("OnEnter") then
    parent:GetScript("OnEnter")(parent)
  end
end

function addonTable.Designer.IconMixin:OnLeave()
  GameTooltip:Hide()
  local parent = self:GetParent()
  if parent:GetScript("OnLeave") then
    parent:GetScript("OnLeave")(parent)
  end
end

function addonTable.Designer.IconMixin:ApplySize()
end

addonTable.Designer.BarMixin = {}

function addonTable.Designer.BarMixin:OnLoad()
  self.statusBar = CreateFrame("StatusBar", nil, self)
  self.statusBar:SetStatusBarTexture(LSM:Fetch("statusbar", "Cooli: Solid Transparency"))
  self.statusBar:SetMinMaxValues(0, 5)
  self.statusBar:SetValue(3)
  self.statusBar:SetAllPoints()

  self.background = self.statusBar:CreateTexture(nil, "BACKGROUND")
  self.background:SetAllPoints()
  self.borderWrapper = CreateFrame("Frame", nil, self)
  self.borderWrapper:SetPoint("CENTER", self.statusBar)
  self.borderWrapper:SetSize(10, 10)
  self.border = self.borderWrapper:CreateTexture(nil, "BORDER")
  self.border:SetPoint("CENTER")
  self.borderMask = self.statusBar:CreateMaskTexture()
  self.borderMask:SetAllPoints()
end

function addonTable.Designer.BarMixin:Setup(details)
  self.rawWidth, self.rawHeight, self.borderWidth, self.borderHeight, self.lowerScale = addonTable.Display.ApplyStatusBar(details, self.statusBar, self.border, self.borderMask, self.background)
  self.details = details

  if details.thresholdColors then
    local color = details.thresholdColors[2].color
    self.statusBar:GetStatusBarTexture():SetVertexColor(color.r, color.g, color.b)
  end

  self.borderWrapper:SetFrameLevel(self.statusBar:GetFrameLevel() + 2)
end

function addonTable.Designer.BarMixin:ApplySize()
  PixelUtil.SetSize(self, self.rawWidth * self.details.scale, self.rawHeight * self.details.scale)
  PixelUtil.SetSize(self.border, self.borderWidth * self.lowerScale, self.borderHeight * self.lowerScale)
end

function addonTable.Designer.BarMixin:OnEnter()
end

function addonTable.Designer.BarMixin:OnLeave()
end

addonTable.Designer.BarWithIconMixin = CreateFromMixins(addonTable.Designer.BarMixin)

function addonTable.Designer.BarWithIconMixin:OnLoad()
  addonTable.Designer.BarMixin.OnLoad(self)

  self.icon = CreateFrame("Frame", nil, self)
  self.icon.Icon = self.icon:CreateTexture()
  self.icon.Icon:SetAllPoints()
  self.icon.Mask = self.icon:CreateMaskTexture()
  self.icon.Mask:SetAtlas("UI-HUD-CoolDownManager-Mask")
  self.icon.Mask:SetAllPoints()
  self.icon.Icon:AddMaskTexture(self.icon.Mask)

  self.statusBar:ClearAllPoints()
end

function addonTable.Designer.BarWithIconMixin:Setup(details)
  addonTable.Designer.BarMixin.Setup(self, details)

  if details.resource then
    self.icon.Icon:SetTexture(C_Spell.GetSpellTexture(details.resource.spellID))
  end
end

function addonTable.Designer.BarWithIconMixin:ApplySize()
  local iconSize
  if self.details.layout == "vertical" then
    iconSize = self.rawWidth * self.details.scale
    PixelUtil.SetSize(self, self.rawWidth * self.details.scale, self.rawHeight * self.details.scale + (self.borderHeight - self.rawHeight) / 2 + 1 + iconSize)
  else
    iconSize = self.rawHeight * self.details.scale
    PixelUtil.SetSize(self, self.rawWidth * self.details.scale + (self.borderWidth - self.rawWidth) / 2 + 1 + iconSize, self.rawHeight * self.details.scale)
  end
  PixelUtil.SetSize(self.statusBar, self.rawWidth * self.lowerScale, self.rawHeight * self.lowerScale)
  PixelUtil.SetSize(self.border, self.borderWidth * self.lowerScale, self.borderHeight * self.lowerScale)

  PixelUtil.SetSize(self.icon, iconSize, iconSize)

  self.icon:ClearAllPoints()
  self.statusBar:ClearAllPoints()
  if self.details.layout == "horizontal" then
    self.icon:SetPoint("LEFT")
    self.statusBar:SetPoint("RIGHT")
  else
    self.icon:SetPoint("TOP")
    self.statusBar:SetPoint("BOTTOM")
  end
end
