import { api, LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getRecord from "@salesforce/apex/ExplorerCtrl.getRecord";

export default class ObjectViewLookupItem extends NavigationMixin(
  LightningElement
) {
  @api sourceId;
  @api recordId;
  @api recordName;
  value;

  get hasLookup() {
    return !!this.recordId;
  }

  get loading() {
    return !!this.recordId && !this.value;
  }

  @wire(getRecord, { recordId: "$recordId" })
  wiredRecord({ error, data }) {
    if (data) {
      this.value = data;
    } else if (error) {
      console.error("Error fetching record:", error);
    }
  }

  handleClick() {
    const event = {
      detail: {
        sourceId: this.sourceId,
        recordId: this.recordId,
        name: this.recordName
      },
      bubbles: true,
      composed: true
    };

    this.dispatchEvent(new CustomEvent("lookupclick", event));
  }
}
