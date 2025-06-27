public with sharing class ExplorerCtrl {
    private static Explorer e = new Explorer();

    @AuraEnabled(cacheable=true)
    public static String getRecordQuery(Id recordId) {
        return e.getRecordQuery(recordId);
    }

    @AuraEnabled(cacheable=true)
    public static SObject getRecord(Id recordId) {
        return e.getRecord(recordId);
    }

    @AuraEnabled(cacheable=true)
    public static Explorer.RelatedRecordsResult getRelatedRecords(
        Id recordId,
        Explorer.SObjectChildRelationship relationship
    ) {
        return e.getRelatedRecords(recordId, relationship);
    }

    @AuraEnabled(cacheable=true)
    public static Explorer.RelatedRecordsResult getRelatedRecordsAggregated(
        Id recordId,
        Explorer.SObjectChildRelationship relationship
    ) {
        return e.getRelatedRecordsAggregated(recordId, relationship);
    }

    @AuraEnabled(cacheable=true)
    public static Explorer.SObjectDefinition getRecordDefinition(Id recordId) {
        return e.getRecordDefinition(recordId);
    }

    @AuraEnabled(cacheable=true)
    public static List<RecentlyViewed> getRecentRecords() {
        try {
            return [SELECT Id, Name FROM RecentlyViewed];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
