# frozen_string_literal: true

module DiscourseShopPro
  module Public
    class ProductsController < ::ApplicationController
      requires_plugin DiscourseShopPro::PLUGIN_NAME

      def index
        @products = DiscourseShopPro::Product.order(created_at: :desc)
        respond_to do |format|
          format.html { render }
          format.json { render_json_dump(products: serialize_data(@products, DiscourseShopPro::ProductSerializer)) }
        end
      end

      def show
        @product = DiscourseShopPro::Product.find_by(id: params[:id])
        raise Discourse::NotFound unless @product

        respond_to do |format|
          format.html { render }
          format.json { render_json_dump(product: serialize_data(@product, DiscourseShopPro::ProductSerializer)) }
        end
      end
    end
  end
end
