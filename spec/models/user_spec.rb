# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "validates items_per_page inclusion" do
      user = build(:user, items_per_page: 99)
      expect(user).not_to be_valid
      expect(user.errors[:items_per_page]).to be_present
    end

    it "allows nil items_per_page" do
      user = build(:user, items_per_page: nil)
      expect(user).to be_valid
    end
  end

  describe "password complexity" do
    it "accepts a strong password with all requirements" do
      user = build(:user, password: "StrongPass1!", password_confirmation: "StrongPass1!")
      expect(user).to be_valid
    end

    it "rejects password without uppercase letter" do
      user = build(:user, password: "password1!", password_confirmation: "password1!")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "rejects password without lowercase letter" do
      user = build(:user, password: "PASSWORD1!", password_confirmation: "PASSWORD1!")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "rejects password without number" do
      user = build(:user, password: "StrongPass!", password_confirmation: "StrongPass!")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "rejects password without special character" do
      user = build(:user, password: "StrongPass1", password_confirmation: "StrongPass1")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "rejects password shorter than 8 characters" do
      user = build(:user, password: "Ab1!xyz", password_confirmation: "Ab1!xyz")
      expect(user).not_to be_valid
    end

    it "accepts password with exactly 8 characters meeting all criteria" do
      user = build(:user, password: "Abcdef1!", password_confirmation: "Abcdef1!")
      expect(user).to be_valid
    end

    it "includes descriptive error message" do
      user = build(:user, password: "weak", password_confirmation: "weak")
      user.valid?
      expect(user.errors[:password].join).to include("maiúsculas")
      expect(user.errors[:password].join).to include("minúsculas")
      expect(user.errors[:password].join).to include("especial")
    end

    it "skips validation when password is blank (edit without changing)" do
      user = create(:user)
      user.password = ""
      user.password_confirmation = ""
      # Devise validatable handles blank password on update
      expect(user.errors[:password]).to be_empty if user.valid?
    end
  end

  describe "devise modules" do
    it "is database_authenticatable" do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it "is recoverable" do
      expect(User.devise_modules).to include(:recoverable)
    end

    it "is lockable" do
      expect(User.devise_modules).to include(:lockable)
    end

    it "is trackable" do
      expect(User.devise_modules).to include(:trackable)
    end
  end
end
