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
