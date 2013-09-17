package js.npm.nodewebkit;

import js.node.events.EventEmitter;

/** 
	See https://github.com/rogerwang/node-webkit/wiki/App
**/
extern class App implements npm.Package.RequireNamespace<"nw.gui","*">
{
	/**
		**Get** the command line arguments when starting the app.
	**/
	static var argv:Array<String>;

	/**
		**Get** all the command line arguments when starting the app. Because node-webkit itself used switches like `--no-sandbox` and `--process-per-tab`, it would confuse the app when the switches were meant to be given to node-webkit, so `App.argv` just filtered such switches (arguments' precedence were kept). You can get the switches to be filtered with `App.filteredArgv`.
	**/
	static var fullArgv:Array<String>;

	/**
		**Get** the application's data path in user's directory. Windows: `%LOCALAPPDATA%/<name>`; Linux: `~/.config/<name>`; OSX: `~/Library/Application Support/<name>` where `<name>` is the field in the manifest.
	**/
	static var dataPath:Array<String>;

	/**
		**Get** the JSON object of the manifest file.
	**/
	static var manifest:{};

	/**
		Clear the HTTP cache in memory and the one on disk. This method call is synchronized.
	**/
	static function clearCache():Void;

	/**
		Send the `close` event to all windows of current app, if no window is blocking the `close` event, then the app will quit after all windows have done shutdown. Use this method to quit an app will give windows a chance to save data.
	**/
	static function closeAllWindows():Void;

	/**
		Query the proxy to be used for loading `url` in DOM. The return value is in the same format used in [PAC](http://en.wikipedia.org/wiki/Proxy_auto-config) (e.g. "DIRECT", "PROXY localhost:8080").
	**/
	static function getProxyForUrl( url:String ):String;

	/**
		Quit current app. This method will **not** send `close` event to windows and app will just quit quietly.
	**/
	static function quit():Void;

	/**
		Emitted when users opened a file with your app. There is a single parameter of this event callback: Since v0.7.0, it is the full command line of the program; before that it's the argument in the command line and the event is sent multiple times for each of the arguments. For more on this, see [[Handling files and arguments]].
	**/
	static var open:EventEmitter;
}