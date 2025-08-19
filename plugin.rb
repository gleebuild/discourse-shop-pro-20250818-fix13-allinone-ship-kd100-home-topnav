# frozen_string_literal: true
# name: discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav
# about: Shop (Products/Orders/WeChatPay/TopicWidget) + Kuaidi100 + Home strip + idempotent migration + robust routes + TOP NAV + DEBUG
# version: 1.11.0-debugfix
# authors: GleeBuild + ChatGPT
# required_version: 3.0.0

enabled_site_setting :shop_enabled
register_asset 'stylesheets/common/discourse-shop-pro.scss'

module ::DiscourseShopPro
  DEBUG = {
    boot_errors: [],
    after_initialize_started: false,
    after_initialize_finished: false,
    engine_loaded: false,
  }
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
    # 1) 先加载 Engine（挂 /shop）
    require_relative 'lib/discourse_shop_pro/engine'
    ::DiscourseShopPro::DEBUG[:engine_loaded] = true
  rescue => e
    ::DiscourseShopPro::DEBUG[:boot_errors] << "require engine.rb: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
  end

  begin
    # 2) 显式加载 Controllers（生产环境下常见：不主动加载就 constantize 失败）
    require_dependency File.expand_path('../app/controllers/discourse_shop_pro/public/products_controller.rb', __FILE__)
    require_dependency File.expand_path('../app/controllers/discourse_shop_pro/admin/orders_controller.rb', __FILE__)
    require_dependency File.expand_path('../app/controllers/discourse_shop_pro/logistics_controller.rb', __FILE__)

    # （可选）如需保证模型也可用，按需加载（你的 index 有 rescue，不一定需要）
    # require_dependency File.expand_path('../app/models/discourse_shop_pro/product.rb', __FILE__)
    # require_dependency File.expand_path('../app/models/discourse_shop_pro/order.rb', __FILE__)
    # require_dependency File.expand_path('../app/models/discourse_shop_pro/shipment.rb', __FILE__)
  rescue => e
    ::DiscourseShopPro::DEBUG[:boot_errors] << "require controllers/models: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
  end

  ::DiscourseShopPro::DEBUG[:after_initialize_finished] = true
end

# === 调试与兜底路由（留在 after_initialize 外，确保即便上面报错也可访问）===
Discourse::Application.routes.append do
  require 'json'

  # ping
  get '/shop/ping' => proc { [200, { 'Content-Type' => 'text/plain' }, ['pong']] }

  # status
  get '/shop/debug/status' => proc {
    body = {
      plugin_loaded: true,
      after_initialize_started: ::DiscourseShopPro::DEBUG[:after_initialize_started],
      after_initialize_finished: ::DiscourseShopPro::DEBUG[:after_initialize_finished],
      engine_loaded: ::DiscourseShopPro::DEBUG[:engine_loaded],
      boot_errors: ::DiscourseShopPro::DEBUG[:boot_errors],
      ruby: RUBY_VERSION,
      rails_env: Rails.env,
      discourse_base_uri: Discourse.base_uri,
    }
    [200, { 'Content-Type' => 'application/json' }, [JSON.pretty_generate(body)]]
  }

  # routes
  get '/shop/debug/routes' => proc {
    paths = Rails.application.routes.routes.map { |r|
      begin r.path.spec.to_s rescue nil end
    }.compact.select { |p| p.start_with?('/shop') }.sort
    [200, { 'Content-Type' => 'application/json' }, [JSON.pretty_generate({ routes: paths })]]
  }

  # match
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
