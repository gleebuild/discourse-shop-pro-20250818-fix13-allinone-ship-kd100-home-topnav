
import { apiInitializer } from "discourse/lib/api";
import { getOwner } from "@ember/application";
import { getURL } from "discourse-common/lib/get-url";
import I18n from "I18n";

export default apiInitializer("1.11.0", (api) => {
  const settings = api.container.lookup("service:site-settings");

  if (!settings.shop_auto_nav_enabled) return;

  function isStaff() {
    try {
      const currentUser = api.getCurrentUser();
      return !!(currentUser && (currentUser.staff || currentUser.admin || currentUser.moderator));
    } catch(e) {
      return false;
    }
  }

  const links = {
    public: [
      {
        key: "shop",
        text: I18n.t("shop.nav.shop", "商城"),
        href: getURL("/shop/public/products"),
      },
    ],
    admin: [
      {
        key: "products",
        text: I18n.t("shop.nav.products", "商品"),
        href: getURL("/admin/plugins/discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav#products"),
      },
      {
        key: "orders",
        text: I18n.t("shop.nav.orders", "订单"),
        href: getURL("/admin/plugins/discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav#orders"),
      },
      {
        key: "logistics",
        text: I18n.t("shop.nav.logistics", "物流"),
        href: getURL("/admin/plugins/discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav#logistics"),
      },
      {
        key: "settings",
        text: I18n.t("shop.nav.settings", "设置"),
        href: getURL("/admin/plugins/discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav/settings"),
      },
    ],
  };

  function ensureShopSection() {
    // Find generic sidebar container
    const sidebar = document.querySelector("aside.sidebar, .sidebar-container, .sidebar-sections");
    if (!sidebar) return;

    // Prefer built-in custom sections list, else create our own section at top
    let list = document.querySelector(".sidebar-sections .custom-sections .sidebar-section-link-list");
    let section = null;
    if (!list) {
      let sections = document.querySelector(".sidebar-sections");
      if (!sections) {
        sections = document.createElement("div");
        sections.className = "sidebar-sections";
        sidebar.appendChild(sections);
      }
      section = document.querySelector(".sidebar-section.shop-section");
      if (!section) {
        section = document.createElement("div");
        section.className = "sidebar-section shop-section";
        const title = document.createElement("div");
        title.className = "sidebar-section-title";
        title.textContent = I18n.t("shop.nav.title", "商城");
        section.appendChild(title);
        list = document.createElement("ul");
        list.className = "sidebar-section-link-list";
        section.appendChild(list);
        sections.insertBefore(section, sections.firstChild);
      } else {
        list = section.querySelector("ul.sidebar-section-link-list");
      }
    }

    if (!list) return;

    // Avoid duplicate links
    const existingKeys = new Set(Array.from(list.querySelectorAll("li[data-shop-key]")).map(li => li.getAttribute("data-shop-key")));

    function appendLink(item) {
      if (existingKeys.has(item.key)) return;
      const li = document.createElement("li");
      li.className = "sidebar-section-link";
      li.setAttribute("data-shop-key", item.key);
      const a = document.createElement("a");
      a.className = "sidebar-section-link-wrapper";
      a.href = item.href;
      a.textContent = item.text;
      li.appendChild(a);
      list.appendChild(li);
    }

    if (settings.shop_auto_nav_public_shop_link) {
      links.public.forEach(appendLink);
    }
    if (settings.shop_auto_nav_admin_only_links && isStaff()) {
      links.admin.forEach(appendLink);
    }
  }

  // Run initially and on each page change
  api.onPageChange(() => {
    try {
      // Observe mutations briefly to wait for sidebar to render
      let ran = false;
      const ready = () => { if (!ran) { ran = true; ensureShopSection(); } };
      const obs = new MutationObserver((muts) => {
        const sidebar = document.querySelector("aside.sidebar, .sidebar-container, .sidebar-sections");
        if (sidebar) { ready(); obs.disconnect(); }
      });
      obs.observe(document.body, { childList: true, subtree: true });
      // Fallback timeout
      setTimeout(ready, 500);
    } catch(e) {
      // swallow
    }
  });
});
