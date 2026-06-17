---@class addonTableCoolinator
local addonTable = select(2, ...)

addonTable.Display.GroupMixin = {}

function addonTable.Display.GroupMixin:OnLoad()
  self:SetScript("OnEvent", self.OnEvent)
end

function addonTable.Display.GroupMixin:Disable()
  self:UnregisterAllEvents()
end

--NOTE: DOES NOT do layout
function addonTable.Display.GroupMixin:Setup(details)
  self.details = details

  local any = false
  for key, value in pairs(self.details.show) do
    if not value then
      any = true
      break
    end
  end

  if any then
    if not self.details.show.mounted or not self.details.show.skyriding then
      self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
      self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    end
    if not self.details.show.combat then
      self:RegisterEvent("PLAYER_IN_COMBAT_CHANGED")
    end
    if not self.details.show.world or not self.details.show.instance then
      self:RegisterEvent("PLAYER_ENTERING_WORLD")
      self:RegisterEvent("GROUP_FORMED")
    end
  end

  self:ApplyShowState()
end

function addonTable.Display.GroupMixin:ApplyShowState()
  local inCombat = PlayerIsInCombat()
  local skyUsable, skyPowerLacking = C_Spell.IsSpellUsable(372608)
  local isSkyriding = IsAdvancedFlyableArea() and IsMounted() and (skyUsable or skyPowerLacking or self.lastMountWasSkyriding)
  local isMounted = IsMounted()
  local isWorld = not IsInInstance() and not C_Scenario.IsInScenario()
  local isInstance = IsInInstance()

  if not self.details.show.combat and inCombat then
    self:Hide()
    return
  end

  if not self.details.show.skyriding and isSkyriding then
    self:Hide()
    return
  end

  if not self.details.show.mounted and isMounted then
    self:Hide()
    return
  end

  if not self.details.show.world and isWorld then
    self:Hide()
    return
  end

  if not self.details.show.instance and isInstance then
    self:Hide()
    return
  end

  self:Show()
end

function addonTable.Display.GroupMixin:OnEvent(eventName, ...)
  if eventName == "UNIT_SPELLCAST_SUCCEEDED" then 
    local _, _, spellID = ...
    local mount = C_MountJournal.GetMountFromSpell(spellID) or nil
    if mount then
      self.lastMountWasSkyriding = select(5, C_MountJournal.GetMountInfoExtraByID(mount)) == 424
      self:ApplyShowState()
    end
  else
    self:ApplyShowState()
  end
end
