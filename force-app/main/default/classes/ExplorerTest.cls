@IsTest
private class ExplorerTest {
    @TestSetup
    static void setup() {
        Account a = new Account(Name = 'Test Account');
        insert a;

        Contact c = new Contact(LastName = 'Test Contact', AccountId = a.Id);
        insert c;
    }

    @IsTest
    static void test1() {
        // Test data setup
        Explorer e = new Explorer();
        Account a = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        // Actual test
        Test.startTest();
        Account result1 = (Account) e.getRecord(a.Id);
        Test.stopTest();

        // Asserts
        Assert.areEqual(
            a.Id,
            result1.Id,
            'The record ID should match the inserted account ID'
        );
    }

    @IsTest
    static void test2() {
        // Test data setup
        Account a = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];
        Explorer e = new Explorer();

        Test.startTest();
        Explorer.SObjectDefinition def = e.getRecordDefinition(a.Id);
        Assert.isNotNull(def, 'The record definition should not be null');
        Assert.areEqual(
            'Account',
            def.name,
            'The record definition name should be Account'
        );
        Assert.isNotNull(
            def.childRelationships,
            'The child relationships should not be null'
        );
        Assert.isTrue(
            def.childRelationships.size() > 0,
            'There should be at least one child relationship'
        );

        Explorer.SObjectChildRelationship contactRelationship;

        for (Explorer.SObjectChildRelationship rel : def.childRelationships) {
            if (rel.objectName != 'Contact') {
                continue;
            }

            Assert.areEqual(
                'Contacts',
                rel.relationshipName,
                'The relationship name for Contact should be Contacts'
            );
            Assert.isTrue(
                rel.isCascadeDelete,
                'The Contact relationship should allow cascade delete'
            );

            contactRelationship = rel;

            break;
        }

        Explorer.RelatedRecordsResult contactsResult1 = (Explorer.RelatedRecordsResult) e.getRelatedRecords(
            a.Id,
            contactRelationship
        );
        Assert.isNotNull(
            contactsResult1,
            'The related records should not be null'
        );
        Assert.areEqual(
            1,
            contactsResult1.records.size(),
            'There should be one related contact'
        );

        Explorer.RelatedRecordsResult contactsResult2 = (Explorer.RelatedRecordsResult) e.getRelatedRecordsAggregated(
            a.Id,
            contactRelationship
        );
        Assert.isNotNull(
            contactsResult2,
            'The related records should not be null'
        );
        Assert.areEqual(
            1,
            contactsResult2.recordCount,
            'There should be one related contact in the aggregated result'
        );
        Test.stopTest();
    }
}
