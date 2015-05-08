# News

## 0.2.2: 2015-05-29

 * `droonga-request`
   * Works correctly with HTTP protocol. (regression)
   * The `--[no-]exit-on-response` option is removed because it is nonsense.

## 0.2.1: 2015-04-29

 * Required fields of input messages are automatically completed by default.
 * Input messages are automatically validated by default.
 * Timeout option for subscription is available.
   You can unsubscribe subscription automatically with specified timeout, like:
   `client.subscribe(request, :subscription_timeout => 10)`
 * New utility commands are available as shorthand.
   * `droonga-system-status`: allows you to send a `system.status` request to the cluster easily.
   * `droonga-add`: allows you to send an `add` request to the cluster easily.
   * `droonga-groonga`: works like the `groonga` command.
 * droonga-send, droonga-request:
   * A new option `--[no-]completion` is introduced.
     You should specify `--no-completion` to send incomplete messages intentionally.
   * A new option `--[no-]validation` is introduced.
     You should specify `--no-validation` to send invalid messages intentionally.
   * A new option `--default-dataset` is introduced.
     It is used for sending messages if they have no `dataset` field.
   * A new option `--default-target-role` is introduced.
     It is used for sending messages if they have no `targetRole` field.
   * The "date" field is filled with the format same to droonga-engine's internal one
     like "2015-04-08T06:16:20.571303Z".

## 0.2.0: 2014-11-29

 * droonga-send:
   * Restrict the number of sending messages per second to 100 by default.
     Too many inpouring messages will make the cluster overflowed.
   * Calculate suitable limitation about number of sending messages per second
     for each endpoint, based on `--messages-per-second`.
     In old versions, actually too many messages are sent to the cluster
     because the limit affected for each node. (So, even if you specify `100`,
     actually 300 messages were possibly sent when there are three endpoints.)

## 0.1.9: 2014-07-29

 * droonga-send: Accept default protocol, port, and tag. Now you can omit them for the `--server` option.

## 0.1.8: 2014-07-14

### Fixes

  * thread backend: Fixed a bug that some responses are dropped.

## 0.1.7: 2014-05-29

 * Updated the default port number, same to `droonga-engine`'s one.

## 0.1.6: 2014-04-29

 * Supports Droonga's protocol.
 * Used "Cool.io" backend for Droonga protocol.

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
  * droonga-protocol: Renamed `Droonga::Client#execute` to
    {Droonga::Client#request}. This is incompatible change.
  * droonga-protocol: Removed `Droonga::Client#search` because it is
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
