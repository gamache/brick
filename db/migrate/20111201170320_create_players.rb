class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :name, :null => false
      t.string :display_name

      t.string :password_salt
      t.string :sha512_password

      t.timestamps
    end

    add_index :players, :name, :unique => true
  end
end
