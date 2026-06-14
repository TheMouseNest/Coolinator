---@class addonTableCoolinator
local addonTable = select(2, ...)

addonTable.Display.CooldownMixin = {}
function addonTable.Display.CooldownMixin:OnLoad()
  self:SetSize(addonTable.Constants.nativeSize - 4, addonTable.Constants.nativeSize - 4)
  self:SetFlattensRenderLayers(true)

  self.Icon = self:CreateTexture()
  self.Icon:SetSize(addonTable.Constants.nativeSize, addonTable.Constants.nativeSize)
  self.Icon:SetPoint("CENTER")
  self.NotUsable = self:CreateTexture()
  self.NotUsable:SetAllPoints(self.Icon)
  self.NotUsable:SetTexture("Interface/AddOns/Coolinator/Assets/Special/white.png")
  self.NotUsable:SetVertexColor(0, 0, 0, 0.5)
  local mask = self:CreateMaskTexture()
  mask:SetAtlas("UI-HUD-CoolDownManager-Mask")
  mask:SetAllPoints(self.Icon)
  self.Icon:AddMaskTexture(mask)
  self.NotUsable:AddMaskTexture(mask)

  local overlay = self:CreateTexture(nil, "OVERLAY")
  overlay:SetAtlas("UI-HUD-CoolDownManager-IconOverlay")
  overlay:SetSize(50+18, 50+16)

  self.ChargesCooldown = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
  self.ChargesCooldown:SetAllPoints(self.Icon)
  self.ChargesCooldown:SetDrawSwipe(false)
  self.ChargesCooldown:SetSwipeTexture("Interface/HUD/UI-HUD-CoolDownManager-Icon-Swipe")

  self.BaseCooldown = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
  self.BaseCooldown:SetAllPoints(self.Icon)
  self.BaseCooldown:SetDrawEdge(false)
	self.BaseCooldown:SetSwipeColor(0, 0, 0, 0.8);
  self.BaseCooldown:SetSwipeTexture("Interface/HUD/UI-HUD-CoolDownManager-Icon-Swipe")

  self.CountFrame = CreateFrame("Frame", nil, self)
  self.CountFrame:SetAllPoints(self.Icon)
  self.CountFrame.text = self.CountFrame:CreateFontString(nil, nil, "NumberFontNormal")
  self.CountFrame.text:SetPoint("BOTTOMRIGHT", -2, -2)

	self.SpellActivationAlert = CreateFrame("Frame", nil, self, "ActionButtonSpellAlertTemplate");
	local frameWidth, frameHeight = self:GetSize();
	self.SpellActivationAlert:SetSize(frameWidth * 1.4, frameHeight * 1.4);
	self.SpellActivationAlert:SetPoint("CENTER", self, "CENTER", 0, 0);		
	self.SpellActivationAlert:SetFrameStrata("MEDIUM")

  self:SetScript("OnEvent", self.OnEvent)
  self:SetScript("OnEnter", self.OnEnter)
  self:SetScript("OnLeave", self.OnLeave)
end

function addonTable.Display.CooldownMixin:OnEnter()
  GameTooltip_SetDefaultAnchor(GameTooltip, self)
  if self.spellID then
    GameTooltip:SetSpellByID(self.spellID)
  elseif self.itemID then
    GameTooltip:SetSpellByID(select(2, C_Item.GetItemSpell(self.itemID)))
  elseif self.equipmentSlot then
    GameTooltip:SetInventoryItem("player", self.equipmentSlot)
  end
end

function addonTable.Display.CooldownMixin:OnLeave()
  GameTooltip:Hide()
end

function addonTable.Display.CooldownMixin:OnEvent(eventName, data, ...)
  if eventName == "SPELL_UPDATE_COOLDOWN" then
    if self.spellID then
      self:UpdateSpellByID(self.spellID, true)
    elseif self.itemID then
      self:UpdateItemByID(self.itemID)
    elseif self.equipmentSlot then
      self:UpdateItemByEquipmentSlot(self.equipmentSlot)
    end
  elseif eventName == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" and data == self.spellID then
    self:SetActivationAlert(true)
  elseif eventName == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" and data == self.spellID then
    self:SetActivationAlert(false)
  elseif eventName == "SPELL_RANGE_CHECK_UPDATE" and data == self.spellID then
    local isInRange, checkedRange = ...
    if not checkedRange or isInRange then
      self.Icon:SetVertexColor(1, 1, 1, 1)
    else
      self.Icon:SetVertexColor(0.8, 0, 0, 1)
    end
  elseif eventName == "SPELL_UPDATE_USABLE" and self.spellID then
    self.NotUsable:SetShown(not C_Spell.IsSpellUsable(self.spellID))
  end
