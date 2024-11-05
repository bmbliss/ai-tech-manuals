class CreateSections < ActiveRecord::Migration[7.2]
  def change
    create_table :sections do |t|
      t.references :manual, null: false, foreign_key: true
      t.text :content, null: false
      t.float :position, null: false
      t.vector :embedding, limit: 1536  # For text-embedding-3-small
      t.timestamps
    end
    
    add_index :sections, :embedding, using: :ivfflat  # For vector similarity search
  end
end
