% skills/test_skill.m
function result = test_skill(params)
    if isfield(params, 'msg')
        result = sprintf('测试成功！收到消息: %s', params.msg);
    else
        result = '测试成功！无参数。';
    end
end
