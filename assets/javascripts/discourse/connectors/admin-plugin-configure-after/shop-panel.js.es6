import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";
import { getURL } from "discourse-common/lib/get-url";

export default apiInitializer("1.11.0", (api) => {
  api.decoratePluginOutlet("admin-plugin-configure:after", (elem, args) => {
    const { pluginId } = args;
    // Be tolerant across Discourse versions: derive pluginId from args or URL
let isTarget = false;
if (pluginId === "discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav") isTarget = true;
const path = (window.location && window.location.pathname) || "";
if (path.includes("/admin/plugins/discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav")) isTarget = true;
// Some builds don't pass pluginId in args, so rely on URL fallback
if (!isTarget) return;
    const box = document.createElement("div");

// Create right-side tabs next to "设置"
function ensureTabs() {
  const tryAttach = () => {
    const container = document.querySelector(".admin-plugin-config") || document.querySelector(".admin-plugins") || document.querySelector("#admin-plugins");
    if (!container) return false;
    const nav = container.querySelector("ul.nav-pills, ul.nav, nav ul.nav, .nav.nav-pills");
    if (!nav) return false;
    // Avoid duplicates
    if (nav.querySelector("a[data-tab='products']")) return true;

    const tabs = [
      ["products", "商品"],
      ["orders", "订单"],
      ["logistics", "物流"],
      ["home", "首页条幅"]
    ];

    tabs.forEach(([key, label]) => {
      const li = document.createElement("li");
      li.className = "nav-item";
      const a = document.createElement("a");
      a.href = "#";
      a.setAttribute("data-tab", key);
      a.textContent = label;
      li.appendChild(a);
      nav.appendChild(li);
    });

    // Ensure '设置' tab has data-tab=settings
    const activeLi = nav.querySelector("li.active");
    if (activeLi && activeLi.querySelector("a") && !activeLi.querySelector("a").getAttribute("data-tab")) {
      activeLi.querySelector("a").setAttribute("data-tab", "settings");
    }
    return true;
  };

  if (tryAttach()) return;
  // Fallback: observe mutations until nav appears
  const obs = new MutationObserver(() => {
    if (tryAttach()) obs.disconnect();
  });
  obs.observe(document.body, { childList: true, subtree: true });
}

// --- Tab switching for right-side nav ---
function switchTab(tab) {
  const settingsBox = document.querySelector(".admin-plugin-config");
  const panel = box;
  panel.style.display = "block";
  // Toggle settings visibility
  if (tab === "settings") {
    if (settingsBox) settingsBox.style.display = "";
    panel.style.display = "none";
    return;
  } else {
    if (settingsBox) settingsBox.style.display = "none";
  }

  // Mark active tab in the nav
  document.querySelectorAll("ul.nav-pills li.nav-item a[data-tab]").forEach(a=>{
    if (a.getAttribute("data-tab") === tab) {
      a.parentElement.classList.add("active");
    } else {
      a.parentElement.classList.remove("active");
    }
  });

  if (tab === "products") {
    panel.innerHTML = "<h3 style='margin:10px 0'>商品管理</h3><p><a class='btn btn-primary' href='/shop/admin/products/new' target='_blank'>创建商品</a> <a class='btn' href='/shop/admin/products' target='_blank'>商品列表</a></p>";
  } else if (tab === "orders") {
    panel.innerHTML = "<h3 style='margin:10px 0'>订单管理</h3><div class='shop-orders-panel'>加载中...</div>";
    load();
    ensureTabs();
    bindTabClicks(); // reuse existing load() to fetch orders table
  } else if (tab === "logistics") {
    panel.innerHTML = "<h3 style='margin:10px 0'>发货/物流</h3><p>在订单列表中点击“发货”按钮可录入快递公司与单号。</p>";
    load();
    ensureTabs();
    bindTabClicks();
  } else if (tab === "home") {
    panel.innerHTML = "<h3 style='margin:10px 0'>首页条幅</h3><p>在站点首页顶部展示商城入口，已在“设置”中提供开关与文案配置。</p>";
  } else {
    // fallback
    panel.innerHTML = "<p>未识别的标签：" + tab + "</p>";
  }
  // save current tab in hash so refresh keeps it
  if (window.history && window.history.replaceState) {
    const url = new URL(window.location.href);
    url.hash = "#" + tab;
    window.history.replaceState(null, "", url.toString());
  } else {
    window.location.hash = "#" + tab;
  }
}

function bindTabClicks() {
  document.querySelectorAll("ul.nav-pills li.nav-item a[data-tab]").forEach(a=>{
    a.addEventListener("click", (e)=>{
      e.preventDefault();
      const tab = a.getAttribute("data-tab");
      switchTab(tab);
    });
  });
  // Load from hash
  const hash = (window.location.hash || "").replace("#","");
  if (hash) {
    switchTab(hash);
  }
}
    box.className = "card shop-admin";
    box.innerHTML = `
      <h3>快捷入口</h3>
      <p><a class="btn" href="${getURL('/shop/public/products')}" target="_blank">打开前台列表</a>
         <a class="btn" href="${getURL('/admin/site_settings/category/plugins?filter=shop')}" target="_blank">打开商城设置</a></p>
      <h3>订单（最近200）</h3>
      <table class="table" id="shop-orders"><thead>
        <tr><th>ID</th><th>状态</th><th>金额</th><th>物流</th><th>操作</th></tr>
      </thead><tbody></tbody></table>
    `;
    elem.append(box);
    const tbody = box.querySelector("#shop-orders tbody");
    function renderRow(o){
      const ship = (o.shipments||[]).map(s=>`[${s.carrier}] ${s.tracking_no} — ${s.status}`).join("<br>") || "<span class='muted'>暂无</span>";
      const price = ((o.total_cents||0)/100).toFixed(2);
      const tr = document.createElement("tr");
      tr.innerHTML = `<td>${o.id}</td><td>${o.status||"?"}</td><td>¥${price}</td><td>${ship}</td><td><button class="btn btn-primary" data-id="${o.id}">发货</button></td>`;
      tbody.appendChild(tr);
    }
    function load(){
      ajax(getURL('/shop/admin/orders.json')).then(list=>{ tbody.innerHTML=""; (list||[]).forEach(renderRow); bind(); });
    }
    function bind(){
      tbody.querySelectorAll("button[data-id]").forEach(btn=>{
        btn.onclick = ()=>{
          const id = btn.getAttribute("data-id");
          const carrier = prompt("快递公司编码（如 yunda/yuantong/zhongtong/shentong/sf）");
          if(!carrier) return;
          const tracking_no = prompt("运单号");
          if(!tracking_no) return;
          ajax(getURL(`/shop/admin/orders/${id}/ship`), { type:"POST", data:{ carrier, tracking_no } }).then(load);
        };
      });
    }
    load();
    ensureTabs();
    bindTabClicks();
  });
});
