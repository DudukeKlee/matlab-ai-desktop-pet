function result = handleAgentSkillCall(appData, skillCall)
% B 调 skill 的统一处理（走 A 的三段式：get_skills / skill_detail / use_skill）
    name = skillCall.name;
    config = appData.config;

    switch name
        case 'get_skills'
            result = getSkillList(config);
        case 'skill_detail'
            if isfield(skillCall, 'params') && isfield(skillCall.params, 'skill')
                result = getSkillDetail(config, skillCall.params.skill);
            else
                result = '[Skill 错误] skill_detail 需要 params.skill。';
            end
        case 'use_skill'
            if isfield(skillCall, 'params') && isfield(skillCall.params, 'skill')
                realCall = struct('name', skillCall.params.skill);
                if isfield(skillCall.params, 'params')
                    realCall.params = skillCall.params.params;
                end
                result = executeSkill(config, realCall, appData, 'B');
                % 截图特殊处理：B 也能看
                if isstruct(result) && isfield(result, 'type') && strcmp(result.type, 'screenshot')
                    if result.success
                        % 把截图作为多模态输入回灌给 B
                        base64Img = imageToBase64(result.filePath);
                        appData.agentB_messages{end+1} = struct('role', 'user', 'content', ...
                            {{struct('type','text','text','[截图已完成] 请分析下面图片。'), ...
                              struct('type','image_url','image_url', ...
                                struct('url',['data:image/png;base64,' base64Img]))}});
                        result = '[截图已生成，已作为图片发给你分析]';
                    else
                        result = result.message;
                    end
                end
            else
                result = '[Skill 错误] use_skill 需要 params.skill。';
            end
        otherwise
            result = sprintf('[Skill 错误] 未知指令: %s', name);
    end
end
