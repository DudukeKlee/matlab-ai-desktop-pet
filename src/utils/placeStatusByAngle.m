function placeStatusByAngle(characterImg, statusImg, characterSize)
% placeStatusByAngle - 根据角度在角色图周围放置状态图
%   characterImg: uiimage 角色图控件
%   statusImg: uiimage 状态图控件
%   characterSize: 角色图配置大小

    if isempty(statusImg) || ~isvalid(statusImg)
        return;
    end
    if isempty(characterImg) || ~isvalid(characterImg)
        return;
    end

    % 从 statusImg 的 UserData 里取角度
    angleDeg = statusImg.UserData;
    if isempty(angleDeg) || ~isnumeric(angleDeg)
        angleDeg = 90;
    end

    charPos = characterImg.Position;
    charX = charPos(1); charY = charPos(2);
    charW = charPos(3); charH = charPos(4);

    % 状态图大小：默认角色图的 15%，上限 25%
    maxRatio = 0.25;
    minRatio = 0.10;
    defaultRatio = 0.15;

    statusSize = round(charH * defaultRatio);

    imgSrc = statusImg.ImageSource;
    if ~isempty(imgSrc) && ischar(imgSrc) && exist(imgSrc, 'file')
        try
            info = imfinfo(imgSrc);
            origMax = max(info(1).Width, info(1).Height);
            maxPx = round(charH * maxRatio);
            minPx = round(charH * minRatio);
            if origMax > maxPx
                statusSize = maxPx;
            elseif origMax < minPx
                statusSize = minPx;
            else
                statusSize = origMax;
            end
        catch
        end
    end

    % 负间距：透明图实际内容不到边界
    gap = -round(charH * 0.08);

    % 门形路径：左侧上半 → 顶部 → 右侧上半
    halfH = charH / 2;
    totalLen = halfH + charW + halfH;

    t = angleDeg / 180;
    pathPos = t * totalLen;

    if pathPos <= halfH
        frac = pathPos / halfH;
        sx = charX - statusSize - gap;
        sy = charY + halfH + (halfH * frac) - statusSize / 2;
    elseif pathPos <= halfH + charW
        frac = (pathPos - halfH) / charW;
        sx = charX + charW * frac - statusSize / 2;
        sy = charY + charH + gap;
    else
        frac = (pathPos - halfH - charW) / halfH;
        sx = charX + charW + gap;
        sy = charY + charH - (halfH * frac) - statusSize / 2;
    end

    statusImg.Position = [sx sy statusSize statusSize];
end
