import { helper } from '@ember/component/helper'; export default helper(function priceCny([cents]){ let v=parseInt(cents||0,10)/100; if(isNaN(v)) v=0; return v.toFixed(2);});
