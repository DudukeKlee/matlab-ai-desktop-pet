function [reply, messages] = sendAIRequest(config, messages, appData)
% sendAIRequest - 发送 OpenAI 格式的 API 请求
%   config: 配置结构体
%   messages: cell 数组，每个元素是 struct('role','...','content','...')
%   appData: 可选，AppData handle 对象，用于请求锁
%   返回:
%     reply: AI 回复的原始文本
%     messages: 更新后的对话历史（已追加 AI 回复）

    if nargin < 3, appData = []; end

    url = sprintf('%s/chat/completions', config.ai.baseURL);

    % 构建请求体
    body = struct();
    body.model = config.ai.model;
    body.messages = messages;
    body.stream = false;

    jsonBody = jsonencode(body);

    % 构建 HTTP 请求
    options = weboptions(...
        'MediaType', 'application/json', ...
        'ContentType', 'json', ...
        'HeaderFields', {'Authorization', ['Bearer ' config.ai.apiKey]; ...
                         'Content-Type', 'application/json'}, ...
        'Timeout', 120, ...
        'RequestMethod', 'post');

    % 加锁
    if ~isempty(appData)
        appData.isWebBusy = true;
    end

    try
        response = webwrite(url, jsonBody, options);

        % 提取回复内容
        if isstruct(response) && isfield(response, 'choices')
            reply = response.choices(1).message.content;
            % 追加到对话历史
            messages{end+1} = struct('role', 'assistant', 'content', reply);
        else
            reply = '[错误] AI 返回格式异常';
        end
    catch ME
        reply = sprintf('[请求失败] %s', ME.message);
    end

    % 解锁
    if ~isempty(appData)
        appData.isWebBusy = false;
    end
end
