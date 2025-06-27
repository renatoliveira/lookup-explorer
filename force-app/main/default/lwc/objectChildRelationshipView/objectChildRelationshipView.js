import { api, LightningElement } from "lwc";
import getRelatedRecordsAggregated from "@salesforce/apex/ExplorerCtrl.getRelatedRecordsAggregated";
import getRelatedRecords from "@salesforce/apex/ExplorerCtrl.getRelatedRecords";

export default class ObjectChildRelationshipView extends LightningElement {
  @api recordId;
  @api relationship;
  loading = true;
  value;
  recordCount = 0;

  get display() {
    return this.recordCount > 0;
  }

  get records() {
    if (this.value && this.value.records) {
      return this.value.records;
    }
    return [];
  }

  connectedCallback() {
    getRelatedRecordsAggregated({
      recordId: this.recordId,
      relationship: this.relationship
    })
      .then((data) => {
        this.recordCount = data?.recordCount || 0;
      })
      .catch((error) => {
        console.error(
          "Error fetching related records:",
          error,
          JSON.stringify(this.relationship)
        );
      })
      .finally(() => {
        this.loading = false;
      });
  }

  handleClick() {
    if (this.loading) {
      // if we're already loading, do nothing
      return;
    }

    // when the user clicks on the relationship, we'll query the data to show the related records
    this.loading = true;

    getRelatedRecords({
      recordId: this.recordId,
      relationship: this.relationship
    })
      .then((data) => {
        this.value = data;
        this.recordCount = data?.recordCount || 0;
      })
      .catch((error) => {
        console.error(
          "Error fetching related records:",
          error,
          JSON.stringify(this.relationship)
        );
      })
      .finally(() => {
        this.loading = false;
      });
  }
}
