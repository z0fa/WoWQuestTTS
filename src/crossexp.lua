local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon
local Array = __module.Array --- @class Array

local useHook = Addon.useHook

local module = {}

function module.isQuestFrameShown()
  if Addon.isRetail then
    return QuestFrame:IsShown()
  else
    return QuestLogFrame:IsShown() or QuestLogDetailFrame:IsShown()
  end
end

function module.getGossipText()
  return C_GossipInfo.GetText()
end

function module.getQuestLogTitle()
  if Addon.isRetail then
    return C_QuestLog.GetTitleForQuestID(QuestMapFrame_GetFocusedQuestID())
  else
    return GetQuestLogTitle(GetQuestLogSelection())
  end
end

function module.useGossipUpdateHook(fn)
  useHook(fn, "Update", "secure-function", GossipFrame)
end

function module.initPlayButton(buttons, factory)
  if Addon.isRetail then
    buttons:push(
      factory(
        QuestMapFrame.DetailsFrame.BackFrame, -8, -10, "quest:focused"
      )
    )
    buttons:push(factory(QuestFrame, -20, 0, "quest"))
    buttons:push(factory(GossipFrame, -20, 0, "gossip"))
    buttons:push(factory(ItemTextFrame, -20, 0, "book"))
  elseif Addon.isClassic then
    buttons:push(factory(QuestFrame, -54, -20, "quest"))
    buttons:push(factory(QuestLogFrame, -56, -13, "quest:focused"))
    -- buttons:push(factory(QuestLogDetailFrame, -24, -13, "quest:focused"))
    buttons:push(factory(GossipFrame, -54, -20, "gossip"))
    buttons:push(factory(ItemTextFrame, -55, -14, "book"))
  elseif Addon.isMoP then
    buttons:push(factory(QuestFrame, -23, 0, "quest"))
    buttons:push(factory(QuestLogFrame, -23, 0, "quest:focused"))
    buttons:push(factory(QuestLogDetailFrame, -23, 0, "quest:focused"))
    buttons:push(factory(GossipFrame, -23, 0, "gossip"))
    buttons:push(factory(ItemTextFrame, -23, 0, "book"))
  else
    buttons:push(factory(QuestFrame, -23, 0, "quest"))
    buttons:push(factory(QuestLogFrame, -23, 0, "quest:focused"))
    buttons:push(factory(QuestLogDetailFrame, -24, -13, "quest:focused"))
    buttons:push(factory(GossipFrame, -23, 0, "gossip"))
    buttons:push(factory(ItemTextFrame, -55, -14, "book"))
  end
end

__module.CrossExp = module
