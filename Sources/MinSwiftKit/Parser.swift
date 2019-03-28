import Foundation
import SwiftSyntax

class Parser: SyntaxVisitor {
    private(set) var tokens: [TokenSyntax] = []
    private var index = 0
    private(set) var currentToken: TokenSyntax!
    var count :Int!=0
    // MARK: Practice 1

    override func visit(_ token: TokenSyntax) {
        tokens.append(token)//tokensの配列の中にtokenが入ってないと最後のtokenしか入ってなくて困る
        print("Parsing \(token.tokenKind)")
    }

    @discardableResult
    func read() -> TokenSyntax {
        currentToken = tokens[index]
        //print(tokens[index].tokenKind)
        index += 1
        return currentToken
        //fatalError("Not Implemented")
    }

    func peek(_ n: Int = 0) -> TokenSyntax {
        var ind = 0
        for i in 0..<tokens.count{
            if currentToken == tokens[i]{
                ind = i+1
            }
        }
        return tokens[ind+n]
        //fatalError("Not Implemented")
    }

    // MARK: Practice 2

    private func extractNumberLiteral(from token: TokenSyntax) -> Double? {
       // fatalError("Not Implemented")
        let int = token.text
        return Double(int)
    }

    func parseNumber() -> Node {
        guard let value = extractNumberLiteral(from: currentToken) else {
            fatalError("any number is expected")
        }
        read() // eat literal
        return NumberNode(value: value)
    }

    func parseIdentifierExpression() -> Node {
        var arguments :[CallExpressionNode.Argument]!=[]
        let tex = currentToken.text
        read()
        if currentToken.tokenKind == .leftParen{
            read()
            while(true){
                if currentToken.tokenKind == .rightParen{
                    break
                }
                if currentToken.tokenKind == .colon{
                    read()
                }
                let argument_body = parseExpression()
                let argument = CallExpressionNode.Argument(label: tex, value: argument_body!)
                arguments.append(argument)
                /*if currentToken.tokenKind == .comma{
                //    read()
                    continue
                    
                }else {
                    read()
                    print(arguments)
                    print(currentToken.tokenKind)
                    break
                }*/
                /*
                if currentToken.tokenKind == .comma{
                    read()
                }*/
            }
            read()
            
            return CallExpressionNode(callee: tex, arguments:arguments)
        }else{
        return VariableNode(identifier:tex)
       // fatalError("Not Implemented")
        }
    }

    // MARK: Practice 3

    func extractBinaryOperator(from token: TokenSyntax) -> BinaryExpressionNode.Operator? {
        switch currentToken.text {
        case "+":
            return BinaryExpressionNode.Operator.addition
        case "-":
            return BinaryExpressionNode.Operator.subtraction
        case "*":
            return BinaryExpressionNode.Operator.multication
        case "/":
            return BinaryExpressionNode.Operator.division
        default:
            return nil
            //fatalError("any number is expected")
        }
        
    }

    private func parseBinaryOperatorRHS(expressionPrecedence: Int, lhs: Node?) -> Node? {
        var currentLHS: Node? = lhs
        while true {
            let binaryOperator = extractBinaryOperator(from: currentToken!)
            let operatorPrecedence = binaryOperator?.precedence ?? -1
            
            // Compare between nextOperator's precedences and current one
            if operatorPrecedence < expressionPrecedence {
                return currentLHS
            }
            
            read() // eat binary operator
            var rhs = parsePrimary()
            if rhs == nil {
                return nil
            }
            
            // If binOperator binds less tightly with RHS than the operator after RHS, let
            // the pending operator take RHS as its LHS.
            let nextPrecedence = extractBinaryOperator(from: currentToken)?.precedence ?? -1
            if (operatorPrecedence < nextPrecedence) {
                // Search next RHS from currentRHS
                // next precedence will be `operatorPrecedence + 1`
                rhs = parseBinaryOperatorRHS(expressionPrecedence: operatorPrecedence + 1, lhs: rhs)
                if rhs == nil {
                    return nil
                }
            }
            
            guard let nonOptionalRHS = rhs else {
                fatalError("rhs must be nonnull")
            }
            
            currentLHS = BinaryExpressionNode(binaryOperator!,
                                              lhs: currentLHS!,
                                              rhs: nonOptionalRHS)
        }
    }
    func CallFunctionDefinitionArgument() -> CallExpressionNode.Argument {
        var start:Int!
        var value:Node!
        for i in 0..<tokens.count{
            /*print(currentToken.tokenKind)
             print(tokens[i].tokenKind)*/
            if tokens[i].tokenKind == currentToken.tokenKind{
                
                start = i
                break
            }
        }
        var name:String!
        for i in start..<tokens.count{
            if tokens[i].tokenKind == .comma||tokens[i].tokenKind == .rightParen{
                read()
                break
            }
            print(currentToken.tokenKind)
            if tokens[i].tokenKind == .colon{
                print("Ok")
                name = tokens[i-1].text
                for j in i-1..<tokens.count{
                    if tokens[j].tokenKind == .comma||tokens[j].tokenKind == .rightParen{
                        break
                    }
                    read()
                    
                }
                // print(currentToken.tokenKind)
            }
            
        }
        value=parseExpression()
        return CallExpressionNode.Argument.init(label: name, value: value)
    }
    // MARK: Practice 4

