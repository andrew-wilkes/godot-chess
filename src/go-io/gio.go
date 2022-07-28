package main

import (
	"fmt"

	"github.com/shadowapex/godot-go/gdnative"
)

type GIO struct {
	base gdnative.Object
}

// Instances is a map of our created Godot classes. This will be populated when
// Godot calls the CreateFunc.
var Instances = map[string]*GIO{}

var Message = ""

// NativeScriptInit will run on NativeScript initialization. It is responsible
// for registering all our classes with Godot.
func nativeScriptInit() {

	createFunc := gdnative.InstanceCreateFunc{
		CreateFunc: gioConstructor,
		MethodData: "GIO",
		FreeFunc:   func(methodData string) {},
	}

	// Define an instance destroy function. This will be called when Godot
	// asks our library to destroy our class instance.
	destroyFunc := gdnative.InstanceDestroyFunc{
		DestroyFunc: gioDestructor,
		MethodData:  "GIO",
		FreeFunc:    func(methodData string) {},
	}

	// Register our class with Godot.
	gdnative.Log.Warning("Registering GIO class...")
	gdnative.NativeScript.RegisterClass(
		"GIO",
		"Reference",
		&createFunc,
		&destroyFunc,
	)

	// Register a method with Godot.
	gdnative.Log.Warning("Registering GIO method...")
	gdnative.NativeScript.RegisterMethod(
		"GIO",
		"write",
		&gdnative.MethodAttributes{
			RPCType: gdnative.MethodRpcModeDisabled,
		},
		&gdnative.InstanceMethod{
			Method:     write,
			MethodData: "GIO",
			FreeFunc:   func(methodData string) {},
		},
	)

	gdnative.NativeScript.RegisterMethod(
		"GIO",
		"read",
		&gdnative.MethodAttributes{
			RPCType: gdnative.MethodRpcModeDisabled,
		},
		&gdnative.InstanceMethod{
			Method:     read,
			MethodData: "GIO",
			FreeFunc:   func(methodData string) {},
		},
	)
}

func gioConstructor(object gdnative.Object, methodData string) string {

	instance := &GIO{
		base: object,
	}

	// Use the pointer address as the instance ID
	instanceID := fmt.Sprintf("%p", instance)
	Instances[instanceID] = instance

	return instanceID
}

func gioDestructor(object gdnative.Object, methodData, userData string) {
	// Delete the instance from our map of instances
	delete(Instances, userData)
}

// Accept strings to be written to the Chess Engine
func write(object gdnative.Object, methodData, userData string, numArgs int, args []gdnative.Variant) gdnative.Variant {
	gdnative.Log.Println("GIO.write() called!")

	data := gdnative.NewStringWithWideString("World from godot-go from instance: " + object.ID() + "!")
	ret := gdnative.NewVariantWithString(data)

	return ret
}

// Return the Message value and reset it
// There seems to be no function to emit a signal from gdnative so we will use polling
func read(object gdnative.Object, methodData, userData string, numArgs int, args []gdnative.Variant) gdnative.Variant {
	gdnative.Log.Println("GIO.read() called!")

	data := gdnative.NewStringWithWideString(Message)
	ret := gdnative.NewVariantWithString(data)
	Message = ""

	return ret
}

func init() {
	gdnative.SetNativeScriptInit(nativeScriptInit)
	// Start the Chess Engine
}

// This never gets called, but it necessary to export as a shared library.
func main() {
}
