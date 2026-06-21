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
    local mask = icon.Icon:GetMaskTexture(1)
    if mask then
      icon.Icon:RemoveMaskTexture(mask)
    end
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

    local debuffBorder = addonTable.Utilities.InitFrameWithMixin(self, addonTable.Display.AuraDebuffBorderMixin)
    debuffBorder:SetAllPoints(icon)

    sourceFrames[sourceWidget] = {
      icon = icon,
      statusBar = statusBar,
      background = background,
      border = border,
      debuffBorder = debuffBorder,
      borderWrapper = borderWrapper,
      borderMask = borderMask,
      duration = statusBar.Duration,
      source = sourceWidget,
    }
  end

  local widgets = sourceFrames[sourceWidget]
  sourceWidget:SetParent(self)
  self.widgets = widgets
  widgets.source:SetMouseMotionEnabled(addonTable.Config.Get(addonTable.Config.Options.SHOW_TOOLTIPS))

  self.rawWidth, self.rawHeight, self.borderWidth, self.borderHeight, self.lowerScale = addonTable.Display.ApplyStatusBar(details, statusBar, widgets.border, widgets.borderMask, widgets.background)

  widgets.borderWrapper:SetFrameLevel(widgets.statusBar:GetFrameLevel() + 2)

  widgets.duration:SetScale(self.lowerScale)

  widgets.icon:SetShown(details.icon.show)

  self.details = details
end

function addonTable.Display.AuraStatusBarMixin:UpdateSource(sourceWidget)
  if sourceWidget ~= self.widgets.source then
    self:Setup(sourceWidget, self.details)
  else
    sourceWidget:SetParent(self)
  end
end

function addonTable.Display.AuraStatusBarMixin:GetDefaultSize()
  return PixelUtil.ConvertPixelsToUIForRegion(self.rawWidth * self.details.scale, self), PixelUtil.ConvertPixelsToUIForRegion(self.rawHeight * self.details.scale, self)
end

function addonTable.Display.AuraStatusBarMixin:ApplySize(width, height)
  local rawWidth, rawHeight = self.rawWidth * self.details.scale, self.rawHeight * self.details.scale
  if self.details.autoSize then
    if self.details.layout == "horizontal" then
      rawWidth = width or rawWidth
    end
    if self.details.layout == "vertical" then
      rawHeight = height or rawHeight
    end
  end
  local statusWidth, statusHeight = self.rawWidth, self.rawHeight
  local borderWidth, borderHeight = self.borderWidth, self.borderHeight
  if self.details.icon.show then
    local iconSize
    if self.details.layout == "vertical" then
      iconSize = self.rawWidth * self.details.scale
      local offset = (self.borderHeight - self.rawHeight) / 2 + 1 + iconSize
      local new = rawHeight - offset
      if new >= addonTable.Assets.BarBordersSize.width * 0.1 then
        statusHeight = new / self.details.scale
        borderHeight = borderHeight + (rawHeight - offset - self.rawHeight * self.details.scale) / self.details.scale
        self.widgets.icon:Show()
      else
        self.widgets.icon:Hide()
      end
    else
      iconSize = self.rawHeight * self.details.scale
      local offset = (self.borderWidth - self.rawWidth) / 2 + 1 + iconSize
      local new = rawWidth - offset
      if new >= addonTable.Assets.BarBordersSize.width * 0.1 then
        statusWidth = new / self.details.scale
        borderWidth = borderWidth + (rawWidth - offset - self.rawWidth * self.details.scale) / self.details.scale
        self.widgets.icon:Show()
      else
        self.widgets.icon:Hide()
      end
    end
    PixelUtil.SetSize(self.widgets.icon, iconSize, iconSize)
  else
    statusWidth, statusHeight = rawWidth / self.details.scale, rawHeight / self.details.scale
    borderWidth = borderWidth + (statusWidth - self.rawWidth)
    borderHeight = borderHeight + (statusHeight - self.rawHeight)
  end
  PixelUtil.SetSize(self, rawWidth, rawHeight)
  PixelUtil.SetSize(self.widgets.statusBar, statusWidth * self.lowerScale, statusHeight * self.lowerScale)
  PixelUtil.SetSize(self.widgets.border, borderWidth * self.lowerScale, borderHeight  * self.lowerScale)

  PixelUtil.SetPoint(self.widgets.icon.Applications, "BOTTOMRIGHT", self.widgets.icon, "BOTTOMRIGHT", -5, 5)

  self.widgets.icon:ClearAllPoints()
  self.widgets.statusBar:ClearAllPoints()
  self.widgets.duration:ClearAllPoints()
  if self.details.layout == "horizontal" then
    self.widgets.icon:SetPoint(self.details.icon.position == "left" and "LEFT" or "RIGHT")
    self.widgets.statusBar:SetPoint(self.details.icon.position == "left" and "RIGHT" or "LEFT")
    self.widgets.duration:SetPoint("RIGHT", self.widgets.statusBar, -8, 0)
  else
    self.widgets.icon:SetPoint(self.details.icon.position == "left" and "BOTTOM" or "TOP")
    self.widgets.statusBar:SetPoint(self.details.icon.position == "left" and "TOP" or "BOTTOM")
    self.widgets.duration:SetPoint("BOTTOM", self.widgets.statusBar, 0, 8)
  end

  self.widgets.source:SetAllPoints(self)
end
