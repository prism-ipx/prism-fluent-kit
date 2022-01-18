import SQLKit

public protocol Database {
    var context: DatabaseContext { get }
    
    func execute(
        query: DatabaseQuery,
        onOutput: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void>
    
    func execute(
        instrumentedQuery: DatabaseQuery,
        addingToPerfRecord: SQLQueryPerformanceRecord?,
        onOutput: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<SQLQueryPerformanceRecord?>

    func execute(
        schema: DatabaseSchema
    ) -> EventLoopFuture<Void>

    func execute(
        enum: DatabaseEnum
    ) -> EventLoopFuture<Void>
    
    var inTransaction: Bool { get }

    func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T>
    
    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T>
}

extension Database {
    /// This gets a little tricky - because instrumentation is optional, the performance record has to be
    /// optional. It also has to be passed in _and_ returned by value to retain any metrics recorded
    /// by callers, while also simultaneously being as invisible as possible to those using the Database
    /// API directly. Not very invisible, as it turns out... This method does not guarantee that the query
    /// is instrumented, it just serves as an entry point for code paths which have the necessary extra
    /// support for instrumentation if and when it is actually desired. There is unfortunately no other
    /// way for the performance record to maintain its full complement of data (if any) in the futures
    /// world. In a Concurrency world, there are much cleaner options... Meanwhile, this extension
    /// implementation's only job is to act like nothing's changed for the sake of drivers that don't care
    /// to deal with this... hassle.
    public func execute(
        instrumentedQuery query: DatabaseQuery,
        addingToPerfRecord perfRecord: SQLQueryPerformanceRecord?,
        onOutput: @escaping (DatabaseOutput) -> ()
    ) -> EventLoopFuture<SQLQueryPerformanceRecord?> {
        self.execute(query: query, onOutput: onOutput).transform(to: perfRecord)
    }
}

extension Database {
    public func query<Model>(_ model: Model.Type) -> QueryBuilder<Model>
        where Model: FluentKit.Model
    {
        return .init(database: self)
    }
}

extension Database {
    public var configuration: DatabaseConfiguration {
        self.context.configuration
    }
    
    public var logger: Logger {
        self.context.logger
    }
    
    public var eventLoop: EventLoop {
        self.context.eventLoop
    }

    public var history: QueryHistory? {
        self.context.history
    }
    
    public var instrumentation: QueryInstrumentation? {
        self.context.instrumentation
    }

    public var pageSizeLimit: Int? {
        self.context.pageSizeLimit
    }
}

public protocol DatabaseDriver {
    func makeDatabase(with context: DatabaseContext) -> Database
    func shutdown()
}

public protocol DatabaseConfiguration {
    var middleware: [AnyModelMiddleware] { get set }
    func makeDriver(for databases: Databases) -> DatabaseDriver
}

public struct DatabaseContext {
    public let configuration: DatabaseConfiguration
    public let logger: Logger
    public let eventLoop: EventLoop
    public let history: QueryHistory?
    public let instrumentation: QueryInstrumentation?
    public let pageSizeLimit: Int?
    
    public init(
        configuration: DatabaseConfiguration,
        logger: Logger,
        eventLoop: EventLoop,
        history: QueryHistory? = nil,
        instrumentation: QueryInstrumentation? = nil,
        pageSizeLimit: Int? = nil
    ) {
        self.configuration = configuration
        self.logger = logger
        self.eventLoop = eventLoop
        self.history = history
        self.instrumentation = instrumentation
        self.pageSizeLimit = pageSizeLimit
    }
}

public protocol DatabaseError {
    var isSyntaxError: Bool { get }
    var isConstraintFailure: Bool { get }
    var isConnectionClosed: Bool { get }
}
