// Feather disable all

function __ElephantValueToDatatype(_value)
{
    switch(typeof(_value))
    {
        case "int32":     return buffer_s32;       break;
        case "bool":      return buffer_bool;      break;
        case "number":    return buffer_f64;       break;
        case "string":    return buffer_string;    break;
        case "undefined": return buffer_undefined; break;
        case "struct":    return buffer_struct;    break;
        
        case "array":
        case "vec3":
        case "vec4": return buffer_array; break;
        
        case "int64":
        case "ptr": return buffer_u64; break;
                
        case "method":
            __ElephantTrace("Methods not supported, writing <undefined>");
            return buffer_undefined;
        break;
                
        default:
            __ElephantError("Datatype not recognised \"", typeof(_value), "\"");
        break
    }
    
    return buffer_undefined;
}