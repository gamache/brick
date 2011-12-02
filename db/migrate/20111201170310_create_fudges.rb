class CreateFudges < ActiveRecord::Migration
  def change
    create_table :fudges do |t|
      t.integer :player_id, :null => false
      t.integer :season, :null => false

      t.string :description

      t.integer :warps
      t.integer :wins
      t.integer :cfbs
      t.integer :come_ons
      t.integer :wimps
      t.integer :mystery_factors
      t.integer :gold_stars

      t.timestamps
    end

    add_index :fudges, :player_id
    add_index :fudges, :season
  end
end
