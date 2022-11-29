local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon
local Main = __module.Main --- @class Addon

local useHook = Addon.useHook
local onLoad = Addon.onLoad

local module = {}

local npcSource = "GossipGossip"
local playCallback = function()
end
local stopCallback = function()
end

function module.getFrame()
  return ((ImmersionFrame or {}).TalkBox or {}).MainFrame
end

function module.guessSource()
  local toRet = nil

  local icon = npcSource
  local isGossip = icon:find("GossipGossip")
  local isQuestProgress = icon:find("IncompleteQuest")
  local isQuestReward = icon:find("ActiveQuest")
  local isQuestDetail = icon:find("AvailableQuest")

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

function module.setPlayCallback(fn)
  playCallback = fn
end

function module.setStopCallback(fn)
  stopCallback = fn
end

onLoad(
  function()
    if not module.getFrame() then
      return
    end

    useHook(
      "UpdateTalkingHead",
      function(self, frame, title, text, npcType, explicitUnit, isToastPlayback)
        npcSource = npcType
        playCallback()

        return self.__oldFn(
          frame, title, text, npcType, explicitUnit, isToastPlayback
        )
      end, "function", ImmersionFrame
    )

    useHook(
      "OnHide", function()
        stopCallback()
      end, "secure-widget", ImmersionFrame
    )
  end
)

__module.Immersion = module
