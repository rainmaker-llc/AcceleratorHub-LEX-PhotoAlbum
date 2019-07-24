@isTest 
private class PhotoAlbumChatterComponentCtrlTest {
    @isTest static void testChatterComponent() {
        
        Account a = new Account();
        a.Name = 'TestClass';
        insert a;
        List<Account> acc = [SELECT Id,name FROM Account WHERE Id = :a.Id LIMIT 1];
        System.assertEquals(acc.size(), 1);
        
        FeedItem fi = new FeedItem();
        fi.Body = 'Testclass';
        fi.parentId = a.Id;
        insert fi; 
        List<FeedItem> feditem = [Select Id from FeedItem where Id = :fi.Id];
        System.assertEquals(feditem.size(), 1);
        
        ContentVersion contentVersion_1 = new ContentVersion(
            PathOnClient = 'cartoon.png',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert contentVersion_1;
        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];ContentDocument cd = new ContentDocument();
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        System.assertEquals(documents.size(), 1);
        System.assertEquals(documents[0].Id, contentVersion_2.ContentDocumentId);
        System.assertEquals(documents[0].LatestPublishedVersionId, contentVersion_2.Id);
        
        FeedAttachment feedAttachment = new FeedAttachment();
        feedAttachment.FeedEntityId = fi.Id;
        feedAttachment.RecordId = contentVersion_2.Id ; 
        feedAttachment.Type = 'Content'; 
        insert feedAttachment;
        List<feedAttachment> fa = [Select Id from feedAttachment where Id = :feedAttachment.Id];
        System.assertEquals(fa.size(), 1);
        List<FeedComment> feedComments=new List<FeedComment>();
        feedComments.add(new FeedComment(feedItemId=fi.Id,
                                         RelatedRecordId=contentVersion_2.Id,
                                         CommentBody='#testBody'
                                        ));
        feedComments.add(new FeedComment(feedItemId=fi.Id,
                                         CommentBody='<p> #testBody '+ '<img src="sfdc://"'+contentVersion_2.Id+' alt="Test"></img></p>'
                                        ));
        insert feedComments;
        
        
        PhotoAlbumChatterComponentCtrl.getChatterComponent(a.Id);
        PhotoAlbumChatterComponentCtrl.saveChunk(a.Id,fi.Body,contentVersion_2.ContentDocumentId,contentVersion_1.PathOnClient);
        PhotoAlbumChatterComponentCtrl.getContentIds('<img src="sfdc://"'+contentVersion_2.Id+' alt="Test"></img>') ;
    }
}