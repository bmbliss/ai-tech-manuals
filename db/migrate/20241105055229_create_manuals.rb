class CreateManuals < ActiveRecord::Migration[7.2]
  def change
    create_table :manuals do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, default: 'draft'
      t.timestamps
    end
  end
end
