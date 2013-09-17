package js.npm;

import js.support.Callback;

/** 
	See https://github.com/learnboost/kue

	Things from the README currently not supported:

	- Custom Redis connection
	- Custom 
**/
extern class Kue implements npm.Package.Require<"kue","*">
{
	/**
		The reference to the Kue web app interface
	**/
	static var app:App;

	/**
		Create a new job queue
	**/
	static function createQueue():Queue;
}

/**
	A Kue web-app interface
**/
extern class App
{
	/**
		Start the Interface listening on a certain port
	**/
	function listen( port:Int ):Void;

	/**
		Set a config item on the app
	**/
	function set( name:String, value:Dynamic ):Void;
}

/**
	A Kue Job Queue
**/
extern class Queue
{
	/**
		Create a new job in this queue.

		The "jobType" should have a corresponding type defined with `process`
	**/
	function create( jobType:String, data:{} ):Job;

	/**
		Add a callback for processing a specific type of job.
	**/
	@:overload(function( jobType:String, concurrency:Int, cb:Job->Callback<String>->Void ):Void {})
	function process( jobType:String, fn:Job->Callback<String>->Void ):Void;

	/**
		Trigger a listener for an event
	**/
	function on( evt:String, cb:Int->Void ):Void;

	/**
		A shortcut for the "job complete" event
	**/
	inline function onComplete( cb:Int->Void ):Void {
		on( "job complete", cb );
	}

	/**
		Set the interval to check for delayed jobs that need to be promoted
	**/
	function promote( int:String ):Void;
}

/**
	A Kue Job
**/
extern class Job
{
	/**
		Get a job with the given ID.
	**/
	static function get( id:Int ):Job;

	/**
		The data that was associated with this job
	**/
	var data:{};

	/**
		Change the priority.

		An int between -20 and 19 I think.  Or a string:

		```
		low: 10
		normal: 0
		medium: -5
		high: -10
		critical: -15
		```

		See https://github.com/learnboost/kue#job-priority

		Returns itself, so chaining is enabled.
	**/
	@:overload(function ( priority:String ):Job {})
	function priority( niceness:Int ):Job;

	/**
		Number of times to attempt the Job if it fails

		See https://github.com/learnboost/kue#failure-attempts

		Returns itself, so chaining is enabled.
	**/
	function attempts( numberAttempts:Int ):Job;

	/**
		Delay this job by a number of milliseconds

		See https://github.com/learnboost/kue#delayed-jobs

		Returns itself, so chaining is enabled.
	**/
	function delay( milliseconds:Int ):Job;

	/**
		Save the current job to the queue
	**/
	function save():Void;

	/**
		Create a log entry on the current job.

		See https://github.com/learnboost/kue#job-logs

		These externs support up to 4 arguments, though the underling function supports an unlimited number.

		Not sure how to represent this in Haxe externs...
	**/
	@:overload(function ( log:String, data1:Dynamic ):Void {})
	@:overload(function ( log:String, data1:Dynamic, data2:Dynamic ):Void {})
	@:overload(function ( log:String, data1:Dynamic, data2:Dynamic, data3:Dynamic ):Void {})
	@:overload(function ( log:String, data1:Dynamic, data2:Dynamic, data3:Dynamic, data4:Dynamic ):Void {})
	function log( log:String ):Void;

	/**
		Update the progress marker for this job
	**/
	function progress( completed:Int, total:Int ):Void;

	/**
		Update the progress marker for this job
	**/
	@:overload(function ( event:String, cb:Int->Void ):Void {})
	function on( event:String, cb:Void->Void ):Void;

	/** Shortcut function for on("progress", cb) **/
	inline function onProgress(cb:Int->Void):Void on("progress", cb);

	/** Shortcut function for on("complete", cb) **/
	inline function onComplete(cb:Void->Void):Void on("complete", cb);

	/** Shortcut function for on("failed", cb) **/
	inline function onFailed(cb:Void->Void):Void on("failed", cb);

	/** Shortcut function for on("promotion", cb) **/
	inline function onPromotion(cb:Void->Void):Void on("promotion", cb);
}