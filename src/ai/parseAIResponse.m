function result = parseAIResponse(rawReply)
% parseAIResponse - 解析 AI 回复

    result = struct();
    result.emotion = '';
    result.status = '';
    result.angle = [];
    result.skillCall = [];
    result.done = false;
    result.toUser = '';
    result.remark = '';
    result.text = rawReply;

    parts = strsplit(rawReply, '---');

    if numel(parts) >= 2
        result.text = strtrim(strjoin(parts(1:end-1), '---'));
        controlBlock = parts{end};
    else
        controlBlock = rawReply;
        result.text = rawReply;
    end

    % emotion
    emotionMatch = regexp(controlBlock, '\[emotion:([^\]]*)\]', 'tokens', 'once');
    if ~isempty(emotionMatch)
        result.emotion = strtrim(emotionMatch{1});
        result.text = regexprep(result.text, '\[emotion:[^\]]*\]', '');
    end

    % angle (替代原 status)
    angleMatch = regexp(controlBlock, '\[angle:([^\]]*)\]', 'tokens', 'once');
    if ~isempty(angleMatch)
        val = str2double(strtrim(angleMatch{1}));
        if ~isnan(val)
            result.angle = max(0, min(180, val));
        end
        result.text = regexprep(result.text, '\[angle:[^\]]*\]', '');
    end
    
        % status
    statusMatch = regexp(controlBlock, '\[status:([^\]]*)\]', 'tokens', 'once');
    if ~isempty(statusMatch)
        result.status = strtrim(statusMatch{1});
        result.text = regexprep(result.text, '\[status:[^\]]*\]', '');
    end



    % skill
    skillMatch = regexp(controlBlock, '\[skill:([^\]]*)\]', 'tokens', 'once');
    if ~isempty(skillMatch)
        skillStr = strtrim(skillMatch{1});
        if ~isempty(skillStr)
            try
                result.skillCall = jsondecode(skillStr);
            catch
                result.skillCall = [];
            end
        end
        result.text = regexprep(result.text, '\[skill:[^\]]*\]', '');
    end

    % done (B 专用)
    doneMatch = regexp(controlBlock, '\[done:([^\]]*)\]', 'tokens', 'once');
    if ~isempty(doneMatch)
        result.done = strcmpi(strtrim(doneMatch{1}), 'true');
        result.text = regexprep(result.text, '\[done:[^\]]*\]', '');
    end

    % toUser (B thinking 模式专用，支持多行)
    toUserMatch = regexp(controlBlock, '\[toUser:(.*?)\]', 'tokens', 'once');
    if ~isempty(toUserMatch)
        result.toUser = strtrim(toUserMatch{1});
        result.text = regexprep(result.text, '\[toUser:.*?\]', '');
    end

    % remark (B 完成任务时的个人发言)
    remarkMatch = regexp(controlBlock, '\[remark:([^\]]*)\]', 'tokens', 'once');
    if ~isempty(remarkMatch)
        result.remark = strtrim(remarkMatch{1});
        result.text = regexprep(result.text, '\[remark:[^\]]*\]', '');
    end

    result.text = strtrim(regexprep(result.text, '\s+', ' '));
    result.text = regexprep(result.text, '\s*-+\s*$', '');
    result.text = strtrim(result.text);
end
