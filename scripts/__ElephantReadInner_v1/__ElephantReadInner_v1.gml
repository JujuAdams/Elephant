function __ElephantReadInner_v1(_buffer, _datatype)
{
    static _system                = __ElephantSystem();
    static _constructorIndexesMap = _system.__constructorIndexesMap;
    
    if (_datatype >= 32)
    {
        var _instanceof = _constructorIndexesMap[? _datatype];
        if (_instanceof == undefined)
        {
            _instanceof = buffer_read(_buffer, buffer_string);
            _constructorIndexesMap[? _datatype] = _instanceof;
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
            var _struct = {};
        }
        
        //Read out the schema version used to serialize this struct
        var _version = buffer_read(_buffer, buffer_u8);
        
        //Execute the pre-read callback if we can
        var _callback = _struct[$ __ELEPHANT_PRE_READ_METHOD_NAME];
        if (is_method(_callback))
        {
            ELEPHANT_SCHEMA_VERSION = _version;
            method(_struct, _callback)();
        }
        
        if (_version > 0)
        {
            var _elephantSchemas = _struct[$ __ELEPHANT_SCHEMA_NAME];
            if (is_struct(_elephantSchemas))
            {
                var _schema = _elephantSchemas[$ "v" + string(_version)];
                if (is_struct(_schema))
                {
                    //Get variables names, and alphabetize them
                    var _names = variable_struct_get_names(_schema);
                    array_sort(_names, true);
                    
                    //Iterate over the serializable variable names and read them
                    var _i = 0;
                    repeat(array_length(_names))
                    {
                        var _name = _names[_i];
                        _struct[$ _name] = __ElephantReadInner_v1(_buffer, _schema[$ _name]);
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
        else
        {
            //If the version was 0 (i.e. no serialization data available for the constructor) then all data has been stored with explicit key names
            var _extraSize = buffer_read(_buffer, buffer_u16);
            var _i = 0;
            repeat(_extraSize)
            {
                var _name = buffer_read(_buffer, buffer_string);
                _struct[$ _name] = __ElephantReadInner_v1(_buffer, buffer_any);
                ++_i;
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
    else if (_datatype == buffer_array)
    {
        var _size  = buffer_read(_buffer, buffer_u16);
        var _array = array_create(_size);
        
        if (_size > 0)
        {
            var _common_datatype = buffer_read(_buffer, buffer_u8);
            var _i = 0;
            repeat(_size)
            {
                _array[@ _i] = __ElephantReadInner_v1(_buffer, _common_datatype);
                ++_i;
            }
        }
        
        return _array;
    }
    else if (_datatype == buffer_struct)
    {
        var _struct = {};
        
        var _size = buffer_read(_buffer, buffer_u16);
        var _i = 0;
        repeat(_size)
        {
            var _name = buffer_read(_buffer, buffer_string);
            _struct[$ _name] = __ElephantReadInner_v1(_buffer, buffer_any);
            ++_i;
        }
        
        return _struct;
    }
    else if (_datatype == buffer_any)
    {
        _datatype = buffer_read(_buffer, buffer_u8);
        return __ElephantReadInner_v1(_buffer,_datatype);
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