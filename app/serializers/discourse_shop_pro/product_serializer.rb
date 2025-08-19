# frozen_string_literal: true

class DiscourseShopPro::ProductSerializer < ApplicationSerializer
  attributes :id, :name, :description, :price_cents, :stock, :image_url, :created_at, :updated_at

  def image_url
    object.image_url
  end
end
