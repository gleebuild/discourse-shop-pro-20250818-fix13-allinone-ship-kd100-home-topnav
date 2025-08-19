# frozen_string_literal: true

# 命名空间逐层定义，避免生产环境 Zeitwerk 提示 "uninitialized constant"
module ::DiscourseShopPro
  module Public
    class ProductsController < ::ApplicationController
      # 允许匿名访问；有的 before_action 在某些版本不存在，因此 raise: false
      skip_before_action :check_xhr, :redirect_to_login_if_required, :ensure_logged_in, raise: false

      def index
        # 先返回一个“空列表”占位；确认路由与控制器无误后，再接入真实数据
        respond_to do |format|
          format.json { render json: [] }
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
