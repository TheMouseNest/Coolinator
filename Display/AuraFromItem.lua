---@class addonTableCoolinator
local addonTable = select(2, ...)

local lastItemID = 0
hooksecurefunc(C_Item, "UseItemByName",function(itemID)
  if type(itemID) == "string" then
    itemID = C_Item.GetItemIDForItemInfo(itemID)
  end
  lastItemID = itemID
end)
hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot)
  local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
  if C_Item.DoesItemExist(location) then
    lastItemID = C_Item.GetItemID(location)
  end
end)

addonTable.Display.AuraFromItemMixin = {}

function addonTable.Display.AuraFromItemMixin:OnLoad()
  self:SetSize(addonTable.Constants.nativeSize - 4, addonTable.Constants.nativeSize - 4)
  self:SetFlattensRenderLayers(true)

  self.Icon = self:CreateTexture()
  self.Icon:SetSize(addonTable.Constants.nativeSize, addonTable.Constants.nativeSize)
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
  self:Hide()
end

function addonTable.Display.AuraFromItemMixin:OnEvent(eventName, _, _, spellID)
  if eventName == "UNIT_SPELLCAST_SUCCEEDED" then
    if spellID == self.details.resource.spellID then
      if self.data.duration == -1 then
        self.BaseCooldown:SetCooldown(GetTime(), self.data.itemIDs[lastItemID])
      else
        self.BaseCooldown:SetCooldown(GetTime(), self.data.duration)
      end
      self:Show()
    end
  elseif eventName == "UNIT_DEAD" then
    self:Hide()
  end
end
