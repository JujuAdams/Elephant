/// @param target

function ElephantDuplicate(_target)
{
    global.__elephantFound = ds_map_create();
    var _duplicate = __ElephantDuplicateInner(_target);
    ds_map_destroy(global.__elephantFound);
    
    return _duplicate;
}

function __ElephantDuplicateInner(_target)
{
    if (is_struct(_target))
    {
        var _duplicate = global.__elephantFound[? _target];
        if (is_struct(_duplicate))
        {
            return _duplicate;
        }
        else
        {
            var _instanceof = instanceof(_target);
            if (_instanceof == "struct")
            {
                var _duplicate = {};
            }
            else
            {
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
                
                var _duplicate = new _constructorFunction();
            }
            
            global.__elephantFound[? _target] = _duplicate;
            
            var _names = variable_struct_get_names(_target);
            var _length = array_length(_names);
            
            var _i = 0;
            repeat(_length)
            {
                var _name = _names[_i];
                _duplicate[$ _name] = __ElephantDuplicateInner(_target[$ _name]);
                ++_i;
            }
            
            return _duplicate;
        }
    }
    else if (is_array(_target))
    {
        var _duplicate = global.__elephantFound[? _target];
        if (is_array(_duplicate))
        {
            return _duplicate;
        }
        else
        {
            var _length = array_length(_target);
            
            var _duplicate = array_create(_length);
            global.__elephantFound[? _target] = _duplicate;
            
            var _i = 0;
            repeat(_length)
            {
                _duplicate[@ _i] = __ElephantDuplicateInner(_target[_i]);
                ++_i;
            }
            
            return _duplicate;
        }
    }
    else
    {
        return _target;
    }
}