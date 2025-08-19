# frozen_string_literal: true
module ::DiscourseShopPro
  module Public
    class ProductsController < ::ApplicationController
      requires_plugin ::DiscourseShopPro::PLUGIN_NAME
      skip_before_action :check_xhr, only: [:index]

      def index
        list = plugin_store_get_list
        respond_to do |format|
          format.html do
            html = +"<h1>Products</h1>\n"
            if list.blank?
              html << "<p>(empty)</p>"
            else
              html << "<ul>"
              list.each do |p|
                price = p['price'] || p[:price]
                name  = p['name']  || p[:name]
                img   = p['image_url'] || p[:image_url]
                html << "<li>#{ERB::Util.html_escape(name)} — #{price}"
                html << " <img src='#{img}' style='max-height:60px;vertical-align:middle;margin-left:8px' />" if img.present?
                html << "</li>"
              end
              html << "</ul>"
            end
            render plain: html, content_type: 'text/html'
          end
          format.json do
            render json: { products: list || [] }
          end
        end
      end

      def show
        list = plugin_store_get_list
        prod = list.find { |p| p['id'].to_s == params[:id].to_s }
        if prod
          render json: prod
        else
          render json: { error: 'not_found' }, status: 404
        end
      end

      private

      def plugin_store_get_list
        PluginStore.get('discourse_shop_pro', 'products') || []
      end
    end
  end
end
