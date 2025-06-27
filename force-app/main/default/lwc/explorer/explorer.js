import getRecentRecords from "@salesforce/apex/ExplorerCtrl.getRecentRecords";
import { LightningElement, track, wire } from "lwc";

export default class Explorer extends LightningElement {
  recordId; // for the input
  isStartingPoint = true;
  history = [];
  recent = [];
  @track records = [];

  @wire(getRecentRecords)
  wiredRecentRecords({ error, data }) {
    if (data) {
      this.recent = data;
    }
  }

  handleRecentClick(event) {
    const recordId = event.target.dataset.id;

    if (!recordId) {
      return;
    }

    const recentRecord = this.recent.find((record) => record.Id === recordId);

    if (!recentRecord) {
      return;
    }

    this.records.push({
      name: recentRecord.Name,
      id: recentRecord.Id
    });

    this.isStartingPoint = false;
  }

  handleRecordIdChange(event) {
    if (!event?.target?.value) {
      return;
    }

    this.records.push({
      name: "?",
      id: event.target.value
    });

    this.isStartingPoint = false;
  }

  handleBreadcrumbClick() {
    return;
  }

  handleDefinitionLoaded(event) {
    const recordId = event?.detail?.recordId;
    const recordObjectName = event?.detail?.name;

    if (!recordId || !recordObjectName) {
      return;
    }

    const existingRecordWithMissingName = this.records.find(
      (record) => record.id === recordId && record.name === "?"
    );

    if (existingRecordWithMissingName) {
      existingRecordWithMissingName.name = recordObjectName;
    }
  }

  handleNewEvent(event) {
    event.stopPropagation();

    const { sourceId, recordId } = event.detail;

    // get the index of the record with the sourceId
    const sourceRecordIndex = this.records.findIndex(
      (record) => record.id === sourceId
    );
    const existingRecordIndex = this.records.findIndex(
      (record) => record.id === recordId
    );

    const crumb = {
      name: event.detail.name || "?",
      id: recordId
    };

    if (sourceRecordIndex !== -1) {
      // add history entry before modifying the records
      this.addHistoryEntry();

      // remove all records after the existing record
      this.records.splice(sourceRecordIndex + 1);

      // add the new record after the existing record
      this.records.push(crumb);
    } else if (existingRecordIndex === -1) {
      this.records.push(crumb);
    }
  }

  handleLookupClick(event) {
    const { recordId, sourceId, name } = event.detail;

    if (!recordId || !sourceId || !name) {
      return;
    }

    const sourceRecordIndex = this.records.findIndex(
      (record) => record.id === sourceId
    );

    // check if the record already exists in the list
    if (this.records.find((record) => record.id === recordId)) {
      // If the record already exists, do nothing
      return;
    }

    // add history entry before modifying the records
    this.addHistoryEntry();

    // remove all records before the source record on the list
    this.records.splice(0, sourceRecordIndex);

    // push record to the a position right before on the list
    this.records.unshift({
      name,
      id: recordId
    });
  }

  addHistoryEntry() {
    // copy the current records to the history
    this.history.push(Object.assign([], this.records));
  }

  handleReset() {
    this.records = [];
    this.isStartingPoint = true;
    this.history = [];
  }
}
