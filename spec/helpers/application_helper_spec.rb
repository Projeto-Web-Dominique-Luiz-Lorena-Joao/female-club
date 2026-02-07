# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#active_class' do
    before do
      allow(helper).to receive(:current_page?).and_return(false)
    end

    context 'when current page matches' do
      before do
        allow(helper).to receive(:current_page?).with('/products').and_return(true)
      end

      it 'returns active class' do
        expect(helper.active_class('/products')).to eq('bg-white text-black')
      end
    end

    context 'when current page does not match' do
      it 'returns inactive class' do
        expect(helper.active_class('/products')).to eq('text-gray-300 hover:bg-white/10 hover:text-white')
      end
    end
  end

  describe '#active_submenu?' do
    before do
      allow(helper).to receive(:current_page?).and_return(false)
    end

    context 'when one of the paths matches' do
      before do
        allow(helper).to receive(:current_page?).with('/products').and_return(true)
      end

      it 'returns true' do
        expect(helper.active_submenu?('/products', '/services')).to be true
      end
    end

    context 'when no paths match' do
      it 'returns false' do
        expect(helper.active_submenu?('/products', '/services')).to be false
      end
    end
  end

  describe '#safe_json' do
    it 'escapes HTML in JSON for XSS prevention' do
      data = { name: '<script>alert("xss")</script>' }
      result = helper.safe_json(data)
      expect(result).not_to include('<script>')
      expect(result).to include('\\u003c')
    end

    it 'handles simple data' do
      data = { name: 'Test', value: 123 }
      result = helper.safe_json(data)
      expect(result).to include('Test')
      expect(result).to include('123')
    end

    it 'handles arrays' do
      data = [ 1, 2, 3 ]
      result = helper.safe_json(data)
      expect(result).to eq('[1,2,3]')
    end
  end

  describe '#sanitize_for_display' do
    it 'escapes HTML entities' do
      result = helper.sanitize_for_display('<script>alert("xss")</script>')
      expect(result).not_to include('<script>')
      expect(result).to include('&lt;script&gt;')
    end

    it 'returns empty string for blank input' do
      expect(helper.sanitize_for_display(nil)).to eq('')
      expect(helper.sanitize_for_display('')).to eq('')
    end

    it 'converts non-string to string' do
      expect(helper.sanitize_for_display(123)).to eq('123')
    end

    it 'handles normal text' do
      expect(helper.sanitize_for_display('Hello World')).to eq('Hello World')
    end
  end
end
