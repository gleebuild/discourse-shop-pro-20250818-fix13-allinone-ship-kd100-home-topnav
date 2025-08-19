import { withPluginApi } from "discourse/lib/plugin-api";
import { getURL } from "discourse-common/lib/get-url";
import Component from "@glimmer/component";

export default {
  name: "shop-top-nav",
  initialize() {
    withPluginApi("1.11.0", (api) => {
      api.renderConnector("header-buttons", "shop-top-nav", ShopNav);
    });
  },
};

class ShopNav extends Component {
  get shopURL(){ return getURL('/shop/public/products'); }
}
