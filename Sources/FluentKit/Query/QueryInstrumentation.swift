import class NIOConcurrencyHelpers.Lock
import SQLKit

// MARK: - Fluent predefined metrics

extension SQLQueryPerformanceRecord.Metric {
    /// The time taken to convert a Fluent `DatabaseQuery` into an `SQLExpression`.
    public static var queryASTGenerationDuration: Self { .init(string: "codes.vapor.fluentkit.metric.queryConversion") }

    /// The number of result rows, if any, returned from a query. This metric has a value, even
    /// if it is zero, if any attempt to retrieve results - including `RETURNING` clauses - was
    /// made. If it has no value at all, the query did not check for or return any results.
    public static var returnedResultRowCount: Self { .init(string: "codes.vapor.fluentkit.metric.resultCount") }
    
    /// The time taken to convert `DatabaseOutput` "rows" into `Model` objects.
    public static var highLevelModelOutputDuration: Self { .init(string: "codes.vapor.fluentkit.metric.modelOutput") }
}

// MARK: - Fluent instrumentation

/// Holds a record of individual query performance statistics, an aggregate record
/// for each database connection, and a global aggregate record for all queries on
/// all databases.
public final class QueryInstrumentation {
    /// The performance records of queries that were executed
    public var queryRecords: [SQLQueryPerformanceRecord] = []
    
    /// The aggregate performance record for the database context this instrumentation container belongs to.
    public var aggregateRecord: SQLQueryPerformanceRecord = .init()
    
    /// The global performance record for the entire process.
    public static var globalRecord: SQLQueryPerformanceRecord = .init()

    /// Protects the global record
    private static var globalLock = Lock()
    
    /// Protects the per-context records
    private var lock = Lock()

    public static func readGlobalRecordSnapshot() -> SQLQueryPerformanceRecord {
        self.globalLock.withLock {
            let snapshot = self.globalRecord
            return snapshot
        }
    }

    public init() {}

    /// - WARNING: This method is _only_ intended for use by database drivers. It should be considered
    ///   non-`public`, and will _NOT_ be treated as part of public API for purposes of determining a
    ///   semver level for changes!
    public func add(record: SQLQueryPerformanceRecord) {
        self.lock.withLock {
            self.queryRecords.append(record)
            self.aggregateRecord.aggregate(record: record)
        }
        Self.globalLock.withLock {
            Self.globalRecord.aggregate(record: record)
        }
    }
}

extension Optional where Wrapped == SQLQueryPerformanceRecord {
    /// A wrapper for the `SQLQueryPerformanceRecord` version of this method which ensures that the
    /// closure is called even if there is no performance record in which to record the duration.
    public mutating func measure<R>(metric: SQLQueryPerformanceRecord.Metric, closure: () throws -> R) rethrows -> R {
        try self?.measure(metric: metric, closure: closure) ?? closure()
    }
}