end

function addonTable.Display.CooldownMixin:SetActivationAlert(state)
  if state then
    self.SpellActivationAlert:Show()
	  self.SpellActivationAlert.ProcStartFlipbook:Show();
	  self.SpellActivationAlert.ProcLoopFlipbook:Show();
	  self.SpellActivationAlert.ProcAltGlow:Hide();
	  self.SpellActivationAlert.ProcStartAnim:Play();
	  self.SpellActivationAlert:Raise()
	else
	  self.SpellActivationAlert:Hide()
	  self.SpellActivationAlert.ProcStartAnim:Stop();
	end
end

function addonTable.Display.CooldownMixin:SetEnabled(state)
  if state then
    self:Enable()
  else
    self:Disable()
  end
end

function addonTable.Display.CooldownMixin:Enable()
  self.itemID = nil
  self.spellID = nil

  self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
  self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
  self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
  self:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")
  self:RegisterEvent("SPELL_UPDATE_USABLE")
end

function addonTable.Display.CooldownMixin:Disable()
  if self.spellID then
    C_Spell.EnableSpellRangeCheck(self.spellID, false)
  end
  self.itemID = nil
  self.spellID = nil

  self:UnregisterAllEvents()
end

function addonTable.Display.CooldownMixin:UpdateSpellByID(spellID, activationOff)
  self.spellID = spellID
  self.itemID = nil
  self.equipmentSlot = nil

  local chargeDuration = C_Spell.GetSpellChargeDuration(spellID)
  if chargeDuration then
    self.ChargesCooldown:SetCooldownFromDurationObject(chargeDuration)
  else
    self.ChargesCooldown:Clear()
  end
  local baseDuration = C_Spell.GetSpellCooldownDuration(spellID)
  self.BaseCooldown:SetCooldownFromDurationObject(baseDuration)
  local gcd = C_Spell.GetSpellCooldown(spellID).isOnGCD
  if gcd == nil then
    gcd = false
  end

  self.BaseCooldown:SetAlphaFromBoolean(gcd, 0, 1)

  self.CountFrame.text:SetText(C_Spell.GetSpellDisplayCount(spellID))
  self.Icon:SetTexture(C_Spell.GetSpellTexture(spellID))

  if not activationOff then
    self:SetActivationAlert(C_SpellActivationOverlay.IsSpellOverlayed(spellID))
  end

  C_Spell.EnableSpellRangeCheck(self.spellID, true)
  if C_Spell.IsSpellInRange(self.spellID, "target") == false then
    self.Icon:SetVertexColor(0.8, 0, 0, 1)
  else
    self.Icon:SetVertexColor(1, 1, 1, 1)
  end
  self.NotUsable:SetShown(not C_Spell.IsSpellUsable(self.spellID))
end

function addonTable.Display.CooldownMixin:UpdateItemByID(itemID)
  self.spellID = nil
  self.itemID = itemID
  self.equipmentSlot = nil

  self.ChargesCooldown:Clear()
  local start, duration, enable = C_Item.GetItemCooldown(self.itemID)
  self.BaseCooldown:SetCooldown(start, duration)
  self.CountFrame.text:SetText("")
  self.Icon:SetTexture(C_Item.GetItemIconByID(self.itemID))

  if C_Item.GetItemCount(self.itemID) == 0 then
    C_Timer.After(0, function()
      addonTable.CallbackRegistry:TriggerEvent("Layout")
    end)
  end

  self.NotUsable:Hide()
end

function addonTable.Display.CooldownMixin:UpdateItemByEquipmentSlot(equipmentSlot)
  self.spellID = nil
  self.itemID = nil
  self.equipmentSlot = equipmentSlot

  local location = ItemLocation:CreateFromEquipmentSlot(equipmentSlot)
  if not C_Item.DoesItemExist(location) then
    C_Timer.After(0, function()
      addonTable.CallbackRegistry:TriggerEvent("Layout")
    end)
  end

  self.ChargesCooldown:Clear()
  local start, duration, enable = GetInventoryItemCooldown("player", equipmentSlot)
  self.BaseCooldown:SetCooldown(start, duration)
  self.CountFrame.text:SetText("")
  self.Icon:SetTexture(C_Item.GetItemIcon(location))

  self.NotUsable:Hide()
end
