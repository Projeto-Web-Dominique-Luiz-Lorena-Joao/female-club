class AddDeviseSecurityFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    # Lockable - proteção contra brute force
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime

    # Trackable - rastreamento de logins
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string

    # Índice único para unlock_token
    add_index :users, :unlock_token, unique: true
  end
end
