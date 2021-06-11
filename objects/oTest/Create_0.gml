base64 = ElephantExportString( { a : 1, b : 3, c : [1, 2, 3, 4, -5, "hello world"] } );
data = ElephantImportString(base64);

show_debug_message(data);

struct = new testConstructor();
struct.a = new testConstructor();
struct.a.a = 43;

base64 = ElephantExportString(struct);
data = ElephantImportString(base64);

show_debug_message(data);
show_debug_message(instanceof(data));
show_debug_message(instanceof(data.a));