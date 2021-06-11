/// @param target
/// @param [buffer]

function ElephantWrite()
{
    var _target = argument[0];
    var _buffer = (argument_count > 1)? argument[1] : undefined;
    
    if (_buffer == undefined)
    {
        _buffer = buffer_create(1024, buffer_grow, 1);
        var _resize_buffer = true; //Also resize the buffer if we've generated our own
    }
    else
    {
        var _resize_buffer = false;
    }
    
    //Do serialization here
    buffer_write(_buffer, buffer_u32, __ELEPHANT_FINGERPRINT);
    buffer_write(_buffer, buffer_u32, __ELEPHANT_BYTE_VERSION);
    
    __ElephantBufferInner(_buffer, _target, buffer_any);
    
    if (_resize_buffer)
    {
        buffer_resize(_buffer, buffer_tell(_buffer));
    }
    
    return _buffer;
}

function __ElephantBufferInner(_buffer, _target, _datatype)
{
    if (_datatype >= __ELEPHANT_CONSTRUCTOR_INDEX_START)
    {
        if (!is_struct(_target)) __ElephantError("Target isn't a struct");
        
        var _instanceof = instanceof(_target);
        
        //If this is the first time we've seen this constructor, associate its name to the datatype index
        if (!variable_struct_exists(global.__elephantConstructorIndexes, _instanceof))
        {
            global.__elephantConstructorIndexes[$ _instanceof] = _datatype;
            buffer_write(_buffer, buffer_string, _instanceof); //TODO - Hash this? Make sure to use a salt too
        }
        
        //Execute the pre-write callback if we can
        var _callback = _target[$ __ELEPHANT_PRE_WRITE_METHOD_NAME];
        if (is_method(_callback)) method(_target, _callback)();
        
        //Discover the latest schema version
        var _latestVersion = 0;
        
        var _elephantSchemas = _target[$ __ELEPHANT_SCHEMA_NAME];
        if (is_struct(_elephantSchemas))
        {
            //Iterate over names inside the root of the schema struct
            var _names = variable_struct_get_names(_elephantSchemas);
            var _i = 0;
            repeat(array_length(_names))
            {
                var _name = _names[_i];
                try
                {
                    //Check the first character (should only ever be "v")
                    if (string_char_at(_name, 1) != "v") throw -1;
                    
                    //Extract the numeric version from the remainder of the string 
                    var _version = real(string_delete(_name, 1, 1));
                    
                    //Check to see if the version number is between 1 and 255 (inclusive)
                    if ((_version < 1) || (_version > 255) || (floor(_version) != _version)) throw -2;
                    
                    //Check if we can go backwards from the version number back to the struct entry
                    if (_name != "v" + string(_version)) throw -3;
                    
                    //Finally, if the found version is larger than the latest version we found already, update the latest version
                    if (_version > _latestVersion) _latestVersion = _version;
                }
                catch(_)
                {
                    __ElephantError("Schema version tag \"", _name, "\" is invalid:\n- Schema versions must start with a lowercase \"v\" and be followed by a version number\n- The version number must be an integer from 1 to 255 inclusive\n- The version number must contain no leading zeros (e.g. \"v001\" is invalid)");
                }
                
                ++_i;
            }
        }
        
        //Write the latest version, even if it's 0
        buffer_write(_buffer, buffer_u8, _latestVersion);
        
        if (_latestVersion > 0)
        {
            //Get the appropriate schema
            var _schema = _elephantSchemas[$ "v" + string(_latestVersion)];
            
            //Get variables names, and alphabetize them
            var _names = variable_struct_get_names(_schema);
            array_sort(_names, lb_sort_ascending);
            
            //Iterate over the serializable variable names and write them
            var _i = 0;
            repeat(array_length(_names))
            {
                var _name = _names[_i];
                __ElephantBufferInner(_buffer, _target[$ _name], _schema[$ _name]);
                ++_i;
            }
        }
        else
        {
            //There's no specific serialization information so we write this constructor as a generic struct
            __ElephantBufferInner(_buffer, _target, buffer_struct);
        }
        
        //Execute the post-write callback if we can
        var _callback = _target[$ __ELEPHANT_POST_WRITE_METHOD_NAME];
        if (is_method(_callback)) method(_target, _callback)();
    }
    else if (_datatype == buffer_array)
    {
        if (!is_array(_target)) __ElephantError("Target isn't an array");
        
        //Write the length of the array
        buffer_write(_buffer, buffer_u16, array_length(_target));
        
        if (array_length(_target) > 0)
        {
            //Discover a common datatype
            //If no common datatype can be found, we use buffer_any
            var _common = undefined;
            var _i = 0;
            repeat(array_length(_target))
            {
                _datatype = __ElephantValueToDatatype(_target[_i]);
                if (_common == undefined)
                {
                    _common = _datatype;
                }
                else if (_common != _datatype)
                {
                    _common = buffer_any;
                    break;
                }
                
                ++_i;
            }
            
            //Write the found common datatype, even if it's buffer_any
            buffer_write(_buffer, buffer_u8, _common);
            
            //Write the contents of the array using the common datatype
            var _i = 0;
            repeat(array_length(_target))
            {
                __ElephantBufferInner(_buffer, _target[_i], _common);
                ++_i;
            }
        }
    }
    else if (_datatype == buffer_struct)
    {
        if (!is_struct(_target)) __ElephantError("Target isn't a struct");
        
        var _names = variable_struct_get_names(_target);
        buffer_write(_buffer, buffer_u16, array_length(_names));
        
        var _i = 0;
        repeat(array_length(_names))
        {
            var _name = _names[_i];
            
            buffer_write(_buffer, buffer_string, _name);
            __ElephantBufferInner(_buffer, _target[$ _name], buffer_any);
            
            ++_i;
        }
    }
    else if (_datatype == buffer_any)
    {
        _datatype = __ElephantValueToDatatype(_target);
        buffer_write(_buffer, buffer_u8, _datatype);
        __ElephantBufferInner(_buffer, _target, _datatype);
    }
    else if (_datatype == buffer_undefined)
    {
        //Don't need to write anything for <undefined> values
    }
    else
    {
        if (_datatype == buffer_text)
        {
            __ElephantTrace("\"buffer_text\" datatype is not usable, using \"buffer_string\" instead");
            _datatype = buffer_string;
        }
        
        buffer_write(_buffer, _datatype, _target);
    }
}