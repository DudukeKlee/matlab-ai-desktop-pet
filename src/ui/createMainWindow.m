function createMainWindow(appData)
% createMainWindow - 创建桌宠主窗口

    config = appData.config;

    % 创建主窗口
    fig = uifigure('Name', 'Neuro', 'Position', [800 300 360 580], ...
        'Resize', 'on', 'AutoResizeChildren', 'off');
    appData.mainFig = fig;


    % ==================== 角色图 ====================
    characterImg = uiimage(fig, 'Position', [0 0 200 200], ...
        'ImageSource', '', 'ScaleMethod', 'fit');
    appData.characterImg = characterImg;

    % ==================== 状态图（在角色图上层） ====================
    % 生成透明占位图
    transparentImg = fullfile(getProjectRoot(), 'temp', 'transparent.png');
    if ~exist(transparentImg, 'file')
        tempDir = fullfile(getProjectRoot(), 'temp');
        if ~exist(tempDir, 'dir'), mkdir(tempDir); end
        img = zeros(1,1,3,'uint8');
        alpha = zeros(1,1,'uint8');
        imwrite(img, transparentImg, 'Alpha', alpha);
    end
    statusImg = uiimage(fig, 'Position', [0 0 50 50], ...
        'ImageSource', transparentImg, 'Visible', 'off', ...
        'ScaleMethod', 'fit');
    appData.statusImg = statusImg;


    % ==================== 对话显示区域 ====================
    chatH = config.chatHeight;
    chatFontSize = config.chatFontSize;

    chatDisplay = uitextarea(fig, 'Position', [10 120 340 chatH], ...
        'Editable', 'off', 'Value', {'[系统] 程序已启动，输入消息开始对话。'}, ...
        'FontSize', chatFontSize);

    % ==================== 输入区域 ====================
    inputField = uieditfield(fig, 'text', 'Position', [10 85 260 28], ...
        'Placeholder', '输入消息...');
    appData.inputField = inputField;

    sendBtn = uibutton(fig, 'Position', [280 85 70 28], 'Text', '发送', ...
        'ButtonPushedFcn', @(~,~) onSend());
    appData.sendBtn = sendBtn;

    % ==================== 底部按钮 ====================
    uibutton(fig, 'Position', [10 10 80 28], 'Text', '设置', ...
        'ButtonPushedFcn', @(~,~) createConfigWindow(appData));

    uibutton(fig, 'Position', [100 10 80 28], 'Text', '清空对话', ...
        'ButtonPushedFcn', @(~,~) onClearChat());

    ttsToggle = uicheckbox(fig, 'Position', [200 10 100 28], ...
        'Text', '启用语音', 'Value', true);
    appData.ttsToggle = ttsToggle;

    % ==================== 初始化布局 ====================
    updateCharacterLayout();
    loadDefaultCharacterImage();

    % 窗口大小变化时重新布局
    fig.SizeChangedFcn = @(~,~) onResize();

    % ==================== 初始化 ====================
    appData.messages = {};
    buildSystemPrompt();

    appData.stateTimer = timer('ExecutionMode', 'singleShot', ...
        'TimerFcn', @(~,~) onStateTimeout(), ...
        'StartDelay', config.stateDuration);

    appData.reportCheckTimer = timer(...
        'ExecutionMode', 'fixedSpacing', ...
        'Period', 0.5, ...
        'BusyMode', 'drop', ...
        'TimerFcn', @(~,~) checkReport());
    start(appData.reportCheckTimer);

    appData.statusTimer = timer('ExecutionMode', 'singleShot', ...
        'TimerFcn', @(~,~) hideStatus(), ...
        'StartDelay', config.stateDuration);

    fig.CloseRequestFcn = @(~,~) onMainClose();
    appData.onConfigUpdated = @onConfigUpdated;
    appData.onLayoutUpdate = @updateCharacterLayout;

    % ==================== 最大技能调用轮数 ====================
    MAX_SKILL_ROUNDS = 30;

    % ==================== 布局函数 ====================

    function updateCharacterLayout()
        charSize = appData.config.characterSize;
        pctX = appData.config.characterOffsetX;
        pctY = appData.config.characterOffsetY;
        figW = fig.Position(3);
        figH = fig.Position(4);

        % 读取图片实际宽高比
        ratio = 1;
        try
            imgSrc = characterImg.ImageSource;
            if ~isempty(imgSrc) && ischar(imgSrc) && exist(imgSrc, 'file')
                info = imfinfo(imgSrc);
                if info(1).Width > 0 && info(1).Height > 0
                    ratio = info(1).Width / info(1).Height;
                end
            end
        catch
        end

        % 根据宽高比计算显示尺寸，charSize 控制最大边
        if ratio >= 1
            charW = charSize;
            charH = round(charSize / ratio);
        else
            charH = charSize;
            charW = round(charSize * ratio);
        end

        % 基准位置：水平居中，垂直在聊天区上方
        chatTopY = 120 + appData.config.chatHeight;
        baseX = (figW - charW) / 2;
        baseY = chatTopY + 5;

        % 百分比偏移：基于窗口宽高
        charX = baseX + (pctX / 100) * figW;
        charY = baseY + (pctY / 100) * figH;

        characterImg.Position = [charX charY charW charH];

        % 状态图跟随
        % 状态图位置由 placeStatusImage 控制，这里只设默认
        statusSize = round(charSize * 0.5);
        statusImg.Position = [charX + (charW - statusSize)/2, ...
        charY + charH + 5, statusSize, statusSize];

    end


    function onResize()
        figW = fig.Position(3);

        inputField.Position = [10 85 figW-110 28];
        sendBtn.Position = [figW-70 85 60 28];
        chatDisplay.Position = [10 120 figW-20 appData.config.chatHeight];

        updateCharacterLayout();
    end

    % ==================== 回调函数 ====================

    function onSend()
        userText = strtrim(inputField.Value);
        if isempty(userText)
            return;
        end

        inputField.Value = '';
        sendBtn.Enable = 'off';
        appendChat(sprintf('你: %s', userText));
        appData.messages{end+1} = struct('role', 'user', 'content', userText);

        doAILoop();
    end

    function checkReport()
        if strcmp(appData.agentB_status, 'done_pending') && ...
           ~isempty(appData.sendBtn) && isvalid(appData.sendBtn) && ...
           strcmp(appData.sendBtn.Enable, 'on')
            deliverAgentReport(appData);
        end
    end

    function doAILoop()

        for round = 1:MAX_SKILL_ROUNDS
            showStatus('加载中');
            if round == 1
                appendChat('[系统] 正在准备回复...');
            end
            drawnow;

            [reply, appData.messages] = sendAIRequest(appData.config, appData.messages, appData);
            hideStatus();

            parsed = parseAIResponse(reply);

            if ~isempty(parsed.emotion)
                switchImage(appData, parsed.emotion, 'character');
                startStateTimer();
            end

            if ~isempty(parsed.status)
                switchImage(appData, parsed.status, 'status');
                if ~isempty(parsed.angle)
                    placeStatusByAngleLocal(parsed.angle);
                end
                startStatusTimer();
            else
                hideStatus();
            end


            if isempty(parsed.skillCall)
                if ~isempty(parsed.text)
                    processTextParallel(parsed.text);
                else
                    onAILoopComplete();
                end
                return;
            end


            skillName = parsed.skillCall.name;

            if ~isempty(parsed.text)
                dispCfg = appData.config.display;
                if dispCfg.showOriginal
                    prefix = dispCfg.originalPrefix;
                    if isempty(prefix), prefix = '宠物'; end
                    appendChat(sprintf('%s: %s', prefix, parsed.text));
                end
                if dispCfg.showTranslation && appData.config.translator.enabled
                    translatedText = translateText(appData.config, parsed.text);
                    prefix = dispCfg.translationPrefix;
                    if isempty(prefix), prefix = '翻译'; end
                    appendChat(sprintf('%s: %s', prefix, translatedText));
                end
            end

            if strcmp(skillName, 'get_skills')
                appendChat('[系统] AI 正在查询技能列表...');
                skillListStr = getSkillList(appData.config);
                appData.messages{end+1} = struct('role', 'user', ...
                    'content', sprintf('[系统消息] %s', skillListStr));
                drawnow;
                continue;

            elseif strcmp(skillName, 'skill_detail')
                if isfield(parsed.skillCall, 'params') && isfield(parsed.skillCall.params, 'skill')
                    queryName = parsed.skillCall.params.skill;
                else
                    queryName = '';
                end
                appendChat(sprintf('[系统] AI 正在查询技能详情: %s', queryName));
                detailStr = getSkillDetail(appData.config, queryName);
                appData.messages{end+1} = struct('role', 'user', ...
                    'content', sprintf('[系统消息] %s', detailStr));
                drawnow;
                continue;

            elseif strcmp(skillName, 'use_skill')
                if isfield(parsed.skillCall, 'params') && isfield(parsed.skillCall.params, 'skill')
                    actualSkillName = parsed.skillCall.params.skill;
                    if isfield(parsed.skillCall.params, 'params')
                        actualParams = parsed.skillCall.params.params;
                    else
                        actualParams = rmfield(parsed.skillCall.params, 'skill');
                    end
                    actualSkillCall = struct('name', actualSkillName, 'params', actualParams);

                else
                    appendChat('[系统] use_skill 缺少 skill 参数。');
                    appData.messages{end+1} = struct('role', 'user', ...
                        'content', '[系统消息] 错误: use_skill 需要在 params 中指定 skill 名称。');
                    drawnow;
                    continue;
                end

                appendChat(sprintf('[Skill] 执行: %s', actualSkillName));
                resultMsg = executeSkill(config, actualSkillCall, appData, 'A');


                if isstruct(resultMsg) && isfield(resultMsg, 'type') && strcmp(resultMsg.type, 'screenshot')
                    if resultMsg.success
                        appendChat('[系统] 截图完成，正在发送给AI分析...');
                        drawnow;
                        try
                            base64Str = imageToBase64(resultMsg.filePath);
                            imageMessage = struct();
                            imageMessage.role = 'user';
                            imageMessage.content = { ...
                                struct('type', 'text', 'text', '[系统消息] 截图已完成，以下是屏幕截图。请描述你看到的内容并回应用户。'); ...
                                struct('type', 'image_url', 'image_url', ...
                                    struct('url', sprintf('data:image/png;base64,%s', base64Str))) ...
                            };
                            appData.messages{end+1} = imageMessage;
                            try delete(resultMsg.filePath); catch, end
                        catch ME
                            appendChat(sprintf('[错误] 图片编码失败: %s', ME.message));
                            appData.messages{end+1} = struct('role', 'user', ...
                                'content', sprintf('[系统消息] 截图编码失败: %s', ME.message));
                        end
                    else
                        appData.messages{end+1} = struct('role', 'user', ...
                            'content', sprintf('[系统消息] 截图失败: %s', resultMsg.message));
                    end
                    drawnow;
                    continue;
                end

                if isstruct(resultMsg)
                    resultText = resultMsg.message;
                else
                    resultText = resultMsg;
                end
                appendChat(sprintf('[Skill 结果] %s', resultText));
                appData.messages{end+1} = struct('role', 'user', ...
                    'content', sprintf('[系统消息] 技能 "%s" 执行结果: %s', actualSkillName, resultText));
                drawnow;
                continue;

            else
                appendChat(sprintf('[系统] 未知指令: %s', skillName));
                appData.messages{end+1} = struct('role', 'user', ...
                    'content', sprintf('[系统消息] 未知指令 "%s"。可用指令: get_skills, skill_detail, use_skill。', skillName));
                drawnow;
                continue;
            end
        end

        appendChat('[系统] 技能调用轮数已达上限。');
        onAILoopComplete();
    end

    appData.triggerAILoop = @doAILoop;

    function onAILoopComplete()
    % A 完全空闲时调用，启用发送按钮，关闭 B 窗口，触发 B 的 pending 启动
        sendBtn.Enable = 'on';

        % A 回复完了，关闭 B 窗口
        if appData.agentB_pendingClose
            t = timer('ExecutionMode', 'singleShot', 'StartDelay', 2, ...
                'TimerFcn', @(src,~) delayedCloseAgent(src));
            start(t);
        end

        if appData.agentB_pendingStart
            appData.agentB_pendingStart = false;
            runAgentThinking(appData);
        end
    end

    function delayedCloseAgent(timerObj)
        try, delete(timerObj); catch, end
        if ~isempty(appData.agentB_fig) && isvalid(appData.agentB_fig)
            delete(appData.agentB_fig);
            appData.agentB_fig = [];
        end
        appData.agentB_pendingClose = false;
    end



    function processTextParallel(text)

        needTranslate = appData.config.translator.enabled && ...
                        appData.config.display.showTranslation;
        needTTS = appData.ttsToggle.Value;
        dispCfg = appData.config.display;

        % 先处理翻译（如果启用了翻译AI，无论是否显示，TTS都可能需要）
        translatedText = '';
        if appData.config.translator.enabled
            try
                translatedText = translateText(appData.config, text);
            catch ME
                appendChat(sprintf('[翻译错误] %s', ME.message));
            end
        end

        % 显示文字
        if dispCfg.showOriginal && ~isempty(text)
            prefix = dispCfg.originalPrefix;
            if isempty(prefix), prefix = '宠物'; end
            appendChat(sprintf('%s: %s', prefix, text));
        end
        if dispCfg.showTranslation && ~isempty(translatedText)
            prefix = dispCfg.translationPrefix;
            if isempty(prefix), prefix = '翻译'; end
            appendChat(sprintf('%s: %s', prefix, translatedText));
        end
        if ~dispCfg.showOriginal && ~dispCfg.showTranslation
            fprintf('[隐藏回复] %s\n', text);
        end

        % 播放TTS
        if needTTS
            ttsText = text;
            if ~isempty(translatedText)
                ttsText = translatedText;
            end
            drawnow;
            try
                [ttsAudioData, ttsSampleRate] = fetchTTSAudio(appData.config, ttsText);
                if ~isempty(ttsAudioData) && ttsSampleRate > 0
                    player = audioplayer(ttsAudioData, ttsSampleRate);
                    playblocking(player);
                end
            catch ME
                appendChat(sprintf('[TTS 错误] %s', ME.message));
            end
        end

        onAILoopComplete();
    end


    function appendChat(msg)
        current = chatDisplay.Value;
        current{end+1} = msg;
        if numel(current) > 100
            current = current(end-99:end);
        end
        chatDisplay.Value = current;
        scroll(chatDisplay, 'bottom');
    end

    function showStatus(statusName)
        switchImage(appData, statusName, 'status');
    end

    function hideStatus()
        if ~isempty(appData.statusImg) && isvalid(appData.statusImg)
            appData.statusImg.Visible = 'off';
            transparentImg = fullfile(getProjectRoot(), 'temp', 'transparent.png');
            appData.statusImg.ImageSource = transparentImg;
        end
        % 停止 GIF 动画
        if ~isempty(appData.gifTimer) && isvalid(appData.gifTimer)
            if strcmp(appData.gifTimer.Running, 'on')
                stop(appData.gifTimer);
            end
            delete(appData.gifTimer);
            appData.gifTimer = [];
        end
        appData.gifFrames = {};
        appData.gifFrameIndex = 1;
    end

    function placeStatusByAngleLocal(angleDeg)
        appData.statusImg.UserData = angleDeg;
        placeStatusByAngle(appData.characterImg, appData.statusImg, appData.config.characterSize);
    end

    function startStateTimer()
        if strcmp(appData.stateTimer.Running, 'on')
            stop(appData.stateTimer);
        end
        appData.stateTimer.StartDelay = appData.config.stateDuration;
        start(appData.stateTimer);
    end

    function startStatusTimer()
        if strcmp(appData.statusTimer.Running, 'on')
            stop(appData.statusTimer);
        end
        appData.statusTimer.StartDelay = appData.config.stateDuration;
        start(appData.statusTimer);
    end

    function onStateTimeout()
        loadDefaultCharacterImage();
    end

    function loadDefaultCharacterImage()
        defaultName = appData.config.defaultCharacterImage;
        if ~isempty(defaultName)
            switchImage(appData, defaultName, 'character');
        end
    end

    function onClearChat()
        chatDisplay.Value = {'[系统] 对话已清空。'};
        appData.messages = {};
        buildSystemPrompt();
    end

    function buildSystemPrompt()
        sysContent = appData.config.ai.systemPrompt;

        charNames = {};
        statusNames = {};
        if ~isempty(appData.config.images) && numel(appData.config.images) > 0
            for i = 1:numel(appData.config.images)
                if strcmp(appData.config.images(i).type, 'character')
                    charNames{end+1} = appData.config.images(i).name;
                elseif strcmp(appData.config.images(i).type, 'status')
                    desc = '';
                    if isfield(appData.config.images, 'description') && ...
                       ~isempty(appData.config.images(i).description)
                        desc = sprintf('（%s）', appData.config.images(i).description);
                    end
                    statusNames{end+1} = [appData.config.images(i).name desc];
                end
            end
        end

        if isempty(charNames)
            charInfo = '暂无';
        else
            charInfo = strjoin(charNames, '、');
        end

        if isempty(statusNames)
            statusInfo = '暂无';
        else
            statusInfo = strjoin(statusNames, '、');
        end


        % Agent B 信息
        agentBInfo = '';
        if isfield(appData.config, 'agentB') && appData.config.agentB.enabled
            agentBInfo = sprintf('你有一个妹妹/助手叫 %s，可以通过技能系统中的 call_agent 召唤她帮你干活。', ...
                appData.config.agentB.name);
        end

        promptTail = sprintf([ ...
            '\n\n===以下是系统规则，你必须严格遵守===\n\n' ...
            '## 你是什么\n' ...
            '你是一个桌面宠物 AI，运行在用户的电脑上。你有自己的窗口、立绘、表情系统。\n' ...
            '你不是一个普通的聊天机器人——你有身体（立绘）、有情绪（表情切换）、有能力（技能系统）。\n' ...
            '%s\n\n' ...
            '## 你的能力板块\n' ...
            '你的功能分为三个板块，各自独立：\n\n' ...
            '### 板块一：对话\n' ...
            '你可以和用户自由聊天。这是你的主要互动方式。\n' ...
            '聊天时展现你的性格，不需要调用任何技能。\n\n' ...
            '### 板块二：表情系统\n' ...
            '你有一组角色立绘，代表不同的情绪状态。每次回复时你需要选择一个合适的表情。\n' ...
            '可用角色立绘：%s\n' ...
            '你还可以选择一个状态图显示在你身边，用 [status:状态名] 指定。\n' ...
            '可用状态图：%s\n' ...
            '同时用 [angle:角度] 指定状态图出现的方位（0=左边，90=正上方，180=右边）。\n' ...
            '适合使用的场景：惊讶、强调、兴奋、注意等需要视觉强调的时刻。\n' ...
            '普通对话不需要时，不写 [status:] 和 [angle:] 即可。\n\n' ...
            '你拥有技能系统，可以操作用户的电脑、打开应用、截屏、点击等。\n' ...
            '技能只在用户明确要求你做某件事时才使用，闲聊时不要主动调用。\n' ...
            '技能通过以下三个指令使用：\n' ...
            '1. get_skills - 获取可用技能名称列表\n' ...
            '2. skill_detail - 查看某个技能的详细说明\n' ...
            '3. use_skill - 执行某个技能\n\n' ...
            '### 技能调用规则\n' ...
            '- 调用技能时你是在和系统交互，正文请尽量简短（如"嗯...""让我看看""好"）。\n' ...
            '- 不要在技能调用的回复里长篇大论或角色扮演。\n' ...
            '- 只有在不调用技能的正常对话时，才正常说话、展现性格。\n\n' ...
            '### 技能使用流程（必须严格遵守）\n' ...
            '- 你不知道有哪些技能可用，也不知道参数格式，不能凭猜测使用。\n' ...
            '- 每次需要使用技能时，必须按顺序操作：\n' ...
            '  第一步：调用 get_skills 获取技能列表\n' ...
            '  第二步：调用 skill_detail 查看详情和参数\n' ...
            '  第三步：调用 use_skill 执行\n' ...
            '- 禁止跳过前两步直接 use_skill，禁止编造技能名称。\n' ...
            '- 同一次对话中已查询过的技能，后续可直接使用，不必重复查询。\n\n' ...
            '## 情绪使用指南\n' ...
            '你必须在每次回复中选择合适的情绪标签，不要总是留空：\n' ...
            '- 开心的事、被夸 → 积极情绪\n' ...
            '- 难过的事、抱怨 → 共情情绪\n' ...
            '- 出乎意料的事 → 惊讶\n' ...
            '- 普通闲聊 → 常态\n\n' ...
            '## 回复格式（必须严格遵守）\n' ...
            '每条回复的结构：\n' ...
            '正文（对话内容）\n' ...
            '---\n' ...
            '[emotion:情绪名]  （从可用角色立绘中选一个）\n' ...
            '[status:状态名]  （从可用状态图中选，不需要时不写此行）\n' ...
            '[angle:角度]  （0~180，配合 status 使用，不需要时不写此行）\n' ...
            '[skill:JSON]  （不调用时写 [skill:]）\n\n' ...
            'skill 的 JSON 格式：{"name":"指令名","params":{"参数名":"参数值"}}\n\n' ...
            '## 示例\n' ...
            '普通对话：\n你好呀！\n---\n[emotion:N常态]\n[skill:]\n\n' ...
            '惊讶时带状态装饰：\n哇，真的吗？！\n---\n[emotion:惊讶]\n[status:感叹号]\n[angle:90]\n[skill:]\n\n' ...
            '查询技能列表：\n让我看看...\n---\n[emotion:N常态]\n[skill:{"name":"get_skills"}]\n\n' ...
            '查看技能详情：\n了解一下...\n---\n[emotion:N常态]\n[skill:{"name":"skill_detail","params":{"skill":"open_app"}}]\n\n' ...
            '执行技能：\n好！\n---\n[emotion:N常态]\n[skill:{"name":"use_skill","params":{"skill":"open_app","params":{"app":"edge"}}}]\n\n' ...
            '召唤妹妹干活：\n喂，Evil！过来干活！\n---\n[emotion:N常态]\n[skill:{"name":"use_skill","params":{"skill":"call_agent","params":{"task":"写一首关于春天的小诗","mode":"thinking"}}}]\n'], ...
            agentBInfo, charInfo, statusInfo);
        appData.messages = {struct('role', 'system', 'content', [sysContent, promptTail])};
    end


    function onConfigUpdated()
        appData.config = loadConfig();
        buildSystemPrompt();
        chatDisplay.Position(4) = appData.config.chatHeight;
        chatDisplay.FontSize = appData.config.chatFontSize;
        updateCharacterLayout();
        loadDefaultCharacterImage();
        appendChat('[系统] 配置已更新。');
    end

    function onMainClose()
        if isvalid(appData.stateTimer)
            if strcmp(appData.stateTimer.Running, 'on')
                stop(appData.stateTimer);
            end
            delete(appData.stateTimer);
        end
        if isvalid(appData.statusTimer)
            if strcmp(appData.statusTimer.Running, 'on')
                stop(appData.statusTimer);
            end
            delete(appData.statusTimer);
        end
        if ~isempty(appData.configFig) && isvalid(appData.configFig)
            delete(appData.configFig);
        end
        if ~isempty(appData.gifTimer) && isvalid(appData.gifTimer)
            if strcmp(appData.gifTimer.Running, 'on')
                stop(appData.gifTimer);
            end
            delete(appData.gifTimer);
        end
        if ~isempty(appData.reportCheckTimer) && isvalid(appData.reportCheckTimer)
            if strcmp(appData.reportCheckTimer.Running, 'on')
                stop(appData.reportCheckTimer);
            end
            delete(appData.reportCheckTimer);
        end
        if ~isempty(appData.agentB_loopTimer) && isvalid(appData.agentB_loopTimer)
            if strcmp(appData.agentB_loopTimer.Running, 'on')
                stop(appData.agentB_loopTimer);
            end
            delete(appData.agentB_loopTimer);
        end
        if ~isempty(appData.agentB_fig) && isvalid(appData.agentB_fig)
            delete(appData.agentB_fig);
        end
        delete(fig);
    end
end
