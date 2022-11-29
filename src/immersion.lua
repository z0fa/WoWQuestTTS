local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon
local Main = __module.Main --- @class Addon

local onLoad = Addon.onLoad
local useHook = Addon.useHook

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

  if npcSource:find("GossipGossip") then
    toRet = "gossip"
  elseif npcSource:find("IncompleteQuest") then
    toRet = "quest:progress"
  elseif npcSource:find("ActiveQuest") then
    toRet = "quest:reward"
  elseif npcSource:find("AvailableQuest") then
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

        if not npcType:find("GossipGossip") then
          playCallback()
        end

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
