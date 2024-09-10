function __ElephantReadInner_v3(_buffer, _datatype)
{
    static _system                = __ElephantSystem();
    static _constructorIndexesMap = _system.__constructorIndexesMap;
    static _foundMap              = _system.__foundMap;
    
    if (_datatype == buffer_array)
    {
        var _length = buffer_read(_buffer, buffer_u16);
        
        //Special value indicating that this is a reference to an array we've seen before
        if (_length == 0xFFFF)
        {
            var _foundIndex = buffer_read(_buffer, buffer_u16);
            return _foundMap[? _foundIndex];
        }
        else
        {
            var _array = array_create(_length);
            
            //Adds this array to ourlook-up table using a unique index
            //If we read a reference to this array in the future then we grab it out of this look-up table
            _foundMap[? _system.__foundCount] = _array;
            _system.__foundCount++;
            
            if (_length > 0)
            {
                var _common_datatype = buffer_read(_buffer, buffer_u8);
                var _i = 0;
                repeat(_length)
                {
                    _array[@ _i] = __ElephantReadInner_v3(_buffer, _common_datatype);
                    ++_i;
                }
            }
            
            return _array;
        }
    }
    else if (_datatype == buffer_struct)
    {
        var _length = buffer_read(_buffer, buffer_u16);
        
        //Special value indicating that this is a reference to a struct we've seen before
        if (_length == 0xFFFF)
        {
            var _foundIndex = buffer_read(_buffer, buffer_u16);
            return _foundMap[? _foundIndex];
        }
        else if (_length == 0xFFFE) //Special value indicating that this is a struct created by a constructor
        {
            var _constructorIndex = buffer_read(_buffer, buffer_u16);
            
            var _instanceof = _constructorIndexesMap[? _constructorIndex];
            if (_instanceof == undefined)
            {
                _instanceof = buffer_read(_buffer, buffer_string);
                _constructorIndexesMap[? _constructorIndex] = _instanceof;
                _system.__constructorNextIndex++;
            }
            
            var _constructorFunction = asset_get_index(_instanceof);
            if (is_method(_constructorFunction))
            {
                //Is a method
                var _struct = new _constructorFunction();
            }
            else if (is_numeric(_constructorFunction) && script_exists(_constructorFunction))
            {
                //Is a script
                var _struct = new _constructorFunction();
            }
            else
            {
                __ElephantError("Could not resolve constructor function \"", _instanceof, "\"");
            }
            
            //Adds this struct to ourlook-up table using a unique index
            //If we read a reference to this struct in the future then we grab it out of this look-up table
            _foundMap[? _system.__foundCount] = _struct;
            _system.__foundCount++;
            
            //Read out the schema version used to serialize this struct and whether it was stored verbosely
            var _version_and_verbose = buffer_read(_buffer, buffer_u8);
            var _verbose = (_version_and_verbose >> 7);
            var _version = (_version_and_verbose & 0x7F);
            
            //Execute the pre-read callback if we can
            var _callback = _struct[$ __ELEPHANT_PRE_READ_METHOD_NAME];
            if (is_method(_callback))
            {
                ELEPHANT_SCHEMA_VERSION = _version;
                method(_struct, _callback)();
            }
            
            if (_verbose)
            {
                var _length = buffer_read(_buffer, buffer_u16);
                var _i = 0;
                repeat(_length)
                {
                    var _name = buffer_read(_buffer, buffer_string);
                    _struct[$ _name] = __ElephantReadInner_v3(_buffer, buffer_any);
                    ++_i;
                }
            }
            else
            {
                var _elephantSchemas = _struct[$ __ELEPHANT_SCHEMA_NAME];
                if (is_struct(_elephantSchemas))
                {
                    var _schema = _elephantSchemas[$ "v" + string(_version)];
                    if (is_struct(_schema))
                    {
                        //Get variables names, and alphabetize them so that they match the order that they were serialized
                        var _names = variable_struct_get_names(_schema);
                        array_sort(_names, true);
                        
                        //Iterate over the variable names and read them
                        var _i = 0;
                        repeat(array_length(_names))
                        {
                            var _name = _names[_i];
                            _struct[$ _name] = __ElephantReadInner_v3(_buffer, _schema[$ _name]);
                            ++_i;
                        }
                    }
                    else
                    {
                        __ElephantError("No Elephant \"v", _version, "\" schema found for constructor \"", _instanceof, "\"");
                    }
                }
                else
                {
                    __ElephantError("No Elephant schema found for constructor \"", _instanceof, "\", but a schema is required for importing");
                }
            }
            
            //Execute the post-read callback if we can
            var _callback = _struct[$ __ELEPHANT_POST_READ_METHOD_NAME];
            if (is_method(_callback))
            {
                ELEPHANT_SCHEMA_VERSION = _version;
                method(_struct, _callback)();
            }
            
            return _struct;
        }
        else
        {
            //If length isn't 0xFFFF or 0xFFFE then it's a generic struct
            var _struct = {};
            
            //Adds this struct to ourlook-up table using a unique index
            //If we read a reference to this struct in the future then we grab it out of this look-up table
            _foundMap[? _system.__foundCount] = _struct;
            _system.__foundCount++;
            
            var _i = 0;
            repeat(_length)
            {
                var _name = buffer_read(_buffer, buffer_string);
                _struct[$ _name] = __ElephantReadInner_v3(_buffer, buffer_any);
                ++_i;
            }
            
            return _struct;
        }
    }
    else if (_datatype == buffer_any)
    {
        _datatype = buffer_read(_buffer, buffer_u8);
        return __ElephantReadInner_v3(_buffer,_datatype);
    }
    else if (_datatype == buffer_undefined)
    {
        return undefined;
    }
    else
    {
        if (_datatype == buffer_text) _datatype = buffer_string;
        return buffer_read(_buffer, _datatype);
    }
}