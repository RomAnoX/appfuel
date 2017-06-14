module Appfuel::Configuration
  RSpec.describe FileLoader do
    context '#load_file' do
      it 'fails when file does not exist' do
        definition = double(DefinitionDsl)

        paths = ['/some-file.yaml']
        key   = 'foo'
        allow(definition).to receive(:file).with(no_args) { paths }
        allow(definition).to receive(:key).with(no_args) { key }
        allow(File).to receive(:exists?).with('/some-file.yaml') { false }
        loader = setup
        msg = "none of :foo config files exist at (/some-file.yaml)"
        expect {
          loader.load_file(definition)
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when the extension is not json or yaml' do
        definition = double(DefinitionDsl)
        paths = ['/some-file.blah']
        key   = 'foo'

        allow(definition).to receive(:file).with(no_args) { paths }
        allow(definition).to receive(:key).with(no_args) { key }
        allow(File).to receive(:exists?).with('/some-file.blah') { false }

        loader = setup
        msg = "extension (blah), for (foo: /some-file.blah) is not valid, " +
          "only yaml and json are supported"

        expect {
          loader.load_file(definition)
        }.to raise_error(RuntimeError, msg)
      end

      it 'delegates to :parse_yaml when file is a yaml file' do
        definition = double(DefinitionDsl)
        paths = ['/some-file.yaml']
        key   = 'foo'
        allow(definition).to receive(:file).with(no_args) { paths }
        allow(definition).to receive(:key).with(no_args) { key }
        allow(File).to receive(:exists?).with('/some-file.yaml') { true }

        loader = setup
        expect(loader).to receive(:parse_yaml).with('/some-file.yaml').once { {} }

        loader.load_file(definition)
      end

      it 'returns :parse_yaml delegated results' do
        definition = double(DefinitionDsl)
        paths  = ['/some-file.yaml']
        key    = :foo
        result = {some: 'result'}
        allow(definition).to receive(:file).with(no_args) { paths }
        allow(definition).to receive(:key).with(no_args) { key }
        allow(File).to receive(:exists?).with('/some-file.yaml') { true }

        loader = setup
        allow(loader).to receive(:parse_yaml).with('/some-file.yaml').once {
          {"foo" => result}
        }

        expect(loader.load_file(definition)).to eq result
      end

      it 'delegates to :parse_json when file is a json file' do
        definition = double(DefinitionDsl)
        paths = ['/some-file.json']
        key   = :foo
        allow(definition).to receive(:file).with(no_args) { paths }
        allow(definition).to receive(:key).with(no_args) { key }
        allow(File).to receive(:exists?).with('/some-file.json') { true }

        loader = setup
        expect(loader).to receive(:parse_json).with('/some-file.json').once { {} }

        loader.load_file(definition)
      end

      it 'returns :parse_json delegated results' do
        definition = double(DefinitionDsl)
        paths  = ['/some-file.json']
        key    = :foo
        result = {some: 'result'}
        allow(definition).to receive(:file).with(no_args) { paths }
        allow(definition).to receive(:key).with(no_args) { key }
        allow(File).to receive(:exists?).with('/some-file.json') { true }

        loader = setup
        allow(loader).to receive(:parse_json).with('/some-file.json').once {
          {"foo" => result}
        }

        expect(loader.load_file(definition)).to eq result
      end
    end

    context 'parse_yaml' do
      it 'parses yaml with YAML.load_file' do
        path = '/foo.yaml'
        expect(YAML).to receive(:load_file).with(path)

        loader = setup
        loader.parse_yaml(path)
      end
    end

    context 'parse_json' do
      it 'reads the file parses it with JSON.parse' do
        path = '/foo.json'
        json = 'some json string'
        allow(File).to receive(:read).with(path) { json }
        expect(JSON).to receive(:parse).with(json)

        loader = setup
        loader.parse_json(path)
      end
    end

    def setup
      loader = Object.new
      loader.extend(FileLoader)
      loader
    end
  end
end
