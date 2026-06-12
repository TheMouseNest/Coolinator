---@class addonTableCoolinator
local addonTable = select(2, ...)

addonTable.Display.AuraFromItemMixin = {}

function addonTable.Display.AuraFromItemMixin:OnLoad()
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
	self.BaseCooldown:SetSwipeColor(0, 0, 0, 0.8);
  self.BaseCooldown:SetSwipeTexture("Interface/HUD/UI-HUD-CoolDownManager-Icon-Swipe")

  self:SetScript("OnEnter", self.OnEnter)
  self:SetScript("OnLeave", self.OnLeave)

  self:SetScript("OnEvent", self.OnEvent)

  self.BaseCooldown:SetScript("OnCooldownDone", function()
    self:Hide()
  end)
end

function addonTable.Display.AuraFromItemMixin:Disable()
  self:UnregisterAllEvents()
end

function addonTable.Display.AuraFromItemMixin:Setup(details)
  self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
  self.details = details
  self.data = addonTable.Constants.AurasFromItems[details.resource.spellID]
  self.Icon:SetTexture(C_Spell.GetSpellTexture(self.details.resource.spellID))
  if not self.data.deathPersistent then
    self:RegisterUnitEvent("PLAYER_DEAD")
  end
end

function addonTable.Display.AuraFromItemMixin:OnEvent(eventName, _, _, spellID)
  if eventName == "UNIT_SPELLCAST_SUCCEEDED" then
    if spellID == self.details.resource.spellID then
      self.BaseCooldown:SetCooldown(GetTime(), self.data.duration)
      self:Show()
    end
  elseif eventName == "UNIT_DEAD" then
    self:Hide()
  end
end
