/// @param buffer

function ElephantRead(_buffer)
{
    if (buffer_get_size(_buffer) - buffer_tell(_buffer) < 9)
    {
        __ElephantError("Buffer is too small, data may be corrupted");
    }
    
    var _fingerprint = buffer_read(_buffer, buffer_u32); //1129141313
    if (_fingerprint != __ELEPHANT_FINGERPRINT) __ElephantError("Fingerprint mismatch");
    
    global.__elephantConstructorNextIndex = 0;
    global.__elephantConstructorIndexes   = {};
    
    global.__elephantFound      = ds_map_create();
    global.__elephantFoundCount = 0;
    
    ELEPHANT_IS_DESERIALIZING = true;
    ELEPHANT_SCHEMA_VERSION   = undefined;
    
    //Read the Elephant version out from the buffer, then figure out which deserialization function to run
    var _version = buffer_read(_buffer, buffer_u32);
    switch(_version)
    {
        case ((1 << 16) | (0 << 8) | (0)): //1.0.0
            global.__elephantReadFunction = __ElephantReadInner_1_0_0;
        break;
        
        case ((1 << 16) | (1 << 8) | (0)): //1.1.0
            global.__elephantReadFunction = __ElephantReadInner_1_1_0;
        break;
        
        default:
            var _major = _version >> 16;
            var _minor = (_version >> 8) & 0xFF;
            var _patch = _version & 0xFF
            __ElephantError("Buffer is for version ", _major, ".", _minor, ".", _patch, " not supported, it may be a newer version\n(Found ", _version, ", we are ", __ELEPHANT_VERSION, ")");
        break;
    }
    
    //Run the read function and grab whatever comes back (hopefully it's useful data!)
    var _result = global.__elephantReadFunction(_buffer, buffer_any);
    
    ds_map_destroy(global.__elephantFound);
    
    ELEPHANT_IS_DESERIALIZING = undefined;
    ELEPHANT_SCHEMA_VERSION   = undefined;
    
    return _result;
}