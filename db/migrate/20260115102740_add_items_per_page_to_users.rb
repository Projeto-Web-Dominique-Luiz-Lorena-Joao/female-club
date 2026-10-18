class AddItemsPerPageToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :items_per_page, :integer, default: 15
  end
end
