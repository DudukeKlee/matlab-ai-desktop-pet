function createConfigWindow(appData)
% createConfigWindow - 创建配置窗口

    % 如果配置窗口已存在且有效，直接激活它
    if ~isempty(appData.configFig) && isvalid(appData.configFig)
        figure(appData.configFig);
        return;
    end

    config = loadConfig();
    % 确保偏移值在百分比范围内
    if config.characterOffsetX < -50 || config.characterOffsetX > 50
        config.characterOffsetX = 0;
    end
    if config.characterOffsetY < -50 || config.characterOffsetY > 50
        config.characterOffsetY = 0;
    end

    % 创建窗口
    fig = uifigure('Name', '设置', 'Position', [200 100 600 750], ...
        'CloseRequestFcn', @(~,~) onClose(), 'AutoResizeChildren', 'off');
    appData.configFig = fig;

    % 创建选项卡组
    tabGroup = uitabgroup(fig, 'Position', [10 50 580 690]);

    % ==================== AI 设置选项卡 ====================
    tabAI = uitab(tabGroup, 'Title', 'AI 设置');

    uilabel(tabAI, 'Position', [20 610 100 22], 'Text', 'API Base URL:');
    editBaseURL = uieditfield(tabAI, 'text', 'Position', [130 610 420 22], ...
        'Value', config.ai.baseURL);

    uilabel(tabAI, 'Position', [20 570 100 22], 'Text', '模型名称:');
    editModel = uieditfield(tabAI, 'text', 'Position', [130 570 420 22], ...
        'Value', config.ai.model);

    uilabel(tabAI, 'Position', [20 530 100 22], 'Text', 'API Key:');
    editApiKey = uieditfield(tabAI, 'text', 'Position', [130 530 420 22], ...
        'Value', config.ai.apiKey);

    uilabel(tabAI, 'Position', [20 490 100 22], 'Text', '系统提示词:');
    editSysPrompt = uitextarea(tabAI, 'Position', [130 390 420 100], ...
        'Value', {config.ai.systemPrompt});

    uilabel(tabAI, 'Position', [20 350 100 22], 'Text', 'TTS 地址:');
    editTTSUrl = uieditfield(tabAI, 'text', 'Position', [130 350 420 22], ...
        'Value', config.tts.url);

    uilabel(tabAI, 'Position', [20 310 100 22], 'Text', 'TTS 语言:');
    editTTSLang = uieditfield(tabAI, 'text', 'Position', [130 310 420 22], ...
        'Value', config.tts.language);

    uilabel(tabAI, 'Position', [20 270 120 22], 'Text', '状态回落时间(秒):');
    editStateDur = uieditfield(tabAI, 'numeric', 'Position', [150 270 100 22], ...
        'Value', config.stateDuration, 'Limits', [1 60]);

    % ==================== 翻译 AI 设置 ====================
    uilabel(tabAI, 'Position', [20 230 200 22], 'Text', '── 翻译 AI（辅助） ──', ...
        'FontWeight', 'bold');

    chkTransEnabled = uicheckbox(tabAI, 'Position', [20 200 120 22], ...
        'Text', '启用翻译', 'Value', config.translator.enabled);

    uilabel(tabAI, 'Position', [20 170 100 22], 'Text', '翻译API URL:');
    editTransURL = uieditfield(tabAI, 'text', 'Position', [130 170 420 22], ...
        'Value', config.translator.baseURL);

    uilabel(tabAI, 'Position', [20 140 100 22], 'Text', '翻译模型:');
    editTransModel = uieditfield(tabAI, 'text', 'Position', [130 140 420 22], ...
        'Value', config.translator.model);

    uilabel(tabAI, 'Position', [20 110 100 22], 'Text', '翻译API Key:');
    editTransKey = uieditfield(tabAI, 'text', 'Position', [130 110 420 22], ...
        'Value', config.translator.apiKey);

    uilabel(tabAI, 'Position', [20 80 100 22], 'Text', '目标语言:');
    editTransLang = uieditfield(tabAI, 'text', 'Position', [130 80 420 22], ...
        'Value', config.translator.targetLanguage);

    % ==================== 显示设置选项卡 ====================
    tabDisplay = uitab(tabGroup, 'Title', '显示设置');

    uilabel(tabDisplay, 'Position', [20 620 300 22], 'Text', '── 角色图片 ──', ...
        'FontWeight', 'bold');

    uilabel(tabDisplay, 'Position', [20 590 120 22], 'Text', '角色图片大小:');
    sldCharSize = uislider(tabDisplay, 'Position', [150 600 300 3], ...
        'Limits', [80 400], 'Value', config.characterSize, ...
        'MajorTicks', [80 120 160 200 240 280 320 360 400]);
    lblCharSizeVal = uilabel(tabDisplay, 'Position', [470 590 60 22], ...
        'Text', sprintf('%d px', config.characterSize));
    sldCharSize.ValueChangedFcn = @(~,~) onCharSizeChange();

    uilabel(tabDisplay, 'Position', [20 550 120 22], 'Text', '水平偏移(%):');
    sldOffsetX = uislider(tabDisplay, 'Position', [150 560 300 3], ...
        'Limits', [-50 50], 'Value', config.characterOffsetX, ...
        'MajorTicks', [-50 -25 0 25 50]);
    lblOffsetXVal = uilabel(tabDisplay, 'Position', [470 550 60 22], ...
        'Text', sprintf('%d%%', config.characterOffsetX));
    sldOffsetX.ValueChangedFcn = @(~,~) onOffsetXChange();

    uilabel(tabDisplay, 'Position', [20 510 120 22], 'Text', '垂直偏移(%):');
    sldOffsetY = uislider(tabDisplay, 'Position', [150 520 300 3], ...
        'Limits', [-50 50], 'Value', config.characterOffsetY, ...
        'MajorTicks', [-50 -25 0 25 50]);
    lblOffsetYVal = uilabel(tabDisplay, 'Position', [470 510 60 22], ...
        'Text', sprintf('%d%%', config.characterOffsetY));
    sldOffsetY.ValueChangedFcn = @(~,~) onOffsetYChange();
    % ── 聊天框设置 ──
    uilabel(tabDisplay, 'Position', [20 470 300 22], 'Text', '── 聊天框设置 ──', ...
        'FontWeight', 'bold');

    uilabel(tabDisplay, 'Position', [20 440 120 22], 'Text', '对话框高度:');
    sldChatHeight = uislider(tabDisplay, 'Position', [150 450 300 3], ...
        'Limits', [60 400], 'Value', config.chatHeight, ...
        'MajorTicks', [60 100 150 200 250 300 350 400]);
    lblChatHeightVal = uilabel(tabDisplay, 'Position', [470 440 60 22], ...
        'Text', sprintf('%d px', config.chatHeight));
    sldChatHeight.ValueChangedFcn = @(~,~) onChatHeightChange();

    uilabel(tabDisplay, 'Position', [20 400 120 22], 'Text', '聊天字体大小:');
    sldChatFont = uislider(tabDisplay, 'Position', [150 410 300 3], ...
        'Limits', [10 28], 'Value', config.chatFontSize, ...
        'MajorTicks', [10 12 14 16 18 20 22 24 26 28]);
    lblChatFontVal = uilabel(tabDisplay, 'Position', [470 400 60 22], ...
        'Text', sprintf('%d pt', config.chatFontSize));
    sldChatFont.ValueChangedFcn = @(~,~) onChatFontChange();

    % ── 聊天显示控制 ──
    uilabel(tabDisplay, 'Position', [20 360 300 22], 'Text', '── 聊天显示控制 ──', ...
        'FontWeight', 'bold');

    chkShowOriginal = uicheckbox(tabDisplay, 'Position', [20 330 200 22], ...
        'Text', '显示AI原文回复', 'Value', config.display.showOriginal);

    uilabel(tabDisplay, 'Position', [40 300 100 22], 'Text', '原文前缀:');
    editOrigPrefix = uieditfield(tabDisplay, 'text', 'Position', [140 300 200 22], ...
        'Value', config.display.originalPrefix);

    chkShowTranslation = uicheckbox(tabDisplay, 'Position', [20 270 200 22], ...
        'Text', '显示翻译结果', 'Value', config.display.showTranslation);

    uilabel(tabDisplay, 'Position', [40 240 100 22], 'Text', '翻译前缀:');
    editTransPrefix = uieditfield(tabDisplay, 'text', 'Position', [140 240 200 22], ...
        'Value', config.display.translationPrefix);

    % 预览效果
    uilabel(tabDisplay, 'Position', [20 200 300 22], 'Text', '── 预览效果 ──', ...
        'FontWeight', 'bold');
    previewArea = uitextarea(tabDisplay, 'Position', [20 80 520 110], ...
        'Editable', 'off', 'Value', {''});
    updatePreview();


    % ==================== Skill 管理选项卡 ====================
    tabSkill = uitab(tabGroup, 'Title', 'Skill 管理');

    skillTableData = buildSkillTableData(config.skills);
    skillTable = uitable(tabSkill, 'Position', [20 200 540 380], ...
        'ColumnName', {'名字', '简介', '文件名'}, ...
        'ColumnWidth', {120, 280, 120}, ...
        'Data', skillTableData, ...
        'ColumnEditable', false);

    uilabel(tabSkill, 'Position', [20 160 60 22], 'Text', '名字:');
    editSkillName = uieditfield(tabSkill, 'text', 'Position', [80 160 150 22]);

    uilabel(tabSkill, 'Position', [20 130 60 22], 'Text', '简介:');
    editSkillDesc = uieditfield(tabSkill, 'text', 'Position', [80 130 420 22]);

    uilabel(tabSkill, 'Position', [20 100 60 22], 'Text', '文件:');
    editSkillFile = uieditfield(tabSkill, 'text', 'Position', [80 100 330 22], ...
        'Editable', 'off');
    uibutton(tabSkill, 'Position', [420 100 80 22], 'Text', '选择.m文件', ...
        'ButtonPushedFcn', @(~,~) onSelectSkillFile());

    uibutton(tabSkill, 'Position', [20 60 100 30], 'Text', '添加 Skill', ...
        'ButtonPushedFcn', @(~,~) onAddSkill());
    uibutton(tabSkill, 'Position', [140 60 100 30], 'Text', '删除选中', ...
        'ButtonPushedFcn', @(~,~) onDeleteSkill());

    % ==================== 图片管理选项卡 ====================
    tabImage = uitab(tabGroup, 'Title', '图片管理');

    imgTableData = buildImageTableData(config.images);
    imgTable = uitable(tabImage, 'Position', [20 230 540 350], ...
        'ColumnName', {'名字', '归属', '文件名', '备注'}, ...
        'ColumnWidth', {100, 80, 180, 140}, ...
        'Data', imgTableData, ...
        'ColumnEditable', false);

    uilabel(tabImage, 'Position', [20 195 60 22], 'Text', '名字:');
    editImgName = uieditfield(tabImage, 'text', 'Position', [80 195 150 22]);

    uilabel(tabImage, 'Position', [250 195 60 22], 'Text', '归属:');
    dropImgType = uidropdown(tabImage, 'Position', [310 195 120 22], ...
        'Items', {'character', 'status', 'agent'}, 'Value', 'character');

    uilabel(tabImage, 'Position', [20 165 60 22], 'Text', '备注:');
    editImgDesc = uieditfield(tabImage, 'text', 'Position', [80 165 350 22], ...
        'Placeholder', '可选，仅供自己查看');

    uilabel(tabImage, 'Position', [20 135 60 22], 'Text', '文件:');
    editImgFile = uieditfield(tabImage, 'text', 'Position', [80 135 330 22], ...
        'Editable', 'off');
    uibutton(tabImage, 'Position', [420 135 80 22], 'Text', '选择图片', ...
        'ButtonPushedFcn', @(~,~) onSelectImageFile());

    uibutton(tabImage, 'Position', [20 60 100 30], 'Text', '添加图片', ...
        'ButtonPushedFcn', @(~,~) onAddImage());
    uibutton(tabImage, 'Position', [140 60 100 30], 'Text', '删除选中', ...
        'ButtonPushedFcn', @(~,~) onDeleteImage());

    uilabel(tabImage, 'Position', [280 65 100 22], 'Text', '默认角色图:');
    charNames = getCharacterNames(config.images);
    if isempty(charNames), charNames = {'(无)'}; end
    defaultVal = config.defaultCharacterImage;
    if isempty(defaultVal) || ~ismember(defaultVal, charNames)
        defaultVal = charNames{1};
    end
    dropDefaultChar = uidropdown(tabImage, 'Position', [380 65 140 22], ...
        'Items', charNames, 'Value', defaultVal);


    % ==================== Agent B 选项卡 ====================
    tabAgentB = uitab(tabGroup, 'Title', 'Agent B');

    uilabel(tabAgentB, 'Position', [20 620 300 22], 'Text', '── Agent B（专家）── ', ...
        'FontWeight', 'bold');

    chkAgentBEnabled = uicheckbox(tabAgentB, 'Position', [20 590 120 22], ...
        'Text', '启用 Agent B', 'Value', config.agentB.enabled);

    uilabel(tabAgentB, 'Position', [20 555 100 22], 'Text', 'Agent 名字:');
    editAgentBName = uieditfield(tabAgentB, 'text', 'Position', [130 555 200 22], ...
        'Value', config.agentB.name);

    uilabel(tabAgentB, 'Position', [20 520 100 22], 'Text', 'API Base URL:');
    editAgentBURL = uieditfield(tabAgentB, 'text', 'Position', [130 520 420 22], ...
        'Value', config.agentB.baseURL);

    uilabel(tabAgentB, 'Position', [20 485 100 22], 'Text', '模型名称:');
    editAgentBModel = uieditfield(tabAgentB, 'text', 'Position', [130 485 420 22], ...
        'Value', config.agentB.model);

    uilabel(tabAgentB, 'Position', [20 450 100 22], 'Text', 'API Key:');
    editAgentBKey = uieditfield(tabAgentB, 'text', 'Position', [130 450 420 22], ...
        'Value', config.agentB.apiKey);

    uilabel(tabAgentB, 'Position', [20 410 100 22], 'Text', '自定义人设:');
    editAgentBPrompt = uitextarea(tabAgentB, 'Position', [130 310 420 100], ...
        'Value', splitLines(config.agentB.userPrompt));

    uilabel(tabAgentB, 'Position', [20 270 100 22], 'Text', '最大轮次:');
    editAgentBMaxR = uieditfield(tabAgentB, 'numeric', 'Position', [130 270 100 22], ...
        'Value', config.agentB.maxRounds, 'Limits', [1 200]);

    uilabel(tabAgentB, 'Position', [20 235 100 22], 'Text', '默认立绘:');
    agentImgNames = getAgentImageNames(config.images);
    if isempty(agentImgNames), agentImgNames = {'(无)'}; end
    defAgentImg = config.agentB.defaultAgentImage;
    if isempty(defAgentImg) || ~ismember(defAgentImg, agentImgNames)
        defAgentImg = agentImgNames{1};
    end
    dropDefaultAgent = uidropdown(tabAgentB, 'Position', [130 235 200 22], ...
        'Items', agentImgNames, 'Value', defAgentImg);

    uilabel(tabAgentB, 'Position', [20 200 100 22], 'Text', '结果保存目录:');
    editAgentBSaveDir = uieditfield(tabAgentB, 'text', 'Position', [130 200 200 22], ...
        'Value', config.agentB.resultSaveDir);

    uilabel(tabAgentB, 'Position', [20 165 120 22], 'Text', '完成自动关闭(秒):');
    editAgentBClose = uieditfield(tabAgentB, 'numeric', 'Position', [150 165 100 22], ...
        'Value', config.agentB.autoCloseDelay, 'Limits', [0 30]);

    uilabel(tabAgentB, 'Position', [20 120 520 40], 'Text', ...
        ['提示：Agent B 是"强模型专家"，A 遇到复杂任务时会召唤它。' newline ...
         'skill 模式：阻塞执行系统操作（多步点击/截图）' newline ...
         'thinking 模式：后台思考（代码生成/文本分析），产出保存到文件'], ...
        'WordWrap', 'on', 'FontColor', [0.4 0.4 0.4]);


    % ==================== 底部保存按钮 ====================
    uibutton(fig, 'Position', [240 10 120 30], 'Text', '保存配置', ...
        'ButtonPushedFcn', @(~,~) onSave());
    % ==================== 回调函数 ====================

    function onCharSizeChange()
        val = round(sldCharSize.Value);
        sldCharSize.Value = val;
        lblCharSizeVal.Text = sprintf('%d px', val);
    end

    function onOffsetXChange()
        val = round(sldOffsetX.Value);
        sldOffsetX.Value = val;
        lblOffsetXVal.Text = sprintf('%d%%', val);
    end

    function onOffsetYChange()
        val = round(sldOffsetY.Value);
        sldOffsetY.Value = val;
        lblOffsetYVal.Text = sprintf('%d%%', val);
    end

    function onChatHeightChange()
        val = round(sldChatHeight.Value);
        sldChatHeight.Value = val;
        lblChatHeightVal.Text = sprintf('%d px', val);
    end

    function onChatFontChange()
        val = round(sldChatFont.Value);
        sldChatFont.Value = val;
        lblChatFontVal.Text = sprintf('%d pt', val);
    end


    function updatePreview()
        lines = {'你: 你好'};
        exOriginal = '你好！很高兴见到你！今天过得怎么样？';
        exTranslation = 'Hello! Nice to meet you! How are you today?';
        if chkShowOriginal.Value
            prefix = strtrim(editOrigPrefix.Value);
            if isempty(prefix), prefix = '宠物'; end
            lines{end+1} = sprintf('%s: %s', prefix, exOriginal);
        end
        if chkShowTranslation.Value
            prefix = strtrim(editTransPrefix.Value);
            if isempty(prefix), prefix = '翻译'; end
            lines{end+1} = sprintf('%s: %s', prefix, exTranslation);
        end
        if ~chkShowOriginal.Value && ~chkShowTranslation.Value
            lines{end+1} = '（注意：原文和翻译都隐藏了，聊天区将不显示AI回复文本）';
        end
        previewArea.Value = lines;
    end

    function onSelectSkillFile()
        [file, fpath] = uigetfile('*.m', '选择 Skill .m 文件');
        if file ~= 0
            editSkillFile.Value = fullfile(fpath, file);
        end
    end

    function onAddSkill()
        sName = strtrim(editSkillName.Value);
        sDesc = strtrim(editSkillDesc.Value);
        sFile = strtrim(editSkillFile.Value);

        if isempty(sName) || isempty(sDesc) || isempty(sFile)
            uialert(fig, '请填写完整的名字、简介和文件。', '提示');
            return;
        end

        projectRoot = getProjectRoot();
        skillDir = fullfile(projectRoot, 'skills');
        [~, fname, fext] = fileparts(sFile);
        destFile = fullfile(skillDir, [fname fext]);
        if ~strcmp(sFile, destFile)
            copyfile(sFile, destFile);
        end

        newSkill = struct('name', sName, 'description', sDesc, 'fileName', [fname fext]);
        if isempty(config.skills) || (isstruct(config.skills) && isempty(fieldnames(config.skills)))
            config.skills = newSkill;
        else
            config.skills(end+1) = newSkill;
        end

        skillTable.Data = buildSkillTableData(config.skills);

        editSkillName.Value = '';
        editSkillDesc.Value = '';
        editSkillFile.Value = '';
    end

    function onDeleteSkill()
        sel = skillTable.Selection;
        if isempty(sel)
            uialert(fig, '请先在表格中点击选中要删除的行。', '提示');
            return;
        end
        row = sel(1);
        if numel(config.skills) >= row
            config.skills(row) = [];
        end
        skillTable.Data = buildSkillTableData(config.skills);
    end

    function onSelectImageFile()
        [file, fpath] = uigetfile({'*.png;*.jpg;*.jpeg;*.gif;*.bmp', '图片文件'}, '选择图片');
        if file ~= 0
            editImgFile.Value = fullfile(fpath, file);
        end
    end

    function onAddImage()
        iName = strtrim(editImgName.Value);
        iType = dropImgType.Value;
        iFile = strtrim(editImgFile.Value);
        iDesc = strtrim(editImgDesc.Value);

        if isempty(iName) || isempty(iFile)
            uialert(fig, '请填写名字并选择图片文件。', '提示');
            return;
        end

        % 过滤文件名非法字符
        safeName = regexprep(iName, '[\\/:*?"<>|]', '_');

        [~, ~, ext] = fileparts(iFile);
        destDir = fullfile(getProjectRoot(), 'images', iType);
        if ~exist(destDir, 'dir'), mkdir(destDir); end

        % 用名字作为文件名，重名则加后缀
        destFileName = [safeName ext];
        destFile = fullfile(destDir, destFileName);
        counter = 2;
        while exist(destFile, 'file')
            destFileName = sprintf('%s_%d%s', safeName, counter, ext);
            destFile = fullfile(destDir, destFileName);
            counter = counter + 1;
        end

        if ~strcmp(iFile, destFile)
            copyfile(iFile, destFile);
        end

        newImg = struct('name', iName, 'type', iType, ...
            'fileName', destFileName, 'description', iDesc);
        if isempty(config.images) || (isstruct(config.images) && isempty(fieldnames(config.images)))
            config.images = newImg;
        else
            config.images(end+1) = newImg;
        end

        imgTable.Data = buildImageTableData(config.images);

        charNames = getCharacterNames(config.images);
        if isempty(charNames), charNames = {'(无)'}; end
        dropDefaultChar.Items = charNames;

        agentNames = getAgentImageNames(config.images);
        if isempty(agentNames), agentNames = {'(无)'}; end
        dropDefaultAgent.Items = agentNames;

        editImgName.Value = '';
        editImgFile.Value = '';
        editImgDesc.Value = '';
    end


    function onDeleteImage()
        sel = imgTable.Selection;
        if isempty(sel)
            uialert(fig, '请先在表格中点击选中要删除的行。', '提示');
            return;
        end
        row = sel(1);
        if numel(config.images) < row, return; end

        imgInfo = config.images(row);
        msg = sprintf('确定删除图片 "%s" 吗？\n文件 %s 也会被删除。', ...
            imgInfo.name, imgInfo.fileName);
        selection = uiconfirm(fig, msg, '确认删除', ...
            'Options', {'删除', '取消'}, 'DefaultOption', 2, 'CancelOption', 2);
        if ~strcmp(selection, '删除'), return; end

        % 删除实际文件
        filePath = fullfile(getProjectRoot(), 'images', imgInfo.type, imgInfo.fileName);
        if exist(filePath, 'file')
            delete(filePath);
        end

        config.images(row) = [];
        imgTable.Data = buildImageTableData(config.images);

        charNames = getCharacterNames(config.images);
        if isempty(charNames), charNames = {'(无)'}; end
        dropDefaultChar.Items = charNames;

        agentNames = getAgentImageNames(config.images);
        if isempty(agentNames), agentNames = {'(无)'}; end
        dropDefaultAgent.Items = agentNames;
    end


    function onSave()
        config.ai.baseURL = editBaseURL.Value;
        config.ai.model = editModel.Value;
        config.ai.apiKey = editApiKey.Value;
        promptLines = editSysPrompt.Value;
        config.ai.systemPrompt = strjoin(promptLines, newline);
        config.tts.url = editTTSUrl.Value;
        config.tts.language = editTTSLang.Value;
        config.stateDuration = editStateDur.Value;

        % 翻译 AI 配置
        config.translator.enabled = chkTransEnabled.Value;
        config.translator.baseURL = editTransURL.Value;
        config.translator.model = editTransModel.Value;
        config.translator.apiKey = editTransKey.Value;
        config.translator.targetLanguage = editTransLang.Value;

        % 角色图片大小和位置
        config.characterSize = round(sldCharSize.Value);
        config.characterOffsetX = round(sldOffsetX.Value);
        config.characterOffsetY = round(sldOffsetY.Value);
        config.chatHeight = round(sldChatHeight.Value);
        config.chatFontSize = round(sldChatFont.Value);


        % 显示设置
        config.display.showOriginal = chkShowOriginal.Value;
        config.display.showTranslation = chkShowTranslation.Value;
        config.display.originalPrefix = strtrim(editOrigPrefix.Value);
        config.display.translationPrefix = strtrim(editTransPrefix.Value);
        if isempty(config.display.originalPrefix)
            config.display.originalPrefix = '宠物';
        end
        if isempty(config.display.translationPrefix)
            config.display.translationPrefix = '翻译';
        end

        % 默认角色图
        if ~strcmp(dropDefaultChar.Value, '(无)')
            config.defaultCharacterImage = dropDefaultChar.Value;
        else
            config.defaultCharacterImage = '';
        end
        
                % Agent B 配置
        config.agentB.enabled = chkAgentBEnabled.Value;
        config.agentB.name = strtrim(editAgentBName.Value);
        config.agentB.baseURL = strtrim(editAgentBURL.Value);
        config.agentB.model = strtrim(editAgentBModel.Value);
        config.agentB.apiKey = strtrim(editAgentBKey.Value);
        promptLines2 = editAgentBPrompt.Value;
        config.agentB.userPrompt = strjoin(promptLines2, newline);
        config.agentB.maxRounds = round(editAgentBMaxR.Value);
        if ~strcmp(dropDefaultAgent.Value, '(无)')
            config.agentB.defaultAgentImage = dropDefaultAgent.Value;
        else
            config.agentB.defaultAgentImage = '';
        end
        config.agentB.resultSaveDir = strtrim(editAgentBSaveDir.Value);
        if isempty(config.agentB.resultSaveDir)
            config.agentB.resultSaveDir = 'results';
        end
        saveConfig(config);
                % 清理未注册的图片文件
        cleanUnregisteredImages(config);


        % 更新 appData（handle 对象，直接生效）
        appData.config = config;

        % 通知主窗口刷新
        if ~isempty(appData.onConfigUpdated) && isa(appData.onConfigUpdated, 'function_handle')
            appData.onConfigUpdated();
        end

        uialert(fig, '配置已保存！', '成功');
    end

    function onClose()
        delete(fig);
    end
