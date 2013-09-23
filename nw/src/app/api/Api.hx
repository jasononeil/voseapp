package app.api;

import app.api.ProjectApi;
import app.api.QueueApi;

class Api 
{
	public var projectApi:ProjectApi;
	public var queueApi:QueueApi;
	public function new() {
		projectApi = new ProjectApi();
		queueApi = new QueueApi();
	}
}