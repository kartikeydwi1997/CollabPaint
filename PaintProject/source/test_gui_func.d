module test_gui_func;
import std.socket;
import std.stdio;
import core.thread.osthread;
import std.string;
import std.getopt;
import std.parallelism;
// modules
import gui;
import server,client;
import utils;
import core.sys.posix.pthread;
import colors;

/// sanity test
@("GUI Sanity test")
unittest {
    Gui test = new Gui();
    test.setBrushColor(cast(byte) colors.PaintBrushColor.BLUE[0],
    cast(byte) colors.PaintBrushColor.BLUE[1],
    cast(byte) colors.PaintBrushColor.BLUE[2]);
    assert(test.red == cast(byte)255);
    assert(test.green == cast(byte)0); 
    assert(test.blue == cast(byte)0);
}

@("Undo callback test")
unittest {
    Gui test = new Gui();
    test.undo_callback();
    test.undo_action();
}   

@("Redo callback test")
unittest {
    Gui test = new Gui();
    test.redo_callback();
    test.redo_action();
}   