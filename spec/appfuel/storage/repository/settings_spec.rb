module Appfuel::Repository
  RSpec.describe Settings do
    context 'constants' do
      it 'derives its default page number from DEFAULT_PAGE' do
        expect(Settings::DEFAULT_PAGE).to eq(1)
      end

      it 'derives its default per page number from DEFAULT_PER_PAGE' do
        expect(Settings::DEFAULT_PER_PAGE).to eq(20)
      end
    end

    context '#initialize' do
      it 'does not require any inputs' do
        expect {
          Settings.new
        }.not_to raise_error
      end

      context 'defaults' do
        it 'assigns a default parser of ExprParser' do
          expect(create_settings.parser).to be_an_instance_of(ExprParser)
        end

        it 'assigns a default transform of ExprTransform' do
          transform = ExprTransform
          expect(create_settings.transform).to be_an_instance_of(transform)
        end

        it 'defaults error_on_empty_dataset? to false' do
          expect(create_settings.error_on_empty_dataset?).to be false
        end

        it 'defaults disable_pagination? to be false' do
          expect(create_settings.disable_pagination?).to be false
        end

        it 'defaults all? to be false' do
          expect(create_settings.all?).to be false
        end

        it 'defaults first? to be false' do
          expect(create_settings.first?).to be false
        end

        it 'defaults last? to be false' do
          expect(create_settings.last?).to be false
        end

        it 'defaults page to be DEFAULT_PAGE' do
          page = Settings::DEFAULT_PAGE
          expect(create_settings.page).to eq(page)
        end

        it 'defaults page to be DEFAULT_PER_PAGE' do
          per_page = Settings::DEFAULT_PER_PAGE
          expect(create_settings.per_page).to eq(per_page)
        end
      end

      it 'assigns a custom parser' do
        parser = 'i am a custom parser'
        expect(create_settings(expr_parser: parser).parser).to eq(parser)
      end

      it 'assigns a custom transform' do
        transform = 'i am a custom transform'
        settings = create_settings(expr_transform: transform)
        expect(settings.transform).to eq(transform)
      end

      it 'assigns error_on_empty_dataset to true' do
        settings = create_settings(error_on_empty: true)
        expect(settings.error_on_empty_dataset?).to be(true)
      end

      it 'disables pagination' do
        settings = create_settings(disable_pagination: true)
        expect(settings.disable_pagination?).to be(true)
      end

      it 'assigns first flag' do
        expect(create_settings(first: true).first?).to be(true)
      end

      it 'assigns last flag' do
        expect(create_settings(last: true).last?).to be(true)
      end

      it 'assigns all flag' do
        expect(create_settings(all: true).all?).to be(true)
      end
    end

    context '#first' do
      it 'toggles flag for grabbing only the first found item' do
        settings = create_settings
        settings.first
        expect(settings.first?).to be(true)
      end

      it 'toggles last to false' do
        settings = create_settings
        settings.last
        expect(settings.last?).to be(true)

        settings.first
        expect(settings.last?).to be(false)
      end

      it 'toggles all to false' do
        settings = create_settings
        settings.all
        expect(settings.all?).to be(true)

        settings.first
        expect(settings.all?).to be(false)
      end
    end

    context '#last' do
      it 'toggles flag for grabbing only the last found item' do
        settings = create_settings
        settings.last
        expect(settings.last?).to be(true)
      end

      it 'toggles first to false' do
        settings = create_settings
        settings.first
        expect(settings.first?).to be(true)

        settings.last
        expect(settings.first?).to be(false)
      end

      it 'toggles all to false' do
        settings = create_settings
        settings.all
        expect(settings.all?).to be(true)

        settings.last
        expect(settings.all?).to be(false)
      end
    end

    context '#all' do
      it 'toggles flag for grabbing all found item' do
        settings = create_settings
        settings.all
        expect(settings.all?).to be(true)
      end

      it 'toggles first to false' do
        settings = create_settings
        settings.first
        expect(settings.first?).to be(true)

        settings.all
        expect(settings.first?).to be(false)
      end

      it 'toggles last to false' do
        settings = create_settings
        settings.last
        expect(settings.last?).to be(true)

        settings.all
        expect(settings.last?).to be(false)
      end
    end

    context 'pagination' do
      it 'disables pagination' do
        settings = create_settings
        settings.disable_pagination
        expect(settings.disable_pagination?).to be true
      end

      it 'enables pagination if its been disabled' do
        settings = create_settings(disable_pagination: true)
        settings.enable_pagination
        expect(settings.disable_pagination?).to be false
      end
    end

    context '#page' do
      it 'returns the value of page when given no args' do
        settings = create_settings(page: 66)
        expect(settings.page).to eq(66)
      end

      it 'assigns page when a number is given' do
        settings = create_settings(page: 66)
        settings.page(55)
        expect(settings.page).to eq(55)
      end

      it 'returns self' do
        settings = create_settings(page: 66)
        expect(settings.page(55)).to eq(settings)
      end

      it 'fails when not an integer' do
        settings = create_settings(page: 66)
        expect {
          settings.page('apb')
        }.to raise_error('invalid value for Integer(): "apb"')
      end
    end

    context '#per_page' do
      it 'returns the value of per_page when given no args' do
        settings = create_settings(per_page: 66)
        expect(settings.per_page).to eq(66)
      end

      it 'assigns page when a number is given' do
        settings = create_settings(per_page: 66)
        settings.per_page(55)
        expect(settings.per_page).to eq(55)
      end

      it 'returns self' do
        settings = create_settings(per_page: 66)
        expect(settings.per_page(55)).to eq(settings)
      end

      it 'fails when not an integer' do
        settings = create_settings(per_page: 66)
        expect {
          settings.per_page('apb')
        }.to raise_error('invalid value for Integer(): "apb"')
      end
    end

    context 'error_on_empty_dataset!' do
      it 'toggles the error_on_empty_dataset flag true' do
        settings = create_settings
        settings.error_on_empty_dataset!
        expect(settings.error_on_empty_dataset?).to be(true)
      end
    end

    context 'empty_dataset_is_valid!' do
      it 'toggles the error_on_empty_dataset flag to false' do
        settings = create_settings
        settings.empty_dataset_is_valid!
        expect(settings.error_on_empty_dataset?).to be(false)
      end
    end

    def create_settings(settings = {})
      Settings.new(settings)
    end
  end
end
