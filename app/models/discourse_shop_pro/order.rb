class DiscourseShopPro::Order < ActiveRecord::Base; self.table_name='shop_orders'; has_many :shipments, class_name:'DiscourseShopPro::Shipment', foreign_key:'order_id'; end
