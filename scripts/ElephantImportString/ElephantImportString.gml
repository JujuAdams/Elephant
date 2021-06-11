/// @param string

function ElephantImportString(_string)
{
    var _compressed = buffer_base64_decode(_string);
    var _buffer = buffer_decompress(_compressed);
    buffer_delete(_compressed);
    
    var _result = ElephantRead(_buffer);
    buffer_delete(_buffer);
    
    return _result;
}