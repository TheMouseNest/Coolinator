---@class addonTableCoolinator
local addonTable = select(2, ...)

function addonTable.Display.StyleIcon(styleSettings, parent, icon, count, maskedTextures, cooldowns)
  if parent.styleSet == styleSettings.id and icon == parent.Icon then
    return
  end
  if icon ~= parent.Icon then
    parent.Icon = icon
  end
  if not parent.border then
    parent.borderWrapper = CreateFrame("Frame", nil, parent)
    parent.borderWrapper:SetAllPoints(parent)
    parent.borderWrapper:SetFrameLevel(count:GetParent():GetFrameLevel())
    parent.border = parent.borderWrapper:CreateTexture()
    parent.border:SetPoint("CENTER")
    parent.Mask = parent:CreateMaskTexture()
  end
  local styleID = styleSettings.id

  parent.Mask:SetAllPoints(icon)

  parent.Icon = icon

  for _, t in ipairs(maskedTextures) do
    if t:GetNumMaskTextures() > 0 then
      for i = 1, t:GetNumMaskTextures() do
        local m = t:GetMaskTexture(i)
        t:RemoveMaskTexture(m)
      end
    end
  end

  local mask = parent.Mask
  mask:SetBlockingLoadsRequested(true)

  if styleID == "square" then
    local asset = addonTable.Assets.IconBorders["Cooli: 1px"]
    mask:SetTexture(asset.mask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    parent.border:SetTexture(asset.file)
    parent.border:SetVertexColor(0, 0, 0)
    parent.border:SetSize(addonTable.Constants.nativeSize, addonTable.Constants.nativeSize)
    for _, c in ipairs(cooldowns) do
      if c:GetDrawSwipe() then
        c:SetSwipeTexture(asset.mask)
      end
    end
  else--if styleID == "blizzard" then
    mask:SetTexture("Interface/AddOns/Coolinator/Assets/IconBorders/blizzard-mask.png", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    parent.border:SetTexture("Interface/AddOns/Coolinator/Assets/IconBorders/blizzard.png")
    parent.border:SetVertexColor(1, 1, 1)
    parent.border:SetSize(50+5, 50+5)
    for _, c in ipairs(cooldowns) do
      if c:GetDrawSwipe() then
        c:SetSwipeTexture("Interface/HUD/UI-HUD-CoolDownManager-Icon-Swipe")
      end
    end
  end

  for _, t in ipairs(maskedTextures) do
    t:AddMaskTexture(mask)
  end

  parent.styleSet = styleID
end
