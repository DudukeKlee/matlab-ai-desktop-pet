function translated = translateText(config, text)
% translateText - 使用辅助 AI 翻译文本
%   config: 配置结构体
%   text: 要翻译的文本
%   返回: 翻译后的文本，失败则返回原文

    if ~config.translator.enabled || isempty(config.translator.baseURL)
        translated = text;
        return;
    end

    if isempty(strtrim(text))
        translated = text;
        return;
    end

    url = sprintf('%s/chat/completions', config.translator.baseURL);

    targetLang = config.translator.targetLanguage;

    % 收集需要保留的专有名词
    keepNames = {};
    if isfield(config, 'agentB') && isfield(config.agentB, 'name') && ~isempty(config.agentB.name)
        keepNames{end+1} = config.agentB.name;
    end
    if isfield(config, 'display') && isfield(config.display, 'translationPrefix') && ~isempty(config.display.translationPrefix)
        keepNames{end+1} = config.display.translationPrefix;
    end
    if isfield(config, 'display') && isfield(config.display, 'originalPrefix') && ~isempty(config.display.originalPrefix)
        keepNames{end+1} = config.display.originalPrefix;
    end
    % 从 systemPrompt 中无法自动提取所有角色名，这里硬编码常用的
    % 也可以在 config 中加一个 translator.keepNames 字段来配置
    if isfield(config, 'translator') && isfield(config.translator, 'keepNames') && ~isempty(config.translator.keepNames)
        if iscell(config.translator.keepNames)
            keepNames = [keepNames, config.translator.keepNames];
        end
    end
    keepNames = unique(keepNames);

    if ~isempty(keepNames)
        nameRule = sprintf('4. 以下是专有名词/角色名，必须保留原文不翻译：%s\n', strjoin(keepNames, '、'));
    else
        nameRule = '';
    end

    messages = {
        struct('role', 'system', 'content', ...
            sprintf(['你是一个专业翻译引擎。你的唯一任务是将输入文本准确翻译为%s。\n' ...
                     '规则：\n' ...
                     '1. 只输出翻译后的文本，不要输出任何其他内容\n' ...
                     '2. 不要添加解释、注释、引号、前缀或额外说明\n' ...
                     '3. 保持原文的语气、风格和标点符号习惯\n' ...
                     '%s' ...
                     '5. 人名、角色名、品牌名等专有名词根据上下文判断，如果是名字则保留原文\n' ...
                     '6. 如果原文已经是%s，则原样输出'], targetLang, nameRule, targetLang));
        struct('role', 'user', 'content', text)
    };

    body = struct();
    body.model = config.translator.model;
    body.messages = messages;
    body.stream = false;
    body.temperature = 0.3;

    jsonBody = jsonencode(body);

    options = weboptions(...
        'MediaType', 'application/json', ...
        'ContentType', 'json', ...
        'HeaderFields', {'Authorization', ['Bearer ' config.translator.apiKey]; ...
                         'Content-Type', 'application/json'}, ...
        'Timeout', 60, ...
        'RequestMethod', 'post');

    try
        response = webwrite(url, jsonBody, options);
        if isstruct(response) && isfield(response, 'choices')
            translated = strtrim(response.choices(1).message.content);
        else
            translated = text;
        end
    catch
        translated = text;
    end
end
