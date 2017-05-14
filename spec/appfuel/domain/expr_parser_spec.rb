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

    context '#number' do
      describe 'parsing any digit' do
        10.times do |nbr|
          it "parses the digit '#{nbr}'" do
            result = parser.number.parse(nbr.to_s)
            expect(result).to be_a(Hash)
            expect(result[:number]).to be_a_slice
          end
        end
      end

      describe 'parsing any negitive digit' do
        10.times do |nbr|
          it "parses the digit '-#{nbr}'" do
            result = parser.number.parse("-#{nbr}")
            expect(result).to be_a(Hash)
            expect(result[:number]).to be_a_slice
          end
        end
      end

      it 'parses a flotaing point number' do
        result = parser.number.parse('1.2345')
        expect(result).to be_a(Hash)
        expect(result[:number]).to be_a_slice
      end

      it 'parses a negitive floating point number' do
        result = parser.number.parse('-1.2345')
        expect(result).to be_a(Hash)
        expect(result[:number]).to be_a_slice
      end

      it 'parses a float as 0.1234' do
        result = parser.number.parse('0.2345')
        expect(result).to be_a(Hash)
        expect(result[:number]).to be_a_slice
      end

      it 'parses a float as -0.1234' do
        result = parser.number.parse('-0.2345')
        expect(result).to be_a(Hash)
        expect(result[:number]).to be_a_slice
      end

      it 'fails to parse a float in the form of .123' do
        msg = "Failed to match sequence " +
              "('-'? ('0' / [1-9] DIGIT{0, }) " +
              "('.' DIGIT{1, })?) at line 1 char 1."
        expect {
          parser.number.parse('.2345')
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

    context '#value' do
      {
        "1234"  => :number,
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
        expect(result).to be_a(Hash)

        feature = result[:domain_attr][:feature]
        expect(feature).to be_a(Hash)
        expect(feature[:attr_label]).to be_a_slice
        expect(feature[:attr_label].to_s).to eq('foo')

        domain = result[:domain_attr][:domain]
        expect(domain).to be_a(Hash)
        expect(domain[:attr_label]).to be_a_slice
        expect(domain[:attr_label].to_s).to eq('bar')
      end

      it 'parses a snake case domain attr like foo_bar.baz_boo' do
        result = parser.domain_attr.parse('foo_bar.baz_boo')
        expect(result).to be_a(Hash)

        feature = result[:domain_attr][:feature]
        expect(feature).to be_a(Hash)
        expect(feature[:attr_label]).to be_a_slice
        expect(feature[:attr_label].to_s).to eq('foo_bar')

        domain = result[:domain_attr][:domain]
        expect(domain).to be_a(Hash)
        expect(domain[:attr_label]).to be_a_slice
        expect(domain[:attr_label].to_s).to eq('baz_boo')
      end
    end

    context '#domain_object_attr' do
      it 'parses a basic domain attr object like user.role.id' do
        result = parser.domain_object_attr.parse('user.role.id')
        expect(result).to be_a(Hash)
        list = result[:domain_object]

        expect(list).to be_a(Array)
        expect(list[0][:attr_label]).to be_a_slice
        expect(list[0][:attr_label].to_s).to eq('user')

        expect(list[1][:attr_label]).to be_a_slice
        expect(list[1][:attr_label].to_s).to eq('role')

        expect(list[2][:attr_label]).to be_a_slice
        expect(list[2][:attr_label].to_s).to eq('id')
      end
    end

    context '#expr_attr' do
      it 'parses an attr_label' do
        result = parser.expr_attr.parse('user')
        slice = result[:expr_attr][:domain_object][:attr_label]
        expect(slice).to be_a_slice
      end

      it 'parses an attr_label with a space' do
        result = parser.expr_attr.parse('user  ')
        slice = result[:expr_attr][:domain_object][:attr_label]
        expect(slice).to be_a_slice
        expect(slice.to_s).to eq('user')
      end

      it 'parses a domain_object_attr' do
        result = parser.expr_attr.parse('user.role.id')
        list = result[:expr_attr][:domain_object]
        expect(list[0][:attr_label]).to be_a_slice
        expect(list[0][:attr_label].to_s).to eq('user')

        expect(list[1][:attr_label]).to be_a_slice
        expect(list[1][:attr_label].to_s).to eq('role')
        expect(list[2][:attr_label]).to be_a_slice
        expect(list[2][:attr_label].to_s).to eq('id')
      end

      it 'parses a domain_object_attr with a space' do
        result = parser.expr_attr.parse('user.role.id ')
        list = result[:expr_attr][:domain_object]
        expect(list[0][:attr_label]).to be_a_slice
        expect(list[1][:attr_label]).to be_a_slice
        expect(list[2][:attr_label]).to be_a_slice
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
