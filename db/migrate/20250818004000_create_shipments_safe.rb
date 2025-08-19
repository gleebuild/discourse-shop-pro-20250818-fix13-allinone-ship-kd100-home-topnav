class CreateShipmentsSafe < ActiveRecord::Migration[7.0]
  def change
    return if ActiveRecord::Base.connection.table_exists?(:shop_shipments)
    create_table :shop_shipments do |t|
      t.integer :order_id, null: false
      t.string  :carrier, null: false
      t.string  :tracking_no, null: false
      t.string  :status, default: 'created'
      t.jsonb   :traces, default: []
      t.boolean :subscribed, default: false
      t.timestamps
    end
    add_index :shop_shipments, :order_id unless index_exists?(:shop_shipments, :order_id)
    add_index :shop_shipments, :tracking_no unless index_exists?(:shop_shipments, :tracking_no)
  end
end
