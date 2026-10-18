class CreateAccessRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :access_requests do |t|
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.text :message
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end

    add_index :access_requests, :email
    add_index :access_requests, :status
  end
end
