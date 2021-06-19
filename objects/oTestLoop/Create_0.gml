a = new TestLoop();
b = new TestLoop();
a.Add(b);

show_debug_message(a);

base64 = ElephantExportString(a);
data = ElephantImportString(base64);

show_debug_message(data);
show_debug_message("Expect \"TestLoop\", got " + string(instanceof(data)));
show_debug_message("Expect \"TestLoop\", got " + string(instanceof(data.children[0])));
show_debug_message("Expect \"TestLoop\", got " + string(instanceof(data.children[0].parent)));
show_debug_message("Expect \"1\", got " + string(data.children[0].parent == data));