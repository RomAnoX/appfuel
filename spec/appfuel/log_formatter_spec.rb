module Appfuel
  RSpec.describe LogFormatter do
    it 'is a Log::Formatter' do
      expect(LogFormatter).to be < Logger::Formatter
    end

    context '#call' do
      it 'formats the log correctly' do
        time      = Time.now
        severity  = Logger::ERROR
        prg_name  = 'my-program'
        msg       = 'my-message'
        formatter = LogFormatter

        process_id = Process.pid
        expected   = "#{prg_name} " +
                     "#{time.utc.iso8601} p-#{process_id} #{severity}: #{msg}\n"

        expect(formatter.call(severity, time, prg_name, msg)).to eq(expected)
      end
    end
  end
end
