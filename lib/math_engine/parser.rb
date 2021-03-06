module MathEngine
  require File.expand_path(File.join(File.dirname(__FILE__), 'nodes'))

  class MathEngine
    class Parser
      def initialize(lexer)
        @lexer = lexer
      end

      def parse
        #statement = { <identifier> <assignment> } expression <end>
        #expression = term { ( <addition> | <subtraction> ) term }
        #term = exp { ( <multiplication> | <division> ) exp }
        #exp = factor { ( <exponent> | <modulus> ) factor }
        #factor = <call> | <identifier> | <number> | ( <open_parenthesis> expression <close_parenthesis> )
        #call = <identifier> <open_parenthesis> { call_parameter } <close_parenthesis>
        #call_parameter = <expression> { <comma> call_parameter }
        statement
      end

      private

      def statement
        next!
        if current.type == :identifier && peek.type == :assignment
          variable_name = current.value
          next!
          expect_current :assignment
          next!
          result = AssignmentNode.new(IdentifierNode.new(variable_name), expression)
        else
          result = expression
        end
        next!
        expect_current :end
        result
      end

      def expression
        left = term
        result = nil
        while [:addition, :subtraction].include? current.type
          node_type = current.type == :addition ? AdditionNode : MathEngine::SubtractionNode
          next!
          left = node_type.new(left, term)
        end
        result = ExpressionNode.new(result || left)
        result
      end

      def term
        left = exp
        result = nil
        while [:multiplication, :division].include? current.type
          node_type = current.type == :multiplication ? MultiplicationNode : MathEngine::DivisionNode
          next!
          left = node_type.new(left, exp)
        end
        result || left
      end

      def exp
        left = factor
          result = nil
        while [:exponent, :modulus].include? current.type
          node_type = current.type == :exponent ? ExponentNode : MathEngine::ModulusNode
          next!
          left = node_type.new(left, factor)
        end
        result || left
      end

      def factor
        if current.type == :number
          result = LiteralNumberNode.new(current.value)
          next!
          return result
        elsif current.type == :identifier
          result = peek.type == :open_parenthesis ? call : IdentifierNode.new(current.value)
          next!
          return result
        end

      expect_current :open_parenthesis, "number, variable or open_parenthesis"
      next!
      result = expression
      expect_current :close_parenthesis
      result.parenthesis # for to_tex show the parenthesis
      next!
      result
      end

      def call
        expect_current :identifier
        function_name = current.value
        next!
        expect_current :open_parenthesis
        next!
        result = FunctionCallNode.new(function_name, current.type == :close_parenthesis ? nil : call_parameter)
        expect_current :close_parenthesis
        result
      end

      def call_parameter
        left = expression
        right = nil
        if current.type == :comma
          next!
          right = call_parameter
        end
        ParametersNode.new(left, right)
      end

      def current
        @lexer.current
      end

      def peek
        @lexer.peek
      end

      def next!
        @lexer.next
      end

      def expect_current(type, friendly = nil)
        raise MathEngine::ParseError.new("Unexpected #{current}, expected: #{friendly ? friendly : type}") unless current.type == type
      end
    end
  end
end
