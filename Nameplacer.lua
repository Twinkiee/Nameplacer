-----------------------------------------------------------------------------------------------
-- Client Lua Script for Nameplacer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

-----------------------------------------------------------------------------------------------
-- Nameplacer Module Definition
-----------------------------------------------------------------------------------------------
local Nameplacer = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local kcrSelectedText = ApolloColor.new("UI_BtnTextHoloPressedFlyby")
local kcrNormalText = ApolloColor.new("UI_BtnTextHoloNormal")
local STR_UNIT_GRID_NAME_BOTTOM = "GridBottom"
local STR_UNIT_GRID_NAME_CHEST = "GridChest"
local STR_UNIT_GRID_NAME_CUSTOM = "GridCustom"
local STR_UNIT_GRID_NAME = "Grid"
local STR_UNIT_LIST_NAME_BOTTOM = "BottomListContainer"
local STR_UNIT_LIST_NAME_CHEST = "ChestListContainer"
local STR_UNIT_LIST_NAME_CUSTOM = "CustomListContainer"
local STR_NAMEPLACER_MAIN_WND = "NameplacerConfigForm"
local STR_UNIT_NAME_INPUT = "UnitNameInput"
local STR_UNIT_LIST_SELECTED_BG = "BK3:UI_BK3_Holo_InsetHeader"
local STR_UNIT_LIST_UNSELECTED_BG = "BK3:UI_BK3_Holo_InsetHeaderThin"
local STR_BTN_FROM_CHEST_TO_BOTTOM = "ButtonFromChestToBottom"
local STR_BTN_FROM_BOTTOM_TO_CHEST = "ButtonFromBottomToChest"
local STR_BTN_FROM_BOTTOM_TO_CUSTOM = "ButtonFromBottomToCustom"
local STR_BTN_FROM_CUSTOM_TO_BOTTOM = "ButtonFromCustomToBottom"

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Nameplacer:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  -- initialize variables here
  o.tUnits = {} -- keep track of all the list items

  -- keep track of which unit is currently selected
  o.strSelectedUnitName = nil

  -- Main unit position list container
  o.wndSelectedUnitPosList = nil

  return o
end

function Nameplacer:Init()
  local bHasConfigureFunction = false
  local strConfigureButtonText = ""
  local tDependencies = {-- "UnitOrPackageName",
  }
  Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end


-----------------------------------------------------------------------------------------------
-- Nameplacer OnLoad
-----------------------------------------------------------------------------------------------
function Nameplacer:OnLoad()
  -- load our form file
  self.xmlDoc = XmlDoc.CreateFromFile("Nameplacer.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- Nameplacer OnDocLoaded
-----------------------------------------------------------------------------------------------
function Nameplacer:OnDocLoaded()

  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    self.wndMain = Apollo.LoadForm(self.xmlDoc, STR_NAMEPLACER_MAIN_WND, nil, self)
    if self.wndMain == nil then
      Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
      return
    end

    -- unit lists containers
    self.wndUnitListChest = self.wndMain:FindChild(STR_UNIT_LIST_NAME_CHEST)
    self.wndUnitListBottom = self.wndMain:FindChild(STR_UNIT_LIST_NAME_BOTTOM)
    self.wndUnitListCustom = self.wndMain:FindChild(STR_UNIT_LIST_NAME_CUSTOM)

    -- unit grids
    self.wndUnitGridChest = self.wndUnitListChest:FindChild(STR_UNIT_GRID_NAME)
    self.wndUnitGridBottom = self.wndUnitListBottom:FindChild(STR_UNIT_GRID_NAME)
    self.wndUnitGridCustom = self.wndUnitListCustom:FindChild(STR_UNIT_GRID_NAME)
    self.wndSelectedUnitPosList = self.wndUnitListChest

    -- buttons
    self.wndButtonFromChestToBottom = self.wndMain:FindChild(STR_BTN_FROM_CHEST_TO_BOTTOM)
    self.wndButtonFromBottomToChest = self.wndMain:FindChild(STR_BTN_FROM_BOTTOM_TO_CHEST)
    self.wndButtonFromBottomToCustom = self.wndMain:FindChild(STR_BTN_FROM_BOTTOM_TO_CUSTOM)
    self.wndButtonFromCustomToBottom = self.wndMain:FindChild(STR_BTN_FROM_CUSTOM_TO_BOTTOM)

    self.tUnitLists = { [STR_UNIT_LIST_NAME_CHEST] = self.wndUnitListChest, [STR_UNIT_LIST_NAME_BOTTOM] = self.wndUnitListBottom, [STR_UNIT_LIST_NAME_CUSTOM] = self.wndUnitListCustom }
    self.tUnitGrids = { [STR_UNIT_GRID_NAME_CHEST] = self.wndUnitGridChest, [STR_UNIT_GRID_NAME_BOTTOM] = self.wndUnitGridBottom, [STR_UNIT_GRID_NAME_CUSTOM] = self.wndUnitGridCustom }
    self.wndUnitNameInput = self.wndMain:FindChild(STR_UNIT_NAME_INPUT)
    self.wndMain:Show(false, true)

    -- if the xmlDoc is no longer needed, you should set it to nil
    -- self.xmlDoc = nil

    -- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
    Apollo.RegisterSlashCommand("nameplacer", "OnNameplacerOn", self)

    Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)


    -- Do additional Addon initialization here
  end
