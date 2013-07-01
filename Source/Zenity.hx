import haxe.io.Eof;
import haxe.io.Input;
import sys.io.Process;

class Zenity
{
	public static function save( ?filename:String, ?confirmOverwrite=true, ?filters:FileFilters, ?fallback:String=null )
	{
		var args = [];
		args.push("--file-selection");
		args.push("--save");
		addFilterArgs(filters, args);
		if (filename!=null) args.push('--filename=$filename');
		if (confirmOverwrite) args.push("--confirm-overwrite");
		return switch call( args ) {
			case Success(text): text;
			case Failure(_,_): fallback;
		}
	}

	public static function open( ?startDir:String, ?filters:FileFilters, ?fallback:String=null )
	{
		var args = [];
		args.push("--file-selection");
		addFilterArgs(filters, args);
		if (startDir!=null) args.push('--filename=$startDir');
		return switch call( args ) {
			case Success(text): text;
			case Failure(_,_): fallback;
		}
	}

	public static function openMultiple( ?startDir:String, ?filters:FileFilters, ?fallback:Array<String> ):Array<String>
	{
		if ( fallback==null ) fallback = [];
		var args = [];
		args.push("--file-selection");
		args.push("--multiple");
		addFilterArgs(filters, args);
		if (startDir!=null) args.push('--filename=$startDir');
		return switch call( args ) {
			case Success(text): text.split("|");
			case Failure(_,_): fallback;
		}
	}

	public static function selectDir( ?startDir:String, ?filters:FileFilters, ?fallback:String=null )
	{
		var args = [];
		args.push("--file-selection");
		args.push("--directory");
		if (startDir!=null) args.push('--filename=$startDir');
		return switch call( args ) {
			case Success(text): text;
			case Failure(_,_): fallback;
		}
	}

	public static function call( args:Array<String> ):Result
	{
		var p = new Process( "zenity", args );
		switch (p.exitCode()) {
			case 0:
				return Success( readString(p.stdout) );
			case code:
				return Failure( readString(p.stderr), code );
		}
	}

	static function readString( i:Input ):String
	{
		var out = [];

		try {
			while (true) {
				out.push( i.readLine() );
			}
		} catch (e:Eof) {}

		return out.join("\n");
	}

	static function addFilterArgs( filters:FileFilters, args:Array<String> )
	{
		if ( filters!=null )
		{
			for ( name in filters.keys() )
			{
				// Wrap extensions in double quotations ("*.jpg") and join them with spaces
				var extensions = filters.get(name).join(" ");
				args.push('--file-filter=$name: $extensions');
			}
		}
	}
}

typedef FileFilters = Map<String,Array<String>>;

enum Result
{
	Success( output:String );
	Failure( msg:String, code:Int );
}