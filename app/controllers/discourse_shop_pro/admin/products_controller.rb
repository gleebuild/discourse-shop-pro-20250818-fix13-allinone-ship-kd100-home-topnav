# frozen_string_literal: true
module ::DiscourseShopPro
  module Admin
    class ProductsController < ::ApplicationController
      requires_plugin ::DiscourseShopPro::PLUGIN_NAME
      before_action :ensure_admin

      def index
        @products = plugin_store_get_list
        render 'discourse_shop_pro/admin/products/index'
      end

      def create
        name = params[:name].to_s.strip
        price = params[:price].to_s.strip
        upload_id = params[:upload_id].presence

        if name.blank?
          return render_json_error("name required", status: 422)
        end

        img_url = nil
        if upload_id
          begin
            upload = Upload.find_by(id: upload_id)
            if upload
              img_url = "#{Discourse.base_url}#{upload.url}"
            else
              return render_json_error("upload not found", status: 422)
            end
          rescue => e
            return render_json_error("upload error: #{e.message}", status: 422)
          end
        end

        list = plugin_store_get_list
        new_id = (list.map { |p| p['id'].to_i }.max || 0) + 1

        product = {
          'id' => new_id,
          'name' => name,
          'price' => price,
          'image_url' => img_url,
          'created_by' => current_user&.username,
          'created_at' => Time.now.utc.iso8601
        }

        list << product
        PluginStore.set('discourse_shop_pro', 'products', list)

        respond_to do |format|
          format.json { render json: { ok: true, product: product } }
          format.html { redirect_to '/shop/admin/products' }
        end
      end

      private

      def plugin_store_get_list
        PluginStore.get('discourse_shop_pro', 'products') || []
      end
    end
  end
end
