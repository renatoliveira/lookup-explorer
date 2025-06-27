import { api, LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getRecord from "@salesforce/apex/ExplorerCtrl.getRecord";
import getRecordDefinition from "@salesforce/apex/ExplorerCtrl.getRecordDefinition";

export default class ObjectView extends NavigationMixin(LightningElement) {
  @api recordId;
  childRelationships = [];
  recordDefinition;
  record;

  get hasChildRelationships() {
    return (
      this.recordDefinition?.childRelationships &&
      this.recordDefinition.childRelationships.length > 0
    );
  }

  get hasLookups() {
    return (
      this.recordDefinition?.lookupFields &&
      this.recordDefinition.lookupFields.length > 0
    );
  }

  get lookupFields() {
    if (this.recordDefinition?.lookupFields && this.record) {
      return this.recordDefinition.lookupFields.map((field) => {
        return {
          name: field.name,
          label: field.label,
          value: this.record[field.name],
          recordId: this.recordId
        };
      });
    }
  }

  get name() {
    if (this.recordDefinition?.nameField && this.record) {
      return this.record[this.recordDefinition?.nameField];
    }

    return this.record?.Name || this.record?.Id || "No Name";
  }

  get objectLabel() {
    if (this.recordDefinition?.label) {
      return this.recordDefinition.label;
    }

    return this.recordDefinition?.name || "";
  }

  @wire(getRecord, { recordId: "$recordId" })
  wiredRecord({ error, data }) {
    if (data) {
      this.record = data;
      this.handleLoadDefinition();
    } else if (error) {
      console.error("Error fetching record:", error);
    }
  }

  @wire(getRecordDefinition, { recordId: "$recordId" })
  wiredRecordDefinition({ error, data }) {
    if (data) {
      this.recordDefinition = data;
      this.childRelationships =
        this.recordDefinition?.childRelationships?.filter((r) => {
          return !!r.relationshipName;
        }) || [];
      this.fields = this.recordDefinition.fields || [];
      this.handleLoadDefinition();
    } else if (error) {
      console.error("Error fetching record definition:", error);
    }
  }

  handleLoadDefinition() {
    if (!this.recordDefinition || !this.recordId) {
      return;
    }

    this.dispatchRecordDefinitionLoadedEvent();
  }

  dispatchRecordDefinitionLoadedEvent() {
    this.dispatchEvent(
      new CustomEvent("recorddefinitionloaded", {
        detail: {
          recordId: this.recordId,
          name: this.name
        },
        bubbles: true,
        composed: true
      })
    );
  }

  handleNavigateToRecord() {
    this[NavigationMixin.GenerateUrl]({
      type: "standard__recordPage",
      attributes: {
        recordId: this.recordId,
        actionName: "view"
      }
    }).then((url) => {
      window.open(url, "_blank");
    });
  }
}
