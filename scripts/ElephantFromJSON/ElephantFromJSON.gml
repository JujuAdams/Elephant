/// @param  target

function ElephantFromJSON(_target)
{
    global.__elephantFound = ds_map_create();
    var _duplicate = __ElephantFromJSONInner(_target);
    ds_map_destroy(global.__elephantFound);
    
    return _duplicate;
}

function __ElephantFromJSONInner(_target)
{
    if (is_struct(_target))
    {
        if (variable_struct_exists(_target, __ELEPHANT_JSON_CIRCULAR_REF))
        {
            return global.__elephantFound[? _target[$ __ELEPHANT_JSON_CIRCULAR_REF]];
        }
        else if (variable_struct_exists(_target, __ELEPHANT_JSON_CONSTRUCTOR))
        {
            var _instanceof = _target[$ __ELEPHANT_JSON_CONSTRUCTOR   ];
            var _version    = _target[$ __ELEPHANT_JSON_SCHEMA_VERSION];
            
            if (_version == undefined) __ElephantError("No schema version found");
            
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
        }
        else
        {
            //Generic struct
            var _struct = {};
        }
        
        var _names = variable_struct_get_names(_target);
        
        //Sort the names alphabetically
        array_sort(_names, lb_sort_ascending);
        
        var _i = 0;
        repeat(array_length(_names))
        {
            var _name = _names[_i];
            if ((_name != __ELEPHANT_JSON_CONSTRUCTOR) && (_name != __ELEPHANT_JSON_SCHEMA_VERSION))
            {
                _struct[$ _name] = __ElephantFromJSONInner(_target[$ _name]);
            }
            
            ++_i;
        }
        
        return _struct;
    }
    else if (is_array(_target))
    {
        var _length = array_length(_target);
        var _array = array_create(_length);
        
        global.__elephantFound[? ds_map_size(global.__elephantFound)] = _array;
        
        var _i = 0;
        repeat(_length)
        {
            _array[@ _i] = __ElephantFromJSONInner(_target[_i]);
            ++_i;
        }
        
        return _array;
    }
    else
    {
        return _target;
    }
}