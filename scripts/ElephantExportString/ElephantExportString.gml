/// @param target

function ElephantExportString(_target)
{
    var _buffer = ElephantWrite(_target);
    
    var _compressed = buffer_compress(_buffer, 0, buffer_get_size(_buffer));
    buffer_delete(_buffer);
    
    var _string = buffer_base64_encode(_compressed, 0, buffer_get_size(_compressed));
    buffer_delete(_compressed);
    
    return _string;
}