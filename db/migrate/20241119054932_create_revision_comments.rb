class CreateRevisionComments < ActiveRecord::Migration[7.2]
  def change
    create_table :revision_comments do |t|
      t.references :section_revision, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content
      t.timestamps
    end
  end
end
