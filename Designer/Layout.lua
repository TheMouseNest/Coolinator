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
  self:SetScript("OnEvent", self.OnEvent)

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
  self.itemFrame = addonTable.Designer.GetItemDialog()
  self.abilityFrame = addonTable.Designer.GetAbilityDialog()
  self.potionFrame = addonTable.Designer.GetPotionEffectDialog()
  self.equipmentFrame = addonTable.Designer.GetEquipmentDialog()
  self.movementArrows = {left = GetArrow(UIParent, math.pi / 2), right = GetArrow(UIParent, -math.pi/2), down = GetArrow(UIParent, math.pi), up = GetArrow(UIParent, 0)}
  self.selectParentButton = GetButton(self, "Interface/AddOns/Coolinator/Assets/Buttons/chain.png")
  self.selectParentButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(self.selectParentButton, "ANCHOR_LEFT")
    GameTooltip:SetText(addonTable.Locales.SELECT_GROUP)
  end)
  self.selectParentButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  self.insertButton = {
    GetButton(self, "Interface/AddOns/Coolinator/Assets/Buttons/plus.png"),
    GetButton(self, "Interface/AddOns/Coolinator/Assets/Buttons/plus.png"),
  }
  for _, b in ipairs(self.insertButton) do
    b:SetScript("OnEnter", function()
      GameTooltip:SetOwner(b, "ANCHOR_LEFT")
      GameTooltip:SetText(addonTable.Locales.INSERT)
    end)
    b:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
  end
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
  addonTable.CallbackRegistry:RegisterCallback("Designer.Options", function(_, new)
    self.selection = new
  end, self)
  addonTable.CallbackRegistry:RegisterCallback("Designer.Reanchor", self.Reanchor, self)

  self.selection = {}
end

function addonTable.Designer.LayoutManagerMixin:GetBar(details)
  local bar
  if details.resource.kind == "aura" or details.resource.kind == "ability" then
    bar = self.barIconPool:Acquire()
  else
    bar = self.barPool:Acquire()
  end
  bar:Show()
  bar:Setup(details)
  return bar
end

function addonTable.Designer.LayoutManagerMixin:GetIcon(details)
  local icon = self.iconPool:Acquire()
  icon:Show()
  icon:Setup(details)
  return icon
end

function addonTable.Designer.LayoutManagerMixin:Delayout()
  self.iconPool:ReleaseAll()
  self.barPool:ReleaseAll()
  self.barIconPool:ReleaseAll()
  self.wrappersPool:ReleaseAll()

  self.insertHorizontal:Hide()
  self.insertVertical:Hide()

  self:SetScript("OnUpdate", nil)
  self:UnregisterAllEvents()
  self.toArrange = {}
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

