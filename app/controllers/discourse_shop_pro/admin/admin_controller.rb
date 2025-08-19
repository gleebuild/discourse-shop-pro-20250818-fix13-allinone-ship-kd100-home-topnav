class DiscourseShopPro::Admin::AdminController < ::Admin::AdminController; def bootstrap; render_json_dump({ok:true}); end; end
