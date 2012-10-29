class CreateLocales < ActiveRecord::Migration
  def change
    create_table :locales do |t|
      t.string :place
      t.string :phone
      t.string :other

      t.timestamps
    end
  end
end
