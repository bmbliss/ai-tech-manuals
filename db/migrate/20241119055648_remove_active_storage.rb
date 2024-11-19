class RemoveActiveStorage < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :active_storage_attachments, column: :blob_id
    remove_foreign_key :active_storage_variant_records, column: :blob_id
    drop_table :active_storage_blobs
    drop_table :active_storage_variant_records
    drop_table :active_storage_attachments
  end
end
