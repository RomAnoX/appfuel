module Appfuel
  RSpec.describe Errors do
    it 'creates an empty message' do
      expect(create_errors.size).to eq 0
    end

    context '.add' do
      it 'can add a message to a key' do
        error = create_errors
        msg   = 'This is a message'
        key   = :foo
        error.add(key, msg)
        expect(error.messages).to eq({"foo" => [msg]})
      end

      it 'will not add the same message twice' do
        error = create_errors
        msg   = 'This is a message'
        key   = :foo
        error.add(key, msg)
        error.add(key, msg)
        expect(error.messages).to eq({"foo" => [msg]})
      end

      it 'can add more than one message to a key' do
        error = create_errors
        msg1  = 'msg 1'
        msg2  = 'msg 2'
        key   = :foo

        error.add(key, msg1)
        error.add(key, msg2)
        expect(error.messages).to eq({"foo" => [msg1, msg2]})
      end
    end


    context '.each' do
      it 'yields each key and list of messages' do
        errors = create_errors
        errors.add(:foo, 'bar')
        errors.add(:baz, 'boo')
        expect {|b|
          errors.each(&b)
        }.to yield_successive_args(["foo", ['bar']],["baz", ['boo']])
      end
    end

    context 'format' do
      it 'formats a single message' do
        errors = create_errors
        errors.add(:foo, 'this is a message')
        expect(errors.format).to eq "foo: this is a message\n"
      end

      it 'formats for multiple keys with single messages' do
        errors = create_errors
        errors.add(:foo, 'msg 1')
        errors.add(:bar, 'msg 2')
        expect(errors.format).to eq "foo: msg 1\nbar: msg 2\n"
      end

      it 'formats for multiple keys with mulitple messages' do
        errors = create_errors
        errors.add(:foo, 'msg 1')
        errors.add(:foo, 'msg 2')

        errors.add(:bar, 'msg 3')
        errors.add(:bar, 'msg 4')
        expected = "foo: msg 1\nmsg 2\nbar: msg 3\nmsg 4\n"
        expect(errors.format).to eq expected
      end
    end

    context '.delete' do
      it 'deletes a list of messages' do
        errors = create_errors
        errors.add(:foo, 'msg 1')
        errors.add(:foo, 'msg 2')
        errors.delete(:foo)
        expect(errors.empty?).to be true
      end

      it 'does nothing where there are no errors to delete' do
        errors = create_errors
        errors.add(:bar, 'msg')
        errors.delete(:foo)
        expect(errors.messages).to eq({"bar" => ['msg']})
      end
    end

    context '[]' do
      it 'can access a list of messages by key' do
        errors = create_errors
        errors.add(:bar, 'msg')
        expect(errors[:bar]).to eq(['msg'])
      end
    end

    context '.size' do
      it 'knows the size of an empty error is 0' do
        errors = create_errors
        expect(errors.size).to eq 0
      end

      it 'knows the size of one key with one message is 1' do
        errors = create_errors
        errors.add(:bar, 'msg')
        expect(errors.size).to eq 1
      end

      it 'knows the size of one key with one message is 2' do
        errors = create_errors
        errors.add(:bar, 'msg')
        errors.add(:bar, 'msg 2')
        expect(errors.size).to eq 1
      end

      it 'knows the size of 2 key with one message is 2' do
        errors = create_errors
        errors.add(:bar, 'msg')
        errors.add(:bar, 'msg 2')
        errors.add(:foo, 'msg 1')
        errors.add(:foo, 'msg 2')

        expect(errors.size).to eq 2
      end
    end

    context 'values' do
      it 'returns a list of all the messages for all keys' do
        errors = create_errors
        errors.add(:bar, 'msg')
        errors.add(:bar, 'msg 2')
        errors.add(:foo, 'msg 1')
        errors.add(:foo, 'msg 2')


        expected = [
          ['msg', 'msg 2'],
          ['msg 1', 'msg 2']
        ]
        expect(errors.values).to eq expected
      end
    end

    context 'keys' do
      it 'returns a list of all the keys' do
        errors = create_errors
        errors.add(:bar, 'msg')
        errors.add(:bar, 'msg 2')
        errors.add(:foo, 'msg 1')
        errors.add(:foo, 'msg 2')


        expected = ["bar", "foo"]
        expect(errors.keys).to eq expected
      end
    end

    context 'clear' do
      it 'empties out the error messages' do
        errors = create_errors
        errors.add(:bar, 'msg')
        errors.add(:bar, 'msg 2')
        errors.add(:foo, 'msg 1')
        errors.add(:foo, 'msg 2')

        errors.clear
        expect(errors.size).to eq 0
      end
    end

    context 'clear' do
      it 'knows the errors are empty' do
        errors = create_errors
        expect(errors.empty?).to eq true
      end

      it 'knows the errors are not empty' do
        errors = create_errors
        errors.add(:foo, 'msg 1')

        expect(errors.empty?).to eq false
      end
    end



    def create_errors
      Errors.new
    end
  end
end
