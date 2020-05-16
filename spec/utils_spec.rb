require 'spec_helper'

describe Utils do
  describe '#string_to_i' do
    context 'with a string as parameter' do
      it 'with number' do
        expect(string_to_i('~st‡ring23')).to eq 23
      end

      it 'if multiple number select the first one' do
        expect(string_to_i('1~ola23')).to eq 1
      end

      it 'without number' do
        expect(string_to_i('string')).to eq nil
      end
    end

    context 'with a number as parameter' do
      it do
        expect(string_to_i(234)).to eq 234
      end
    end
  end
end
