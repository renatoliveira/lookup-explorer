public with sharing class Explorer {
    /**
     * Returns a SOQL query string to retrieve all fields of a record by its Id.
     * @param recordId The Id of the record to query.
     * @return A SOQL query string that retrieves all fields of the specified record.
     */
    public String getRecordQuery(Id recordId) {
        Schema.SObjectType sot = recordId.getSobjectType();
        Schema.DescribeSObjectResult describe = sot.getDescribe();

        String objectName = sot.getDescribe().getName();

        // get all the fields for the object
        Map<String, Schema.SObjectField> fields = describe.fields.getMap();

        // build the query string
        String query = 'SELECT ';

        query += String.join(new List<String>(fields.keySet()), ', ');
        query += ' FROM ' + objectName;
        query += ' WHERE Id = :recordId';

        return query;
    }

    /**
     * Retrieves a record by its Id.
     * @param recordId The Id of the record to retrieve.
     * @return The SObject record corresponding to the specified Id.
     */
    public SObject getRecord(Id recordId) {
        String query = getRecordQuery(recordId);

        return Database.query(query);
    }

    /**
     * Retrieves related records based on a child relationship.
     * @param recordId The Id of the parent record.
     * @param relationshipName The child relationship to query.
     * @return A list of SObject records that are related to the specified parent record through the given child relationship.
     */
    public RelatedRecordsResult getRelatedRecords(
        Id recordId,
        Explorer.SObjectChildRelationship relationshipName
    ) {
        RelatedRecordsResult result = new RelatedRecordsResult();
        Schema.DescribeSObjectResult describe = Schema.describeSObjects(
            new List<String>{ relationshipName.objectName }
        )[0];
        String relatedObjectNameField = new Explorer.SObjectDefinition(
                describe.getSObjectType()
            )
            .nameField;

        String query = 'SELECT ';
        query += String.join(
            new List<String>(describe.fields.getMap().keySet()),
            ', '
        );
        query += ' FROM ' + relationshipName.objectName;
        query +=
            ' WHERE ' +
            relationshipName.fieldName +
            ' = :recordId LIMIT 25';

        result.nameField = relatedObjectNameField;
        result.objectName = relationshipName.objectName;
        result.records = Database.query(query);
        result.recordCount = result.records.size();

        return result;
    }

    /**
     * Retrieves related records based on a child relationship.
     * @param recordId The Id of the parent record.
     * @param relationship The child relationship to query.
     * @return A list of SObject records that are related to the specified parent record through the given child relationship.
     */
    public RelatedRecordsResult getRelatedRecordsAggregated(
        Id recordId,
        Explorer.SObjectChildRelationship relationship
    ) {
        RelatedRecordsResult result = new RelatedRecordsResult();

        String query = 'SELECT COUNT()';
        query += ' FROM ' + relationship.objectName;
        query += ' WHERE ' + relationship.fieldName + ' = :recordId';

        result.objectName = relationship.objectName;

        try {
            result.recordCount = Database.countQuery(query);
        } catch (QueryException e) {
            // If the query fails, we can assume there are no related records
            result.recordCount = 0;
        } catch (ExternalObjectException e) {
            // Handle the case where the object is an external object
            result.recordCount = 0;
        }

        return result;
    }

    /**
     * Retrieves the definition of a record, including its fields and child relationships.
     * @param recordId The Id of the record to describe.
     * @return An SObjectDefinition object containing the name, label, fields, and child relationships of the record.
     */
    public SObjectDefinition getRecordDefinition(Id recordId) {
        return new SObjectDefinition(recordId.getSobjectType());
    }

    public class SObjectChildRelationship {
        @AuraEnabled
        public String objectName { get; set; }
        @AuraEnabled
        public String relationshipName { get; set; }
        @AuraEnabled
        public String fieldName { get; set; }
        @AuraEnabled
        public Boolean isCascadeDelete { get; set; }
        @AuraEnabled
        public Boolean isDeprecatedAndHidden { get; set; }
    }

    public class SObjectDefinition {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String nameField;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public List<String> fields;
        @AuraEnabled
        public List<Explorer.SObjectChildRelationship> childRelationships = new List<Explorer.SObjectChildRelationship>();
        @AuraEnabled
        public List<Explorer.LookupField> lookupFields = new List<Explorer.LookupField>();

        public SObjectDefinition(Schema.SObjectType sot) {
            Schema.DescribeSObjectResult describe = sot.getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = describe.fields.getMap();

            this.name = sot.getDescribe().getName();
            this.label = sot.getDescribe().getLabel();
            this.fields = new List<String>(
                sot.getDescribe().fields.getMap().keySet()
            );

            for (Schema.SObjectField field : fieldsMap.values()) {
                Schema.DescribeFieldResult fDesc = field.getDescribe();

                if (fDesc.isNameField()) {
                    this.nameField = fDesc.getName();
                }

                if (fDesc.getType() == Schema.DisplayType.REFERENCE) {
                    lookupFields.add(
                        new Explorer.LookupField(
                            fDesc.getName(),
                            fDesc.getLabel(),
                            describe.getName()
                        )
                    );
                }
            }

            List<Schema.ChildRelationship> childRelationships = describe.getChildRelationships();

            for (
                Schema.ChildRelationship childRelationship : childRelationships
            ) {
                Explorer.SObjectChildRelationship cr = new Explorer.SObjectChildRelationship();
                cr.fieldName = childRelationship.getField()
                    .getDescribe()
                    .getName();
                cr.objectName = childRelationship.getChildSObject()
                    .getDescribe()
                    .getName();
                cr.relationshipName = childRelationship.getRelationshipName();
                cr.isCascadeDelete = childRelationship.isCascadeDelete();
                cr.isDeprecatedAndHidden = childRelationship.isDeprecatedAndHidden();

                this.childRelationships.add(cr);
            }
        }
    }

    public class RelatedRecordsResult {
        @AuraEnabled
        public String objectName { get; set; }
        @AuraEnabled
        public String nameField { get; set; }
        @AuraEnabled
        public List<SObject> records { get; set; }
        @AuraEnabled
        public Integer recordCount { get; set; }
    }

    public class LookupField {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String objectName;

        public LookupField(String name, String label, String objectName) {
            this.name = name;
            this.label = label;
            this.objectName = objectName;
        }
    }
}
