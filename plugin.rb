# frozen_string_literal: true
# name: discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav
# about: Shop (...) + deep DEBUG
# version: 1.11.0-debugfix2
# authors: GleeBuild + ChatGPT
# required_version: 3.0.0

enabled_site_setting :shop_enabled
register_asset 'stylesheets/common/discourse-shop-pro.scss'

module ::DiscourseShopPro
  DEBUG = { boot_errors: [], after_initialize_started: false, after_initialize_finished: false, engine_loaded: false }
end

after_initialize do
  ::DiscourseShopPro::DEBUG[:after_initialize_started] = true

  begin
    module ::DiscourseShopPro
      PLUGIN_NAME = "discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav"
    end
  rescue => e
    ::DiscourseShopPro::DEBUG[:boot_errors] << "define module/constant: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
  end

  begin
    require_relative 'lib/discourse_shop_pro/engine'
    ::DiscourseShopPro::DEBUG[:engine_loaded] = true
  rescue => e
    ::DiscourseShopPro::DEBUG[:boot_errors] << "require engine.rb: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
  end

  begin
    # ★ 显式加载控制器（生产环境常见必需）
    require_dependency File.expand_path('../app/controllers/discourse_shop_pro/public/products_controller.rb', __FILE__)
    require_dependency File.expand_path('../app/controllers/discourse_shop_pro/admin/orders_controller.rb', __FILE__)
    require_dependency File.expand_path('../app/controllers/discourse_shop_pro/logistics_controller.rb', __FILE__)
    # 需要的话可加模型：
    # require_dependency File.expand_path('../app/models/discourse_shop_pro/product.rb', __FILE__)
  rescue => e
    ::DiscourseShopPro::DEBUG[:boot_errors] << "require controllers/models: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
  end

  ::DiscourseShopPro::DEBUG[:after_initialize_finished] = true
end

# ===== 调试 + 兜底路由（放在 after_initialize 外）=====
Discourse::Application.routes.append do
  require 'json'

  # 0) 存活探测
  get '/shop/ping' => proc { [200, { 'Content-Type' => 'text/plain' }, ['pong']] }

  # 1) 状态页
  get '/shop/debug/status' => proc {
    body = {
      plugin_loaded: true,
      after_initialize_started: ::DiscourseShopPro::DEBUG[:after_initialize_started],
      after_initialize_finished: ::DiscourseShopPro::DEBUG[:after_initialize_finished],
      engine_loaded: ::DiscourseShopPro::DEBUG[:engine_loaded],
      boot_errors: ::DiscourseShopPro::DEBUG[:boot_errors],
      ruby: RUBY_VERSION, rails_env: Rails.env, discourse_base_uri: Discourse.base_uri,
    }
    [200, { 'Content-Type' => 'application/json' }, [JSON.pretty_generate(body)]]
  }

  # 2) 列出 /shop* 路由
  get '/shop/debug/routes' => proc {
    paths = Rails.application.routes.routes.map { |r| (r.path.spec.to_s rescue nil) }.compact.select { |p| p.start_with?('/shop') }.sort
    [200, { 'Content-Type' => 'application/json' }, [JSON.pretty_generate({ routes: paths })]]
  }

  # 3) 查看路径匹配
  get '/shop/debug/match' => proc { |env|
    req = Rack::Request.new(env)
    path = req.params['path'].to_s
    result = if path.empty?
      { error: 'missing query param: path' }
    else
      begin
        hit = Rails.application.routes.recognize_path(path, method: :get) rescue Rails.application.routes.recognize_path(path)
        { path: path, recognized: true, to: hit }
      rescue => e
        { path: path, recognized: false, error: "#{e.class}: #{e.message}" }
      end
    end
    [200, { 'Content-Type' => 'application/json' }, [JSON.pretty_generate(result)]]
  }

  # 4) 新增：常量与来源文件检查
  get '/shop/debug/constants' => proc {
    info = {}
    begin
      info[:products_defined] = defined?(::DiscourseShopPro::Public::ProductsController) ? true : false
      if info[:products_defined]
        info[:products_source] =
          ::DiscourseShopPro::Public::ProductsController.instance_method(:index).source_location rescue nil
      end
    rescue => e
      info[:products_error] = "#{e.class}: #{e.message}"
    end

    begin
      info[:orders_defined] = defined?(::DiscourseShopPro::Admin::OrdersController) ? true : false
      if info[:orders_defined]
        info[:orders_source] =
          ::DiscourseShopPro::Admin::OrdersController.instance_method(:index).source_location rescue nil
      end
    rescue => e
      info[:orders_error] = "#{e.class}: #{e.message}"
    end

    [200, { 'Content-Type' => 'application/json' }, [JSON.pretty_generate(info)]]
  }

  # 5) 业务路由（指向控制器）
  get  '/shop/public/products'       => 'discourse_shop_pro/public/products#index'
  get  '/shop/public/products/:id'   => 'discourse_shop_pro/public/products#show'
  get  '/shop/admin/orders'          => 'discourse_shop_pro/admin/orders#index'
  post '/shop/admin/orders/:id/ship' => 'discourse_shop_pro/admin/orders#ship'
  post '/shop/logistics/kd100/notify'=> 'discourse_shop_pro/logistics#kd100_notify'
end

# ===== 兜底控制器（若上面没加载到真正的控制器，这里提供最小实现；不会覆盖已存在的类）=====
unless defined?(::DiscourseShopPro::Public::ProductsController)
  module ::DiscourseShopPro
    module Public
      class ProductsController < ::ApplicationController
        skip_before_action :check_xhr, :redirect_to_login_if_required, :ensure_logged_in, raise: false
        def index
          render json: []
        end
        def show
          render plain: "fallback show ##{params[:id]}", content_type: "text/plain"
        end
      end
    end
  end
end

unless defined?(::DiscourseShopPro::Admin::OrdersController)
  module ::DiscourseShopPro
    module Admin
      class OrdersController < ::Admin::AdminController
        def index
          render json: []
        end
        def ship
          render json: { ok: true }
        end
      end
    end
  end
end
