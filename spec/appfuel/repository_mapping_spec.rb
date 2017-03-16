module Appfuel
  RSpec.describe RepositoryMapping do

    context 'getting & setting mapper' do
      it 'return nil when no mapper has been assigned' do
        repo_class = setup
        expect(repo_class.mapper).to be nil
      end

      it 'returns the mapper that has been assigned' do
        repo_class = setup
        mapper     = instance_double(DbEntityMapper)
        repo_class.mapper = mapper
        expect(repo_class.mapper).to eq mapper
      end
    end

    context '.mapper?' do
      it 'returns false when there is no mapper' do
        repo_class = setup
        expect(repo_class.mapper?).to be false
      end

      it 'returns true when a mapper is set' do
        repo_class = setup
        mapper     = instance_double(DbEntityMapper)
        repo_class.mapper = mapper
        expect(repo_class.mapper?).to be true
      end
    end

    context '.map_dsl_class' do
      it 'defaults to DbEntityMapDsl' do
        expect(setup.map_dsl_class).to eq DbEntityMapDsl
      end

      it 'can assign a custom map dsl' do
        repo_class = setup
        map_dsl    = double('SomeMapDsl')
        repo_class.map_dsl_class = map_dsl
        expect(repo_class.map_dsl_class).to eq map_dsl
      end
    end

    context '.mapper_class' do
      it 'defaults to DbEntityMapper' do
        expect(setup.mapper_class).to eq DbEntityMapper
      end

      it 'can assign a custom mapper' do
        repo_class   = setup
        mapper_class = double('SomeMapper')
        repo_class.mapper_class = mapper_class
        expect(repo_class.mapper_class).to eq mapper_class
      end
    end

    context '.map_class' do
      it 'defaults to DbEntityMap' do
        expect(setup.map_class).to eq DbEntityMap
      end

      it 'can assign a custom map class' do
        repo_class = setup
        map_class  = double('SomeMapClass')
        repo_class.map_class = map_class
        expect(repo_class.map_class).to eq map_class
      end
    end

    xcontext '.mapping' do
      it 'adds a mapper with no mappings' do
        repo_class = setup
        domain     = entity_instance_double
        db_model   = db_model_instance_double

        allow(domain).to receive(:basename).with(no_args) { 'bar' }

        allow_type('foo.bar', domain)
        allow_db_type('foo_bar', db_model)

        repo_class.mapping 'foo.bar', db: 'foo_bar' do
        end

        mapper = repo_class.mapper
        expect(repo_class.mapper?).to be true
        expect(mapper).to be_an_instance_of(repo_class.mapper_class)
        expect(mapper.entity_class('bar')).to eq domain
        expect(mapper.db_class('bar')).to eq db_model
      end

      it 'adds new maps to the existing mapper' do
        repo_class = setup
        domain     = entity_instance_double
        db_model   = db_model_instance_double

        domain2    = entity_instance_double
        db_model2  = db_model_instance_double

        allow(domain).to receive(:basename).with(no_args) { 'bar' }
        allow(domain2).to receive(:basename).with(no_args) { 'fiz' }

        allow_type('foo.bar', domain)
        allow_db_type('foo_bar', db_model)

        allow_type('biz.fiz', domain2)
        allow_db_type('biz_fiz', db_model2)

        repo_class.mapping 'foo.bar', db: 'foo_bar' do
        end


        repo_class.mapping 'biz.fiz', db: 'biz_fiz' do
        end

        mapper = repo_class.mapper
        expect(mapper).to be_an_instance_of(repo_class.mapper_class)
        expect(mapper.entity_class('bar')).to eq domain
        expect(mapper.db_class('bar')).to eq db_model
        expect(mapper.entity_class('fiz')).to eq domain2
        expect(mapper.db_class('fiz')).to eq db_model2
      end

      it 'holds a map with a key that is different to entity basename' do
        repo_class = setup
        domain     = entity_instance_double
        db_model   = db_model_instance_double

        allow(domain).to receive(:basename).with(no_args) { 'bar' }

        allow_type('foo.bar', domain)
        allow_db_type('foo_bar', db_model)

        repo_class.mapping 'foo.bar', key: :custom_name, db: 'foo_bar' do
        end

        mapper = repo_class.mapper
        expect(mapper.entity_class('bar')).to eq domain
        expect(mapper.db_class("bar.custom_name")).to eq db_model
      end
    end

    def setup
      repo_class = Class.new
      repo_class.include RepositoryMapping
      repo_class
    end
  end
end
