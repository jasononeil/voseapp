package vidproject.commands;

import haxe.PosInfos;
import hxevents.Dispatcher;
using tink.core.types.Outcome;

class Command
{
	public var name(default,null):String;
	public var status(default,null):CommandStatus;
	public var logEntries(default,null):Array<{ msg:String, pos:PosInfos }>;
	public var onStatusUpdate(default,null):Dispatcher<CommandStatus>;

	private function new() {
		onStatusUpdate = new Dispatcher();
		updateStatus( SNotReady );
		logEntries = [];
		name = "Unknown Command";
	}

	public function log( l:Dynamic, ?p:haxe.PosInfos ) {
		logEntries.push( { msg: Std.string(l), pos: p } );
		trace( l, p );
	}

	public function execute() throw "Abstract Method";

	function updateStatus( s ) {
		this.status = s;
		onStatusUpdate.dispatch( s );
	}
}

enum CommandStatus 
{
	SNotReady;
	SInvalid( err:String );
	SReady;
	SInProgress( ?completion:Float );
	SCompleted;
	SError( err:String );
}