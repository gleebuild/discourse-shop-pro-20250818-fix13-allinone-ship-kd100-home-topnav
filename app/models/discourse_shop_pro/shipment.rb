class DiscourseShopPro::Shipment < ActiveRecord::Base; self.table_name='shop_shipments'; serialize :traces, JSON; end
