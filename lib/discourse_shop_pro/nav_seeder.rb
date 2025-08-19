
# frozen_string_literal: true

module ::DiscourseShopPro
  class NavSeeder
    def self.col?(model, name)
      return false unless model.respond_to?(:column_names)
      model.column_names.include?(name.to_s)
    end

    def self.find_or_create_section!
      section_model = Object.const_defined?("SidebarSection") ? Object.const_get("SidebarSection") : nil
      raise "SidebarSection model not found" unless section_model

      # Prefer slug match; fallback to title
      criteria = if col?(section_model, :slug)
        { slug: "shop" }
      elsif col?(section_model, :name)
        { name: "商城" }
      else
        { title: "商城" }
      end

      section = section_model.where(criteria).first || section_model.new
      section.slug = "shop" if col?(section_model, :slug)
      section.name = "商城" if col?(section_model, :name)
      section.title = "商城" if col?(section_model, :title)
      section.position = 0 if col?(section_model, :position) && section.position.nil?
      section.enabled = true if col?(section_model, :enabled) && section.enabled.nil?
      section.save!
      section
    end

    def self.upsert_link!(section, key:, name:, url:, admin_only:, icon: nil)
      url_model = Object.const_defined?("SidebarUrl") ? Object.const_get("SidebarUrl") : nil
      raise "SidebarUrl model not found" unless url_model

      attrs = {}
      attrs[:sidebar_section_id] = section.id if col?(url_model, :sidebar_section_id)
      attrs[:value] = url if col?(url_model, :value)
      attrs[:url] = url if !attrs[:value] && col?(url_model, :url)

      link = url_model.where(attrs).first || url_model.new

      link.sidebar_section_id = section.id if col?(url_model, :sidebar_section_id)
      link.section_id = section.id if col?(url_model, :section_id)

      link.name = name if col?(url_model, :name)
      link.title = name if col?(url_model, :title)
      link.value = url if col?(url_model, :value)
      link.url = url if col?(url_model, :url)
      link.icon = icon if icon && col?(url_model, :icon)

      if col?(url_model, :only_staff)
        link.only_staff = admin_only
      elsif col?(url_model, :staff_only)
        link.staff_only = admin_only
      elsif col?(url_model, :visibility)
        link.visibility = admin_only ? "staff" : "everyone"
      end

      link.save!
      link
    end

    def self.ensure!
      return false unless Object.const_defined?("SidebarSection") && Object.const_defined?("SidebarUrl")
      section = find_or_create_section!

      upsert_link!(section, key: "shop", name: "商城", url: "/shop/public/products", admin_only: false, icon: "store")

      admin_links = [
        { key: "products",  name: "商品",  url: "/admin/plugins/discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav#products",  admin_only: true,  icon: "box" },
        { key: "orders",    name: "订单",  url: "/admin/plugins/discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav#orders",    admin_only: true,  icon: "receipt" },
        { key: "logistics", name: "物流",  url: "/admin/plugins/discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav#logistics", admin_only: true,  icon: "truck" },
        { key: "settings",  name: "设置",  url: "/admin/plugins/discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav/settings",  admin_only: true,  icon: "gear" },
      ]
      admin_links.each { |l| upsert_link!(section, **l) }

      true
    rescue => e
      Rails.logger.warn("[Shop/NavSeeder] failed: #{e.class} #{e.message}")
      false
    end
  end
end
