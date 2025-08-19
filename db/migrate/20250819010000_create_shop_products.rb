class CreateShopProducts < ActiveRecord::Migration[7.0]
  def change
    return if ActiveRecord::Base.connection.table_exists?(:shop_products)

    create_table :shop_products do |t|
      t.string  :name, null: false
      t.text    :description
      t.integer :price_cents, default: 0, null: false
      t.integer :stock, default: 0, null: false
      t.integer :image_upload_id # references uploads.id
      t.timestamps
    end
    add_index :shop_products, :name unless index_exists?(:shop_products, :name)
    add_index :shop_products, :image_upload_id unless index_exists?(:shop_products, :image_upload_id)
  end
end
