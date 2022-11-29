local __namespace, __module = ...

local module = {}

function module.getFrame()
  return ((ImmersionFrame or {}).TalkBox or {}).MainFrame
end

function module.guessSource()
  local toRet = nil

  local icon = ImmersionFrame.TalkBox.MainFrame.Indicator:GetTextureFilePath()
  local isGossip = icon:find("GossipGossipIcon")
  local isQuestProgress = icon:find("IncompleteQuestIcon")
  local isQuestReward = icon:find("ActiveQuestIcon")
  local isQuestDetail = icon:find("AvailableQuestIcon")

  if isGossip then
    toRet = "gossip"
  elseif isQuestProgress then
    toRet = "quest:progress"
  elseif isQuestReward then
    toRet = "quest:reward"
  elseif isQuestDetail then
    toRet = "quest:detail"
  end

  return toRet
end

__module.Immersion = module