-- Strip all groups that aren't strictly necessary for layout
local function Degroup(groupDetails)
  for _, entry in ipairs(groupDetails.entries) do
    if entry.kind == "group" then
      Degroup(entry)
    end
  end
  local final = {}
  for _, entry in ipairs(groupDetails.entries) do
    if entry.kind == "group" and (entry.layout == groupDetails.layout or #entry.entries == 1) and entry.alpha == 1 and entry.scale == 1 and entry.padding == groupDetails.padding and entry.alignment == groupDetails.alignment then
      tAppendAll(final, entry.entries)
    else
      table.insert(final, entry)
    end
  end
  groupDetails.entries = final
end

local function IsSimilarEnough(details1, details2)
  if not details1 or not details2 then
    return false
  end
  if details1.kind ~= details2.kind then
    return false
  end
  if details1.kind == "bar" and details1.resource.kind ~= details2.resource.kind then
    return false
  end
  return true
end

-- Group similar widgets together automatically
local function GroupSimilar(groupDetails)
  if groupDetails.layout == "standalone" then
    for _, entry in ipairs(groupDetails.entries) do
      GroupSimilar(entry)
    end
    return
  end
  local last
  local count = 1
  local index = 1
  local function Apply()
    local entries = {}
    for i = index - count, index - 1 do
      local entry = groupDetails.entries[i]
      table.insert(entries, entry)
    end
    for i = index - 1, index - count, -1 do
      table.remove(groupDetails.entries, i)
    end
    index = index - count
    local new = CopyTable(addonTable.Designer.Defaults.Group)
    new.alignment = groupDetails.alignment
    new.layout = groupDetails.layout
    new.padding = groupDetails.padding
    new.entries = entries
    table.insert(groupDetails.entries, index, new)
  end
  while index <= #groupDetails.entries do
    local details = groupDetails.entries[index]
    if IsSimilarEnough(details, last) and details.kind ~= "group" then
      count = count + 1
    elseif count > 1 then
      Apply()
      count = 1
    else
      count = 1
    end
    index = index + 1
    last = details
  end
  if count > 1 and count ~= #groupDetails.entries then
    Apply()
  end

  if #groupDetails.entries == 1 then
    if groupDetails.entries[1].kind == "group" and (groupDetails.entries[1].alignment == groupDetails.alignment or groupDetails.entries[1].layout ~= groupDetails.layout) then
      groupDetails.scale = groupDetails.entries[1].scale * groupDetails.scale
      groupDetails.alpha = groupDetails.entries[1].alpha * groupDetails.alpha
      groupDetails.layout = groupDetails.entries[1].layout
      groupDetails.alignment = groupDetails.entries[1].alignment
      groupDetails.padding = groupDetails.entries[1].padding
      groupDetails.entries = groupDetails.entries[1].entries
    end
  end

  for _, entry in ipairs(groupDetails.entries) do
    if entry.kind == "group" then
      GroupSimilar(entry)
    end
  end
end

local function AutoGroup(groupDetails)
  Degroup(groupDetails)
  GroupSimilar(groupDetails)
end

local function DeleteRoot(root, shouldUpdate)
  if root.details.layout == "standalone" then
    return
  end
  local parentDetails = root:GetParent().details
  local index = tIndexOf(parentDetails.entries, root.details)
  if not index then
    return
  end

  table.remove(parentDetails.entries, index)
  root.deleted = true
  if #parentDetails.entries == 0 and parentDetails.layout ~= "standalone" then
    DeleteRoot(root:GetParent(), false)
  end

  local details = root.details
  if shouldUpdate then
    addonTable.CallbackRegistry:TriggerEvent("Designer.Options", {})
    if CheckChildren(details, function(d) return d.kind == "bar" and d.resource.kind == "aura" end) then
      addonTable.CallbackRegistry:TriggerEvent("AuraBarsChanged")
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
  if group.details.layout == "vertical" then
    for index, child in ipairs(group.children) do
      if root:GetBottom()*root:GetEffectiveScale() <= child:GetTop()*child:GetEffectiveScale() and root:GetTop()*root:GetEffectiveScale() >= child:GetBottom()*child:GetEffectiveScale() and child.details ~= root.details then
        local mod = child:GetTop()*child:GetEffectiveScale()<root:GetTop()*root:GetEffectiveScale() and 1 or 0
        if startIndex == nil then
          startIndex = index + mod
          endIndex = index + mod
        else
          endIndex = index + mod
        end
      end
    end
  else
    for index, child in ipairs(group.children) do
      if root:GetLeft()*root:GetEffectiveScale() <= child:GetRight()*child:GetEffectiveScale() and root:GetRight()*root:GetEffectiveScale() >= child:GetLeft()*child:GetEffectiveScale() and child.details ~= root.details then
        local mod = child:GetRight()*child:GetEffectiveScale()<root:GetRight()*root:GetEffectiveScale() and 1 or 0
        if startIndex == nil then
          startIndex = index + mod
          endIndex = index + mod
        else
          endIndex = index + mod
        end
      end
    end
  end

  if startIndex == nil then
    return nil
  end

  return startIndex + math.floor((endIndex - startIndex) / 2)
end

function addonTable.Designer.LayoutManagerMixin:GetInsertDirection(root, group)
  local startIndex, endIndex
  if group.details.layout == "vertical" then
    for index, child in ipairs(group.children) do
      if root:GetBottom()*root:GetEffectiveScale() <= child:GetTop()*child:GetEffectiveScale() and root:GetTop()*root:GetEffectiveScale() >= child:GetBottom()*child:GetEffectiveScale() and child.details ~= root.details then
        if startIndex == nil then
          startIndex = index
          endIndex = index
        else
          endIndex = index
        end
      end
    end
  else
    for index, child in ipairs(group.children) do
      if root:GetLeft()*root:GetEffectiveScale() <= child:GetRight()*child:GetEffectiveScale() and root:GetRight()*root:GetEffectiveScale() >= child:GetLeft()*child:GetEffectiveScale() and child.details ~= root.details then
        if startIndex == nil then
          startIndex = index
          endIndex = index
        else
          endIndex = index
        end
      end
    end
  end
  if startIndex == nil then
    return nil
  end
  local index = startIndex + math.floor((endIndex - startIndex) / 2)

  local child = group.children[index]

  if child.details.kind ~= root.details.kind and child.details.kind ~= "group" then
    index = -1
  end

  local topOverlap = child:GetTop()*child:GetEffectiveScale() - root:GetBottom()*root:GetEffectiveScale()
  local bottomOverlap = root:GetTop()*root:GetEffectiveScale() - child:GetBottom()*child:GetEffectiveScale()
  local rightOverlap = child:GetRight()*child:GetEffectiveScale() - root:GetLeft()*root:GetEffectiveScale()
  local leftOverlap = root:GetRight()*root:GetEffectiveScale() - child:GetLeft()*child:GetEffectiveScale()
  local heightMargin = math.min(root:GetHeight()*root:GetEffectiveScale(), child:GetHeight()*child:GetEffectiveScale()) * 0.4
  local widthMargin = math.min(root:GetHeight()*root:GetEffectiveScale(), child:GetWidth()*child:GetEffectiveScale()) * 0.4

  if topOverlap < heightMargin and rightOverlap > widthMargin and leftOverlap > widthMargin then
    return index, 2, "vertical"
  elseif bottomOverlap < heightMargin and rightOverlap > widthMargin and leftOverlap > widthMargin then
    return index, 1, "vertical"
  elseif rightOverlap < widthMargin and topOverlap > heightMargin and bottomOverlap > heightMargin then
    return index, 2, "horizontal"
  elseif leftOverlap < widthMargin and topOverlap > heightMargin and bottomOverlap > heightMargin then
    return index, 1, "horizontal"
  else
    return nil
  end
end

function addonTable.Designer.LayoutManagerMixin:InsertRootAt(root)
  local group = self:GetDeepestGroupOverlapping(root, self.root)
  if not group then
    local details = root.details
    local point, _, relativePoint, x, y = root:GetPoint(1)
    local new = CopyTable(addonTable.Designer.Defaults.Group)
    table.insert(new.entries, details)
    new.anchor = {point, "UIParent", relativePoint, x * root:GetEffectiveScale() / self.root:GetEffectiveScale(), y * root:GetEffectiveScale() / self.root:GetEffectiveScale()}
    DeleteRoot(root, false)
    table.insert(self.root.details.entries, new)
    AutoGroup(self.root.details)
    Announce()
    return
  end
  if root:GetParent() == group and #group.details.entries == 1 then
    if group.details.anchor then
      local point, _, relativePoint, x, y = root:GetPoint(1)
      group.details.anchor = {point, "UIParent", relativePoint, x * root:GetEffectiveScale() / self.root:GetEffectiveScale(), y * root:GetEffectiveScale() / self.root:GetEffectiveScale()}
    end
    Announce()
    return
  end
  local insertIndex = self:GetInsertionPointFromGroup(root, group)
  local altIndex, newIndex, layout = self:GetInsertDirection(root, group)
  local groupDetails = group.details
  local rootDetails = root.details
  local rootIndex = tIndexOf(groupDetails.entries, rootDetails)
  DeleteRoot(root, false)
  if layout and layout ~= groupDetails.layout then
    if rootIndex and altIndex >= rootIndex then
      altIndex = altIndex - 1
    end
    local childDetails = groupDetails.entries[altIndex]
    if #groupDetails.entries == 1 then
      groupDetails.layout = layout
      table.insert(groupDetails.entries, newIndex, rootDetails)
    elseif altIndex == -1 then
      local new = CopyTable(addonTable.Designer.Defaults.Group)
      new.layout = layout
      new.entries = {groupDetails}
      table.insert(new.entries, newIndex, rootDetails)
      local groupParentDetails = group:GetParent().details
      if groupParentDetails.layout == "standalone" then
        new.anchor = groupDetails.anchor
        groupDetails.anchor = nil
      end
      groupParentDetails.entries[tIndexOf(groupParentDetails.entries, groupDetails)] = new
    else
      local new = CopyTable(addonTable.Designer.Defaults.Group)
      new.layout = layout
      table.insert(new.entries, childDetails)
      table.insert(new.entries, newIndex, rootDetails)
      groupDetails.entries[altIndex] = new
    end
    AutoGroup(self.root.details)
  elseif insertIndex then
    if rootIndex and rootIndex < insertIndex then
      insertIndex = insertIndex - 1
    end
    table.insert(groupDetails.entries, insertIndex,  rootDetails)
    AutoGroup(self.root.details)
  else
    table.insert(groupDetails.entries, rootIndex,  rootDetails)
    AutoGroup(self.root.details)
  end
  Announce()
end

function addonTable.Designer.LayoutManagerMixin:AddHandlers(root)
  root.deleted = nil
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
      self:MarkSelected(root.details)
    elseif button == "RightButton" then
      MenuUtil.CreateContextMenu(root, function(_, rootDescription)
        rootDescription:CreateButton(addonTable.Locales.OPTIONS, function()
          addonTable.CallbackRegistry:TriggerEvent("Designer.Options", {root.details})
        end)
        local parentDetails = root:GetParent() ~= UIParent and root:GetParent().details
        if parentDetails and parentDetails.layout ~= "standalone" then
          local insert = rootDescription:CreateButton(addonTable.Locales.INSERT)
          self:AddEntryToInsert(insert, root.details, function(new)
            table.insert(parentDetails.entries, (tIndexOf(parentDetails.entries, root.details) + 1) or 1, new)
            AutoGroup(self.root.details)
            Announce()
            addonTable.CallbackRegistry:TriggerEvent("Designer.Options", {new})
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
            AutoGroup(self.root.details)
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
        local altIndex, newIndex, layout = self:GetInsertDirection(root, group)
        local anchorFrame
        local point = group.children[insertIndex]
        if layout ~= group.details.layout then
          if altIndex == -1 then
            anchorFrame = group
          else
            anchorFrame = group.children[altIndex]
          end
        elseif not point then
          anchorFrame = group
          layout = group.details.layout
        end
        if anchorFrame then
          if layout == "vertical" then
            self.insertVertical:Show()
            self.insertVertical:SetPoint("TOP", anchorFrame, newIndex == 1 and "BOTTOM" or "TOP", 0, 4 - group.details.padding * (addonTable.Constants.nativeSize - 4))
            self.insertVertical:SetSize(anchorFrame:GetWidth(), 8)
          else
            self.insertHorizontal:Show()
            self.insertHorizontal:SetPoint("RIGHT", anchorFrame, newIndex == 1 and "LEFT" or "RIGHT", 4 - group.details.padding * (addonTable.Constants.nativeSize - 4), 0)
            self.insertHorizontal:SetSize(8, anchorFrame:GetHeight())
          end
        elseif point ~= root then
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
  rootDescription:CreateButton(addonTable.Locales.ABILITY_BAR, function()
    self.abilityFrame:Update(function(data)
      local new = CopyTable(addonTable.Designer.Defaults.AbilityBar)
      new.resource.spellID = data
      if origin.kind == "bar" and origin.resource.kind == "ability" then
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
  rootDescription:CreateButton(addonTable.Locales.ITEM, function()
    self.itemFrame:Update(function(data)
      local new = CopyTable(addonTable.Designer.Defaults.ItemIcon)
      new.resource.itemID = data
      if origin.kind == "icon" and origin.resource.kind == "item" then
        ImportStyle(new, origin)
      end
      inserter(new)
    end)
  end)
  rootDescription:CreateButton(addonTable.Locales.EQUIPMENT, function()
    self.equipmentFrame:Update(function(data)
      local new = CopyTable(addonTable.Designer.Defaults.EquipmentIcon)
      new.resource.equipmentSlot = data
      if origin.kind == "icon" and origin.resource.kind == "equipment" then
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
  local index = tIndexOf(self.selection, details)
  if index then
    if IsShiftKeyDown() then
      table.remove(self.selection, index)
    else
      self.selection = {}
    end
    addonTable.CallbackRegistry:TriggerEvent("Designer.Options", self.selection)
  elseif IsShiftKeyDown() then
    local current = self.selection[1]
    if not current or current.kind == details.kind and (
      not details.resource or
      (current.resource.kind == "class" and tCompare(details.resource, current.resource)) or
      (current.resource.kind == "aura" and details.resource.kind == current.resource.kind) or
      (current.resource.kind == "ability" and details.resource.kind == current.resource.kind)
    ) then
      table.insert(self.selection, details)
      addonTable.CallbackRegistry:TriggerEvent("Designer.Options", self.selection)
    else
      UIErrorsFrame:AddMessage(addonTable.Locales.INCOMPATIBLE_WIDGET_TYPE, 1.0, 0.1, 0.1, 1.0)
    end
  else
    self.selection = {details}
    addonTable.CallbackRegistry:TriggerEvent("Designer.Options", self.selection)
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

function addonTable.Designer.LayoutManagerMixin:UpdateSelectionJustOne()
  local frame = self:GetForDetails(self.selection[1], self.root)
  if not frame then
    self.selection = {}
    return
  end
  local selector = self.selectorPool:Acquire()
  selector:Show()
  selector:SetFrameLevel(9999)
  selector:SetAllPoints(frame)
  if IsShiftKeyDown() then
    return
  end
  local details = self.selection[1]
  local parentDetails = frame:GetParent() ~= UIParent and frame:GetParent().details
  if details.kind == "group" then
    if parentDetails.layout == "vertical" then
      local up, down = self.movementArrows.up, self.movementArrows.down
      up:Show()
      down:Show()
      up:SetPoint("BOTTOM", frame, "TOP", 0, 2)
      up:SetScript("OnClick", function()
        local index = tIndexOf(parentDetails.entries, details)
        if index < #parentDetails.entries then
          local tmp = parentDetails.entries[index + 1]
          parentDetails.entries[index + 1] = details
          parentDetails.entries[index] = tmp
          Announce()
        end
      end)
      down:SetPoint("TOP", frame, "BOTTOM", 0, -2)
      down:SetScript("OnClick", function()
        local index = tIndexOf(parentDetails.entries, details)
        if index > 1 then
          local tmp = parentDetails.entries[index - 1]
          parentDetails.entries[index - 1] = details
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
        local index = tIndexOf(parentDetails.entries, details)
        if index < #parentDetails.entries then
          local tmp = parentDetails.entries[index + 1]
          parentDetails.entries[index + 1] = details
          parentDetails.entries[index] = tmp
          Announce()
        end
      end)
      left:SetPoint("RIGHT", frame, "LEFT", -2, 0)
      left:SetScript("OnClick", function()
        local index = tIndexOf(parentDetails.entries, details)
        if index > 1 then
          local tmp = parentDetails.entries[index - 1]
          parentDetails.entries[index - 1] = details
          parentDetails.entries[index] = tmp
          Announce()
        end
      end)
    end
  else
    for index, button in ipairs(self.insertButton) do
      button:ClearAllPoints()
      button:Show()
      button:SetScript("OnClick", function()
        MenuUtil.CreateContextMenu(frame, function(_, rootDescription)
          self:AddEntryToInsert(rootDescription, details, function(new)
            table.insert(parentDetails.entries, tIndexOf(parentDetails.entries, details) + index - 1, new)
            AutoGroup(self.root.details)
            Announce()
          end)
        end)
      end)
    end
    if parentDetails.layout == "vertical" then
      self.insertButton[1]:SetPoint("TOP", frame, "BOTTOM", 0, -2)
      self.insertButton[2]:SetPoint("BOTTOM", frame, "TOP", 0, 2)
    elseif parentDetails.layout == "horizontal" then
      self.insertButton[1]:SetPoint("RIGHT", frame, "LEFT", -2, 0)
      self.insertButton[2]:SetPoint("LEFT", frame, "RIGHT", 2, 0)
    end
  end
  if parentDetails.layout ~= "standalone" then
    self.selectParentButton:Show()
    self.selectParentButton:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", -2, 2)
    self.selectParentButton:SetScript("OnClick", function()
      self:MarkSelected(parentDetails)
    end)

    self.deleteButton:Show()
    self.deleteButton:SetPoint("BOTTOMLEFT", frame, "TOPRIGHT", 2, 2)
    self.deleteButton:SetScript("OnClick", function()
      DeleteRoot(frame, true)
      AutoGroup(self.root.details)
      Announce()
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

    if details.kind == "group" then
      self.popoutStandaloneButton:Show()
      self.popoutStandaloneButton:SetPoint("BOTTOM", self.selectParentButton, "TOP", 0, 2)
      self.popoutStandaloneButton:SetScript("OnClick", function()
        DeleteRoot(frame, false)
        if frame.details.kind ~= "group" then
          local tmp = CopyTable(addonTable.Designer.Defaults.Group)
          table.insert(tmp.entries, details)
          details = tmp
        end
        details.anchor = {"BOTTOM", "UIParent", "CENTER", 0, 0}
        table.insert(self.root.details.entries, details)
        AutoGroup(self.root.details)
        Announce()
      end)
    end
  else
    self.dragButton:Show()
    self.dragButton:SetPoint("CENTER", frame)
    self.dragButton:SetScript("OnDragStart", function()
      frame:StartMoving()
    end)
    self.dragButton:SetScript("OnDragStop", function()
      frame:StopMovingOrSizing()
      local point, x, y = addonTable.Designer.ConvertAnchorToCorner(frame.details.anchor[1], frame, UIParent)
      frame.details.anchor = {point, "UIParent", point, x * frame.details.scale, y * frame.details.scale}
    end)
    frame:SetMovable(true)
    self.dragButton:RegisterForDrag("LeftButton")
  end
end

function addonTable.Designer.LayoutManagerMixin:HideSelectedButtons()
  for _, frame in pairs(self.movementArrows) do
    frame:Hide()
  end
  for _, frame in ipairs(self.insertButton) do
    frame:Hide()
  end
  self.selectParentButton:Hide()
  self.deleteButton:Hide()
  self.dragButton:Hide()
  self.popoutStandaloneButton:Hide()
end

function addonTable.Designer.LayoutManagerMixin:UpdateSelection()
  self.selectorPool:ReleaseAll()
  self:HideSelectedButtons()
  if #self.selection == 1 then
    self:UpdateSelectionJustOne()
  elseif #self.selection > 1 then
    for i = #self.selection, 1, -1 do
      local details = self.selection[i]
      local frame = self:GetForDetails(details, self.root)
      if not frame then
        table.remove(self.selection, i)
      else
        local selector = self.selectorPool:Acquire()
        selector:Show()
        selector:SetFrameLevel(9999)
        selector:SetAllPoints(frame)
      end
    end
  end
end

function addonTable.Designer.LayoutManagerMixin:Reanchor(details, value)
  assert(details.anchor)
  local frame = self:GetForDetails(details, self.root)
  assert(frame)
  local _, x, y = addonTable.Designer.ConvertAnchorToCorner(value, frame, UIParent)
  details.anchor[1] = value
  details.anchor[3] = value
  details.anchor[4] = x * details.scale
  details.anchor[5] = y * details.scale
end

function addonTable.Designer.LayoutManagerMixin:OnEvent(eventName)
  if eventName == "MODIFIER_STATE_CHANGED" and #self.selection > 0 then
    if not IsShiftKeyDown() then
      self:UpdateSelection()
    else
      self:HideSelectedButtons()
    end
  end
end

function addonTable.Designer.LayoutManagerMixin:Layout()
  self.pending = true

  self.autoSize = addonTable.Config.Get(addonTable.Config.Options.COMPRESS_LAYOUT)

  self.currentLayout = addonTable.Designer.GetCurrent()

  self:Delayout()

  self:RegisterEvent("MODIFIER_STATE_CHANGED")

  local wrapper = self:GetGroup(self.currentLayout)

  wrapper:SetParent(UIParent)
  wrapper:Show()

  self.root = wrapper

  self:UpdateSelection()

  self:AddHandlers(wrapper)

  self.pending = false
end