    func parseFunctionDefinitionArgument() -> FunctionNode.Argument {
        var start:Int!
        
        for i in 0..<tokens.count{
            /*print(currentToken.tokenKind)
            print(tokens[i].tokenKind)*/
            if tokens[i].tokenKind == currentToken.tokenKind{

                start = i
                break
            }
        }
        var name:String!
        for i in start..<tokens.count{
            if tokens[i].tokenKind == .comma||tokens[i].tokenKind == .rightParen{
                read()
              //  print("Ok")
                break
            }
            if tokens[i].tokenKind == .colon{
                name = tokens[i-1].text
                read()
                read()
                read()
              // print(currentToken.tokenKind)
            }
            
        }
        return FunctionNode.Argument.init(label: name, variableName: name)
    }

    func parseFunctionDefinition() -> Node {
        guard case .funcKeyword = currentToken.tokenKind else{
            fatalError("funcKeyword is expected but received \(currentToken.tokenKind)")
        }//guard case の条件が真である時、これ以降のコードを実行可能。この場合、本当に関数の名前が来ているかどうか判定している。(本来は他の場所にも適用すべき)
        read()
        let name = currentToken.text
        read()
        var argument :[FunctionNode.Argument]!=[]
        for i in 0..<tokens.count{
           // print(currentToken.indexInParent)
            if tokens[i].tokenKind == .leftParen && tokens[i+1].tokenKind == .rightParen{
                read()
                read()
                break
            }
            if tokens[i].tokenKind == .colon{
                count+=1
                if count == 1{
                    read()
                }
               // print(count)
            }
          //  print(tokens[i].tokenKind)
            if tokens[i].tokenKind == .rightParen{
                for _ in 0..<count{
                      //  print(count)
                      //  print(argument)
                        argument.append(parseFunctionDefinitionArgument())
                    if count>1&&i<count-1{
                        read()
                    }

                }
            }
        }
        read()
        read()
        read()
        let Node = parseExpression()
       
        print(Node)
        read()
        return FunctionNode.init(name: name, arguments:argument, returnType:Type(rawValue: "Double")!, body: Node!)
        //fatalError("not implemented")
    }

    // MARK: Practice 7

    func parseIfElse() -> Node {
        fatalError("Not Implemented")
    }

    // PROBABLY WORKS WELL, TRUST ME

    func parse() -> [Node] {
        var nodes: [Node] = []
        read()
        while true {
            switch currentToken.tokenKind {
            case .eof:
                return nodes
            case .funcKeyword:
                let node = parseFunctionDefinition()
                nodes.append(node)
            default:
                if let node = parseTopLevelExpression() {
                    nodes.append(node)
                    break
                } else {
                    read()
                }
            }
        }
        return nodes
    }

    private func parsePrimary() -> Node? {
        switch currentToken.tokenKind {
        case .identifier:
            return parseIdentifierExpression()
        case .integerLiteral, .floatingLiteral:
            return parseNumber()
        case .leftParen:
            return parseParen()
        case .funcKeyword:
            return parseFunctionDefinition()
        case .returnKeyword:
            return parseReturn()
        case .ifKeyword:
            return parseIfElse()
        case .eof:
            return nil
        default:
            fatalError("Unexpected token \(currentToken.tokenKind) \(currentToken.text)")
        }
        return nil
    }

    func parseExpression() -> Node? {
        guard let lhs = parsePrimary() else {
            return nil
        }
        return parseBinaryOperatorRHS(expressionPrecedence: 0, lhs: lhs)
    }

    private func parseReturn() -> Node {
        guard case .returnKeyword = currentToken.tokenKind else {
            fatalError("returnKeyword is expected but received \(currentToken.tokenKind)")
        }
        read() // eat return
        if let expression = parseExpression() {
            return ReturnNode(body: expression)
        } else {
            // return nothing
            return ReturnNode(body: nil)
        }
    }

    private func parseParen() -> Node? {
        read() // eat (
        guard let v = parseExpression() else {
            return nil
        }

        guard case .rightParen = currentToken.tokenKind else {
                fatalError("expected ')'")
        }
        read() // eat )

        return v
    }

    private func parseTopLevelExpression() -> Node? {
        if let expression = parseExpression() {
            // we treat top level expressions as anonymous functions
            let anonymousPrototype = FunctionNode(name: "main", arguments: [], returnType: .int, body: expression)
            return anonymousPrototype
        }
        return nil
    }
}

private extension BinaryExpressionNode.Operator {
    var precedence: Int {
        switch self {
        case .addition, .subtraction: return 20
        case .multication, .division: return 40
        case .lessThan:
            fatalError("Not Implemented")
        }
    }
}
