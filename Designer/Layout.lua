---@class addonTableCoolinator
local addonTable = select(2, ...)

local function Announce()
  addonTable.CallbackRegistry:TriggerEvent("Designer.Open")
end

addonTable.Designer.LayoutManagerMixin = CreateFromMixins(addonTable.Display.BaseLayoutManagerMixin)

local function GetSelectorMarker(frame, isHover)
  local texture = frame:CreateTexture()
  texture:SetTexture("Interface/AddOns/Coolinator/Assets/selection-outline.png")
  texture:SetVertexColor(78/255, 165/255, 252/255, isHover and 0.45 or 0.8)
  texture:SetTextureSliceMargins(45, 45, 45, 45)
  texture:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
  texture:SetScale(0.25)
  texture:SetAllPoints()

  return frame
end

local function GetButton(frame, asset)
  local button = CreateFrame("Button", nil, frame)
  button:SetNormalTexture("Interface/AddOns/Coolinator/Assets/Buttons/dark-up.png")
  button:SetPushedTexture("Interface/AddOns/Coolinator/Assets/Buttons/dark-down.png")
  button.Icon = button:CreateTexture(nil ,"OVERLAY")
  button.Icon:SetAllPoints()
  button.Icon:SetPoint("CENTER")
  button.Icon:SetTexture(asset)
  button:SetScript("OnMouseDown", function()
    button.Icon:SetPoint("CENTER", -1, -1)
  end)
  button:SetScript("OnMouseUp", function()
    button.Icon:SetPoint("CENTER", 0, 0)
  end)
  button:SetSize(30, 30)
  button:SetFrameLevel(9999)

  return button
end

local function GetArrow(frame, rotation)
  local button = GetButton(frame, "Interface/AddOns/Coolinator/Assets/Buttons/arrow.png")
  button.Icon:SetRotation(rotation)
  return button
end

function addonTable.Designer.LayoutManagerMixin:OnLoad()
  addonTable.Display.BaseLayoutManagerMixin.OnLoad(self)

  self.iconPool = addonTable.Display.GeneratePool(addonTable.Designer.IconMixin, "")
  self.barPool = addonTable.Display.GeneratePool(addonTable.Designer.BarMixin, "")
  self.barIconPool = addonTable.Display.GeneratePool(addonTable.Designer.BarWithIconMixin, "")
  self.selectorPool = CreateFramePool("Frame", UIParent, nil, nil, false, GetSelectorMarker)
  self.hoverMarker = CreateFrame("Frame", nil, UIParent)
  self.hoverMarker:SetFrameLevel(9999)
  GetSelectorMarker(self.hoverMarker, true)

  self.auraFrame = addonTable.Designer.GetAuraDialog()
  self.abilityFrame = addonTable.Designer.GetAbilityDialog()
  self.movementArrows = {left = GetArrow(UIParent, math.pi / 2), right = GetArrow(UIParent, -math.pi/2), down = GetArrow(UIParent, math.pi), up = GetArrow(UIParent, 0)}
  self.selectParentButton = GetButton(self, "Interface/AddOns/Coolinator/Assets/Buttons/chain.png")
  self.selectParentButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(self.selectParentButton, "ANCHOR_LEFT")
    GameTooltip:SetText(addonTable.Locales.SELECT_GROUP)
  end)
  self.selectParentButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  self.insertInParent = GetButton(self, "Interface/AddOns/Coolinator/Assets/Buttons/plus.png")
  self.insertInParent:SetScript("OnEnter", function()
    GameTooltip:SetOwner(self.insertInParent, "ANCHOR_LEFT")
    GameTooltip:SetText(addonTable.Locales.INSERT_END)
  end)
  self.insertInParent:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  self.deleteButton = GetButton(self, "Interface/AddOns/Coolinator/Assets/Buttons/cross.png")
  self.dragButton = GetButton(self, "Interface/AddOns/Coolinator/Assets/Buttons/drag.png")
  self.dragButton:SetSize(40, 40)

  addonTable.CallbackRegistry:RegisterCallback("Designer.Open", self.Layout, self)
  addonTable.CallbackRegistry:RegisterCallback("Designer.Close", self.Delayout, self)

  addonTable.CallbackRegistry:RegisterCallback("Designer.Options", self.MarkSelected, self)
end

function addonTable.Designer.LayoutManagerMixin:GetBar(details)
  local bar
  if details.resource.kind == "aura" then
    bar = self.barIconPool:Acquire()
  else
    bar = self.barPool:Acquire()
  end
  bar:Setup(details)
  return bar
end

function addonTable.Designer.LayoutManagerMixin:GetIcon(details)
  local icon = self.iconPool:Acquire()
  icon:Setup(details)
  icon:Show()
  return icon
end

function addonTable.Designer.LayoutManagerMixin:Delayout()
  self.iconPool:ReleaseAll()
  self.barPool:ReleaseAll()
  self.barIconPool:ReleaseAll()
  self.wrappersPool:ReleaseAll()
end

