local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon
local Array = __module.Array --- @class Array
local Settings = __module.Settings
local GameSettings = _G["Settings"]

local onLoad = Addon.onLoad
local useHook = Addon.useHook



local module = {}

function module.isQuestFrameShown()
  return QuestFrame:IsShown()
end

function module.getGossipText()
  return C_GossipInfo.GetText()
end

function module.getQuestLogTitle()
  return C_QuestLog.GetTitleForQuestID(QuestMapFrame_GetFocusedQuestID())
end

function module.useGossipUpdateHook(fn)
  useHook("Update", fn, "secure-function", GossipFrame)
end

function module.initPlayButton(buttons, factory)
  buttons:push(factory(QuestMapFrame.DetailsFrame.BackFrame, -8, -10, "quest:focused"))
  buttons:push(factory(QuestFrame, -20, 0, "quest"))
  buttons:push(factory(GossipFrame, -20, 0, "gossip"))
  buttons:push(factory(ItemTextFrame, -20, 0, "book"))
end

function module.initSettings()
  local function getVoiceOptions()
    local toRet = GameSettings.CreateControlTextContainer()

    Array.new(C_VoiceChat.GetTtsVoices()):forEach(
      function(voice)
        toRet:Add(voice.voiceID, voice.name)
      end
    )

    return toRet:GetData()
  end

  local function proxySetting(category, setting, name)
    local globalName = setting.globalName
    local varName = setting.varName
    local defaultValue = setting.defaultValue

    local varTbl = _G[globalName]
    local varKey = varName
    local toRet = GameSettings.RegisterAddOnSetting(
      category, varName, varKey, varTbl, type(defaultValue), name, defaultValue
    )
    --[[
    local toRet = GameSettings.RegisterAddOnSetting(
      category, name, varName, type(defaultValue), defaultValue
    )

    local SetValue = toRet.SetValue
    toRet.SetValue = function(self, value, force)
      local tmp = SetValue(self, value, force)

      setting.set(toRet:GetValue())

      return tmp
    end
    ]]
    onLoad(
      function()
        toRet:SetValue(setting.get())
      end
    )

    return toRet
  end

  local category, layout = GameSettings.RegisterVerticalLayoutCategory(__namespace)
  Settings.CATEGORY_ID = category:GetID()

  local readTitle = proxySetting(
    category, Settings.readTitle, "Read quest title"
  )
  GameSettings.CreateCheckbox(category, readTitle, "")

  local readObjective = proxySetting(
    category, Settings.readObjective, "Read quest objective"
  )
  GameSettings.CreateCheckbox(category, readObjective, "")

  local readNpcName = proxySetting(
    category, Settings.readNpcName, "Read npc name"
  )
  GameSettings.CreateCheckbox(category, readNpcName, "")

  local autoReadQuest = proxySetting(
    category, Settings.autoReadQuest, "Auto read quest text"
  )
  GameSettings.CreateCheckbox(category, autoReadQuest, "")

  local autoReadGossip = proxySetting(
    category, Settings.autoReadGossip, "Auto read gossip text"
  )
  GameSettings.CreateCheckbox(category, autoReadGossip, "")

  local skipRecentText = proxySetting(
    category, Settings.skipRecentText, "Skip recently played text"
  )
  GameSettings.CreateCheckbox(category, skipRecentText, "")

  local autoStopRead = proxySetting(
    category, Settings.autoStopRead,
    "Auto stop read when closing quest/gossip frame or interacting with npc"
  )
  GameSettings.CreateCheckbox(category, autoStopRead, "")

  local hookAutoTurnIn = proxySetting(
    category, Settings.hookAutoTurnIn,
    "Enable experimental AutoTurnIn integration (requires reload)"
  )
  GameSettings.CreateCheckbox(category, hookAutoTurnIn, "")

  local voice1 =
    proxySetting(category, Settings.voice1, "Voice for male npcs")
  GameSettings.CreateDropdown(category, voice1, getVoiceOptions, "")

  local voice2 = proxySetting(
    category, Settings.voice2, "Voice for female npcs"
  )
  GameSettings.CreateDropdown(category, voice2, getVoiceOptions, "")

  local voice3 = proxySetting(
    category, Settings.voice3, "Voice for other gender npcs"
  )
  GameSettings.CreateDropdown(category, voice3, getVoiceOptions, "")

  local voiceSpeed =
    proxySetting(category, Settings.voiceSpeed, "Voice speed")
  local voiceSpeedOptions = GameSettings.CreateSliderOptions(
    TEXTTOSPEECH_RATE_MIN, TEXTTOSPEECH_RATE_MAX, 1
  )
  voiceSpeedOptions:SetLabelFormatter(
    MinimalSliderWithSteppersMixin.Label.Left, function()
      return "Slow"
    end
  )
  voiceSpeedOptions:SetLabelFormatter(
    MinimalSliderWithSteppersMixin.Label.Right, function()
      return "Fast"
    end
  )
  GameSettings.CreateSlider(category, voiceSpeed, voiceSpeedOptions, "")

  local voiceVolume = proxySetting(
    category, Settings.voiceVolume, "Voice volume"
  )
  local voiceVolumeOptions = GameSettings.CreateSliderOptions(
    TEXTTOSPEECH_VOLUME_MIN, TEXTTOSPEECH_VOLUME_MAX, 1
  )
  voiceVolumeOptions:SetLabelFormatter(
    MinimalSliderWithSteppersMixin.Label.Top, function(val)
      return val .. "%"
    end
  )
  GameSettings.CreateSlider(category, voiceVolume, voiceVolumeOptions, "")

  GameSettings.RegisterAddOnCategory(category)
end

if Addon.isRetail then
  __module.CrossExp = module
end
