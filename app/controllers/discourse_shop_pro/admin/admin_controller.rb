class DiscourseShopPro::Admin::AdminController < ::Admin::AdminController; def bootstrap; render_json_dump({ok:true}); end; end

def seed_nav
  guardian.ensure_admin
  ok = ::DiscourseShopPro::NavSeeder.ensure!
  render json: { success: ok }
end
