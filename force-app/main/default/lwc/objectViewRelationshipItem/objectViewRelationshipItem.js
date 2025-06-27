import { api, LightningElement } from "lwc";

export default class ObjectViewRelationshipItem extends LightningElement {
  @api sourceId;
  @api recordId;
  @api nameField;
  @api value;

  get displayName() {
    if (this.value && this.value[this.nameField]) {
      return this.value[this.nameField];
    }

    return this.value?.Name || this.value?.Id || "No Name";
  }

  openContext() {
    const event = {
      detail: {
        sourceId: this.sourceId,
        recordId: this.recordId,
        nameField: this.nameField,
        name: this.displayName,
        value: this.value
      },
      bubbles: true,
      composed: true
    };

    this.dispatchEvent(new CustomEvent("opencontext", event));
  }
}
