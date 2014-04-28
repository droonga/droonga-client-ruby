# News

## 0.1.6: 2014-04-29 (planned)

 * Supports droonga's protocol.

## 0.1.5: 2014-03-29

### Improvements

  * droonga-request: Reported results correctly event if there were multiple threads.
  * Added a new command `droonga-send` just for sending requests and ignoring responses.

## 0.1.4: 2014-02-28

### Improvements

  * droonga-request: Supported multiple input files.

## 0.1.3: 2014-02-17

### Improvements

  * droonga-request: Supported multiple JSONs.
  * droonga-request: Added `--report-request` option.

## 0.1.2: 2014-02-09

### Improvements

  * Supported a large response.
  * Added droonga-request command.

## 0.1.1: 2014-01-29

### Improvements

  * droonga-protocol: Removed needless `statusCode` parameter from request.
  * droonga-protocol: Renamed {Droonga::Client#execute} to
    {Droonga::Client#request}. This is incompatible change.
  * droonga-protocol: Removed {Droonga::Client#search} because it is
    not useful.
  * droonga-protocol: Changed to use `Socket.gethostname` as the
    default receiver host instead of `0.0.0.0`.
  * Added {Droonga::Client#subscribe} for PubSub style messaging.
  * http: Started to support HTTP.

## 0.1.0: 2013-12-29

### Improvements

  * Added {Droonga::Client.open}.
  * Added {Droonga::Client#close}.
  * Supported multiple responses.
  * Supported asynchronous request.

## 0.0.1: 2013-11-29

The first release!!!
