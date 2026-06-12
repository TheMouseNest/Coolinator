---@class addonTableCoolinator
local addonTable = select(2, ...)

local LSM = LibStub("LibSharedMedia-3.0")

addonTable.Display.AuraStatusBarMixin = {}
function addonTable.Display.AuraStatusBarMixin:OnLoad()
end

local sourceFrames = {}

function addonTable.Display.AuraStatusBarMixin:Setup(sourceWidget, details)
  local statusBar = sourceWidget.Bar

  if not sourceFrames[sourceWidget] then
    sourceWidget.DebuffBorder:SetParent(addonTable.hiddenFrame)
    statusBar.BarBG:SetParent(addonTable.hiddenFrame)
    statusBar.Pip:SetParent(addonTable.hiddenFrame)
    sourceWidget.Icon:SetParent(addonTable.hiddenFrame)
    statusBar.Name:SetParent(addonTable.hiddenFrame)

    statusBar.Duration:SetSmoothScaling(true)
    local file, height, flags = statusBar.Duration:GetFont()
    statusBar.Duration:SetFont(file, height, "OUTLINE SLUG")

    local background = statusBar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    local borderWrapper = CreateFrame("Frame", nil, statusBar)
    borderWrapper:SetAllPoints()
    local border = borderWrapper:CreateTexture(nil, "BORDER")
    border:SetPoint("CENTER")
    local borderMask = statusBar:CreateMaskTexture()
    borderMask:SetAllPoints()

    local icon = CreateFrame("Frame", nil, sourceWidget)
    icon:SetSize(30, 30)
    icon.Icon = sourceWidget.Icon.Icon
    icon.Icon:SetParent(icon)
    icon.Icon:RemoveMaskTexture(icon.Icon:GetMaskTexture(1))
    icon.Icon:SetAllPoints()
    icon.Mask = icon:CreateMaskTexture()
    icon.Mask:SetAtlas("UI-HUD-CoolDownManager-Mask")
    icon.Mask:SetAllPoints()
    icon.Icon:AddMaskTexture(icon.Mask)
    icon.Applications = sourceWidget.Icon.Applications
    icon.Applications:SetParent(icon)
    icon.Applications:ClearAllPoints()
    icon.Applications:SetSize(30, 10)
    icon.Applications:SetPoint("BOTTOMRIGHT", -5, 5)

    sourceFrames[sourceWidget] = {
      icon = icon,
      statusBar = statusBar,
      background = background,
      border = border,
      borderWrapper = borderWrapper,
      borderMask = borderMask,
      duration = statusBar.Duration,
      source = sourceWidget,
    }
  end

  local widgets = sourceFrames[sourceWidget]
  sourceWidget:SetParent(self)
  self.widgets = widgets

  self.rawWidth, self.rawHeight, self.borderWidth, self.borderHeight, self.lowerScale = addonTable.Display.ApplyStatusBar(details, statusBar, widgets.border, widgets.borderMask, widgets.background)

  widgets.borderWrapper:SetFrameLevel(widgets.statusBar:GetFrameLevel() + 2)

  widgets.duration:SetScale(2)

  self.details = details
end

function addonTable.Display.AuraStatusBarMixin:ApplySize()
  local iconSize
  if self.details.layout == "vertical" then
    iconSize = self.rawWidth * self.details.scale
    PixelUtil.SetSize(self, self.rawWidth * self.details.scale, self.rawHeight * self.details.scale + (self.borderHeight - self.rawHeight) / 2 + 1 + iconSize)
  else
    iconSize = self.rawHeight * self.details.scale
    PixelUtil.SetSize(self, self.rawWidth * self.details.scale + (self.borderWidth - self.rawWidth) / 2 + 1 + iconSize, self.rawHeight * self.details.scale)
  end
  PixelUtil.SetSize(self.widgets.statusBar, self.rawWidth * self.lowerScale, self.rawHeight * self.lowerScale)
  PixelUtil.SetSize(self.widgets.border, self.borderWidth * self.lowerScale, self.borderHeight * self.lowerScale)

  PixelUtil.SetSize(self.widgets.icon, iconSize, iconSize)
  PixelUtil.SetSize(self.widgets.icon.Applications, iconSize, 10)
  PixelUtil.SetPoint(self.widgets.icon.Applications, "BOTTOMRIGHT", self.widgets.icon, "BOTTOMRIGHT", -5, 5)

  self.widgets.icon:ClearAllPoints()
  self.widgets.statusBar:ClearAllPoints()
  if self.details.layout == "horizontal" then
    self.widgets.icon:SetPoint("LEFT")
    self.widgets.statusBar:SetPoint("RIGHT")
  else
    self.widgets.icon:SetPoint("TOP")
    self.widgets.statusBar:SetPoint("BOTTOM")
  end

  self.widgets.source:ClearAllPoints()
  self.widgets.source:SetAllPoints(self)
end
