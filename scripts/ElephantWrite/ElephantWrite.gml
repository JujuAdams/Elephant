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
    
    global.__elephantConstructorNextIndex = 0;
    global.__elephantConstructorIndexes   = {};
    
    global.__elephantFound      = ds_map_create();
    global.__elephantFoundCount = 0;
    
    //Do serialization here
    buffer_write(_buffer, buffer_u32, __ELEPHANT_FINGERPRINT);
    buffer_write(_buffer, buffer_u32, __ELEPHANT_BYTE_VERSION);
    
    __ElephantBufferInner(_buffer, _target, buffer_any);
    
    if (_resize_buffer)
    {
        buffer_resize(_buffer, buffer_tell(_buffer));
    }
    
    //Make sure we clear references to 
    ds_map_destroy(global.__elephantFound);
    
    ELEPHANT_SCHEMA_VERSION = undefined;
    
    return _buffer;
}

function __ElephantBufferInner(_buffer, _target, _datatype)
{
    if (_datatype == buffer_array)
    {
        if (!is_array(_target)) __ElephantError("Target isn't an array");
        
        //Check to see if we've seen this array before
        var _foundIndex = global.__elephantFound[? _target];
        if (is_numeric(_foundIndex))
        {
            //Write a special length here to indicate we're going to use a previously-created reference
            buffer_write(_buffer, buffer_u16, 0xFFFF);
            
            //Followed by the index of the found data structure
            buffer_write(_buffer, buffer_u16, _foundIndex);
        }
        else
        {
            var _length = array_length(_target);
            if (_length >= 0xFFFF)
            {
                __ElephantError("Array length must be less than 65535 (was ", _length, ")");
            }
            else
            {
                //Adds this array to our already-written struct using a unique index
                //If we need to store a reference to this array in the future then we use this index instead
                global.__elephantFound[? _target] = global.__elephantFoundCount;
                global.__elephantFoundCount++;
                
                //Write the length of the array
                buffer_write(_buffer, buffer_u16, _length);
                
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
        }
    }
    else if (_datatype == buffer_struct)
    {
        if (!is_struct(_target)) __ElephantError("Target isn't a struct");
        
        //Check to see if we've seen this struct before
        var _foundIndex = global.__elephantFound[? _target];
        if (is_numeric(_foundIndex))
        {
            //Write a special length here to indicate we're going to use a previously-created reference
            buffer_write(_buffer, buffer_u16, 0xFFFF);
            
            //Followed by the index of the found data structure
            buffer_write(_buffer, buffer_u16, _foundIndex);
        }
        else
        {
            //Adds this struct to our already-written struct using a unique index
            //If we need to store a reference to this struct in the future then we use this index instead
            global.__elephantFound[? _target] = global.__elephantFoundCount;
            global.__elephantFoundCount++;
            
            //Check to see if this is a normal struct
            var _instanceof = instanceof(_target);
            if (_instanceof == "struct")
            {
                //...if so, we want to serialize all variables for this struct (using buffer_any)
                var _names = variable_struct_get_names(_target);
                var _length = array_length(_names);
                
                //Check the length. We use the length property of structs to communicate two special bits of data
                //  length = 0xFFFF = Seen this struct before, use that reference
                //  length = OcFFFE = Struct was instantiated using a constructor
                //Therefore we cannot allow those lengths for structs
                if (_length >= 0xFFFE)
                {
                    __ElephantError("Structs must contain fewer than 65534 member variables (was ", _length, ")");
                }
                else
                {
                    buffer_write(_buffer, buffer_u16, _length);
                    
                    var _i = 0;
                    repeat(array_length(_names))
                    {
                        var _name = _names[_i];
                        
                        buffer_write(_buffer, buffer_string, _name);
                        __ElephantBufferInner(_buffer, _target[$ _name], buffer_any);
                        
                        ++_i;
                    }
                }
            }
            else
            {
                //The struct's instanceof indicates this has been instantiated using a constructor
                //Let's write a special value to communicate that to the deserializer
                buffer_write(_buffer, buffer_u16, 0xFFFE);
                
                //Try to find a datatype index for this constructor
                var _index = global.__elephantConstructorIndexes[$ _instanceof];
                if (_index != undefined)
                {
                    buffer_write(_buffer, buffer_u16, _index);
                }
                else
                {
                    //If we can't find one, return a new index
                    //We handle what to do with a new index when we run __ElephantBufferInner() again
                    _index = global.__elephantConstructorNextIndex;
                    global.__elephantConstructorNextIndex++;
                    global.__elephantConstructorIndexes[$ _instanceof] = _index;
                    
                    //Write our new index and which constructor this maps to
                    buffer_write(_buffer, buffer_u16, _index);
                    buffer_write(_buffer, buffer_string, _instanceof); //TODO - Hash this? Make sure to use a salt too
                }
                
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
                
                //Execute the pre-write callback if we can
                ELEPHANT_SCHEMA_VERSION = _latestVersion;
                var _callback = _target[$ __ELEPHANT_PRE_WRITE_METHOD_NAME];
                if (is_method(_callback)) method(_target, _callback)();
        
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
                    var _names = variable_struct_get_names(_target);
                    var _length = array_length(_names);
                    buffer_write(_buffer, buffer_u16, _length);
                    
                    var _i = 0;
                    repeat(_length)
                    {
                        var _name = _names[_i];
                        
                        buffer_write(_buffer, buffer_string, _name);
                        __ElephantBufferInner(_buffer, _target[$ _name], buffer_any);
                        
                        ++_i;
                    }
                }
                
                //Execute the post-write callback if we can
                ELEPHANT_SCHEMA_VERSION = _latestVersion;
                var _callback = _target[$ __ELEPHANT_POST_WRITE_METHOD_NAME];
                if (is_method(_callback)) method(_target, _callback)();
            }
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