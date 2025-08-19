import { withPluginApi } from "discourse/lib/plugin-api";
import Component from "@glimmer/component";
import { ajax } from "discourse/lib/ajax";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { getURL } from "discourse-common/lib/get-url";

export default {
  name: "shop-home-strip",
  initialize() {
    withPluginApi("1.11.0", (api) => {
      api.renderConnector("discovery-list-container-top", "shop-home-strip", ShopStrip);
    });
  },
};

class ShopStrip extends Component {
  @tracked items = [];
  @tracked page = 0;
  perPage = 2;

  constructor() {
    super(...arguments);
    this.load();
  }

  async load(){
    const list = await ajax(getURL('/shop/public/products.json?limit=12'));
    this.items = (list || []).map(p => ({ ...p, first_image: (p.images||[])[0] }));
  }

  productURL(id){ return getURL(`/shop/public/products/${id}`); }

  get visible(){
    const start = this.page * this.perPage;
    return this.items.slice(start, start + this.perPage);
  }
  get isFirst(){ return this.page <= 0; }
  get isLast(){ return (this.page + 1) * this.perPage >= this.items.length; }

  @action prev(){ if(!this.isFirst){ this.page--; } }
  @action next(){ if(!this.isLast){ this.page++; } }
}
