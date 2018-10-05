class CreateFudges < ActiveRecord::Migration[5.2]
  def change
    create_table :fudges do |t|
      t.integer :player_id
      t.integer :season

      t.string :notes

      t.integer :warps
      t.integer :games
      t.integer :nights
      t.integer :wins
      t.integer :cfbs
      t.integer :come_ons
      t.integer :wimps
      t.integer :mystery_factors
      t.integer :gold_stars
      t.integer :nights_won
      t.integer :high_night

      t.timestamps
    end

    add_index :fudges, :player_id
    add_index :fudges, :season
  end
end
