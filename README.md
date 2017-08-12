00# HMRequestFramework-iOS
Network/Database request framework for iOS clients.

This framework provides handlers, processors and middlewares to manage all manners of requests, be it database or network. It guarantees immutability in most cases and relies heavily on RxSwift.

### Handlers ###

Request handlers only perform the requests. Requests can be chained together into one sequential stream, with the ones below taking the result
of those immediately above them as input. All emission are wrapped in Try<Val> and no errors are thrown anywhere. This allows us to write performant code without worrying about uncaught errors (which, under other circumstances, would kill the active stream).

### Processors ###

Processors wrap handlers and provide result-processing capabilities. This is done so that the underlying implementation of the requests is not leaked.

For example, the CoreData request processor can be used to emit only pure objects. Conversion of NSManagedObject instances is done automatically.

### Middlewares ###

These are used to intercept some result. Currently only request middlewares are supported.

We can use middlewares to automatically insert HTTP headers (or change the request however we wish). The request object itself will not be mutated - a new request is created in its place.