local function DeleteRoot(root, shouldAnnounce)
  if root.details.layout == "standalone" then
    return
  end
  local parentDetails = root:GetParent().details
  local index = tIndexOf(parentDetails.entries, root.details)
  if index then
    table.remove(parentDetails.entries, index)
    if #parentDetails.entries == 0 and parentDetails.layout ~= "standalone" then
      DeleteRoot(root:GetParent(), false)
    end
    addonTable.CallbackRegistry:TriggerEvent("Designer.Options", nil)
    Announce()
    if root.details.kind == "bar" and root.details.resource.kind == "aura" then
      addonTable.CallbackRegistry:TriggerEvent("AuraBarsChanged")
    end
  end
end

function addonTable.Designer.LayoutManagerMixin:AddHandlers(root)
  root:SetAlpha(root.details.alpha or 1)
  root:SetScript("OnEnter", function()
    if root.OnEnter then
      root:OnEnter()
    end
    self.hoverMarker:SetAllPoints(root)
    self.hoverMarker:Show()
  end)
  root:SetScript("OnLeave", function()
    if root.OnLeave then
      root:OnLeave()
    end
    self.hoverMarker:Hide()
  end)
  root:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
      if root.details == self.selection then
        addonTable.CallbackRegistry:TriggerEvent("Designer.Options", nil)
      else
        addonTable.CallbackRegistry:TriggerEvent("Designer.Options", root.details)
      end
    elseif button == "RightButton" then
      MenuUtil.CreateContextMenu(root, function(_, rootDescription)
        rootDescription:CreateButton(addonTable.Locales.OPTIONS, function()
          addonTable.CallbackRegistry:TriggerEvent("Designer.Options", root.details)
        end)
        local parentDetails = root:GetParent() ~= UIParent and root:GetParent().details
        if parentDetails and parentDetails.layout ~= "standalone" then
          local insert = rootDescription:CreateButton(addonTable.Locales.INSERT)
          self:AddEntryToInsert(insert, root.details, function(new)
            table.insert(parentDetails.entries, (tIndexOf(parentDetails.entries, root.details) + 1) or 1, new)
            Announce()
            addonTable.CallbackRegistry:TriggerEvent("Designer.Options", new)
          end)
        end
      end)
    end
  end)
  if root.details.kind == "group" then
    for _, entry in ipairs(root.children) do
      self:AddHandlers(entry)
    end
  end
end

local function ImportStyle(new, old)
  assert(new.resource.kind == old.resource.kind)
  for key, val in pairs(old) do
    if key ~= "kind" and key ~= "resource" then
      new[key] = type(val) == "table" and CopyTable(val) or val
    end
  end
end

function addonTable.Designer.LayoutManagerMixin:AddEntryToInsert(rootDescription, origin, inserter)
  rootDescription:CreateButton(addonTable.Locales.ABILITY, function()
    self.abilityFrame:Update(function(data)
      local new = CopyTable(addonTable.Designer.Defaults.AbilityIcon)
      new.resource.spellID = data
      if origin.kind == "icon" and origin.resource.kind == "ability" then
        ImportStyle(new, origin)
      end
      inserter(new)
    end)
  end)
  rootDescription:CreateButton(addonTable.Locales.AURA, function()
    self.auraFrame:Update(function(data)
      local new = CopyTable(addonTable.Designer.Defaults.AuraIcon)
      new.resource.spellID = data
      if origin.kind == "icon" and origin.resource.kind == "aura" then
        ImportStyle(new, origin)
      end
      inserter(new)
    end)
  end)
  rootDescription:CreateButton(addonTable.Locales.AURA_BAR, function()
    self.auraFrame:Update(function(data)
      local new = CopyTable(addonTable.Designer.Defaults.AuraBar)
      new.resource.spellID = data
      if origin.kind == "bar" and origin.resource.kind == "aura" then
        ImportStyle(new, origin)
      end
      inserter(new)
      addonTable.CallbackRegistry:TriggerEvent("AuraBarsChanged")
    end)
  end)
  local resources = addonTable.Designer.GetAvailableClassResources()
  for _, r in ipairs(resources) do
    if addonTable.Designer.Defaults.ClassResource[r] then
      rootDescription:CreateButton(addonTable.Constants.BarClassResourceLabelMap[r], function()
        inserter(CopyTable(addonTable.Designer.Defaults.ClassResource[r]))
      end)
    end
  end
end

function addonTable.Designer.LayoutManagerMixin:MarkSelected(details)
  if details == self.selection then
    self.selection = nil
  else
    self.selection = details
  end
  self:UpdateSelection()
end

function addonTable.Designer.LayoutManagerMixin:GetForDetails(details, root)
  if root.details == details then
    return root
  elseif root.details.kind == "group" then
    for _, e in ipairs(root.children) do
      local result = self:GetForDetails(details, e)
      if result then
        return result
      end
    end
  end