end

-----------------------------------------------------------------------------------------------
-- Nameplacer Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/nameplacer"
function Nameplacer:OnNameplacerOn()
  self.wndMain:Invoke() -- show the window

  self:ResetListSelection()
  -- populate the item list
  -- self:PopulateItemList()
end


-----------------------------------------------------------------------------------------------
-- NameplacerForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function Nameplacer:OnOK()
  self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function Nameplacer:OnCancel()
  self.wndMain:Close() -- hide the window
end


-----------------------------------------------------------------------------------------------
-- ItemList Functions
-----------------------------------------------------------------------------------------------

------------------------------------------------------------------------
-- Add a new unit to the units list and updates the related grid
------------------------------------------------------------------------
function Nameplacer:AddUnit(strUnitName, wndUnitGrid)

  self:AddUnitRow(strUnitName, wndUnitGrid)

  if (wndUnitGrid == STR_UNIT_GRID_NAME_CHEST) then
    table.insert(self.tUnits, strUnitName, { nAnchorId = CombatFloater.CodeEnumFloaterLocation.Chest })
  elseif (wndUnitGrid == STR_UNIT_GRID_NAME_BOTTOM) then
    table.insert(self.tUnits, strUnitName, { nAnchorId = CombatFloater.CodeEnumFloaterLocation.Bottom })
  else
    table.insert(self.tUnits, strUnitName, { nOffsetY = 0 })
  end

  -- end
end

------------------------------------------------------------------------
-- Add a new row to the units grid
------------------------------------------------------------------------
function Nameplacer:AddUnitRow(strUnitName, wndUnitGrid)

  local strGridName = wndUnitGrid:GetName()
  Print("wndUnitGrid: " .. wndUnitGrid:GetName() .. "; strUnitName: " .. strUnitName)

  local nNewRowIndex = wndUnitGrid:AddRow(strUnitName)

  Print("tRowIndex: " .. tostring(nNewRowIndex))

  self:SelectUnitGridRow(nNewRowIndex, wndUnitGrid)

  table.insert(self.tUnits, strUnitName, { strPosType = strGridName, nValue = 0 })
  -- end
end

------------------------------------------------------------------------
-- Remove a unit from the units list and updates the related grid
------------------------------------------------------------------------
function Nameplacer:DeleteUnit(strUnitName, wndUnitGrid)

  local nDeletedRow = self:DeleteUnitRow(strUnitName, wndUnitGrid)

  if (nDeletedRow) then
    table.remove(self.tUnits, strUnitName)
  end
