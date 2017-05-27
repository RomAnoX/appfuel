module Appfuel::Domain
  RSpec.describe ExprParser do
    context '#space' do
      it 'parses a single space' do
        expect(parser.space.parse(' ')).to be_a_slice
      end

      it 'parses multiple spaces' do
        expect(parser.space.parse('     ')).to be_a_slice
      end

      it 'fails to parse an empty string' do
        expect {
          parser.space.parse('')
        }.to raise_error(parse_failed_error, space_error_msg)
      end

      it 'fails when string is not a space' do
        expect {
          parser.space.parse('abc')
        }.to raise_error(parse_failed_error, space_error_msg)
      end
    end

    context '#space?' do
      it 'parsers a single space' do
        expect(parser.space?.parse(' ')).to be_a_slice
      end

      it 'parses multiple spaces' do
        expect(parser.space?.parse('     ')).to be_a_slice
      end

      it 'parses no spaces' do
        expect(parser.space?.parse('')).to eq('')
      end

      it 'fails when not an empty string or a space' do
        expect {
          parser.space.parse('abc')
        }.to raise_error(parse_failed_error, space_error_msg)
      end
    end

    context '#comma' do
      it 'parses a single comma' do
        expect(parser.comma.parse(',')).to be_a_slice
      end

      it 'parses a comma followed by a space' do
        expect(parser.comma.parse(', ')).to be_a_slice
      end

      it 'parses a comma followed my multiple spaces' do
        expect(parser.comma.parse(',       ')).to be_a_slice
      end

      it 'fails when no comma with or without spaces is given' do
        msg = "Failed to match sequence (SPACE? ',' SPACE?) at line 1 char 1."
        expect {
          parser.comma.parse('abc')
        }.to raise_error(parse_failed_error, msg)
      end
    end

    context '#digit' do
      10.times do |nbr|
        it "parses the digit '#{nbr}'" do
          expect(parser.digit.parse(nbr.to_s)).to be_a_slice
        end
      end

      it 'fails when the text is not a digit between 0-9' do
        msg = 'Failed to match [0-9] at line 1 char 1.'
        expect {
          parser.digit.parse('abc')
        }.to raise_error(parse_failed_error, msg)
      end
    end

    context '#integer' do
      it 'parses simple digits' do
        expect(parser.integer.parse("55")[:integer]).to be_a_slice
      end

      it 'parsers a negitive integer' do
        expect(parser.integer.parse("-1")[:integer]).to be_a_slice
      end

      it 'parses a large positive integer' do
        expect(parser.integer.parse("1234567897655444")[:integer]).to be_a_slice
      end

      it 'parses an integer with leading 0s' do
        expect(parser.integer.parse("0001")[:integer]).to be_a_slice
      end

      it 'parses a zero' do
        expect(parser.integer.parse("0")[:integer]).to be_a_slice
      end

      it 'fails to parse a float' do
        msg = "Failed to match sequence ('-'? DIGIT DIGIT{0, }) " +
              "at line 1 char 2."

        expect {
          parser.integer.parse('1.3')
        }.to raise_error(parse_failed_error, msg)
      end
    end

    context '#lparen' do
      it 'parses a single left parenthesis (' do
        expect(parser.lparen.parse('(')).to be_a_slice
      end

      it 'parses a single left parenthesis with a space' do
        expect(parser.lparen.parse('( ')).to be_a_slice
      end

      it 'parses a single left parenthesis with multiple spaces' do
        expect(parser.lparen.parse('(          ')).to be_a_slice
      end

      it 'fails when not a left parenthesis with or without spaces' do
        msg = "Failed to match sequence ('(' SPACE?) at line 1 char 1."
        expect {
          parser.lparen.parse('abc')
        }.to raise_error(parse_failed_error, msg)
      end
    end

    context '#rparen' do
      it 'parses a single right parenthesis )' do
        expect(parser.rparen.parse(')')).to be_a_slice
      end

      it 'parses a single right parenthesis with a space' do
        expect(parser.rparen.parse(') ')).to be_a_slice
      end

      it 'parses a single right parenthesis with multiple spaces' do
        expect(parser.rparen.parse(')          ')).to be_a_slice
      end

      it 'fails when not a right parenthesis with or without spaces' do
        msg = "Failed to match sequence (')' SPACE?) at line 1 char 1."
        expect {
          parser.rparen.parse('abc')
        }.to raise_error(parse_failed_error, msg)
      end
    end

    context '#float' do
      it 'parses a flotaing point number' do
        result = parser.float.parse('1.2345')
        expect(result).to be_a(Hash)
        expect(result[:float]).to be_a_slice
      end

      it 'parses a negitive floating point number' do
        result = parser.float.parse('-1.2345')
        expect(result).to be_a(Hash)
        expect(result[:float]).to be_a_slice
      end

      it 'parses a float as 0.1234' do
        result = parser.float.parse('0.2345')
        expect(result).to be_a(Hash)
        expect(result[:float]).to be_a_slice
      end

      it 'parses a float as -0.1234' do
        result = parser.float.parse('-0.2345')
        expect(result).to be_a(Hash)
        expect(result[:float]).to be_a_slice
      end

      it 'fails to parse a float in the form of .123' do
          msg = "Failed to match sequence ('-'? DIGIT{1, } '.' DIGIT{1, }) " +
                "at line 1 char 1."
        expect {
          parser.float.parse('.2345')
        }.to raise_error(parse_failed_error, msg)
      end
    end

    context '#string' do
      it 'parses an empty string' do
        result = parser.string.parse('""')
        expect(result).to be_a(Hash)
        expect(result[:string]).to be_empty
      end

      it 'parses a string value' do
        result = parser.string.parse('"hello world"')
        expect(result).to be_a(Hash)
        expect(result[:string]).to be_a_slice
      end

      it 'parses a string value with escape characters' do
        result = parser.string.parse('"hello\\nworld"')
        expect(result).to be_a(Hash)
        expect(result[:string]).to be_a_slice
      end

      it 'parses a string with many escape characters' do
        result = parser.string.parse('"hello\\t\\n\\\\\\0world\\n"')
        expect(result).to be_a(Hash)
        expect(result[:string]).to be_a_slice
      end

      it 'parses a string with a single quote' do
        result = parser.string.parse("\"foo's\"")
        expect(result).to be_a(Hash)
        expect(result[:string]).to be_a_slice
      end

      it 'parses a string with a escaped single quote ' do
        result = parser.string.parse('"\'"')
        expect(result).to be_a(Hash)
        expect(result[:string]).to be_a_slice
      end

      it 'parses an interpolated string using %Q' do
        string = '"' + %Q[this is Sirfooish's work] + '"'
        result = parser.string.parse(string)
        expect(result).to be_a(Hash)
        expect(result[:string]).to be_a_slice
      end
    end

    context '#boolean' do
      it 'parses the string "true"' do
        result = parser.boolean.parse('true')
        expect(result).to be_a(Hash)
        expect(result[:boolean]).to be_a_slice
      end

      it 'parses the string "false"' do
        result = parser.boolean.parse('false')
        expect(result).to be_a(Hash)
        expect(result[:boolean]).to be_a_slice
      end

      it 'parses the string "TRUE"' do
        result = parser.boolean.parse('TRUE')
        expect(result).to be_a(Hash)
        expect(result[:boolean]).to be_a_slice
      end
    end

    context '#datetime' do
      it 'parses basic older datetime' do
        result = parser.datetime.parse('1979-05-27T07:32:00Z')
        expect(result[:datetime]).to be_a_slice
      end

      it 'parses basic newer datetime' do
        result = parser.datetime.parse('2017-02-24T17:26:21Z')
        expect(result[:datetime]).to be_a_slice
      end

      it 'fails to parse invalid datatime' do
        msg = "Failed to match sequence " +
              "(DIGIT{4, } '-' DIGIT{2, } '-' DIGIT{2, } " +
              "'T' DIGIT{2, } ':' DIGIT{2, } ':' DIGIT{2, } 'Z') " +
              "at line 1 char 5."

        expect {
          parser.datetime.parse('1979l05-27 07:32:00')
        }.to raise_error(parse_failed_error, msg)
      end

    end

    context '#value' do
      {
        "1234"  => :integer,
        "1.23"  => :float,
        '"abc"' => :string,
        'true'  => :boolean,
        'false' => :boolean
      }.each do |value_str, type|
        it "will parse a #{type} as #{value_str}" do
          result = parser.value.parse(value_str)
          expect(result).to be_a(Hash)
          expect(result[type]).to be_a_slice
        end
      end
    end

    context '#attr_label' do
      it 'parses a basic attr label like foo' do
        result = parser.attr_label.parse('foo')
        expect(result).to be_a(Hash)
        expect(result[:attr_label]).to be_a_slice
      end

      it 'parses a snake case label like foo_bar' do
        result = parser.attr_label.parse('foo_bar')
        expect(result).to be_a(Hash)
        expect(result[:attr_label]).to be_a_slice
      end

      it 'parses an attr label with a number like foo4' do
        result = parser.attr_label.parse('foo4')
        expect(result).to be_a(Hash)
        expect(result[:attr_label]).to be_a_slice
      end

      it 'fails when attr label container uppercase char' do
        msg = 'Expected at least 1 of [a-z0-9_] at line 1 char 1.'
        expect {
          parser.attr_label.parse('Foo')
        }.to raise_error(parse_failed_error, msg)
      end

      it 'fails when attr label has a space' do
        msg = 'Extra input after last repetition at line 1 char 4.'
        expect {
          parser.attr_label.parse('foo bar')
        }.to raise_error(parse_failed_error, msg)
      end
    end

    context '#domain_attr' do
      it 'parses a basic domain attr like foo.bar' do
        result = parser.domain_attr.parse('foo.bar')

        list = result[:domain_attr]
        expect(list).to be_a(Array)
        expect(list[0][:attr_label]).to be_a_slice
        expect(list[0][:attr_label].to_s).to eq('foo')

        expect(list[1][:attr_label]).to be_a_slice
        expect(list[1][:attr_label].to_s).to eq('bar')
      end

      it 'parses a snake case domain attr like foo_bar.baz_boo' do
        result = parser.domain_attr.parse('foo_bar.baz_boo')

        list = result[:domain_attr]
        expect(list).to be_a(Array)
        expect(list[0][:attr_label]).to be_a_slice
        expect(list[0][:attr_label].to_s).to eq('foo_bar')

        expect(list[1][:attr_label]).to be_a_slice
        expect(list[1][:attr_label].to_s).to eq('baz_boo')
      end

      it 'parse a single domain attr like foo_id' do
        result = parser.domain_attr.parse('foo_id')

        expect(result[:domain_attr][:attr_label]).to be_a_slice
        expect(result[:domain_attr][:attr_label].to_s).to eq('foo_id')
      end
    end

    ['and', 'or', 'like', 'between', 'in'].each do |op|
      context "##{op}_op" do
        let(:op_parser) { parser.send("#{op}_op") }

        it "parses the #{op} operator, lowercase" do
          result = op_parser.parse(op.downcase)
          expect(result).to be_a_slice
        end

        it "parses the #{op} operator, uppercase" do
          result = op_parser.parse(op.upcase)
          expect(result).to be_a_slice
        end

        it "parses the #{op} operator, mixed case" do
          result = op_parser.parse(op.capitalize)
          expect(result).to be_a_slice
        end
      end
    end

    context 'not in' do
      it 'parses the operator "not in"' do
        result = parser.in_op.parse("not in")
        expect(result).to be_a_slice
        expect(result.to_s).to eq('not in')
      end
    end

    context 'not like' do
      it 'parses the operator "not like"' do
        result = parser.like_op.parse("not like")
        expect(result).to be_a_slice
        expect(result.to_s).to eq('not like')
      end
    end

    context 'not between' do
      it 'parses the operator "not betwwen"' do
        result = parser.between_op.parse("not between")
        expect(result).to be_a_slice
        expect(result.to_s).to eq('not between')
      end
    end


    context '#eq_op' do
      it 'parses the = operator' do
        result = parser.eq_op.parse('=')
        expect(result).to be_a_slice
      end
    end

    context '#gt_op' do
      it 'parses the > operator' do
        result = parser.gt_op.parse('>')
        expect(result).to be_a_slice
      end
    end

    context '#gteq_op' do
      it 'parses the >= operator' do
        result = parser.gteq_op.parse('>=')
        expect(result).to be_a_slice
      end
    end

    context '#lt_op' do
      it 'parses the < operator' do
        result = parser.lt_op.parse('<')
        expect(result).to be_a_slice
      end
    end

    context '#lteq_op' do
      it 'parses the <= operator' do
        result = parser.lteq_op.parse('<=')
        expect(result).to be_a_slice
      end
    end

    context 'expression' do
      context 'eq_expr' do
        it 'parses id = 6' do
          result = parser.eq_expr.parse('id = 6')
          id     = result[:domain_attr][:attr_label]
          op     = result[:op]
          value  = result[:value][:integer]

          expect(id).to be_a_slice
          expect(op).to be_a_slice
          expect(value).to be_a_slice
        end

        it 'parses a domain_object eq expr like user.role.id = 9' do
          result = parser.eq_expr.parse('user.role.id = 6')
          attrs  = result[:domain_attr]
          op     = result[:op]
          value  = result[:value][:integer]

          expect(attrs).to be_an(Array)
          expect(attrs[0][:attr_label]).to be_a_slice
          expect(attrs[1][:attr_label]).to be_a_slice
          expect(attrs[2][:attr_label]).to be_a_slice
          expect(op).to be_a_slice
          expect(value).to be_a_slice
        end
      end

      context 'gt_expr' do
        it 'parses a domain_attr eq expr like user.role.id > 9' do
          result = parser.gt_expr.parse('user.role.id > 9')

          attrs  = result[:domain_attr]
          op     = result[:op]
          value  = result[:value][:integer]

          expect(attrs).to be_an(Array)
          expect(attrs[0][:attr_label]).to be_a_slice
          expect(attrs[1][:attr_label]).to be_a_slice
          expect(attrs[2][:attr_label]).to be_a_slice
          expect(op).to be_a_slice
          expect(value).to be_a_slice
        end
      end

      context 'gteq_expr' do
        it 'parses a domain_object eq expr like user.role.id >= 9' do
          result = parser.gteq_expr.parse('user.role.id >= 9')
          attrs  = result[:domain_attr]
          op     = result[:op]
          value  = result[:value][:integer]

          expect(attrs).to be_an(Array)
          expect(attrs[0][:attr_label]).to be_a_slice
          expect(attrs[1][:attr_label]).to be_a_slice
          expect(attrs[2][:attr_label]).to be_a_slice
          expect(op).to be_a_slice
          expect(value).to be_a_slice
        end
      end


      context 'lteq_expr' do
        it 'parses a domain_object eq expr like user.role.id <= 9' do
          result = parser.lteq_expr.parse('user.role.id <= 9')
          attrs  = result[:domain_attr]
          op     = result[:op]
          value  = result[:value][:integer]

          expect(attrs).to be_an(Array)
          expect(attrs[0][:attr_label]).to be_a_slice
          expect(attrs[1][:attr_label]).to be_a_slice
          expect(attrs[2][:attr_label]).to be_a_slice
          expect(op).to be_a_slice
          expect(value).to be_a_slice
        end
      end

      context 'lt_expr' do
        it 'parses a domain_object eq expr like user.role.id < 9' do
          result = parser.lt_expr.parse('user.role.id < 9')
          attrs  = result[:domain_attr]
          op     = result[:op]
          value  = result[:value][:integer]

          expect(attrs).to be_an(Array)
          expect(attrs[0][:attr_label]).to be_a_slice
          expect(attrs[1][:attr_label]).to be_a_slice
          expect(attrs[2][:attr_label]).to be_a_slice
          expect(op).to be_a_slice
          expect(value).to be_a_slice
        end
      end

      context 'relational_expr' do
        it "parses the relational expr 'user.role.specific_rile.id = 9'" do
          expr = "user.role.specific_role.id = 9"
          result = parser.relational_expr.parse(expr)
          expect(result[:domain_attr]).to be_a(Array)
          expect(result[:op]).to be_a_slice
          expect(result[:value]).to be_a(Hash)
        end

        it "parses the relational expr 'user_id > 9'" do
          expr = "user_id > 9"
          result = parser.relational_expr.parse(expr)
          expect(result[:domain_attr][:attr_label]).to be_a_slice
          expect(result[:op]).to be_a_slice
          expect(result[:value]).to be_a(Hash)
        end

        it "parses the relational expr 'user.role.id >= 9'" do
          expr = "user.role.id >= 9"
          result = parser.relational_expr.parse(expr)
          expect(result[:domain_attr]).to be_a(Array)
          expect(result[:op]).to be_a_slice
          expect(result[:value]).to be_a(Hash)
        end

        it "parses the relational expr 'user.id < 9'" do
          expr = "user.id < 9"
          result = parser.relational_expr.parse(expr)
          expect(result[:domain_attr]).to be_a(Array)
          expect(result[:op]).to be_a_slice
          expect(result[:value]).to be_a(Hash)
        end

        it "parses the relational expr 'id <= 9'" do
          expr = "id <= 9"
          result = parser.relational_expr.parse(expr)
          expect(result[:domain_attr][:attr_label]).to be_a_slice
          expect(result[:op]).to be_a_slice
          expect(result[:value]).to be_a(Hash)
        end
      end

      context 'in_expr' do
        it 'parses an expression like id IN ("foo", "bar")' do
          result = parser.in_expr.parse('id IN ("foo", "bar")')
          attr_label = result[:domain_attr][:attr_label]
          op    = result[:op]
          value = result[:value]

          expect(attr_label).to be_a_slice
          expect(op).to be_a_slice
          expect(value).to be_an(Array)

          expect(value[0][:string]).to be_a_slice
          expect(value[0][:string].to_s).to eq('foo')

          expect(value[1][:string]).to be_a_slice
          expect(value[1][:string].to_s).to eq('bar')
        end
      end

      context 'between_expr' do
        it 'parses an expression like "id between 3 and 9"' do
          result = parser.between_expr.parse("id between 3 and 9")
          attr_label = result[:domain_attr][:attr_label]

          expect(attr_label).to be_a_slice
          expect(result[:op]).to be_a_slice

          value = result[:value]
          expect(value[:lvalue][:integer]).to be_a_slice
          expect(value[:lvalue][:integer].to_s).to eq("3")
          expect(value[:rvalue][:integer]).to be_a_slice
          expect(value[:rvalue][:integer].to_s).to eq("9")
        end
      end

      context 'like_expr' do
        it 'parses an expression like first_name like "%foo%"' do
          result = parser.like_expr.parse('first_name like "%foo%"')

          attr_label = result[:domain_attr][:attr_label]
          value      = result[:value][:string]

          expect(attr_label).to be_a_slice
          expect(result[:op]).to be_a_slice
          expect(value).to be_a_slice
        end

      end

      context 'domain_expr' do
        it 'parses an eq_expr' do
          result = parser.domain_expr.parse('first_name = "Fooish"')
          attr_label = result[:domain_expr][:domain_attr][:attr_label]
          op         = result[:domain_expr][:op]
          value      = result[:domain_expr][:value][:string]

          expect(attr_label).to be_a_slice
          expect(op).to be_a_slice
          expect(value).to be_a_slice
        end

        it 'parses a gt_expr' do
          result = parser.domain_expr.parse('foo.id > 9')

          foo = result[:domain_expr][:domain_attr][0][:attr_label]
          id = result[:domain_expr][:domain_attr][1][:attr_label]

          op    = result[:domain_expr][:op]
          value = result[:domain_expr][:value][:integer]

          expect(foo).to be_a_slice
          expect(id).to be_a_slice
          expect(op).to be_a_slice
          expect(value).to be_a_slice
        end

        it 'parses a gteq_expr' do
          result = parser.domain_expr.parse('id >= 9')
          expect(result[:domain_expr][:domain_attr][:attr_label]).to be_a_slice
          expect(result[:domain_expr][:op]).to be_a_slice
          expect(result[:domain_expr][:value][:integer]).to be_a_slice
        end

        it 'parses a lt_expr' do
          result = parser.domain_expr.parse('id < 9')
          expect(result[:domain_expr][:domain_attr][:attr_label]).to be_a_slice
          expect(result[:domain_expr][:op]).to be_a_slice
          expect(result[:domain_expr][:value][:integer]).to be_a_slice
        end

        it 'parses a lteq_expr' do
          result = parser.domain_expr.parse('date <= 2017-01-01')
          expect(result[:domain_expr][:domain_attr][:attr_label]).to be_a_slice
          expect(result[:domain_expr][:op]).to be_a_slice
          expect(result[:domain_expr][:value][:date]).to be_a_slice
        end

        it 'parses an in_expr' do
          result = parser.domain_expr.parse('status IN ("a", "b", "c")')
          expect(result[:domain_expr][:domain_attr][:attr_label]).to be_a_slice
          expect(result[:domain_expr][:op]).to be_a_slice
          expect(result[:domain_expr][:value][0][:string]).to be_a_slice
          expect(result[:domain_expr][:value][1][:string]).to be_a_slice
          expect(result[:domain_expr][:value][2][:string]).to be_a_slice
        end

        it 'parses a like_expr' do
          result = parser.domain_expr.parse('name like "foo"')
          expect(result[:domain_expr][:domain_attr][:attr_label]).to be_a_slice
          expect(result[:domain_expr][:op]).to be_a_slice
          expect(result[:domain_expr][:value][:string]).to be_a_slice
        end

        it 'parses a between_expr' do
          result = parser.domain_expr.parse('id between 1 and 6')
          expect(result[:domain_expr][:domain_attr][:attr_label]).to be_a_slice
          expect(result[:domain_expr][:op]).to be_a_slice
          expect(result[:domain_expr][:value][:lvalue][:integer]).to be_a_slice
          expect(result[:domain_expr][:value][:rvalue][:integer]).to be_a_slice
        end
      end

      context '#primary' do
        it 'parses a normal domain_expr' do
          result = parser.primary.parse('id = 6')
          expect(result[:domain_expr][:domain_attr][:attr_label]).to be_a_slice
          expect(result[:domain_expr][:op]).to be_a_slice
          expect(result[:domain_expr][:value][:integer]).to be_a_slice
        end

        it 'parses parens with one expr' do
          result = parser.primary.parse('(id = 6)')
          expect(result[:domain_expr][:domain_attr][:attr_label]).to be_a_slice
          expect(result[:domain_expr][:op]).to be_a_slice
          expect(result[:domain_expr][:value][:integer]).to be_a_slice
        end

        it 'parses a simple and conjunction in parens' do
          result = parser.primary.parse('(id = 6 and id = 3)')
          expect(result[:and]).to be_a(Hash)
          expect(result[:and][:left][:domain_expr]).to be_a(Hash)
          expect(result[:and][:right][:domain_expr]).to be_a(Hash)
        end

        it 'parses a simple or conjunction in parens' do
          result = parser.primary.parse('(id = 6 or id = 3)')
          expect(result[:or]).to be_a(Hash)
          expect(result[:or][:left][:domain_expr]).to be_a(Hash)
          expect(result[:or][:right][:domain_expr]).to be_a(Hash)
        end

        it 'parses a domain expr with a conjunction in parens' do
          result = parser.primary.parse('(id = 8 and (id = 6 or id = 3))')
          expect(result[:and]).to be_a(Hash)
          expect(result[:and][:left][:domain_expr]).to be_a(Hash)
          expect(result[:and][:right][:or]).to be_a(Hash)
          expect(result[:and][:right][:or][:left][:domain_expr]).to be_a(Hash)
          expect(result[:and][:right][:or][:right][:domain_expr]).to be_a(Hash)
        end
      end

      context '#and_operation' do
        it 'parses a normal primary' do
          result = parser.and_operation.parse('id = 6')
          expect(result[:domain_expr][:domain_attr][:attr_label]).to be_a_slice
          expect(result[:domain_expr][:op]).to be_a_slice
          expect(result[:domain_expr][:value][:integer]).to be_a_slice
        end

        it 'parses two simple expression joined with an and' do
          result = parser.parse('id = 6 and first_name = "bar"')
          expect(result[:and]).to be_a(Hash)
          expect(result[:and][:left][:domain_expr]).to be_a(Hash)
          expect(result[:and][:right][:domain_expr]).to be_a(Hash)
        end
      end

      context '#or_operation' do
        it 'parses a normal primary' do
          result = parser.or_operation.parse('id = 6')
          expect(result[:domain_expr][:domain_attr][:attr_label]).to be_a_slice
          expect(result[:domain_expr][:op]).to be_a_slice
          expect(result[:domain_expr][:value][:integer]).to be_a_slice
        end

        it 'parses an or conjunction' do
          result = parser.or_operation.parse('id = 6 or status = "foo"')
          expect(result[:or]).to be_a(Hash)
          expect(result[:or][:left][:domain_expr]).to be_a(Hash)
          expect(result[:or][:right][:domain_expr]).to be_a(Hash)
        end

      end

      context '#parse' do
        it 'parses a simple expr' do
          result = parser.parse('id = 6')
          expect(result[:domain_expr][:domain_attr][:attr_label]).to be_a_slice
          expect(result[:domain_expr][:op]).to be_a_slice
          expect(result[:domain_expr][:value][:integer]).to be_a_slice
        end

        it 'parses "code != "foo"' do
          result = parser.parse('code != "foo"')
          expect(result[:domain_expr][:domain_attr][:attr_label]).to be_a_slice
          expect(result[:domain_expr][:op]).to be_a_slice
          expect(result[:domain_expr][:value][:string]).to be_a_slice
        end

        it 'parses expr1 and expr2 and expr3' do
          result = parser.parse('id = 6 and id = 5 and id = 4')

          id_6 = result[:and][:left][:domain_expr][:value][:integer]
          expect(id_6).to be_a_slice
          expect(id_6.to_s).to eq('6')

          id_5 = result[:and][:right][:and][:left][:domain_expr][:value][:integer]
          expect(id_5).to be_a_slice
          expect(id_5.to_s).to eq('5')

          id_4 = result[:and][:right][:and][:right][:domain_expr][:value][:integer]
          expect(id_4).to be_a_slice
          expect(id_4.to_s).to eq('4')
        end

        it 'parses (expr1 and expr2) or expr3' do
          result = parser.parse('(a = 6 and b = 5) or c = 4')

          a = result[:or][:left][:and][:left][:domain_expr][:value][:integer]
          b = result[:or][:left][:and][:right][:domain_expr][:value][:integer]
          c = result[:or][:right][:domain_expr][:value][:integer]

          expect(a).to be_a_slice
          expect(b).to be_a_slice
          expect(c).to be_a_slice

          expect(a.to_s).to eq('6')
          expect(b.to_s).to eq('5')
          expect(c.to_s).to eq('4')
        end

        it 'parses expr1 and (expr2 or expr3)' do
          result = parser.parse('id = 6 and (id = 5 and id = 4)')

          a = result[:and][:left][:domain_expr][:value][:integer]
          b = result[:and][:right][:and][:left][:domain_expr][:value][:integer]
          c = result[:and][:right][:and][:right][:domain_expr][:value][:integer]

          expect(a.to_s).to eq('6')
          expect(b.to_s).to eq('5')
          expect(c.to_s).to eq('4')
        end
      end
    end

    def space_error_msg
      'Expected at least 1 of \\\\s at line 1 char 1.'
    end

    def parse_failed_error
      Parslet::ParseFailed
    end

    def be_a_slice
      be_an_instance_of(slice)
    end

    def slice
      Parslet::Slice
    end

    def parser
      ExprParser.new
    end
  end
end