end
function addonTable.Designer.LayoutManagerMixin:UpdateSelection()
  self.selectorPool:ReleaseAll()
  for _, frame in pairs(self.movementArrows) do
    frame:Hide()
  end
  self.selectParentButton:Hide()
  self.insertInParent:Hide()
  self.deleteButton:Hide()
  self.dragButton:Hide()
  local frame = self:GetForDetails(self.selection, self.root)
  if frame then
    local selector = self.selectorPool:Acquire()
    selector:Show()
    selector:SetFrameLevel(9999)
    selector:SetAllPoints(frame)
    local parentDetails = frame:GetParent() ~= UIParent and frame:GetParent().details
    if parentDetails.layout == "vertical" then
      local up, down = self.movementArrows.up, self.movementArrows.down
      up:Show()
      down:Show()
      up:SetPoint("BOTTOM", frame, "TOP", 0, 2)
      up:SetScript("OnClick", function()
        local index = tIndexOf(parentDetails.entries, self.selection)
        if index < #parentDetails.entries then
          local tmp = parentDetails.entries[index + 1]
          parentDetails.entries[index + 1] = self.selection
          parentDetails.entries[index] = tmp
          Announce()
        end
      end)
      down:SetPoint("TOP", frame, "BOTTOM", 0, -2)
      down:SetScript("OnClick", function()
        local index = tIndexOf(parentDetails.entries, self.selection)
        if index > 1 then
          local tmp = parentDetails.entries[index - 1]
          parentDetails.entries[index - 1] = self.selection
          parentDetails.entries[index] = tmp
          Announce()
        end
      end)
    elseif parentDetails.layout == "horizontal" then
      local left, right = self.movementArrows.left, self.movementArrows.right
      left:Show()
      right:Show()
      right:SetPoint("LEFT", frame, "RIGHT", 2, 0)
      right:SetScript("OnClick", function()
        local index = tIndexOf(parentDetails.entries, self.selection)
        if index < #parentDetails.entries then
          local tmp = parentDetails.entries[index + 1]
          parentDetails.entries[index + 1] = self.selection
          parentDetails.entries[index] = tmp
          Announce()
        end
      end)
      left:SetPoint("RIGHT", frame, "LEFT", -2, 0)
      left:SetScript("OnClick", function()
        local index = tIndexOf(parentDetails.entries, self.selection)
        if index > 1 then
          local tmp = parentDetails.entries[index - 1]
          parentDetails.entries[index - 1] = self.selection
          parentDetails.entries[index] = tmp
          Announce()
        end
      end)
    end
    if parentDetails.layout ~= "standalone" then
      self.selectParentButton:Show()
      self.selectParentButton:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", -2, 2)
      self.selectParentButton:SetScript("OnClick", function()
       addonTable.CallbackRegistry:TriggerEvent("Designer.Options", parentDetails)
      end)

      self.insertInParent:Show()
      self.insertInParent:SetPoint("BOTTOM", self.selectParentButton, "TOP", 0, 2)
      self.insertInParent:SetScript("OnClick", function()
        MenuUtil.CreateContextMenu(frame, function(_, rootDescription)
          self:AddEntryToInsert(rootDescription, frame.details, function(new)
            table.insert(parentDetails.entries, new)
            Announce()
            addonTable.CallbackRegistry:TriggerEvent("Designer.Options", new)
          end)
          local group = rootDescription:CreateButton(addonTable.Locales.GROUP_WITH)
          self:AddEntryToInsert(group, frame.details, function(new)
            table.insert(parentDetails.entries, {
              kind = "group",
              layout = "horizontal",
              padding = 0.2,
              alpha = 1,
              scale = 1,
              entries = {
                new
              }
            })
            Announce()
            addonTable.CallbackRegistry:TriggerEvent("Designer.Options", new)
          end)
        end)
      end)

      self.deleteButton:Show()
      self.deleteButton:SetPoint("BOTTOMLEFT", frame, "TOPRIGHT", 2, 2)
      self.deleteButton:SetScript("OnClick", function()
        DeleteRoot(frame, true)
      end)
      self.deleteButton:SetScript("OnEnter", function()
        frame:SetAlpha(0.5 * frame.details.alpha)
        GameTooltip:SetOwner(self.deleteButton, "ANCHOR_RIGHT")
        GameTooltip:SetText(addonTable.Locales.DELETE)
      end)
      self.deleteButton:SetScript("OnLeave", function()
        frame:SetAlpha(frame.details.alpha)
        GameTooltip:Hide()
      end)
    else
      self.dragButton:Show()
      self.dragButton:SetPoint("CENTER", frame)
      self.dragButton:SetScript("OnDragStart", function()
        frame:StartMoving()
      end)
      self.dragButton:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, relativePoint, x, y = frame:GetPoint(1)
        frame.details.anchor = {point, "UIParent", relativePoint, x, y}
      end)
      frame:SetMovable(true)
      self.dragButton:RegisterForDrag("LeftButton")
    end
  end
end

function addonTable.Designer.LayoutManagerMixin:Layout()
  self.currentLayout = addonTable.Designer.GetCurrent()

  self:Delayout()

  local wrapper = self:GetGroup(self.currentLayout)

  wrapper:SetParent(UIParent)
  wrapper:Show()

  self.root = wrapper

  self:UpdateSelection()

  self:AddHandlers(wrapper)
end
