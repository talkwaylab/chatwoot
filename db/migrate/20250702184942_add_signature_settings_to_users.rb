class AddSignatureSettingsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :signature_settings, :jsonb, default: {}
  end
end
