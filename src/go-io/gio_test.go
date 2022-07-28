package main

import (
	"testing"
)

// test function
func TestNativeScriptInit(t *testing.T) {
	// Need to init gdnative somehow
	// godot_gdnative_init is the library entry point. When the library is loaded
	// this method will be called by Godot.
	//func godot_gdnative_init(options *C.godot_gdnative_init_options)
	nativeScriptInit()
}
