package js.npm.nodewebkit;

/**
	See https://github.com/rogerwang/node-webkit/wiki/Shell 
**/
extern class Shell implements npm.Package.RequireNamespace<"nw.gui","*">
{
	/**
		Open the given external protocol `URI` in the desktop's default manner. (For example, mailto: URLs in the default mail user agent.)
	**/
	static function openExternal( uri:String ):Void;

	/**
		Open the given `file_path` in the desktop's default manner.
	**/
	static function openItem( file_path:String ):Void;

	/**
		Show the given `file_path` in a file manager. If possible, select the file.
	**/
	static function showItemInFolder( file_path:String ):Void;
}