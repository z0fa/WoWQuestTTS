local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon
local Array = __module.Array --- @class Array
local MySettings = __module.Settings

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
    local toRet = Settings.CreateControlTextContainer()

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

    local toRet = Settings.RegisterAddOnSetting(
      category, name, varName, type(defaultValue), defaultValue
    )

    local SetValue = toRet.SetValue
    toRet.SetValue = function(self, value, force)
      local tmp = SetValue(self, value, force)

      setting.set(toRet:GetValue())

      return tmp
    end

    onLoad(
      function()
        toRet:SetValue(setting.get())
      end
    )

    return toRet
  end

  local category, layout = Settings.RegisterVerticalLayoutCategory(__namespace)

  local readTitle = proxySetting(
    category, MySettings.readTitle, "Read quest title"
  )
  Settings.CreateCheckbox(category, readTitle, "")

  local readObjective = proxySetting(
    category, MySettings.readObjective, "Read quest objective"
  )
  Settings.CreateCheckbox(category, readObjective, "")

  local readNpcName = proxySetting(
    category, MySettings.readNpcName, "Read npc name"
  )
  Settings.CreateCheckbox(category, readNpcName, "")

  local autoReadQuest = proxySetting(
    category, MySettings.autoReadQuest, "Auto read quest text"
  )
  Settings.CreateCheckbox(category, autoReadQuest, "")

  local autoReadGossip = proxySetting(
    category, MySettings.autoReadGossip, "Auto read gossip text"
  )
  Settings.CreateCheckbox(category, autoReadGossip, "")

  local skipRecentText = proxySetting(
    category, MySettings.skipRecentText, "Skip recently played text"
  )
  Settings.CreateCheckbox(category, skipRecentText, "")

  local autoStopRead = proxySetting(
    category, MySettings.autoStopRead,
    "Auto stop read when closing quest/gossip frame or interacting with npc"
  )
  Settings.CreateCheckbox(category, autoStopRead, "")

  local hookAutoTurnIn = proxySetting(
    category, MySettings.hookAutoTurnIn,
    "Enable experimental AutoTurnIn integration (requires reload)"
  )
  Settings.CreateCheckbox(category, hookAutoTurnIn, "")

  local voice1 =
    proxySetting(category, MySettings.voice1, "Voice for male npcs")
  Settings.CreateDropdown(category, voice1, getVoiceOptions, "")

  local voice2 = proxySetting(
    category, MySettings.voice2, "Voice for female npcs"
  )
  Settings.CreateDropdown(category, voice2, getVoiceOptions, "")

  local voice3 = proxySetting(
    category, MySettings.voice3, "Voice for other gender npcs"
  )
  Settings.CreateDropdown(category, voice3, getVoiceOptions, "")

  local voiceSpeed =
    proxySetting(category, MySettings.voiceSpeed, "Voice speed")
  local voiceSpeedOptions = Settings.CreateSliderOptions(
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
  Settings.CreateSlider(category, voiceSpeed, voiceSpeedOptions, "")

  local voiceVolume = proxySetting(
    category, MySettings.voiceVolume, "Voice volume"
  )
  local voiceVolumeOptions = Settings.CreateSliderOptions(
    TEXTTOSPEECH_VOLUME_MIN, TEXTTOSPEECH_VOLUME_MAX, 1
  )
  voiceVolumeOptions:SetLabelFormatter(
    MinimalSliderWithSteppersMixin.Label.Top, function(val)
      return val .. "%"
    end
  )
  Settings.CreateSlider(category, voiceVolume, voiceVolumeOptions, "")

  Settings.RegisterAddOnCategory(category)
end

if Addon.isRetail then
  __module.CrossExp = module
end
