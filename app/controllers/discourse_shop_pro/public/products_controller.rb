# frozen_string_literal: true

module ::DiscourseShopPro
  module Public
    class ProductsController < ::ApplicationController
      # 允许匿名访问这些公开页
      skip_before_action :check_xhr, :redirect_to_login_if_required, :ensure_logged_in, raise: false

      def index
        respond_to do |format|
          format.json { render json: { products: [] } }
          format.html { render html: "<h2>Products (empty)</h2>".html_safe }
        end
      end

      def show
        pid = params[:id]
        respond_to do |format|
          format.json { render json: { id: pid, name: "Product #{pid}" } }
          format.html { render html: "<h2>Product ##{pid}</h2>".html_safe }
        end
      end
    end
  end
end
