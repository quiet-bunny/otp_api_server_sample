class CreateApplications < ActiveRecord::Migration
  def change
    create_table :applications do |t|
      t.string  :name, null: false
      t.string  :encrypted_secret, limit: 64, null: false
      t.integer :key_expire
      t.integer :cached_key_expire
      t.timestamps
    end

    add_index :applications, :name, unique: true
  end
end
