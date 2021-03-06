//
//  Parser+Conjunction.swift
//  ParserCombinator
//
//  Created by Benjamin Herzog on 13.08.17.
//

extension Parser {
    
    /// Concatenates the results of both parsers.
    ///
    /// - Parameter other: another parser which results should be added
    /// - Returns: a parser that contains both parsing results.
    public func or(_ other: @escaping @autoclosure () -> Parser<T, R>) -> Parser<T, R> {
        return Parser { tokens in
            let result = self.parse(tokens)
            switch result {
            case .fail(_):
                return other().parse(tokens)
            default:
                return result
            }
        }
    }
    
    /// Discards the result of self and executes other afterwards on the rest.
    ///
    /// - Parameter other: another parser to execute afterwards
    /// - Returns: a parser that first parses self and then other on the rest of self
    public func then<B>(_ other: @escaping @autoclosure () -> Parser<T, B>) -> Parser<T, B> {
        return self.flatMap { _ in other() }
    }
    
    /// Provides a fallback if the parser fails.
    ///
    /// - Parameter defaultValue: a value that should be parsed instead.
    /// - Returns: a parser that tries to parse and uses defaultValue if parsing failed.
    ///
    /// *NOTE* If parsing fails, there are no tokens consumed!
    public func fallback(_ defaultValue: @escaping @autoclosure () -> R) -> Parser<T, R> {
        return Parser { tokens in
            let result = self.parse(tokens)
            switch result {
            case .fail(_):
                return .success(result: defaultValue(), rest: tokens)
            default:
                return result
            }
        }
    }
    
    /// Provides a fallback parser that is being used if self.parse fails.
    ///
    /// - Parameter defaultValue: the parser to use in case of failure
    /// - Returns: a parser that first tries self.parse and only uses defaultValue if self failed.
    public func fallback(_ defaultValue: @escaping @autoclosure () -> Parser<T, R>) -> Parser<T, R> {
        return Parser { tokens in
            switch self.parse(tokens) {
            case let .success(result, rest):
                return .success(result: result, rest: rest)
            default:
                return defaultValue().parse(tokens)
            }
        }
    }
    
    /// Erases the type of the parser
    public var typeErased: Parser<T, ()> {
        return Parser<T, ()> { tokens in
            switch self.parse(tokens) {
            case let .success(_, rest):
                return .success(result: (), rest: rest)
            case let .fail(err):
                return .fail(err)
            }
            
        }
    }
    
    /// Parses self repetitive and returns results in array
    public var rep: Parser<T, [R]> {
        return Parser<T, [R]> { tokens in
            var results = [R]()
            var totalRest = tokens

            loop: while true {
                switch self.parse(totalRest) {
                case let .success(result, rest):
                    results.append(result)
                    totalRest = rest
                case .fail(_):
                    break loop
                }
            }

            return .success(result: results, rest: totalRest)
        }
    }
    
    /// Parses self repetitive separated by sep Parser.
    ///
    /// - Parameter sep: the parser that separates self.parse operations.
    /// - Returns: a parser that parses self separated by sep as long as it doesn't fail.
    public func rep<B>(sep: Parser<T, B>) -> Parser<T, [R]> {
        return Parser<T, [R]> { tokens in
            var results = [R]()
            var totalRest = tokens
            
            let both = self <~ sep
            
            loop: while true {
                
                switch both.parse(totalRest) {
                case let .success(result, rest):
                    results.append(result)
                    totalRest = rest
                case .fail(_):
                    switch self.parse(totalRest) {
                    case let .success(singleResult, singleRest):
                        results.append(singleResult)
                        totalRest = singleRest
                        break loop
                    case .fail(_):
                        return .success(result: results, rest: totalRest)
                    }
                }
                
            }
            
            return .success(result: results, rest: totalRest)
        }
    }
    
}
