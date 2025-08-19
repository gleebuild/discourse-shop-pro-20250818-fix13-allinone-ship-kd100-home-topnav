# frozen_string_literal: true

module ::DiscourseShopPro
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseShopPro
    # 这里不画 engine 路由，路由已在 plugin.rb 里 append 了
  end
end