end

% ==================== 辅助函数 ====================

function data = buildSkillTableData(skills)
    if isempty(skills) || (isstruct(skills) && numel(skills) == 0)
        data = cell(0, 3);
    else
        n = numel(skills);
        data = cell(n, 3);
        for i = 1:n
            data{i,1} = skills(i).name;
            data{i,2} = skills(i).description;
            data{i,3} = skills(i).fileName;
        end
    end
end

function data = buildImageTableData(images)
    if isempty(images) || (isstruct(images) && numel(images) == 0)
        data = cell(0, 4);
    else
        n = numel(images);
        data = cell(n, 4);
        for i = 1:n
            data{i,1} = images(i).name;
            data{i,2} = images(i).type;
            data{i,3} = images(i).fileName;
            if isfield(images, 'description')
                data{i,4} = images(i).description;
            else
                data{i,4} = '';
            end
        end
    end
end


function names = getCharacterNames(images)
    names = {};
    if isempty(images) || (isstruct(images) && numel(images) == 0)
        return;
    end
    for i = 1:numel(images)
        if strcmp(images(i).type, 'character')
            names{end+1} = images(i).name; %#ok<AGROW>
        end
    end
end
function names = getAgentImageNames(images)
    names = {};
    if isempty(images) || (isstruct(images) && numel(images) == 0)
        return;
    end
    for i = 1:numel(images)
        if strcmp(images(i).type, 'agent')
            names{end+1} = images(i).name; %#ok<AGROW>
        end
    end