end

------------------------------------------------------------------------
-- Deletes a row from the units list if the unit is actually in the list
------------------------------------------------------------------------
function Nameplacer:DeleteUnitRow(strUnitName, wndUnitGrid)
  local nRowIndex = self:GetUnitRowIndex(strUnitName, wndUnitGrid)

  if (nRowIndex) then
    wndUnitGrid:DeleteRow(nRowIndex)
  end

  return nRowIndex
end

------------------------------------------------------------------------
-- Returns the grid contained by the given list.
------------------------------------------------------------------------
function Nameplacer:FromListToGrid(wndList)
  if (wndList:GetName() == STR_UNIT_LIST_NAME_BOTTOM) then
    return self.self.wndUnitGridBottom
  elseif (wndList:GetName() == STR_UNIT_LIST_NAME_CHEST) then
    return self.self.wndUnitGridChest
  else
    return self.self.wndUnitGridCustom
  end

end

------------------------------------------------------------------------
-- Returns the row index for the given units list.
-- Returns nil if the unit is not present or the list is nil
------------------------------------------------------------------------
function Nameplacer:GetUnitRowIndex(strUnitName, wndUnitGrid)

  if (not wndUnitGrid) then
    return nil
  end

  Print("wndUnitGrid:GetName(): " .. wndUnitGrid:GetName() .. "; strUnitName: " .. strUnitName)

  local tRowIndex

  local trackedUnitCount = wndUnitGrid:GetRowCount()
  for i = 1, trackedUnitCount do
    local strCurrUnitName = wndUnitGrid:GetCellText(i, 1)
    if (strUnitName == strCurrUnitName) then
      tRowIndex = i
      return tRowIndex
    end
  end

  return nil
end

--function Nameplacer:InitUnitList()
--
--  local nRowIndex
--
--  for _, wndGrid in pairs(self.tUnitGrids) do
--
--    nRowIndex = self:GetUnitRowIndex(self.strSelectedUnitName, wndGrid)
--    if (nRowIndex) then
--      self:SelectUnitGridRow(nRowIndex, wndGrid)
--      return
--    end
--  end
--
--  self:ResetGridSelection()
--end

-------------------------------------------------------------------------
-- Update the selected unit input box
-------------------------------------------------------------------------
function Nameplacer:UpdateUnitNameInput(strUnitName)
  self.strSelectedUnitName = strUnitName
  self.wndUnitNameInput:SetText(strUnitName)
end

-------------------------------------------------------------------------
-- Update the selected unit and signal the update
-------------------------------------------------------------------------
function Nameplacer:UpdateSelectedUnit(strUnitName, nCodeEnumFloaterLocation, nYoffset)
  self.strSelectedUnitName = strUnitName
  Event_FireGenericEvent("Nameplacer_UnitNameplatePositionChanged", nCodeEnumFloaterLocation, nYoffset)
end


-------------------------------------------------------------------------
-- Unselect any grid selection other than the selected one
-------------------------------------------------------------------------
function Nameplacer:ResetGridSelection(wndSelectedGrid)

  for _, wndGrid in pairs(self.tUnitGrids) do

    if (wndSelectedGrid ~= wndGrid) then
      wndGrid:SetCurrentRow(0)
    end
  end

  if (wndSelectedGrid) then
    self:ResetListSelection(wndSelectedGrid:GetParent())
  end
end

function Nameplacer:SelectUnitGridRow(nRowIndex, wndGrid)

  Print("nRowIndex: " .. tostring(nRowIndex))
  Print("wndGrid: " .. wndGrid:GetParent():GetName())
  wndGrid:SelectCell(nRowIndex, 1)
  self:ResetGridSelection(wndGrid)
end


