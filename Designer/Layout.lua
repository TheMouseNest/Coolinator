---@class addonTableCoolinator
local addonTable = select(2, ...)

local function Announce()
  addonTable.CallbackRegistry:TriggerEvent("Designer.Layout")
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

local function GetInsertionMarker(frame, atlas)
  local texture = frame:CreateTexture()
  texture:SetAtlas(atlas)
  texture:SetAllPoints()

  return frame
end

local function ImportStyle(new, old)
  assert(new.resource.kind == old.resource.kind)
  for key, val in pairs(old) do
    if key ~= "kind" and key ~= "resource" then
      new[key] = type(val) == "table" and CopyTable(val) or val
    end
  end
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
  self.hoverMarker = GetSelectorMarker(CreateFrame("Frame", nil, UIParent), true)
  self.hoverMarker:SetFrameLevel(9999)

  self.insertVertical = GetInsertionMarker(CreateFrame("Frame", nil, UIParent), "CDM-horizontal")
  self.insertVertical:SetFrameLevel(9999)
  self.insertHorizontal = GetInsertionMarker(CreateFrame("Frame", nil, UIParent), "CDM-vertical")
  self.insertHorizontal:SetFrameLevel(9999)

  self.auraFrame = addonTable.Designer.GetAuraDialog()
  self.abilityFrame = addonTable.Designer.GetAbilityDialog()
  self.potionFrame = addonTable.Designer.GetPotionEffectDialog()
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
  self.popoutStandaloneButton = GetButton(self, "Interface/AddOns/Coolinator/Assets/Buttons/popout.png")
  self.popoutStandaloneButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(self.popoutStandaloneButton, "ANCHOR_LEFT")
    GameTooltip:SetText(addonTable.Locales.POPOUT_STANDALONE)
  end)
  self.popoutStandaloneButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  addonTable.CallbackRegistry:RegisterCallback("Designer.Open", self.Layout, self)
  addonTable.CallbackRegistry:RegisterCallback("Designer.Layout", self.Layout, self)
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
  bar:Show()
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

  self.insertHorizontal:Hide()
  self.insertVertical:Hide()
end

local function CheckChildren(details, checker)
  if checker(details) then
    return true
  elseif details.kind == "group" then
    for _, entry in ipairs(details.entries) do
      if CheckChildren(entry, checker) then
        return true
      end
    end
  end
  return false
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
    local details = root.details
    addonTable.CallbackRegistry:TriggerEvent("Designer.Options", nil)
    if shouldAnnounce then
      Announce()
      if CheckChildren(details, function(d) return d.kind == "bar" and d.resource.kind == "aura" end) then
        addonTable.CallbackRegistry:TriggerEvent("AuraBarsChanged")
      end
    end
  end
end

local function DoesRootOverlapSufficiently(root, group)
  local topExtension = root:GetTop()*root:GetEffectiveScale() - group:GetTop()*group:GetEffectiveScale()
  local bottomExtension = group:GetBottom()*group:GetEffectiveScale() - root:GetBottom()*root:GetEffectiveScale()
  local rightExtension = root:GetRight()*root:GetEffectiveScale() - group:GetRight()*group:GetEffectiveScale()
  local leftExtension = group:GetLeft()*group:GetEffectiveScale() - root:GetLeft()*root:GetEffectiveScale()
  local heightMargin = root:GetHeight()*root:GetEffectiveScale() * 0.4
  local widthMargin = root:GetHeight()*root:GetEffectiveScale() * 0.4
  local isTaller = root:GetHeight()*root:GetEffectiveScale() >= group:GetHeight()*group:GetEffectiveScale() * 0.8
  local isWider = root:GetWidth()*root:GetEffectiveScale() >= group:GetWidth()*group:GetEffectiveScale() * 0.8
  local widthDifference = (root:GetWidth()*root:GetEffectiveScale() - group:GetWidth()*group:GetEffectiveScale()) * 0.6
  local heightDifference = (root:GetHeight()*root:GetEffectiveScale() - group:GetHeight()*group:GetEffectiveScale()) * 0.6
  return (
    (topExtension < heightMargin and bottomExtension < heightMargin) or
    isTaller and (
      (topExtension >= 0 and topExtension < heightMargin and bottomExtension < 0) or
      (bottomExtension >= 0 and bottomExtension < heightMargin and topExtension < 0) or
      topExtension <= heightDifference and bottomExtension <= heightDifference
    )
  ) and (
    (rightExtension < widthMargin and leftExtension < widthMargin) or
    isWider and (
      (rightExtension >= 0 and rightExtension < widthMargin and leftExtension < 0) or
      (leftExtension >=0 and leftExtension < widthMargin and rightExtension < 0) or
      leftExtension <= widthDifference and rightExtension <= widthDifference
    )
  )
end
function addonTable.Designer.LayoutManagerMixin:GetDeepestGroupOverlapping(root, currentGroup)
  if currentGroup.details.kind ~= "group" then
    return nil
  end
  for _, g in ipairs(currentGroup.children) do
    if g.details.kind == "group" and g:Intersects(root) and (DoesRootOverlapSufficiently(root, g) or currentGroup.details.layout == "standalone") then
      local nested = self:GetDeepestGroupOverlapping(root, g)
      if nested and DoesRootOverlapSufficiently(root, nested) then
        return nested
      else
        return g
      end
    end
  end

  return nil
end

