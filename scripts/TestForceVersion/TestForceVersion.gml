function TestForceVersion() constructor
{
    a = 0;
    b = 2;
    c = 4;
    
    ELEPHANT_SCHEMA
    {
        ELEPHANT_FORCE_VERSION : 1,
        
        v1 : {
            a : buffer_any,
        },
        
        v2 : {
            b : buffer_any,
        },
        
        v3 : {
            c : buffer_any,
        }
    }
}