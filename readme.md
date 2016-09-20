# Streaming Api Demo

This is an OSX 10.6 application that demonstrates the Force.com Streaming API (currently in pilot).

You can download a build version of the code from http://www.pocketsoap.com/osx/streamer.

## Not under active development

# Around the code

StreamingApiClient : This is the primary Api client class, it handles the cometd protocol used by the streaming api, and calls methods on the delegate when messages arive, or the connection state changes.

*Controller : These classes are primarily responsible for coordinating the various pieces of the UI

UrlConnectionDelegate: These are some helpers that handle common cases/patterns with the URLConnection delegate implemenation, these are uses as the basis for all the HTTP requests made by the app.

