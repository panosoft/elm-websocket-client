var _panosoft$elm_websocket_client$Native_Websocket;
(function() {
	// Elm globals (some for elm-native-helpers and some for us and some for the future)
	const E = {
		A2: A2,
		A3: A3,
		A4: A4,
		Scheduler: {
			nativeBinding: _elm_lang$core$Native_Scheduler.nativeBinding,
			succeed:  _elm_lang$core$Native_Scheduler.succeed,
			fail: _elm_lang$core$Native_Scheduler.fail,
			rawSpawn: _elm_lang$core$Native_Scheduler.rawSpawn
		},
		List: {
			fromArray: _elm_lang$core$Native_List.fromArray
		},
		Maybe: {
			Nothing: _elm_lang$core$Maybe$Nothing,
			Just: _elm_lang$core$Maybe$Just
		},
		Result: {
			Err: _elm_lang$core$Result$Err,
			Ok: _elm_lang$core$Result$Ok
		}
	};
	// This module is in the same scope as Elm but all modules that are required are NOT
	// So we must pass elm globals to it (see https://github.com/panosoft/elm-native-helpers for the minimum of E)
	const helper = require('@panosoft/elm-native-helpers/helper')(E);
	_panosoft$elm_websocket_client$Native_Websocket = function() {
		const wsCloseReason = event => {
			// See http://tools.ietf.org/html/rfc6455#section-7.4.1
			if (event.code == 1000)
				return "Normal closure, meaning that the purpose for which the connection was established has been fulfilled.";
			else if(event.code == 1001)
				return "An endpoint is \"going away\", such as a server going down or a browser having navigated away from a page.";
			else if(event.code == 1002)
				return "An endpoint is terminating the connection due to a protocol error";
			else if(event.code == 1003)
				return "An endpoint is terminating the connection because it has received a type of data it cannot accept (e.g., an endpoint that understands only text data MAY send this if it receives a binary message).";
			else if(event.code == 1004)
				return "Reserved. The specific meaning might be defined in the future.";
			else if(event.code == 1005)
				return "No status code was actually present.";
			else if(event.code == 1006)
			   return "The connection was closed abnormally, e.g., without sending or receiving a Close control frame";
			else if(event.code == 1007)
				return "An endpoint is terminating the connection because it has received data within a message that was not consistent with the type of the message (e.g., non-UTF-8 [http://tools.ietf.org/html/rfc3629] data within a text message).";
			else if(event.code == 1008)
				return "An endpoint is terminating the connection because it has received a message that \"violates its policy\". This reason is given either if there is no other sutible reason, or if there is a need to hide specific details about the policy.";
			else if(event.code == 1009)
			   return "An endpoint is terminating the connection because it has received a message that is too big for it to process.";
			else if(event.code == 1010) // Note that this status code is not used by the server, because it can fail the WebSocket handshake instead.
				return "An endpoint (client) is terminating the connection because it has expected the server to negotiate one or more extension, but the server didn't return them in the response message of the WebSocket handshake. <br /> Specifically, the extensions that are needed are: " + event.reason;
			else if(event.code == 1011)
				return "A server is terminating the connection because it encountered an unexpected condition that prevented it from fulfilling the request.";
			else if(event.code == 1015)
				return "The connection was closed due to a failure to perform a TLS handshake (e.g., the server certificate can't be verified).";
			else
				return "Unknown reason";
		};
	    //////////////////////////////////////////////////////////////////////////////////////////////////////////
		// Cmds
	    const _connect = (url, messageCb, connectionClosedCb, cb) => {
	        try {
				var ws;
				if (!process.env.BROWSER) {
					const WebSocket = require('ws')
					ws = new WebSocket(url);
				}
	            else
	            	ws = new WebSocket(url);
	            var open = false;
	            ws.addEventListener('open', _ => {
					open = true;
					cb(null, ws);
				});
	            ws.addEventListener('message', event => E.Scheduler.rawSpawn(messageCb(event.data)));
	            ws.addEventListener('close', event => {
					if (open) {
						open = false;
						E.Scheduler.rawSpawn(connectionClosedCb());
					}
					else
						cb(wsCloseReason(event));
				});
	        }
	        catch (err) {
	            cb(err.message)
	        }
	    };

	    const _send = (ws, message, cb) => {
	        try {
	            ws.send(message);
	            cb();
	        }
	        catch (err) {
	            cb(err.message)
	        }
	    };

	    const _disconnect = (ws, cb) => {
	        try {
	            ws.close();
	            cb()
	        }
	        catch (err) {
	            cb(err.message);
	        }
	    };
	    const connect = helper.call3_1(_connect);
	    const send = helper.call2_0(_send);
	    const disconnect = helper.call1_0(_disconnect);
		return {
			///////////////////////////////////////////
			// Cmds
	        connect: F4(connect),
	        send: F3(send),
	        disconnect: F2(disconnect)
			///////////////////////////////////////////
			// Subs
		};

	}();
})();
// for local testing
const _user$project$Native_Websocket = _panosoft$elm_websocket_client$Native_Websocket;
