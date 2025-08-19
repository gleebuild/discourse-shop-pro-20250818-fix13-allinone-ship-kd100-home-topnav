# frozen_string_literal: true
# name: discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav
# about: Shop (Products/Orders/WeChatPay/TopicWidget) + Kuaidi100 + Home strip + idempotent migration + robust routes + TOP NAV + DEBUG
# version: 1.11.0-debug
# authors: GleeBuild + ChatGPT
# required_version: 3.0.0

enabled_site_setting :shop_enabled
register_asset 'stylesheets/common/discourse-shop-pro.scss'

# ---- 诊断用全局存储（内存）----
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
    require_relative 'lib/discourse_shop_pro/engine'
    ::DiscourseShopPro::DEBUG[:engine_loaded] = true
  rescue => e
    ::DiscourseShopPro::DEBUG[:boot_errors] << "require engine.rb: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
  end

  ::DiscourseShopPro::DEBUG[:after_initialize_finished] = true
end

# ---- 兜底 + 调试 路由（放在 after_initialize 外，确保即便上面报错也能生效）----
Discourse::Application.routes.append do
  require 'json'

  # 0) 最小“存活”探测
  get '/shop/ping' => proc { [200, { 'Content-Type' => 'text/plain' }, ['pong']] }

  # 1) 状态页：after_initialize 及 engine 加载情况
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

  # 2) 列出所有以 /shop 开头的已注册路由（最终生效的）
  get '/shop/debug/routes' => proc {
    paths = Rails.application.routes.routes.map { |r|
      begin
        r.path.spec.to_s
      rescue
        nil
      end
    }.compact.select { |p| p.start_with?('/shop') }.sort

    [200, { 'Content-Type' => 'application/json' }, [JSON.pretty_generate({ routes: paths })]]
  }

  # 3) 试着识别一个路径会匹配到哪个 controller#action
  #    用法：/shop/debug/match?path=/shop/public/products.json
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

  # 4) 原计划的“兜底业务路由”——指向 controller（便于在 engine 失效时仍可测试）
  get  '/shop/public/products'       => 'discourse_shop_pro/public/products#index'
  get  '/shop/public/products/:id'   => 'discourse_shop_pro/public/products#show'
  get  '/shop/admin/orders'          => 'discourse_shop_pro/admin/orders#index'
  post '/shop/admin/orders/:id/ship' => 'discourse_shop_pro/admin/orders#ship'
  post '/shop/logistics/kd100/notify'=> 'discourse_shop_pro/logistics#kd100_notify'
end
