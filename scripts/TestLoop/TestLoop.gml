function TestLoop() constructor
{
    parent   = undefined;
    children = [];
    
    static Add = function(_child)
    {
        _child.parent = self;
        array_push(children, _child);
    }
}