function Nameplacer:ResetListSelection(wndSelectedUnitPosListContainer)
  self.wndSelectedUnitPosList = wndSelectedUnitPosListContainer

  -- Print("self.wndSelectedUnitPosList: " .. self.wndSelectedUnitPosList:GetName())
  local strSelectedUnitPosContainerName
  local wndUnitPosListContainerBackground

  if (wndSelectedUnitPosListContainer) then
    strSelectedUnitPosContainerName = wndSelectedUnitPosListContainer:GetName()
    wndUnitPosListContainerBackground = wndSelectedUnitPosListContainer:FindChild("Background")
    wndUnitPosListContainerBackground:SetSprite(STR_UNIT_LIST_SELECTED_BG)
  end

  for strUnitPosListName, wndUnitPosListContainer in pairs(self.tUnitLists) do

    Print("wndUnitPosListContainer: " .. tostring(strSelectedUnitPosContainerName))

    if (not wndSelectedUnitPosListContainer or wndUnitPosListContainer:GetName() ~= wndSelectedUnitPosListContainer:GetName()) then

      wndUnitPosListContainerBackground = wndUnitPosListContainer:FindChild("Background")
      wndUnitPosListContainerBackground:SetSprite(STR_UNIT_LIST_UNSELECTED_BG)
    end
  end

  if (strSelectedUnitPosContainerName == STR_UNIT_LIST_NAME_CHEST) then
    self.wndButtonFromChestToBottom:Enable(true)
    self.wndButtonFromBottomToChest:Enable(false)
    self.wndButtonFromBottomToCustom:Enable(false)
    self.wndButtonFromCustomToBottom:Enable(false)
  elseif (strSelectedUnitPosContainerName == STR_UNIT_LIST_NAME_BOTTOM) then
    self.wndButtonFromChestToBottom:Enable(false)
    self.wndButtonFromBottomToChest:Enable(true)
    self.wndButtonFromBottomToCustom:Enable(true)
    self.wndButtonFromCustomToBottom:Enable(false)
  elseif (strSelectedUnitPosContainerName == STR_UNIT_LIST_NAME_CUSTOM) then
    self.wndButtonFromChestToBottom:Enable(false)
    self.wndButtonFromBottomToChest:Enable(false)
    self.wndButtonFromBottomToCustom:Enable(false)
    self.wndButtonFromCustomToBottom:Enable(true)
  else
    self.wndButtonFromChestToBottom:Enable(false)
    self.wndButtonFromBottomToChest:Enable(false)
    self.wndButtonFromBottomToCustom:Enable(false)
    self.wndButtonFromCustomToBottom:Enable(false)
  end
end

-------------------------------------------------------------------------
-- On add unit button press
-------------------------------------------------------------------------
function Nameplacer:OnAddUnit()
  local wndUnitNameInput = self.wndUnitNameInput
  local strUnitName = trim(wndUnitNameInput:GetText())

  Print("strUnitName: " .. strUnitName)
  Print("self:GetUnitRowIndex(strUnitName, self.wndUnitGridBottom): " .. tostring(self:GetUnitRowIndex(strUnitName, self.wndUnitGridBottom)))
  Print("self:GetUnitRowIndex(strUnitName, self.wndUnitGridChest): " .. tostring(self:GetUnitRowIndex(strUnitName, self.wndUnitGridChest)))
  Print("self:GetUnitRowIndex(strUnitName, self.wndUnitGridCustom): " .. tostring(self:GetUnitRowIndex(strUnitName, self.wndUnitGridCustom)))
  Print("self.wndSelectedUnitPosList: " .. self.wndSelectedUnitPosList:GetName())

  if (not self:GetUnitRowIndex(strUnitName, self.wndUnitGridBottom) and not self:GetUnitRowIndex(strUnitName, self.wndUnitGridChest) and not self:GetUnitRowIndex(strUnitName, self.wndUnitGridCustom)) then
    local nNewRowIndex = self:AddUnitRow(strUnitName, self:FromListToGrid(self.wndSelectedUnitPosList))
  end
