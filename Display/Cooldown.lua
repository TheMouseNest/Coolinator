---@class addonTableCoolinator
local addonTable = select(2, ...)

addonTable.Display.CooldownMixin = {}
function addonTable.Display.CooldownMixin:OnLoad()
  self:SetSize(addonTable.Constants.nativeSize - 4, addonTable.Constants.nativeSize - 4)
  self:SetFlattensRenderLayers(true)

  self.Icon = self:CreateTexture(nil, "OVERLAY")
  self.Icon:SetSize(addonTable.Constants.nativeSize, addonTable.Constants.nativeSize)
  self.Icon:SetPoint("CENTER")
  self.NotUsable = self:CreateTexture(nil, "OVERLAY")
  self.NotUsable:SetAllPoints(self.Icon)
  self.NotUsable:SetTexture("Interface/AddOns/Coolinator/Assets/Special/white.png")
  self.NotUsable:SetVertexColor(0, 0, 0, 0.5)

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

  self.KeyBindingFrame = CreateFrame("Frame", nil, self)
  self.KeyBindingFrame:SetAllPoints(self.Icon)
  self.KeyBindingFrame.text = self.KeyBindingFrame:CreateFontString(nil, nil, "NumberFontNormal")
  self.KeyBindingFrame.text:SetPoint("TOPRIGHT", -2, -2)
  self.KeyBindingFrame.text:SetTextColor(0.7, 0.7, 0.7)

	self.SpellActivationAlert = CreateFrame("Frame", nil, self, "ActionButtonSpellAlertTemplate");
	local frameWidth, frameHeight = self:GetSize();
	self.SpellActivationAlert:SetSize(frameWidth * 1.4, frameHeight * 1.4);
	self.SpellActivationAlert:SetPoint("CENTER", self, "CENTER", 0, 0);
	self.SpellActivationAlert:SetFrameStrata("MEDIUM")

  self:SetScript("OnEvent", self.OnEvent)
  self:SetScript("OnEnter", self.OnEnter)
  self:SetScript("OnLeave", self.OnLeave)
end

function addonTable.Display.CooldownMixin:Style()
  addonTable.Display.StyleIcon({id = self.details.style}, self, self.Icon, self.CountFrame.text,
    {self.Icon, self.NotUsable},
    {self.BaseCooldown, self.ChargesCooldown,}
  )
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

  addonTable.CallbackRegistry:RegisterCallback("UpdateSpellIcons", function(_, spellID)
    if self.spellID and (not spellID or C_Spell.GetBaseSpell(self.spellID) == spellID) then
      self.Icon:SetTexture(C_Spell.GetSpellTexture(self.spellID))
    end
  end, self)
  addonTable.CallbackRegistry:RegisterCallback("UpdateKeyBindings", function(_, spellID)
    self:UpdateBindingText()
  end, self)
end

function addonTable.Display.CooldownMixin:Disable()
  if self.spellID then
    C_Spell.EnableSpellRangeCheck(self.spellID, false)
  end
  self.itemID = nil
  self.spellID = nil

  self:UnregisterAllEvents()
  addonTable.CallbackRegistry:UnregisterCallback("UpdateSpellIcons", self)
end

function addonTable.Display.CooldownMixin:Setup(details)
  self.details = details
  self.spellID = nil
  self.itemID = nil
  self.equipmentSlot = nil

  if details.resource.spellID then
    self:UpdateSpellByID(addonTable.Utilities.IsAbilitySpellKnown(details.resource.spellID) or details.resource.spellID)
  elseif details.resource.itemID then
    self:UpdateItemByID(details.resource.itemID)
  else
    self:UpdateItemByEquipmentSlot(details.resource.equipmentSlot)
  end

  self:UpdateBindingText()
  self:Style()

  self:SetMouseMotionEnabled(details.showTooltips)
end

function addonTable.Display.CooldownMixin:UpdateBindingText()
  if not addonTable.Config.Get(addonTable.Config.Options.SHOW_KEYBINDINGS) then
    self.KeyBindingFrame.text:SetText("")
    return
  end
  if self.spellID then
    self.KeyBindingFrame.text:SetText(addonTable.State.Bindings.spells[C_Spell.GetBaseSpell(self.spellID)] or "")
  elseif self.itemID then
    self.KeyBindingFrame.text:SetText(addonTable.State.Bindings.items[self.itemID] or "")
  elseif self.equipmentSlot then
    local location = ItemLocation:CreateFromEquipmentSlot(self.equipmentSlot)
    if C_Item.DoesItemExist(location) then
      self.KeyBindingFrame.text:SetText(addonTable.State.Bindings.items[C_Item.GetItemID(location)] or "")
    end
  end
end

function addonTable.Display.CooldownMixin:UpdateSpellByID(spellID, activationOff)
  self.spellID = spellID

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
  local isUsable = C_Spell.IsSpellUsable(self.spellID)
  self.NotUsable:SetShown(not isUsable)
end

function addonTable.Display.CooldownMixin:UpdateItemByID(itemID)
  self.itemID = itemID

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
  self.equipmentSlot = equipmentSlot

  local location = ItemLocation:CreateFromEquipmentSlot(equipmentSlot)
  if not C_Item.DoesItemExist(location) then
    C_Timer.After(0, function()
      addonTable.CallbackRegistry:TriggerEvent("Layout")
    end)
    return
  end

  self.ChargesCooldown:Clear()
  local start, duration, enable = GetInventoryItemCooldown("player", equipmentSlot)
  self.BaseCooldown:SetCooldown(start, duration)
  self.CountFrame.text:SetText("")
  self.Icon:SetTexture(C_Item.GetItemIcon(location))

  self.NotUsable:Hide()
end
