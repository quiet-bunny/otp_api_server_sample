class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :application_id, null: false
      t.string :secret, null: false, limit: 16
      t.string :user_id, null: false
      t.timestamps
    end

    add_index :users, [:application_id, :user_id], unique: true
  end
end
