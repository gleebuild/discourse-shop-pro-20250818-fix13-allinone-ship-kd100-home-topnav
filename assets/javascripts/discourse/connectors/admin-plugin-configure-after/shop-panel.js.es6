import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";
import { getURL } from "discourse-common/lib/get-url";

export default apiInitializer("1.11.0", (api) => {
  api.decoratePluginOutlet("admin-plugin-configure:after", (elem, args) => {
    const { pluginId } = args;
    if (pluginId !== "discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav") return;
    const box = document.createElement("div");
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
  });
});
