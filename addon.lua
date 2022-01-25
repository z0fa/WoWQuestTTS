local addon = CreateFrame("Frame")

local frames = {
  QuestTTSPlayButton1 = nil,
  QuestTTSPlayButton2 = nil,
  QuestTTSPlayButton3 = nil,
  QuestTTSPlayButton4 = nil,
  QuestTTSPlayButton5 = nil,
}

local state = {
  isPlaying = false,
}

function addon:Init()
  addon:SetScript("OnEvent", addon.OnEvent)
  addon:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_FINISHED")
  addon:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_FAILED")

  frames.QuestTTSPlayButton1 = frames:InitQuestTTSPlayButton(QuestMapFrame.DetailsFrame, 18, 30, "questlog")
  frames.QuestTTSPlayButton2 = frames:InitQuestTTSPlayButton(QuestFrame, -10, -30, "")
  frames.QuestTTSPlayButton3 = frames:InitQuestTTSPlayButton(GossipFrame, -10, -30, "gossip")
  frames.QuestTTSPlayButton4 = frames:InitQuestTTSPlayButton(addon:ImmersionGetFrame(), -59, -17, "immersion")
  frames.QuestTTSPlayButton5 = frames:InitQuestTTSPlayButton(ItemTextFrame, -23, 0, "book")

  QuestTTS.dynamicVoice = QuestTTS.dynamicVoice or false
end

function addon:OnEvent(event)
  if event == "VOICE_CHAT_TTS_PLAYBACK_FINISHED" or event == "VOICE_CHAT_TTS_PLAYBACK_FAILED" then
    state.isPlaying = false
    frames:Update()
  end
end

function addon:ReadQuest(source)
  if state.isPlaying then
    addon:TTSStop()
    return
  end

  local text = ""

  if (source == "questlog") then
    local title = C_QuestLog.GetTitleForQuestID(QuestMapFrame_GetFocusedQuestID())
    local description, objective = GetQuestLogQuestText()
    text = title .. "\n" .. description .. "\n" .. objective
  elseif (source == "gossip" or (source == "immersion" and addon:ImmersionIsGossip())) then
    local info = C_GossipInfo.GetText()
    text = info
  elseif (source == "book") then
    local title = ItemTextGetItem()
    local description = ItemTextGetText()
    text = title .. "\n" .. description
  elseif (QuestFrameRewardPanel:IsShown()) then
    local title = GetTitleText()
    local reward = GetRewardText()
    text = title .. "\n" .. reward
  elseif (QuestFrameProgressPanel:IsShown()) then
    local title = GetTitleText()
    local progress = GetProgressText()
    text = title .. "\n" .. progress
  else
    local title = GetTitleText()
    local description = GetQuestText()
    local objective = GetObjectiveText()
    text = title .. "\n" .. description .. "\n" .. objective
  end

  addon:TTSPlay(addon:CleanText(text))
end

function addon:KeyboundReadQuest()
  local isImmersionLoaded = addon.ImmersionGetFrame() ~= -1
  local isQuestFocused = QuestMapFrame_GetFocusedQuestID()

  if WorldMapFrame:IsVisible() and isQuestFocused then
    addon:ReadQuest("questlog")
  elseif QuestFrame:IsVisible() then
    addon:ReadQuest("")
  elseif GossipFrame:IsVisible() and not isImmersionLoaded then
    addon:ReadQuest("gossip")
  elseif isImmersionLoaded and addon.ImmersionGetFrame():IsVisible() then
    addon:ReadQuest("immersion")
  else
    addon:TTSStop()
  end
end

function addon:RunCmd(msg)
  local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

  if cmd == "play" then
    addon:KeyboundReadQuest()
    addon:Print("Playing...")
  elseif cmd == "stop" then
    addon:TTSStop()
    addon:Print("Stopping...")
  elseif cmd == "dvoice" then
    QuestTTS.dynamicVoice = not QuestTTS.dynamicVoice
    local status = QuestTTS.dynamicVoice and "ENABLED" or "DISABLED"
    addon:Print("Experimental dynamic voice is now " .. status)
  end
end

function addon:CleanText(text)
  local toRet = text

  toRet = toRet:gsub("<", ""):gsub(">", "")

  return toRet
end

function addon:TTSPlay(text)
  state.isPlaying = true
  TextToSpeech_Speak(text, TextToSpeech_GetSelectedVoice(addon:GetTTSVoice()))
  frames:Update()
end

function addon:TTSStop()
  state.isPlaying = false
  C_VoiceChat.StopSpeakingText()
  frames:Update()
end

function addon:ImmersionGetFrame()
  if (ImmersionFrame and ImmersionFrame.TalkBox and ImmersionFrame.TalkBox.MainFrame) then
    return ImmersionFrame.TalkBox.MainFrame
  end

  return -1
end

function addon:ImmersionIsGossip()
  return ImmersionFrame.TalkBox.MainFrame.Indicator:GetTextureFilePath():find("GossipGossipIcon")
end

function addon:GetTTSVoice()
  local toRet = 0

  if not QuestTTS.dynamicVoice then
    return toRet
  end

  if UnitExists("target") and UnitSex("target") == Enum.Unitsex.Female then
    toRet = 0
  else
    toRet = 1
  end

  return toRet
end

function addon:Print(msg)
  print("|cffff8000QuestTTS: |r" .. msg)
end

function addon:Dump(var)
  DevTools_Dump(var)
end

function frames:InitQuestTTSPlayButton(parent, x, y, fromQuestLog)
  if (parent == -1) then
    return {
      Update = function() end
    }
  end

  local button = CreateFrame("Button", nil, parent)
  button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
  button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  button:SetPoint("TOPRIGHT", x, y)
  button:SetWidth(22)
  button:SetHeight(22)
  button:RegisterForClicks("LeftButtonUp", "RightButtonDown")
  button:SetScript("OnClick", function(_, event)
    if event == "RightButton" then
      InterfaceOptionsAccessibilityPanelConfigureTextToSpeechButton_OnClick()
    else
      addon:ReadQuest(fromQuestLog)
    end
  end)
  button.Update = function()
    if state.isPlaying then
      button:SetNormalTexture("Interface\\TimeManager\\PauseButton")
    else
      button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    end
  end

  return button
end

function frames:Update()
  frames.QuestTTSPlayButton1:Update()
  frames.QuestTTSPlayButton2:Update()
  frames.QuestTTSPlayButton3:Update()
  frames.QuestTTSPlayButton4:Update()
  frames.QuestTTSPlayButton5:Update()
end

QuestTTS = QuestTTS or {}
BINDING_HEADER_QUESTTTS = "Quest TTS"
BINDING_NAME_QUESTTTS_PLAY = "Read quest"
SLASH_QUESTTTS1 = "/qtts"
SlashCmdList["QUESTTTS"] = function(msg) addon:RunCmd(msg) end
function QuestTTSKeyboundReadQuest() addon:KeyboundReadQuest() end

addon:Init()
