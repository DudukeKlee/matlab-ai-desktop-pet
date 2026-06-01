function base64Str = imageToBase64(imagePath)
% imageToBase64 - 将图片文件转为 base64 字符串
%   imagePath: 图片文件路径
%   返回: base64 编码的字符串

    fid = fopen(imagePath, 'rb');
    if fid == -1
        error('无法打开图片文件: %s', imagePath);
    end
    bytes = fread(fid, inf, 'uint8=>uint8');
    fclose(fid);

    % 使用 Java Base64 编码器
    encoder = java.util.Base64.getEncoder();
    base64Str = char(encoder.encodeToString(bytes));
end
