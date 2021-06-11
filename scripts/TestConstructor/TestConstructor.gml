function TestConstructor() constructor
{
    a = 0;
    b = 2;
    c = 4;
    
    ELEPHANT_SCHEMA
    {
        v1 : {
            a: buffer_any,
            b: buffer_f64,
        },
    }
}