end

function Nameplacer:OnDeleteUnit()
  local wndUnitNameInput = self.wndUnitNameInput
  local strUnitName = trim(wndUnitNameInput:GetText())

  Print("strUnitName: " .. strUnitName)
  Print("self.wndSelectedUnitPosList: " .. self.wndSelectedUnitPosList:GetName())

  self:DeleteUnit(strUnitName, self:FromListToGrid(self.wndSelectedUnitPosList))


--  for _, wndUnitGrid in pairs(self.tUnitGrids) do
--    local nUnitRowIndex = self:GetUnitRowIndex(strUnitName, wndUnitGrid)
--
--    Print("wndUnitGrid:" .. wndUnitGrid:GetName() .. "; self:GetUnitRowIndex(strUnitName, wndUnitGrid): " .. tostring(nUnitRowIndex))
--
--    if (nUnitRowIndex) then
--      self:DeleteUnit(strUnitName, wndUnitGrid)
--      return
--    end
--  end
end

-------------------------------------------------------------------------
-- On unit list row selection change
-------------------------------------------------------------------------
function Nameplacer:OnUnitListSelChange(wndControl, wndHandler, iRow, iCol)

  Print("wndHandler: " .. wndHandler:GetName() .. "; wndControl: " .. wndControl:GetName() .. "; iRow: " .. tostring(iRow) .. "; iCol: " .. tostring(iCol))
  local strUnitName = wndHandler:GetCellText(iRow, iCol)

  self:UpdateUnitNameInput(strUnitName)

  --  for a, wndUnitGrid in ipairs(self.tUnitGrids) do
  --
  --    Print("Grid: " .. wndUnitGrid:GetParent():GetName())
  --
  --    if (wndUnitGrid ~= wndHandler) then
  --      Print("Resetting grid selection: " .. wndUnitGrid:GetParent():GetName())
  --      wndHandler:SetCurrentRow(0)
  --    end
  --  end

  local wndSelectedUnitPosListContainer = wndHandler:GetParent()

  if (not self.tUnitGrids) then
    Print("not self.tUnitGrids")
  end
  Print(table.tostring(self.tUnitGrids))

  self:ResetGridSelection(wndHandler)
end

function Nameplacer:OnTargetUnitChanged(oTarget)

  if (not oTarget) then return end

  local strUnitName = oTarget:GetName()
  self:UpdateUnitNameInput(strUnitName)
end

---------------------------------------------------------------------------------------------------
-- NameplacerConfigForm Functions
---------------------------------------------------------------------------------------------------

--function Nameplacer:OnUnitPosListGainedFocus(wndHandler, wndControl)
--
--  self.wndSelectedUnitPosList = wndHandler
--
--  local wndUnitPosListContainerBackground
--
--  for strUnitPosListName, wndUnitPosList in pairs(self.tUnitLists) do
--    local wndCurrUnitPosList = wndControl:FindChild(strUnitPosListName)
--
--    if wndCurrUnitPosList then
--
--      self.wndSelectedUnitPosList = wndCurrUnitPosList
--      wndUnitPosListContainerBackground = wndControl:FindChild("Background")
--      wndUnitPosListContainerBackground:SetSprite(STR_UNIT_LIST_SELECTED_BG)
--    else
--
--      local wndUnitPosListContainer = wndUnitPosList:GetParent()
--      wndUnitPosListContainerBackground = wndUnitPosListContainer:FindChild("Background")
--      wndUnitPosListContainerBackground:SetSprite(STR_UNIT_LIST_UNSELECTED_BG)
--    end
--  end
--end


function Nameplacer:OnButtonSignalButtonSelectUnitPosList(wndHandler, wndControl, eMouseButton)

  Print("OnButtonSignalButtonSelectUnitPosList; wndControl: " .. wndControl:GetName())

  local wndSelectedUnitPosListContainer = wndHandler:GetParent()
  self:ResetListSelection(wndSelectedUnitPosListContainer)
