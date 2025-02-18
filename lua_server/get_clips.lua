return function(req, res)

    local url = req.url;
    local limit = 0;
    local count = 0;

    local quert_sep = url:find("?");
    if quert_sep == nil then
        return badReq(res);
    else
        local qs = querystring.parse(url:sub(quert_sep + 1, -1))
        limit = tonumber(qs.limit)
        count = tonumber(qs.count)
        if not count or not limit or count == 0 then
            return badReq(res);
        end
    end

    local clips, image_blobs = clip.get_clips(limit, count);
    if not clips then
        res.statusCode = 204;
        res:finish();
        return
    end

    local json = JSON.stringify(clips);

    res.statusCode = 200;
    res:setHeader('Content-Type', 'application/octet-stream');
    res:setHeader('Access-Control-Allow-Origin', '*');
    res:setHeader('Access-Control-Expose-Headers', 'X-Json-Size');
    res:setHeader('X-Json-Size', #json);
    if image_blobs then
        res:write(json .. image_blobs);
    else
        res:write(json);
    end

    res:finish();
end