end

function lines = splitLines(s)
    if isempty(s)
        lines = {''};
        return;
    end
    if iscell(s)
        lines = s;
        return;
    end
    lines = strsplit(s, newline);
    if isempty(lines)
        lines = {''};
    end
end

function cleanUnregisteredImages(config)
% 扫描 images/ 下所有子文件夹，删除不在 config.images 注册列表中的文件
    imgRoot = fullfile(getProjectRoot(), 'images');
    if ~exist(imgRoot, 'dir'), return; end

    % 收集所有已注册的 type/fileName
    registered = {};
    if ~isempty(config.images) && numel(config.images) > 0
        for i = 1:numel(config.images)
            registered{end+1} = fullfile(config.images(i).type, config.images(i).fileName); %#ok<AGROW>
        end
    end

    % 扫描子文件夹
    subDirs = {'character', 'status', 'agent'};
    for d = 1:numel(subDirs)
        folder = fullfile(imgRoot, subDirs{d});
        if ~exist(folder, 'dir'), continue; end
        files = dir(folder);
        for f = 1:numel(files)
            if files(f).isdir, continue; end
            relPath = fullfile(subDirs{d}, files(f).name);
            if ~ismember(relPath, registered)
                fullPath = fullfile(folder, files(f).name);
                try
                    delete(fullPath);
                catch
                end
            end
        end
    end
end

