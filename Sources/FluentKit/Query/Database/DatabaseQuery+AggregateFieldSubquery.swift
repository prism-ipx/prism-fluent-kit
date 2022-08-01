//
//  DatabaseQuery+AggregateFieldSubquery.swift
//
//
//  Created by Bruce Quinton on 16/9/20.
//
extension DatabaseQuery {
    public enum AggregateFieldSubquery {
      public enum Method {
          case count
          case sum
          case average
          case minimum
          case maximum
          case custom(Any)
      }

      case AggregateSubquery(
          schema: String,
          subschema: String,
          method: Method,
          field: FieldKey,
          foreign: FieldKey,
          local: FieldKey
      )
      case custom(Any)
    }
}

extension DatabaseQuery.AggregateFieldSubquery: CustomStringConvertible {
    public var description: String {
        switch self {
        case .AggregateSubquery(let schema, let subschema, let method, let field, let foreign, let local):
          //SQLColumn(self.key(key), table: schema)
          let queryMethod: String

          switch method {
          case .count:
            queryMethod = method.description
          case .custom:
            queryMethod = method.description
          default:
            queryMethod = method.description + "(\(field))"
          }

          return "(select \(queryMethod) from \(subschema) where \(subschema).\(foreign) = \(schema).\(local))"

        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}

extension DatabaseQuery.AggregateFieldSubquery.Method: CustomStringConvertible {
    public var description: String {
        switch self {
        case .count:
            return "count(*)"
        case .sum:
            return "sum"
        case .average:
            return "average"
        case .minimum:
            return "minimum"
        case .maximum:
            return "maximum"
        case .custom(let custom):
            return "custom(\(custom))"
        }
    }
}