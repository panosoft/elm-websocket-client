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
const _panosoft$elm_websocket_browser$Native_Websocket = (_ => {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Cmds
    const _connect = (url, openCb, messageCb, connectionClosedCb, cb) => {
        try {
            const ws = new WebSocket(url);
            var open = false;
            ws.addEventListener('open', _ => open = true, E.Scheduler.rawSpawn(A2(openCb, url, ws)));
            ws.addEventListener('message', event => E.Scheduler.rawSpawn(messageCb(event.data)));
            ws.addEventListener('close', _ => open ? E.Scheduler.rawSpawn(connectionClosedCb()) : null);
            cb();
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
    const connect = helper.call4_0(_connect);
    const send = helper.call2_0(_send);
    const disconnect = helper.call1_0(_disconnect);
	return {
		///////////////////////////////////////////
		// Cmds
        connect: F5(connect),
        send: F3(send),
        disconnect: F2(disconnect)
		///////////////////////////////////////////
		// Subs
	};

})();
// for local testing
const _user$project$Native_Websocket = _panosoft$elm_websocket_browser$Native_Websocket;
