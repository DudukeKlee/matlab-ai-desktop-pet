function skillInfo = getSkillList(config)
% getSkillList - 获取所有 skill 的名字列表
%   config: 配置结构体
%   返回: 格式化的字符串，列出所有可用 skill 名称

    if isempty(config.skills) || numel(config.skills) == 0
        skillInfo = '当前没有可用的技能。';
        return;
    end

    names = {};
    for i = 1:numel(config.skills)
        names{end+1} = config.skills(i).name; %#ok<AGROW>
    end

    skillInfo = sprintf('可用技能: %s', strjoin(names, ', '));
end
