# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessRequest, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      request = build(:access_request)
      expect(request).to be_valid
    end

    it 'requires email' do
      request = build(:access_request, email: '')
      expect(request).not_to be_valid
      expect(request.errors[:email]).to be_present
    end

    it 'requires valid email format' do
      request = build(:access_request, email: 'invalid')
      expect(request).not_to be_valid
    end

    it 'requires password' do
      request = build(:access_request, password: '', password_confirmation: '')
      expect(request).not_to be_valid
      expect(request.errors[:password]).to be_present
    end

    it 'requires password confirmation' do
      request = build(:access_request, password: 'Password123!', password_confirmation: '')
      expect(request).not_to be_valid
      expect(request.errors[:password_confirmation]).to be_present
    end

    it 'requires passwords to match' do
      request = build(:access_request, password: 'Password123!', password_confirmation: 'Different1!')
      expect(request).not_to be_valid
      expect(request.errors[:password_confirmation]).to be_present
    end

    it 'rejects password without uppercase letter' do
      request = build(:access_request, password: 'password1!', password_confirmation: 'password1!')
      expect(request).not_to be_valid
      expect(request.errors[:password]).to be_present
    end

    it 'rejects password without lowercase letter' do
      request = build(:access_request, password: 'PASSWORD1!', password_confirmation: 'PASSWORD1!')
      expect(request).not_to be_valid
      expect(request.errors[:password]).to be_present
    end

    it 'rejects password without number' do
      request = build(:access_request, password: 'StrongPass!', password_confirmation: 'StrongPass!')
      expect(request).not_to be_valid
      expect(request.errors[:password]).to be_present
    end

    it 'rejects password without special character' do
      request = build(:access_request, password: 'StrongPass1', password_confirmation: 'StrongPass1')
      expect(request).not_to be_valid
      expect(request.errors[:password]).to be_present
    end

    it 'requires password to be at least 8 characters' do
      request = build(:access_request, password: 'Ab1!xyz', password_confirmation: 'Ab1!xyz')
      expect(request).not_to be_valid
    end

    it 'accepts strong password meeting all criteria' do
      request = build(:access_request, password: 'Abcdef1!', password_confirmation: 'Abcdef1!')
      expect(request).to be_valid
    end

    it 'includes descriptive error message for weak password' do
      request = build(:access_request, password: 'weak', password_confirmation: 'weak')
      request.valid?
      expect(request.errors[:password].join).to include('maiúsculas')
      expect(request.errors[:password].join).to include('especial')
    end

    it 'validates status inclusion' do
      request = build(:access_request)
      request.save!
      request.status = 'invalid'
      expect(request).not_to be_valid
    end

    it 'does not require message' do
      request = build(:access_request, message: nil)
      expect(request).to be_valid
    end
  end

  describe 'encryption' do
    it 'encrypts password before saving' do
      request = create(:access_request, password: 'Password123!', password_confirmation: 'Password123!')
      expect(request.encrypted_password).to be_present
      expect(request.encrypted_password).not_to eq('Password123!')
    end
  end

  describe 'scopes' do
    let!(:pending_request) { create(:access_request) }
    let!(:approved_request) { create(:access_request, :approved) }
    let!(:rejected_request) { create(:access_request, :rejected) }

    it '.pending returns only pending requests' do
      expect(AccessRequest.pending).to contain_exactly(pending_request)
    end

    it '.recent orders by created_at desc' do
      expect(AccessRequest.recent.first).to eq(rejected_request)
    end
  end

  describe 'status methods' do
    it '#pending? returns true for pending' do
      request = build(:access_request, status: 'pending')
      expect(request.pending?).to be true
    end

    it '#approved? returns true for approved' do
      request = create(:access_request)
      request.update!(status: 'approved')
      expect(request.approved?).to be true
    end

    it '#rejected? returns true for rejected' do
      request = create(:access_request)
      request.update!(status: 'rejected')
      expect(request.rejected?).to be true
    end
  end

  describe '#status_badge_class' do
    it 'returns yellow for pending' do
      expect(build(:access_request).status_badge_class).to include('yellow')
    end

    it 'returns green for approved' do
      request = create(:access_request, :approved)
      expect(request.status_badge_class).to include('green')
    end

    it 'returns red for rejected' do
      request = create(:access_request, :rejected)
      expect(request.status_badge_class).to include('red')
    end
  end

  describe '#status_label' do
    it 'returns Pendente for pending' do
      expect(build(:access_request).status_label).to eq('Pendente')
    end

    it 'returns Aprovada for approved' do
      expect(create(:access_request, :approved).status_label).to eq('Aprovada')
    end

    it 'returns Rejeitada for rejected' do
      expect(create(:access_request, :rejected).status_label).to eq('Rejeitada')
    end
  end
end
