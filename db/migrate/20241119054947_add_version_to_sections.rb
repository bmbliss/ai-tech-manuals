class AddVersionToSections < ActiveRecord::Migration[7.2]
  def change
    add_column :sections, :version_number, :integer, default: 1
    add_column :sections, :latest_revision_id, :bigint
    add_index :sections, :latest_revision_id
  end
end
