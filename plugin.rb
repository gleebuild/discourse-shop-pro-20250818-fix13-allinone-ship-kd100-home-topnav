# frozen_string_literal: true
# name: discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav
# about: Shop (...) + deep DEBUG (namespace bootstrap + safe requires)
# version: 1.11.0-debugfix4
# authors: GleeBuild + ChatGPT
# required_version: 3.0.0

enabled_site_setting :shop_enabled
register_asset 'stylesheets/common/discourse-shop-pro.scss'

module ::DiscourseShopPro
  DEBUG = { boot_errors: [], after_initialize_started: false, after_initialize_finished: false, engine_loaded: false }
end

after_initialize do
  ::DiscourseShopPro::DEBUG[:after_initialize_started] = true

  # 定义顶层模块
  module ::DiscourseShopPro
    PLUGIN_NAME = "discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav"
  end

  # ★ 关键：预先定义中间命名空间，避免 require 时出现
  # "uninitialized constant DiscourseShopPro::Public/Admin"
  module ::DiscourseShopPro; module Public; end; end unless defined?(::DiscourseShopPro::Public)
  module ::DiscourseShopPro; module Admin;  end; end unless defined?(::DiscourseShopPro::Admin)

  # 载入 Engine（挂载路由）
  begin
    require_relative 'lib/discourse_shop_pro/engine'
    ::DiscourseShopPro::DEBUG[:engine_loaded] = true
  rescue => e
    ::DiscourseShopPro::DEBUG[:boot_errors] << "require engine.rb: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
  end

  # 显式加载控制器（生产环境需要）
  begin
    require_dependency File.expand_path('../app/controllers/discourse_shop_pro/public/products_controller.rb', __FILE__)
    require_dependency File.expand_path('../app/controllers/discourse_shop_pro/admin/orders_controller.rb', __FILE__)
    require_dependency File.expand_path('../app/controllers/discourse_shop_pro/logistics_controller.rb', __FILE__)
  rescue => e
    ::DiscourseShopPro::DEBUG[:boot_errors] << "require controllers/models: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
  end

  ::DiscourseShopPro::DEBUG[:after_initialize_finished] = true
end

# ===== 调试 + 业务路由（放在 after_initialize 外）=====
Discourse::Application.routes.append do
  require 'json'

  get '/shop/ping' => proc { [200, { 'Content-Type' => 'text/plain' }, ['pong']] }

  get '/shop/debug/status' => proc {
    body = {
      plugin_loaded: true,
      after_initialize_started: ::DiscourseShopPro::DEBUG[:after_initialize_started],
      after_initialize_finished: ::DiscourseShopPro::DEBUG[:after_initialize_finished],
      engine_loaded: ::DiscourseShopPro::DEBUG[:engine_loaded],
      boot_errors: ::DiscourseShopPro::DEBUG[:boot_errors]
    }
    [200, { 'Content-Type' => 'application/json' }, [JSON.pretty_generate(body)]]
  }

  get '/shop/debug/routes' => proc {
    paths = Rails.application.routes.routes.map { |r| (r.path.spec.to_s rescue nil) }
             .compact.select { |p| p.start_with?('/shop') }.sort
    [200, { 'Content-Type' => 'application/json' }, [JSON.pretty_generate({ routes: paths })]]
  }

  get '/shop/debug/match' => proc { |env|
    req = Rack::Request.new(env)
    path = req.params['path'].to_s
    result =
      if path.empty?
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

  # 业务路由
  get  '/shop/public/products'       => 'discourse_shop_pro/public/products#index'
  get  '/shop/public/products/:id'   => 'discourse_shop_pro/public/products#show'
  get  '/shop/admin/orders'          => 'discourse_shop_pro/admin/orders#index'
  post '/shop/admin/orders/:id/ship' => 'discourse_shop_pro/admin/orders#ship'
  post '/shop/logistics/kd100/notify'=> 'discourse_shop_pro/logistics#kd100_notify'
end