function addonTable.Designer.LayoutManagerMixin:GetInsertionPointFromGroup(root, group)
  local startIndex, endIndex
  for index, child in ipairs(group.children) do
    if child:Intersects(root) and child.details ~= root.details then
      local mod
      if group.details.layout == "horizontal" then
        mod = child:GetRight()*child:GetEffectiveScale()<root:GetRight()*root:GetEffectiveScale() and 1 or 0
      elseif group.details.layout == "vertical" then
        mod = child:GetTop()*child:GetEffectiveScale()<root:GetTop()*root:GetEffectiveScale() and 1 or 0
      end
      if startIndex == nil then
        startIndex = index + mod
        endIndex = index + mod
      else
        endIndex = index + mod
      end
    end
  end

  if startIndex == nil then
    return nil
  end

  return startIndex + math.floor((endIndex - startIndex) / 2)
end

function addonTable.Designer.LayoutManagerMixin:InsertRootAt(root)
  local group = self:GetDeepestGroupOverlapping(root, self.root)
  if not group then
    Announce()
    return
  end
  local insertIndex = self:GetInsertionPointFromGroup(root, group)
  if not insertIndex then
    Announce()
    return
  end
  local details = root.details
  local groupDetails = group.details
  local oldIndex = tIndexOf(groupDetails.entries, details)
  if oldIndex and oldIndex < insertIndex then
    insertIndex = insertIndex - 1
  end
  DeleteRoot(root, false)
  table.insert(groupDetails.entries, insertIndex, details)
  Announce()
end

function addonTable.Designer.LayoutManagerMixin:AddHandlers(root)
  root:SetFrameLevel(root:GetParent():GetFrameLevel() + 1)
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
  root.isMoving = nil
  root:SetScript("OnMouseUp", function(_, button)
    if root.isMoving then
      root.isMoving = nil
      return
    end
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
        if parentDetails then
          rootDescription:CreateButton(addonTable.Locales.WRAP_IN_GROUP, function()
            local new = CopyTable(addonTable.Designer.Defaults.Group)
            local index = tIndexOf(parentDetails.entries, root.details)
            local details = root.details
            table.insert(new.entries, details)
            if details.anchor then
              local point, _, relativePoint, x, y = unpack(details.anchor)
              new.anchor = {point, "UIParent", relativePoint, x / details.scale, y / details.scale}
              details.anchor = nil
            end
            parentDetails.entries[index] = new
            Announce()
          end)
        end
      end)
    end
  end)
  if root.details.kind ~= "group" then
    root:SetMovable(true)
    root:RegisterForDrag("LeftButton")
    root:SetScript("OnDragStart", function()
      root:SetFrameLevel(5000)
      root.isMoving = true
      root:StartMoving()
      root:SetScript("OnUpdate", function()
        self.insertHorizontal:Hide()
        self.insertVertical:Hide()
        local group = self:GetDeepestGroupOverlapping(root, self.root)
        if not group then
          return
        end
        local insertIndex = self:GetInsertionPointFromGroup(root, group)
        if not insertIndex then
          return
        end
        local point = group.children[insertIndex]
        if not point or point == root then
          if group.details.layout == "vertical" then
            self.insertVertical:Show()
            self.insertVertical:SetPoint("TOP", group, "TOP", 0, 4 - group.details.padding * (addonTable.Constants.nativeSize - 4))
            self.insertVertical:SetSize(group:GetWidth(), 8)
          else
            self.insertHorizontal:Show()
            self.insertHorizontal:SetPoint("RIGHT", group, "RIGHT", 4 - group.details.padding * (addonTable.Constants.nativeSize - 4), 0)
            self.insertHorizontal:SetSize(8, group:GetHeight())
          end
        else
          if group.details.layout == "vertical" then
            self.insertVertical:Show()
            self.insertVertical:SetPoint("TOP", point, "BOTTOM", 0, 4 - group.details.padding * (addonTable.Constants.nativeSize - 4))
            self.insertVertical:SetSize(group:GetWidth(), 8)
          else
            self.insertHorizontal:Show()
            self.insertHorizontal:SetPoint("RIGHT", point, "LEFT", 4 - group.details.padding * (addonTable.Constants.nativeSize - 4), 0)
            self.insertHorizontal:SetSize(8, group:GetHeight())
          end
        end
      end)
    end)
    root:SetScript("OnDragStop", function()
      root:StopMovingOrSizing()
      root:SetScript("OnDragStart", nil)
      root:SetScript("OnDragStop", nil) -- Necessary to prevent OnDragStop firing twice (second time is when hiden in relayout)
      root:SetScript("OnUpdate", nil)
      self:InsertRootAt(root)
    end)
  end
  if root.details.kind == "group" then
    for _, entry in ipairs(root.children) do
      self:AddHandlers(entry)
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
  rootDescription:CreateButton(addonTable.Locales.POTION_EFFECT, function()
    self.potionFrame:Update(function(data)
      local new = CopyTable(addonTable.Designer.Defaults.AuraIcon)
      new.resource.spellID = data
      if origin.kind == "icon" and origin.resource.kind == "aura" then
        ImportStyle(new, origin)
      end
      inserter(new)
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
  self.popoutStandaloneButton:Hide()
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
            local g = CopyTable(addonTable.Designer.Defaults.Group)
            table.insert(g.entries, new)
            Announce()
            addonTable.CallbackRegistry:TriggerEvent("Designer.Options", g)
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

      self.popoutStandaloneButton:Show()
      self.popoutStandaloneButton:SetPoint("BOTTOM", self.insertInParent, "TOP", 0, 2)
      self.popoutStandaloneButton:SetScript("OnClick", function()
        local details = frame.details
        DeleteRoot(frame, false)
        if frame.details.kind ~= "group" then
          local tmp = CopyTable(addonTable.Designer.Defaults.Group)
          table.insert(tmp.entries, details)
          details = tmp
        end
        details.anchor = {"BOTTOM", "UIParent", "CENTER", 0, 0}
        table.insert(self.root.details.entries, details)
        Announce()
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
        frame.details.anchor = {point, "UIParent", relativePoint, x * frame.details.scale, y * frame.details.scale}
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
