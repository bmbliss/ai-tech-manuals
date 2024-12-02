class CreateSectionRevisions < ActiveRecord::Migration[7.2]
  def change
    create_table :section_revisions do |t|
      t.references :section, null: false, foreign_key: true
      t.references :manual, null: false, foreign_key: true
      t.text :content
      t.text :base_content
      t.integer :base_version
      t.string :status, default: 'pending'  # pending, approved, rejected
      t.string :change_type  # update, create, delete, move
      t.float :position
      t.float :base_position
      t.text :change_description
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps

      t.index [:section_id, :status]
    end
  end
end
