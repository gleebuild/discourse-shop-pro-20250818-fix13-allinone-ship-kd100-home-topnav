# frozen_string_literal: true

module ::DiscourseShopPro
  module Admin
    class OrdersController < ::Admin::AdminController
      # 确认开启插件
      requires_plugin ::DiscourseShopPro::PLUGIN_NAME

      def index
        respond_to do |format|
          format.json { render json: [] }
          format.html { render html: "<h2>Orders (empty)</h2>".html_safe }
        end
      end

      def ship
        render json: { ok: true, id: params[:id] }
      end
    end
  end
end
