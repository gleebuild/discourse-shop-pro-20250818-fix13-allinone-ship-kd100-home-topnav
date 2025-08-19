# frozen_string_literal: true

module DiscourseShopPro
  class Product < ActiveRecord::Base
    self.table_name = "shop_products"

    belongs_to :image_upload, class_name: "Upload", optional: true

    validates :name, presence: true
    validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :stock, numericality: { greater_than_or_equal_to: 0 }

    def image_url
      image_upload&.url
    end
  end
end