end

function Nameplacer:OnButtonSignalChangeUnitList(wndHandler, wndControl, eMouseButton)

  local strButtonName = wndControl:GetName()
  Print("OnButtSigChangePos; wndControl: " .. wndControl:GetName())

  if (strButtonName == STR_BTN_FROM_CHEST_TO_BOTTOM) then
    self:DeleteUnitRow(self.strSelectedUnitName, self.wndUnitGridChest)
    self:AddUnitRow(self.strSelectedUnitName, self.wndUnitGridBottom)
    self:ResetGridSelection(self.wndUnitGridBottom)
    self.wndUnitGridBottom:SetCurrentRow(self:GetUnitRowIndex(self.strSelectedUnitName, self.wndUnitGridBottom))
  elseif (strButtonName == STR_BTN_FROM_BOTTOM_TO_CHEST) then
    self:DeleteUnitRow(self.strSelectedUnitName, self.wndUnitGridBottom)
    self:AddUnitRow(self.strSelectedUnitName, self.wndUnitGridChest)
    self:ResetGridSelection(self.wndUnitGridChest)
    self.wndUnitGridChest:SetCurrentRow(self:GetUnitRowIndex(self.strSelectedUnitName, self.wndUnitGridChest))
  elseif (strButtonName == STR_BTN_FROM_BOTTOM_TO_CUSTOM) then
    self:DeleteUnitRow(self.strSelectedUnitName, self.wndUnitGridBottom)
    self:AddUnitRow(self.strSelectedUnitName, self.wndUnitGridCustom)
    self:ResetGridSelection(self.wndUnitGridCustom)
    self.wndUnitGridCustom:SetCurrentRow(self:GetUnitRowIndex(self.strSelectedUnitName, self.wndUnitGridCustom))
  elseif (strButtonName == STR_BTN_FROM_CUSTOM_TO_BOTTOM) then
    self:DeleteUnitRow(self.strSelectedUnitName, self.wndUnitGridCustom)
    self:AddUnitRow(self.strSelectedUnitName, self.wndUnitGridBottom)
    self:ResetGridSelection(self.wndUnitGridBottom)
    self.wndUnitGridBottom:SetCurrentRow(self:GetUnitRowIndex(self.strSelectedUnitName, self.wndUnitGridBottom))
  end
end

function Nameplacer:OnEditBoxChangedUnitNameInput(wndHandler, wndControl, strText)

  for strUnitGridName, wndUnitGrid in pairs(self.tUnitGrids) do
    local nUnitRowIndex = self:GetUnitRowIndex(strText, wndUnitGrid)

    if (nUnitRowIndex) then
      self.strSelectedUnitName = strText
      self:SelectUnitGridRow(nUnitRowIndex, wndUnitGrid)
      return
    end
  end

  self:ResetGridSelection()
end

-----------------------------------------------------------------------------------------------
-- Nameplacer Instance
-----------------------------------------------------------------------------------------------
local NameplacerInst = Nameplacer:new()
NameplacerInst:Init()


function table.val_to_str(v)
  if "string" == type(v) then
    v = string.gsub(v, "\n", "\\n")
    if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v, '"', '\\"') .. '"'
  else
    return "table" == type(v) and table.tostring(v) or
        tostring(v)
  end
end

function table.key_to_str(k)
  if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
    return k
  else
    return "[" .. table.val_to_str(k) .. "]"
  end
end

function table.tostring(tbl)
  local result, done = {}, {}
  for k, v in ipairs(tbl) do
    table.insert(result, table.val_to_str(v))
    done[k] = true
  end
  for k, v in pairs(tbl) do
    if not done[k] then
      table.insert(result,
        table.key_to_str(k) .. "=" .. table.val_to_str(v))
    end
  end
  return "{" .. table.concat(result, ",") .. "}"
end
