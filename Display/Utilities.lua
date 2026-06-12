---@class addonTableCoolinator
local addonTable = select(2, ...)

local LSM = LibStub("LibSharedMedia-3.0")

--[[function addonTable.Display.ApplyAnchor(frame, anchor)
  frame:ClearAllPoints()
  if #anchor == 0 then
    frame:SetPoint("CENTER")
  elseif #anchor == 3 then
    PixelUtil.SetPoint(frame, anchor[1], frame:GetParent(), "CENTER", anchor[2], anchor[3])
  elseif #anchor == 2 then
    PixelUtil.SetPoint(frame, "CENTER", frame:GetParent(), "CENTER", anchor[1], anchor[2])
  elseif #anchor == 1 then
    frame:SetPoint("TOP", frame:GetParent(), "CENTER")
  end
end]]

function addonTable.Display.ApplyStatusBar(details, statusBar, border, borderMask, background)
  local borderDetails = LSM:Fetch("ninesliceborder", details.border.asset, true) or LSM:Fetch("ninesliceborder", "Cooli: 1px")
  assert(borderDetails)
  local borderSliceDetails = LSM:Fetch("nineslice", borderDetails.nineslice)
  assert(borderSliceDetails)
  local foregroundAsset = LSM:Fetch("statusbar", details.foreground.asset, true) or LSM:Fetch("statusbar", "Cooli: Solid White")
  local backgroundAsset = LSM:Fetch("statusbar", details.background.asset, true) or LSM:Fetch("statusbar", "Cooli: Solid White")

  local rawWidth, rawHeight = details.width * addonTable.Assets.BarBordersSize.width, details.height * addonTable.Assets.BarBordersSize.height
  if details.layout == "vertical" then
    local tmp = rawWidth
    rawWidth = rawHeight
    rawHeight = tmp
    statusBar:SetOrientation("VERTICAL")
  else
    statusBar:SetOrientation("HORIZONTAL")
  end
  local borderWidth = rawWidth + (borderSliceDetails.padding.left + borderSliceDetails.padding.right) / 2
  local borderHeight = rawHeight + (borderSliceDetails.padding.top + borderSliceDetails.padding.bottom) / 2

  statusBar:SetStatusBarTexture(foregroundAsset)
  statusBar:GetStatusBarTexture():SetDrawLayer("ARTWORK")
  statusBar:SetScale(borderSliceDetails.scaleModifier * details.scale)
  statusBar:GetStatusBarTexture():SetVertexColor(details.foreground.color.r, details.foreground.color.g, details.foreground.color.b)

  local lowerScale = 1/borderSliceDetails.scaleModifier

  background:SetTexture(backgroundAsset)
  background:SetVertexColor(details.background.color.r, details.background.color.g, details.background.color.b, details.background.color.a)

  border:SetTexture(borderSliceDetails.file)
  border:SetVertexColor(details.border.color.r, details.border.color.g, details.border.color.b, details.border.color.a)
  border:SetTextureSliceMargins(borderSliceDetails.margins.left, borderSliceDetails.margins.top, borderSliceDetails.margins.right, borderSliceDetails.margins.bottom)
  if border:GetParent() ~= statusBar and border:GetParent():GetParent() ~= statusBar then
    border:SetScale(borderSliceDetails.scaleModifier * details.scale)
  end

  statusBar:GetStatusBarTexture():RemoveMaskTexture(borderMask)
  background:RemoveMaskTexture(borderMask)

  local maskDetails = borderDetails.mask
  borderMask:SetBlockingLoadsRequested(true)
  borderMask:SetTexture(maskDetails.file, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  borderMask:SetTextureSliceMargins(maskDetails.margins.left, maskDetails.margins.top, maskDetails.margins.right, maskDetails.margins.bottom)

  statusBar:GetStatusBarTexture():AddMaskTexture(borderMask)
  background:AddMaskTexture(borderMask)

  return rawWidth, rawHeight, borderWidth, borderHeight, lowerScale
end

function addonTable.Display.GeneratePool(mixin, template)
  return CreateFramePool("Frame", UIParent, template or "CoolinatorPropagateMouseClicksTemplate", function(_, frame)
    if frame.Disable then
      frame:Disable()
    end
    frame:SetParent(UIParent)
    frame:ClearAllPoints()
    frame:Hide()
  end, false, function(frame)
    Mixin(frame, mixin)
    frame.kind = "bar"
    frame:OnLoad()
  end)
end
