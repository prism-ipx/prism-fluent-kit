public protocol Database {
    var eventLoop: EventLoop { get }
    
    func execute(
        _ query: DatabaseQuery,
        _ onOutput: @escaping (DatabaseOutput) throws -> ()
    ) -> EventLoopFuture<Void>
    
    func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void>
    
    func close() -> EventLoopFuture<Void>
}
