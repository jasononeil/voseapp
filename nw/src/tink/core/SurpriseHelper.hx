package tink.core;

import tink.CoreApi;

class SurpriseHelper {
	static public inline function then<A,B>( s:Surprise<A,B>, cb:Callback<A> ) {
		s.handle( function(outcome) {
			switch outcome {
				case Success(d): cb.invoke(d);
				default:
			}
		});
		return s;
	}
	static public inline function error<A,B>( s:Surprise<A,B>, cb:Callback<B> ) {
		s.handle( function(outcome) {
			switch outcome {
				case Failure(f): cb.invoke(f);
				default:
			}
		});
		return s;
	}
}